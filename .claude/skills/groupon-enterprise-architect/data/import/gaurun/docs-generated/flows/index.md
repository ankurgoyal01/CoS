---
service: "gaurun"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Gaurun Push Notification Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [iOS Push Notification Dispatch](ios-push-dispatch.md) | asynchronous | `POST /grpn/push` with `jobType=APNS` | Accepts an iOS notification, routes through Kafka queue, and delivers to Apple APNs |
| [Android Push Notification Dispatch](android-push-dispatch.md) | asynchronous | `POST /grpn/push` with `jobType=FCM` | Accepts an Android notification, routes through Kafka queue, and delivers to Google FCM |
| [Notification Retry Flow](notification-retry.md) | event-driven | Delivery failure published to `mta.gaurun.retry` | Re-submits failed notifications to APNs or FCM after a minimum age delay, up to 12 attempts |
| [Merchant Push Notification Dispatch](merchant-push-dispatch.md) | asynchronous | `POST /grpn/pushmerchant` | Accepts a merchant-targeted Android notification and delivers directly via FCM without Kafka queuing |
| [Graceful Shutdown Flow](graceful-shutdown.md) | event-driven | `SIGTERM` from Kubernetes | Drains in-flight push workers and Kafka consumers, then exits cleanly |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 4 |
| Batch / Scheduled | 1 |

> Note: The iOS and Android dispatch flows are logically asynchronous — the HTTP response is returned immediately after Kafka enqueue, and delivery to APNs/FCM happens in background worker goroutines.

## Cross-Service Flows

- **Upstream**: Internal notification producer services POST to `POST /grpn/push`. The central architecture model (`notificationProducerService_4b2a5c`) tracks callers; specific caller flows are documented in upstream service docs.
- **Downstream delivery**: iOS dispatch terminates at Apple APNs (`appleApns_7f1d6a`); Android dispatch terminates at Google FCM (`googleFcm_9c4e1b`).
- **Log shipping**: Logstash sidecar ships send/failure logs to the Kafka cluster (`kafkaCluster_2f6b9d`) as `push_service` and `mta_push_bounce` event types — consumed by downstream analytics pipelines.
