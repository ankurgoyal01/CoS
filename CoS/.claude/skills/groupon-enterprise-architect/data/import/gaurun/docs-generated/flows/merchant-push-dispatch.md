---
service: "gaurun"
title: "Merchant Push Notification Dispatch"
generated: "2026-03-03"
type: flow
flow_name: "merchant-push-dispatch"
flow_type: asynchronous
trigger: "POST /grpn/pushmerchant"
participants:
  - "notificationProducerService_4b2a5c"
  - "gaurunHttpApi"
  - "gaurunNotificationIngestor"
  - "gaurunPushWorkerManager"
  - "gaurunFcmClient"
  - "googleFcm_9c4e1b"
  - "gaurunMetricsReporter"
  - "gaurunAccessLogger"
architecture_ref: "GaurunComponents"
---

# Merchant Push Notification Dispatch

## Summary

The merchant push flow handles notifications targeted at the Groupon Merchant Android app. Unlike the consumer Android flow, merchant notifications are routed through a dedicated in-memory queue (`QueueMerchantNotification`) with a fixed capacity of 100 entries, bypassing the Kafka producer/consumer path. Three merchant worker goroutines (`pushNotificationMerchantWorker`) dispatch these notifications directly to FCM using the `merchant` Android FCM context configuration. The caller receives an immediate response after enqueuing.

## Trigger

- **Type**: api-call
- **Source**: Internal notification producer POSTs to `POST /grpn/pushmerchant`
- **Frequency**: On-demand, per merchant notification

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Notification Producer | Initiates merchant push request | `notificationProducerService_4b2a5c` |
| HTTP API | Receives and routes merchant push request | `gaurunHttpApi` |
| Notification Ingestor | Validates and normalizes to `platform=3` (PlatFormMerchant) | `gaurunNotificationIngestor` |
| Push Worker Manager | Three dedicated merchant goroutines dispatching from `QueueMerchantNotification` | `gaurunPushWorkerManager` |
| FCM Client | Sends notification to Google FCM using merchant context | `gaurunFcmClient` |
| Google FCM | External Android notification gateway | `googleFcm_9c4e1b` |
| Metrics Reporter | Records success/failure counters | `gaurunMetricsReporter` |
| Access Logger | Writes push log entry | `gaurunAccessLogger` |

## Steps

1. **Receive merchant push request**: Producer POSTs `GrpnPayload` (or standard notification payload) to `POST /grpn/pushmerchant`.
   - From: `notificationProducerService_4b2a5c`
   - To: `gaurunHttpApi`
   - Protocol: HTTP/JSON

2. **Route to merchant handler**: `MerchantNotificationHandler` processes the request — validates method is `POST`, body non-empty.
   - From: `gaurunHttpApi`
   - To: `gaurunNotificationIngestor`
   - Protocol: In-process

3. **Normalize payload**: Ingestor sets `platform=3` (PlatFormMerchant) on the `RequestGaurunNotification`.
   - From: `gaurunNotificationIngestor`
   - To: `gaurunQueueManager`
   - Protocol: In-process

4. **Enqueue to merchant channel**: `enqueueNotifications` routes `platform=3` notifications to `QueueMerchantNotification` (buffered channel, capacity 100). If `merchant.enabled=false`, logs `disabled-push` and discards.
   - From: `gaurunNotificationIngestor`
   - To: `QueueMerchantNotification`
   - Protocol: Go channel

5. **Return response to caller**: HTTP API returns `{"message":"ok"}` immediately.
   - From: `gaurunHttpApi`
   - To: `notificationProducerService_4b2a5c`
   - Protocol: HTTP/JSON

6. **Dispatch from merchant worker**: One of three `pushNotificationMerchantWorker` goroutines reads from `QueueMerchantNotification`, acquires semaphore, and spawns async push.
   - From: `gaurunQueueManager`
   - To: `gaurunPushWorkerManager`
   - Protocol: Go channel

7. **Build FCM merchant payload**: FCM client constructs FCM message from `RequestGaurunNotification`. Merchant payloads use `MerchantPayload` type which includes `MerchantUuid` field.
   - From: `gaurunPushWorkerManager`
   - To: `gaurunFcmClient`
   - Protocol: In-process

8. **Send to Google FCM**: FCM client posts to Firebase Cloud Messaging using the `merchant` context API key/service account.
   - From: `gaurunFcmClient`
   - To: `googleFcm_9c4e1b`
   - Protocol: HTTP

9. **Log and emit metrics**: Access logger writes result; metrics reporter increments `gaurun.succeeded.push{deviceType=android}` or `gaurun.failed.push{deviceType=android}`.
   - From: `gaurunMetricsReporter` / `gaurunAccessLogger`
   - To: Telegraf, log files
   - Protocol: InfluxDB line protocol, file write

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Merchant queue full (100 entries) | `QueueMerchantNotification` channel blocks — no backpressure to HTTP caller in this path (direct enqueue) | Potential goroutine blocking; low capacity by design for lower-volume merchant traffic |
| `merchant.enabled = false` | Logs `disabled-push`; notification discarded | No delivery |
| FCM transient error | Retries up to `android.retry_max` times inline; if exhausted publishes to `mta.gaurun.retry` | Retry flow handles recovery |
| Dry-run mode | Worker logs `accepted-dryrun` without calling FCM | Simulated delivery |

## Sequence Diagram

```
NotificationProducer -> gaurunHttpApi: POST /grpn/pushmerchant
gaurunHttpApi -> gaurunNotificationIngestor: normalize (platform=3)
gaurunNotificationIngestor -> QueueMerchantNotification: enqueue
gaurunHttpApi --> NotificationProducer: 200 OK {"message":"ok"}
gaurunPushWorkerManager -> gaurunFcmClient: dispatch (merchant context)
gaurunFcmClient -> googleFcm: HTTP POST (merchant FCM)
googleFcm --> gaurunFcmClient: success / error
gaurunAccessLogger -> send.log: write result
gaurunMetricsReporter -> Telegraf: counter
```

## Related

- Architecture component view: `GaurunComponents`
- Related flows: [Android Push Notification Dispatch](android-push-dispatch.md), [Notification Retry Flow](notification-retry.md)
- Configuration: [Configuration](../configuration.md) — `[merchant]` and `[android-context.android-merchant]` sections
