---
service: "android-consumer"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: [firebase-cloud-messaging, firebase-analytics, appsflyer, bloomreach, android-intents]
---

# Events

## Overview

The Android Consumer App uses a mix of outbound telemetry publishing and inbound push/intent consumption. It does not connect to a traditional message broker (Kafka/RabbitMQ). Published events flow to Firebase Analytics, Firebase Crashlytics, AppsFlyer, and Bloomreach via their respective Android SDKs. Inbound events arrive via Firebase Cloud Messaging push notifications and Android deep-link intents.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| Firebase Analytics | User behavior event | User interaction with UI (tap, view, purchase) | event name, screen name, user ID, deal ID |
| Firebase Crashlytics | Crash / non-fatal error report | Unhandled exception or explicit log call | stack trace, device info, app version, user ID |
| Firebase Cloud Messaging | FCM token registration | App install or token refresh | FCM device token |
| AppsFlyer | Attribution / install event | App install, in-app purchase, deep-link open | campaign source, install time, conversion data |
| Bloomreach (Exponea) | Customer engagement event | User action (view, add to cart, purchase, etc.) | event type, customer ID, session ID, properties |

### Firebase Analytics Event Detail

- **Topic**: Firebase Analytics
- **Trigger**: User interaction with any tracked screen or UI element
- **Payload**: Event name, associated parameters (screen name, deal ID, user segment), user properties
- **Consumers**: Firebase Analytics dashboard, Google BigQuery export (if configured)
- **Guarantees**: at-most-once (best-effort SDK batching)

### Firebase Crashlytics Report Detail

- **Topic**: Firebase Crashlytics
- **Trigger**: Unhandled exception (crash) or explicit `recordException()` call from `androidConsumer_telemetryAndCrash`
- **Payload**: Stack trace, device model, OS version, app version, user ID (if set)
- **Consumers**: Firebase Crashlytics dashboard, alerting via Firebase
- **Guarantees**: at-least-once (SDK queues and retries on connectivity)

### AppsFlyer Attribution Event Detail

- **Topic**: AppsFlyer SDK
- **Trigger**: App install, deep-link open, or in-app conversion event
- **Payload**: Install source, campaign ID, media source, conversion value, AppsFlyer ID
- **Consumers**: AppsFlyer dashboard, downstream marketing analytics
- **Guarantees**: at-least-once (SDK retries on failure)

### Bloomreach Engagement Event Detail

- **Topic**: Bloomreach (Exponea) SDK
- **Trigger**: Tracked user actions (browse, cart, purchase, notification interaction)
- **Payload**: Event type, customer ID, timestamp, session ID, custom properties
- **Consumers**: Bloomreach CDP platform (UK and US tenants configured separately)
- **Guarantees**: at-least-once (SDK queues and retries)

### FCM Token Registration Detail

- **Topic**: Firebase Cloud Messaging
- **Trigger**: App install, reinstall, or SDK-initiated token refresh
- **Payload**: FCM device registration token
- **Consumers**: Groupon push notification backend (registers token for targeting)
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| Firebase Cloud Messaging | Push notification | FCM `onMessageReceived` listener | Display system notification; navigate on tap |
| Android Intent system | Deep-link intent | Activity intent filter | Launch targeted screen or flow |
| Android ConnectivityManager | Network state change | Network callback | Trigger sync queue flush or pause background work |

### Push Notification Detail

- **Topic**: Firebase Cloud Messaging (FCM)
- **Handler**: FCM messaging service listener in the notifications feature module
- **Idempotency**: Best-effort; duplicate pushes may display duplicate notifications
- **Error handling**: Dropped silently if notification payload is malformed
- **Processing order**: Unordered

### Deep-link Intent Detail

- **Topic**: Android Intent (scheme-based deep links and App Links)
- **Handler**: Activity intent filters in `androidConsumer_appEntryPoints`
- **Idempotency**: Navigation is idempotent for the same URI
- **Error handling**: Falls back to home screen if deep-link target is not resolvable
- **Processing order**: Unordered

## Dead Letter Queues

> Not applicable. The app does not use a traditional broker with DLQ support. SDK-level retry buffers are managed internally by Firebase, AppsFlyer, and Bloomreach SDKs.
