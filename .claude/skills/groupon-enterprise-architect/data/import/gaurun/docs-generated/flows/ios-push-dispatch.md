---
service: "gaurun"
title: "iOS Push Notification Dispatch"
generated: "2026-03-03"
type: flow
flow_name: "ios-push-dispatch"
flow_type: asynchronous
trigger: "POST /grpn/push with vctx.jobType=APNS"
participants:
  - "notificationProducerService_4b2a5c"
  - "gaurunHttpApi"
  - "gaurunNotificationIngestor"
  - "gaurunQueueManager"
  - "gaurunKafkaProducer"
  - "gaurunKafkaConsumer"
  - "gaurunPushWorkerManager"
  - "gaurunApnsClient"
  - "appleApns_7f1d6a"
  - "gaurunRetryProcessor"
  - "gaurunMetricsReporter"
  - "gaurunAccessLogger"
architecture_ref: "GaurunComponents"
---

# iOS Push Notification Dispatch

## Summary

This flow describes how Gaurun accepts an iOS push notification request from an internal producer, validates and normalizes the payload, publishes it to the `ios_gaurun_pn` Kafka topic for durability, consumes it back into a per-context in-memory queue, and dispatches it to Apple APNs via HTTP/2. The caller receives an immediate `200 OK` after the notification is enqueued; delivery to Apple is asynchronous. Delivery results are emitted as metrics and logged for analytics.

## Trigger

- **Type**: api-call
- **Source**: Internal notification producer service POSTs to `POST /grpn/push`
- **Frequency**: On-demand, per notification batch

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Notification Producer | Initiates push request | `notificationProducerService_4b2a5c` |
| HTTP API | Receives and validates HTTP request | `gaurunHttpApi` |
| Notification Ingestor | Normalizes payload into `RequestGaurunNotification` | `gaurunNotificationIngestor` |
| Queue Manager | Routes notification to APNs producer channel | `gaurunQueueManager` |
| Kafka Producer | Publishes notification to `ios_gaurun_pn` Kafka topic | `gaurunKafkaProducer` |
| Kafka Consumer | Consumes from `ios_gaurun_pn`; routes into per-context queue | `gaurunKafkaConsumer` |
| Push Worker Manager | Dispatches from per-context queue to APNs client | `gaurunPushWorkerManager` |
| APNs Client | Sends notification to Apple APNs via HTTP/2 | `gaurunApnsClient` |
| Apple APNs | External iOS notification gateway | `appleApns_7f1d6a` |
| Retry Processor | Handles failed delivery by publishing to `mta.gaurun.retry` | `gaurunRetryProcessor` |
| Metrics Reporter | Records success/failure counters | `gaurunMetricsReporter` |
| Access Logger | Writes per-notification push log entry | `gaurunAccessLogger` |

## Steps

1. **Receive push request**: Producer service POSTs `GrpnPayload` JSON to `POST /grpn/push`.
   - From: `notificationProducerService_4b2a5c`
   - To: `gaurunHttpApi`
   - Protocol: HTTP/JSON

2. **Validate request format**: HTTP API checks method is `POST`, body is non-empty, then decodes `GrpnPayload`.
   - From: `gaurunHttpApi`
   - To: `gaurunNotificationIngestor`
   - Protocol: In-process

3. **Normalize payload**: For each recipient in `GrpnPayload.Recipients`, ingestor maps `IosPayload` fields to `RequestGaurunNotification` (`platform=1`, title, body, badge, sound, content-available, mutable-content, extend fields, `context` from `to` field).
   - From: `gaurunHttpApi`
   - To: `gaurunNotificationIngestor`
   - Protocol: In-process

4. **Return 200 OK to caller**: After calling `enqueueNotificationsInQueue`, HTTP API returns `{"message":"ok"}` immediately. Subsequent steps are asynchronous.
   - From: `gaurunHttpApi`
   - To: `notificationProducerService_4b2a5c`
   - Protocol: HTTP/JSON

5. **Validate notification fields**: Ingestor checks token non-empty, platform in range `[1,3]`, message non-empty (unless `allows_empty_message=true`), push_type valid.
   - From: `gaurunNotificationIngestor`
   - To: `gaurunQueueManager`
   - Protocol: In-process

6. **Enqueue to APNS producer channel**: Valid notification is placed on `APNSProducerQueueNotification` (buffered channel, capacity 100,000). If full, returns `429`.
   - From: `gaurunNotificationIngestor`
   - To: `gaurunQueueManager`
   - Protocol: Go channel

