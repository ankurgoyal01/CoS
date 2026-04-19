---
service: "mobile-flutter-merchant"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: [firebase-cloud-messaging]
---

# Events

## Overview

The Mobile Flutter Merchant app uses Firebase Cloud Messaging (FCM) as its sole async messaging channel. The app consumes push notifications dispatched by the NOTS Service and other Continuum backend services. Local notification display is handled by the `flutter_local_notifications` library. The app does not publish events to any message broker.

## Published Events

> No evidence found — this service does not publish events to any message broker or queue.

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| FCM push channel | Push Notification | `mmaMerchantEngagementModule` / `firebase_messaging` handler | Displays local notification, updates inbox badge, triggers in-app navigation |

### Push Notification Detail

- **Topic**: Firebase Cloud Messaging device topic (per-device FCM token)
- **Handler**: `firebase_messaging` background and foreground message handler within `mmaMerchantEngagementModule`; surfaces alerts via `flutter_local_notifications`
- **Idempotency**: Display-level idempotency managed by the local notification library; no deduplication at the application layer is evidenced
- **Error handling**: FCM delivery guarantees at-most-once for notification delivery; missed notifications are not replayed by the app
- **Processing order**: Unordered — each push notification is handled independently

## Dead Letter Queues

> Not applicable — FCM does not use DLQs. Undelivered push notifications are subject to FCM platform retry policies managed server-side by the NOTS Service.
