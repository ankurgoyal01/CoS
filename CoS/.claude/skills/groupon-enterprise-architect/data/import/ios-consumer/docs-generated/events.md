---
service: "ios-consumer"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [apns, kafka]
---

# Events

## Overview

The iOS Consumer App participates in asynchronous messaging as a push notification consumer. The app registers its APNS device token with the Groupon backend and receives push notifications delivered by the `gaurun` push infrastructure service. On the server side, `gaurun` uses a Kafka consumer named `ios-consumer` that reads from the `APNSConsumerQueueNotification` channel and delivers notifications via the Apple Push Notification service (APNS).

The app itself does not publish to any message bus. All outbound interactions are synchronous HTTPS calls to `api-lazlo-sox`.

## Published Events

> No evidence found in codebase. The iOS Consumer App does not publish events to any message bus.

## Consumed Events

### Push Notification Receipt

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| APNS (device-level) | Push notification payload | iOS system + App foreground handler | Displays alert/badge, updates app state, triggers deep link navigation |

### Push Notification Detail

- **Topic**: APNS device channel (routed via `gaurun` Kafka `APNSConsumerQueueNotification` → `ios-consumer` worker)
- **Handler**: iOS system delivers to foreground or background app process; app's notification handler processes payload and navigates to relevant content
- **Idempotency**: Not applicable — APNS delivers at-most-once to the device
- **Error handling**: APNS handles delivery retries at infrastructure level; failed deliveries are not re-queued to the app
- **Processing order**: unordered

## Dead Letter Queues

> No evidence found in codebase.

## Push Notification Registration Flow

The app registers for remote notifications during onboarding and persists the registration state in NSUserDefaults under:

- `pushNotificationsEnabled` — user consent state
- `lastPushContractVersion` — version of the push permission contract presented to user
- `didSuccessfullyPostDeviceToken` — whether the device token was successfully registered with the backend
