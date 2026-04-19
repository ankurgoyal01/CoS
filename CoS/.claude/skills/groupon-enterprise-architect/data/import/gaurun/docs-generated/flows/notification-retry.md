---
service: "gaurun"
title: "Notification Retry Flow"
generated: "2026-03-03"
type: flow
flow_name: "notification-retry"
flow_type: event-driven
trigger: "Push delivery fails; RetryQueueWorkerNew publishes to mta.gaurun.retry Kafka topic"
participants:
  - "gaurunPushWorkerManager"
  - "gaurunRetryProcessor"
  - "gaurunKafkaProducer"
  - "gaurunKafkaConsumer"
  - "gaurunHttpApi"
  - "gaurunNotificationIngestor"
architecture_ref: "GaurunComponents"
---

# Notification Retry Flow

## Summary

When a push notification fails delivery to APNs or FCM with a retriable error (after exhausting the immediate retry count), Gaurun publishes the failed notification to the `mta.gaurun.retry` Kafka topic. A dedicated `RetryQueueProcessorNew` goroutine consumes from that topic, enforces a minimum message age delay (default 5 minutes), increments the attempt counter, and re-submits the notification to the local `POST /grpn/retry` endpoint. The flow repeats until the notification is delivered or the maximum attempt count (default 12) is reached, at which point it is permanently dropped.

## Trigger

- **Type**: event
- **Source**: `retryQueueWorker.RetryLaterNew(req)` called by a push worker goroutine after exhausting `retry_max` inline retries on a retriable error
- **Frequency**: On-demand, triggered per failed notification

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Push Worker Manager | Detects retriable failure; calls RetryQueueWorkerNew | `gaurunPushWorkerManager` |
| Retry Queue Worker | Publishes failed notification to `mta.gaurun.retry` | `gaurunRetryProcessor` |
| Kafka cluster | Stores retry messages on `mta.gaurun.retry` topic | `kafkaCluster_2f6b9d` |
| Retry Processor | Consumes retry topic; enforces delay; re-submits | `gaurunRetryProcessor` |
| HTTP API (local) | Receives re-submitted notification at `POST /grpn/retry` | `gaurunHttpApi` |
| Notification Ingestor | Re-enqueues notification for delivery | `gaurunNotificationIngestor` |

## Steps

1. **Detect retriable failure**: Push worker goroutine (`pushAsync` or `pushSync`) calls `pusher(req, c)` and receives an error. `isExternalServerError(err, platform)` returns `true` (e.g., `IdleTimeout`, `Shutdown`, `InternalServerError`, `ServiceUnavailable` for APNs; `Unavailable`, `InternalServerError`, timeout for FCM). `req.Retry < retryMax` is `false` (immediate retry budget exhausted).
   - From: `gaurunPushWorkerManager`
   - To: `gaurunRetryProcessor`
   - Protocol: In-process function call

2. **Publish to retry Kafka topic**: `RetryLaterNew(req)` JSON-marshals the `RequestGaurunNotification` (with current `attempts` count and `created` timestamp) and publishes to the `mta.gaurun.retry` Kafka topic (consumer group: `gaurun.consumer.group`).
   - From: `gaurunRetryProcessor` (worker role)
   - To: Kafka cluster (`kafkaCluster_2f6b9d`)
   - Protocol: Kafka (SSL)

3. **Consume retry record**: `RetryQueueProcessorNew.Run` goroutine's inner `ConsumeRetryRecord` call reads a message from `mta.gaurun.retry` into `messageChan` (buffered, capacity 5,000).
   - From: Kafka cluster
   - To: `gaurunRetryProcessor` (processor role)
   - Protocol: Kafka (SSL)

4. **Enforce minimum age delay**: Processor checks if `notification.Created` is older than `retry_later.min_message_age` (default 300,000 ms = 5 minutes). If the message is too new, `time.Sleep(minAge)` pauses processing. This prevents rapid re-delivery during sustained outages.
   - From: `gaurunRetryProcessor`
   - To: (internal delay)
   - Protocol: In-process

5. **Check attempt limit**: If `notification.Attempt >= retry_later.max_retries` (default 12), logs error and discards the message. Emits `gaurun.retry.exhausted` metric.
   - From: `gaurunRetryProcessor`
   - To: (drop path)
   - Protocol: In-process

6. **Re-submit to retry endpoint**: Processor resets `notification.Created = time.Now()` and POSTs the JSON-encoded notification to the local `POST /grpn/retry` endpoint via `SimpleHttpClient`.
   - From: `gaurunRetryProcessor`
   - To: `gaurunHttpApi`
   - Protocol: HTTP/JSON (loopback)

7. **Validate and re-enqueue**: `GrpnRetryLaterEndpoint` handler increments `notification.Attempt`, validates non-zero, checks attempt limit again, emits `gaurun.retry.attempt{retry-count=N}` metric, and calls `enqueueNotifications` to re-enqueue for delivery.
   - From: `gaurunHttpApi`
   - To: `gaurunNotificationIngestor`
   - Protocol: In-process

8. **Re-dispatch to push worker**: `enqueueNotifications` routes the notification to `QueueIosNotification` or `QueueAndroidNotification` in-memory channel (not via Kafka for retry path — uses direct in-memory queue).
   - From: `gaurunNotificationIngestor`
   - To: `gaurunPushWorkerManager`
   - Protocol: Go channel

9. **Attempt delivery**: Push worker retries delivery to APNs or FCM. On success, flow ends. On retriable failure, cycle repeats from Step 1.
   - From: `gaurunPushWorkerManager`
   - To: `appleApns_7f1d6a` / `googleFcm_9c4e1b`
   - Protocol: HTTP/2 or HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `notification.Attempt >= max_retries` (12) | Logs error; emits `gaurun.retry.exhausted` metric; discards | Notification permanently dropped |
| JSON unmarshal error on retry message | Logs error; message skipped | Message consumed but not retried |
| `POST /grpn/retry` returns non-200 | Logs error; message is consumed but delivery not retried from Kafka | Notification lost for this cycle |
| Non-retriable APNs/FCM error | Not published to retry topic; logged as `failed-push` | Notification dropped permanently |
| `mta.gaurun.retry` topic consumer channel closed (shutdown) | `ConsumeRetryRecord` closes `messageChan`; processor exits | Graceful shutdown; in-flight retries may be lost |

## Sequence Diagram

```
gaurunPushWorkerManager -> APNs/FCM: attempt delivery (fails, retriable)
gaurunPushWorkerManager -> gaurunRetryProcessor: RetryLaterNew(req)
gaurunRetryProcessor -> mta.gaurun.retry (Kafka): publish notification JSON
RetryQueueProcessorNew -> mta.gaurun.retry (Kafka): consume message
RetryQueueProcessorNew -> RetryQueueProcessorNew: enforce min_message_age delay
RetryQueueProcessorNew -> gaurunHttpApi: POST /grpn/retry (notification JSON)
gaurunHttpApi -> gaurunNotificationIngestor: increment attempt; re-enqueue
gaurunNotificationIngestor -> QueueIosNotification/QueueAndroidNotification: enqueue
gaurunPushWorkerManager -> APNs/FCM: reattempt delivery
```

## Related

- Architecture component view: `GaurunComponents`
- Related flows: [iOS Push Notification Dispatch](ios-push-dispatch.md), [Android Push Notification Dispatch](android-push-dispatch.md)
- Configuration: [Configuration](../configuration.md) — `[retry_later]` and `[kafka]` sections
- Events: [Events](../events.md) — `mta.gaurun.retry` topic details
- Runbook: [Runbook](../runbook.md) — Retry topic backlog troubleshooting