7. **Publish to Kafka topic**: Kafka producer goroutine reads from `APNSProducerQueueNotification`, JSON-marshals the notification, and publishes to `ios_gaurun_pn` Kafka topic (SSL, acks=1, lz4 compression).
   - From: `gaurunKafkaProducer`
   - To: Kafka cluster (`kafkaCluster_2f6b9d`)
   - Protocol: Kafka (SSL)

8. **Consume from Kafka topic**: Kafka consumer goroutine (consumer group `ios.gaurun.consumer.group`) reads from `ios_gaurun_pn`, unmarshals the notification, reads `context` field (e.g., `iphone-consumer`), and routes into the matching named in-memory queue channel.
   - From: `gaurunKafkaConsumer`
   - To: `gaurunQueueManager`
   - Protocol: Kafka (SSL) → in-process channel

9. **Dispatch to push worker**: iOS push worker goroutine (`pushNotificationIosWorker`) reads from the named context queue, acquires a semaphore slot, and spawns an async goroutine to deliver the notification.
   - From: `gaurunQueueManager`
   - To: `gaurunPushWorkerManager`
   - Protocol: Go channel

10. **Build APNs payload**: APNs client sets the notification message fields (alert, badge, sound, content-available, mutable-content, extend extras) on the request.
    - From: `gaurunPushWorkerManager`
    - To: `gaurunApnsClient`
    - Protocol: In-process

11. **Send to Apple APNs**: APNs client sends HTTP/2 request to `api.push.apple.com` (or sandbox). On success, increments `StatGaurun.Ios.PushSuccess` and calls `ReportSuccessfulSend`.
    - From: `gaurunApnsClient`
    - To: `appleApns_7f1d6a`
    - Protocol: HTTP/2

12. **Log push result**: Access logger writes push log entry with status (`succeeded-push`, `failed-push`, `accepted-dryrun`) to `gaurun_accept.log` / send log files.
    - From: `gaurunAccessLogger`
    - To: Log files
    - Protocol: In-process file write

13. **Emit metrics**: Metrics reporter increments `gaurun.succeeded.push{deviceType=ios}` or `gaurun.failed.push{deviceType=ios}` counter to Telegraf/InfluxDB.
    - From: `gaurunMetricsReporter`
    - To: `telegrafInfluxdb_3a8c2e`
    - Protocol: InfluxDB line protocol

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Malformed JSON body | HTTP API returns `400 Bad Request` | Caller must fix payload and retry |
| Empty token or invalid platform | `validateNotification` returns error; metric `gaurun.requests{valid=false}` emitted | Notification discarded; `400` not returned (error logged only, since async) |
| APNS producer queue full (100,000 entries) | `enqueueNotificationsInQueue` returns error; HTTP API returns `429 Too Many Requests` | Caller should back off and retry |
| APNs transient error (`IdleTimeout`, `Shutdown`, `InternalServerError`, `ServiceUnavailable`) | Push worker retries up to `ios.retry_max` times (default 5) inline | If retries exhausted, publishes to `mta.gaurun.retry`; see [Notification Retry Flow](notification-retry.md) |
| APNs permanent error (e.g., `BadDeviceToken`) | Logged as failed push; failure logged to `failed.log` | Notification dropped; no retry |
| Dry-run mode active | Push worker logs `accepted-dryrun` status and returns without calling APNs | Notification simulated; no delivery |

## Sequence Diagram

```
NotificationProducer -> gaurunHttpApi: POST /grpn/push (GrpnPayload JSON)
gaurunHttpApi -> gaurunNotificationIngestor: decode + normalize payload
gaurunHttpApi --> NotificationProducer: 200 OK {"message":"ok"}
gaurunNotificationIngestor -> APNSProducerQueueNotification: enqueue RequestGaurunNotification
gaurunKafkaProducer -> ios_gaurun_pn (Kafka): publish JSON notification
gaurunKafkaConsumer -> ios_gaurun_pn (Kafka): consume notification
gaurunKafkaConsumer -> ContextQueue[iphone-consumer]: route by context
gaurunPushWorkerManager -> gaurunApnsClient: dispatch notification
gaurunApnsClient -> appleApns: HTTP/2 push request
appleApns --> gaurunApnsClient: 200 OK (or error)
gaurunAccessLogger -> send.log: write push result
gaurunMetricsReporter -> Telegraf: gaurun.succeeded.push / gaurun.failed.push
```

## Related

- Architecture component view: `GaurunComponents`
- Related flows: [Android Push Notification Dispatch](android-push-dispatch.md), [Notification Retry Flow](notification-retry.md)
- Configuration: [Configuration](../configuration.md) — `[ios]` and `[ios-context.*]` sections
- Events: [Events](../events.md) — `ios_gaurun_pn` topic details
