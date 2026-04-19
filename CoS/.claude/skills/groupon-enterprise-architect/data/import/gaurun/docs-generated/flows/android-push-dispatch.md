---
service: "gaurun"
title: "Android Push Notification Dispatch"
generated: "2026-03-03"
type: flow
flow_name: "android-push-dispatch"
flow_type: asynchronous
trigger: "POST /grpn/push with vctx.jobType not APNS (Android path)"
participants:
  - "notificationProducerService_4b2a5c"
  - "gaurunHttpApi"
  - "gaurunNotificationIngestor"
  - "gaurunQueueManager"
  - "gaurunKafkaProducer"
  - "gaurunKafkaConsumer"
  - "gaurunPushWorkerManager"
  - "gaurunFcmClient"
  - "googleFcm_9c4e1b"
  - "gaurunRetryProcessor"
  - "gaurunMetricsReporter"
  - "gaurunAccessLogger"
architecture_ref: "GaurunComponents"
---

# Android Push Notification Dispatch

## Summary

This flow describes how Gaurun accepts an Android push notification request from an internal producer, maps the payload to `RequestGaurunNotification` with `platform=2`, publishes it to the `android_gaurun_pn` Kafka topic, consumes it back into a per-context in-memory queue, and dispatches it to Google FCM. The caller receives an immediate `200 OK` after Kafka enqueue; FCM delivery is asynchronous. Results are emitted as metrics and logged.

## Trigger

- **Type**: api-call
- **Source**: Internal notification producer service POSTs to `POST /grpn/push` (Android recipients with `jobType != APNS`)
- **Frequency**: On-demand, per notification batch

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Notification Producer | Initiates push request | `notificationProducerService_4b2a5c` |
| HTTP API | Receives and validates HTTP request | `gaurunHttpApi` |
| Notification Ingestor | Normalizes payload to Android `RequestGaurunNotification` | `gaurunNotificationIngestor` |
| Queue Manager | Routes notification to Android producer channel | `gaurunQueueManager` |
| Kafka Producer | Publishes notification to `android_gaurun_pn` | `gaurunKafkaProducer` |
| Kafka Consumer | Consumes from `android_gaurun_pn`; routes into per-context queue | `gaurunKafkaConsumer` |
| Push Worker Manager | Dispatches from per-context queue to FCM client | `gaurunPushWorkerManager` |
| FCM Client | Sends notification to Google FCM | `gaurunFcmClient` |
| Google FCM | External Android notification gateway | `googleFcm_9c4e1b` |
| Retry Processor | Handles failed delivery via `mta.gaurun.retry` | `gaurunRetryProcessor` |
| Metrics Reporter | Records success/failure counters | `gaurunMetricsReporter` |
| Access Logger | Writes per-notification push log entry | `gaurunAccessLogger` |

## Steps

1. **Receive push request**: Producer POSTs `GrpnPayload` JSON to `POST /grpn/push`.
   - From: `notificationProducerService_4b2a5c`
   - To: `gaurunHttpApi`
   - Protocol: HTTP/JSON

2. **Validate and decode**: HTTP API verifies method is `POST`, body is non-empty, decodes `GrpnPayload`.
   - From: `gaurunHttpApi`
   - To: `gaurunNotificationIngestor`
   - Protocol: In-process

3. **Normalize Android payload**: For each recipient where `jobType != APNS`, ingestor maps `AndroidPayload` fields — sets `platform=2`, `priority` from `vctx.priority` (default `normal`), `time_to_live=43200`, `delay_while_idle=false`, `message`, `title`, `alert`, `link`, `image`, `badge`, `country`, `division`, `extend[nid]`, `context` from `to` field.
   - From: `gaurunNotificationIngestor`
   - To: `gaurunQueueManager`
   - Protocol: In-process

4. **Return 200 OK to caller**: HTTP API returns `{"message":"ok"}` immediately after `enqueueNotificationsInQueue` succeeds.
   - From: `gaurunHttpApi`
   - To: `notificationProducerService_4b2a5c`
   - Protocol: HTTP/JSON

5. **Validate notification fields**: Checks token, platform range, non-empty message.
   - From: `gaurunNotificationIngestor`
   - To: `gaurunQueueManager`
   - Protocol: In-process

6. **Enqueue to Android producer channel**: Notification placed on `AndroidProducerQueueNotification` (capacity 100,000). If full, returns `429`.
   - From: `gaurunNotificationIngestor`
   - To: `gaurunQueueManager`
   - Protocol: Go channel

