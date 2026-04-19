---
service: "gaurun"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [kafka]
---

# Events

## Overview

Gaurun uses Kafka as its primary durability and queuing layer. Inbound push requests are published to platform-specific Kafka topics by producer goroutines, then consumed back by consumer goroutines that route messages into per-context in-memory queues for push workers. A separate retry topic (`mta.gaurun.retry`) provides delayed retry for failed delivery attempts. Logstash sidecar containers forward send and failure log files to the central Kafka cluster for downstream analytics.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `android_gaurun_pn` | Android push notification | Notification accepted on `/grpn/push` for Android platform | `token`, `platform`, `message`, `context`, `title`, `link`, `image`, `badge`, `vctx` |
| `ios_gaurun_pn` | iOS push notification | Notification accepted on `/grpn/push` for iOS platform | `token`, `platform`, `message`, `context`, `title`, `badge`, `sound`, `content_available`, `vctx` |
| `mta.gaurun.retry` | Retry push notification | Push delivery fails with a retriable error; `RetryQueueWorkerNew` publishes | Full `RequestGaurunNotification` JSON including `attempts` counter and `created` timestamp |

### `android_gaurun_pn` Detail

- **Topic**: `android_gaurun_pn`
- **Trigger**: An inbound notification is validated, its platform is identified as Android (`platform=2`), and `enqueueNotificationsInQueue` places it on the `AndroidProducerQueueNotification` channel; `KafkaProducer` goroutines publish from that channel.
- **Payload**: Full `RequestGaurunNotification` JSON — includes `token` (array), `platform`, `message`, `title`, `alert`, `link`, `image`, `badge`, `collapse_key`, `time_to_live`, `priority`, `context`, `country`, `division`, `vctx` fields.
- **Consumers**: `gaurunKafkaConsumer` — consumed by Gaurun itself to route into per-context in-memory queues for push workers. Consumer group: `android.gaurun.consumer.group`.
- **Guarantees**: At-least-once (Kafka acks=1, offset reset=earliest).

### `ios_gaurun_pn` Detail

- **Topic**: `ios_gaurun_pn`
- **Trigger**: An inbound notification is validated, its platform is iOS (`platform=1`), and `enqueueNotificationsInQueue` places it on the `APNSProducerQueueNotification` channel; `KafkaProducer` goroutines publish from that channel.
- **Payload**: Full `RequestGaurunNotification` JSON — includes `token`, `platform`, `message`, `title`, `subtitle`, `badge`, `sound`, `content_available`, `mutable_content`, `expiry`, `push_type`, `context`, `country`, `divisionId`, `extend`, `vctx` fields.
- **Consumers**: `gaurunKafkaConsumer` — consumed by Gaurun itself to route into per-context in-memory queues for push workers. Consumer group: `ios.gaurun.consumer.group`.
- **Guarantees**: At-least-once (Kafka acks=1, offset reset=earliest).

### `mta.gaurun.retry` Detail

- **Topic**: `mta.gaurun.retry`
- **Trigger**: A push worker fails to deliver a notification after exhausting its immediate retry limit (`isExternalServerError` returns true and `req.Retry >= retryMax`); `retryQueueWorker.RetryLaterNew(req)` publishes to this topic.
- **Payload**: Full `RequestGaurunNotification` JSON including `attempts` (incremented counter) and `created` (timestamp of original submission).
- **Consumers**: `RetryQueueProcessorNew` — consumed by Gaurun itself; processor re-posts to `/grpn/retry` after a minimum age delay (`retry_later.min_message_age`). Consumer group: `gaurun.consumer.group`.
- **Guarantees**: At-least-once.

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `android_gaurun_pn` | Android push notification | `gaurunKafkaConsumer.ConsumeRecord` | Routes into per-context in-memory queue channel; push workers dispatch to FCM |
| `ios_gaurun_pn` | iOS push notification | `gaurunKafkaConsumer.ConsumeRecord` | Routes into per-context in-memory queue channel; push workers dispatch to APNs |
| `mta.gaurun.retry` | Retry push notification | `RetryQueueProcessorNew.Run` | Re-posts notification to `/grpn/retry`; increments attempt counter; drops if `attempts >= max_retries` |

### `android_gaurun_pn` / `ios_gaurun_pn` Consumer Detail

- **Topic**: `android_gaurun_pn`, `ios_gaurun_pn`
- **Handler**: `ConsumeRecord` reads messages, unmarshals `RequestGaurunNotification`, looks up the `context` field to find the target in-memory channel queue, and enqueues for push workers.
- **Idempotency**: Not explicitly idempotent — duplicate delivery will re-attempt the push to APNs/FCM, which may result in duplicate notifications.
- **Error handling**: Unmarshal failures and missing queue names are logged and skipped (message is consumed but not re-queued). Delivery failures are published to `mta.gaurun.retry`.
- **Processing order**: Unordered (multiple consumer goroutines per topic).

### `mta.gaurun.retry` Consumer Detail

- **Topic**: `mta.gaurun.retry`
- **Handler**: `RetryQueueProcessorNew` — enforces a minimum message age (`retry_later.min_message_age` ms, default 300,000 ms = 5 minutes) before re-submitting. Drops messages that have reached `retry_later.max_retries` (default 12).
- **Idempotency**: Not explicitly idempotent.
- **Error handling**: Drops messages at max retry limit; logs errors for JSON decode failures.
- **Processing order**: Unordered.

## Dead Letter Queues

> No explicit dead letter queues are configured. Notifications that exhaust `retry_later.max_retries` (default 12) are logged as errors and dropped. Failed send events are written to `/var/groupon/gaurun/sends/failed.log` and forwarded via Logstash to the Kafka cluster under type `mta_push_bounce`.