7. **Publish to Kafka topic**: Kafka producer goroutine reads from `AndroidProducerQueueNotification`, JSON-marshals, publishes to `android_gaurun_pn` (SSL, acks=1, lz4 compression).
   - From: `gaurunKafkaProducer`
   - To: Kafka cluster (`kafkaCluster_2f6b9d`)
   - Protocol: Kafka (SSL)

8. **Consume from Kafka topic**: Kafka consumer goroutine (consumer group `android.gaurun.consumer.group`) reads from `android_gaurun_pn`, extracts `context` field, routes into named per-context queue channel.
   - From: `gaurunKafkaConsumer`
   - To: `gaurunQueueManager`
   - Protocol: Kafka (SSL) → in-process channel

9. **Dispatch to push worker**: Android push worker (`pushNotificationAndroidWorker`) reads from the named context channel (e.g., `android-fcm-consumer`), acquires semaphore, dispatches async goroutine.
   - From: `gaurunQueueManager`
   - To: `gaurunPushWorkerManager`
   - Protocol: Go channel

10. **Build FCM payload**: FCM client builds Android notification message object from `RequestGaurunNotification` fields.
    - From: `gaurunPushWorkerManager`
    - To: `gaurunFcmClient`
    - Protocol: In-process

11. **Send to Google FCM**: FCM client sends HTTP request to Firebase Cloud Messaging. On success, increments `StatGaurun.Android.PushSuccess` and calls `ReportSuccessfulSend`.
    - From: `gaurunFcmClient`
    - To: `googleFcm_9c4e1b`
    - Protocol: HTTP

12. **Log push result**: Access logger writes push log entry (succeeded/failed) to send log files.
    - From: `gaurunAccessLogger`
    - To: Log files
    - Protocol: In-process file write

13. **Emit metrics**: Metrics reporter increments `gaurun.succeeded.push{deviceType=android}` or `gaurun.failed.push{deviceType=android}`.
    - From: `gaurunMetricsReporter`
    - To: `telegrafInfluxdb_3a8c2e`
    - Protocol: InfluxDB line protocol

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Malformed JSON body | HTTP API returns `400 Bad Request` | Caller must fix payload |
| Empty token or invalid platform | `validateNotification` logs error, emits `valid=false` metric | Notification discarded silently |
| Android producer queue full | `enqueueNotificationsInQueue` returns error; HTTP API returns `429 Too Many Requests` | Caller should back off and retry |
| FCM transient error (`Unavailable`, `InternalServerError`, timeout) | Push worker retries up to `android.retry_max` times (default 5) | If retries exhausted, publishes to `mta.gaurun.retry`; see [Notification Retry Flow](notification-retry.md) |
| FCM permanent error (e.g., invalid registration) | Logged as failed; failure written to `failed.log` | Notification dropped |
| Dry-run mode | Worker logs `accepted-dryrun`; FCM not called | No delivery |

## Sequence Diagram

```
NotificationProducer -> gaurunHttpApi: POST /grpn/push (GrpnPayload JSON)
gaurunHttpApi -> gaurunNotificationIngestor: decode + normalize payload (platform=2)
gaurunHttpApi --> NotificationProducer: 200 OK {"message":"ok"}
gaurunNotificationIngestor -> AndroidProducerQueueNotification: enqueue
gaurunKafkaProducer -> android_gaurun_pn (Kafka): publish JSON notification
gaurunKafkaConsumer -> android_gaurun_pn (Kafka): consume notification
gaurunKafkaConsumer -> ContextQueue[android-fcm-consumer]: route by context
gaurunPushWorkerManager -> gaurunFcmClient: dispatch notification
gaurunFcmClient -> googleFcm: HTTP POST
googleFcm --> gaurunFcmClient: success / error
gaurunAccessLogger -> send.log: write push result
gaurunMetricsReporter -> Telegraf: gaurun.succeeded.push / gaurun.failed.push
```

## Related

- Architecture component view: `GaurunComponents`
- Related flows: [iOS Push Notification Dispatch](ios-push-dispatch.md), [Notification Retry Flow](notification-retry.md), [Merchant Push Notification Dispatch](merchant-push-dispatch.md)
- Configuration: [Configuration](../configuration.md) — `[android]` and `[android-context.*]` sections
- Events: [Events](../events.md) — `android_gaurun_pn` topic details
