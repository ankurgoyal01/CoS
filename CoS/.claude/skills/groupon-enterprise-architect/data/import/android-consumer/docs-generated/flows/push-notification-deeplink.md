---
service: "android-consumer"
title: "Push Notification and Deep-link"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "push-notification-deeplink"
flow_type: event-driven
trigger: "Firebase Cloud Messaging push received by device, or Android deep-link intent fired"
participants:
  - "androidConsumer_appEntryPoints"
  - "androidConsumer_featureModules"
  - "androidConsumer_telemetryAndCrash"
  - "continuumAndroidLocalStorage"
  - "firebase"
architecture_ref: "dynamic-android-consumer-push-deeplink"
---

# Push Notification and Deep-link

## Summary

The push notification and deep-link flow handles two inbound event paths. In the FCM path, a push notification message is received from Firebase Cloud Messaging, the app displays a system notification, and when the user taps it the payload's deep-link URI is parsed to navigate the user to the correct in-app screen. In the direct deep-link path, an Android intent (from a browser, email, or another app) is routed to the app's registered intent filters and resolved to the appropriate screen. Both paths emit analytics events on receipt and tap.

## Trigger

- **Type**: event (inbound)
- **Source**: Firebase Cloud Messaging (Groupon push notification backend sends message to FCM); or external Android intent (URL scheme / App Link)
- **Frequency**: On demand — whenever a push is sent or a deep link is opened

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Firebase Cloud Messaging | Delivers push notification payload to the device | `firebase` |
| App Entry Points | Hosts FCM messaging service and intent filters for deep links | `androidConsumer_appEntryPoints` |
| Feature Modules (Notifications) | Parses notification payload; resolves deep-link target | `androidConsumer_featureModules` |
| Android Local Storage | Reads session/auth state to determine if user is signed in | `continuumAndroidLocalStorage` |
| Telemetry and Crash Reporting | Emits push received, notification displayed, and tap analytics events | `androidConsumer_telemetryAndCrash` |

## Steps

### Path A: FCM Push Notification

1. **FCM delivers push payload to device**: Firebase Cloud Messaging delivers the notification data payload to the device while the app is in the foreground, background, or terminated.
   - From: `firebase` (FCM)
   - To: `androidConsumer_appEntryPoints` (FCM messaging service)
   - Protocol: FCM SDK / Android push

2. **FCM service receives message**: The app's FCM `onMessageReceived` handler is invoked with the notification payload containing title, body, and a deep-link URI.
   - From: FCM SDK
   - To: `androidConsumer_featureModules` (notification handler)
   - Protocol: Direct (Android service callback)

3. **System notification displayed**: The notification feature module builds and posts a system notification using Android `NotificationManager`; the notification contains the deep-link URI as the tap intent.
   - From: `androidConsumer_featureModules`
   - To: Android system notification tray
   - Protocol: Direct (Android NotificationManager API)

4. **Analytics event emitted on receipt**: Notification feature module emits a push-received analytics event.
   - From: `androidConsumer_featureModules`
   - To: `androidConsumer_telemetryAndCrash`
   - Protocol: Direct

5. **User taps the notification**: User taps the notification; Android system fires the pending intent carrying the deep-link URI.
   - From: User
   - To: `androidConsumer_appEntryPoints`
   - Protocol: Android PendingIntent

6. **Deep-link URI parsed and resolved**: The receiving Activity extracts the deep-link URI from the intent; the Feature Module resolves the URI to a target screen (deal detail, category, account, etc.).
   - From: `androidConsumer_appEntryPoints`
   - To: `androidConsumer_featureModules`
   - Protocol: Direct (Android navigation component)

7. **App navigates to target screen**: The navigation component routes the user to the resolved destination.
   - From: `androidConsumer_featureModules`
   - To: UI layer
   - Protocol: Direct

8. **Analytics event emitted on tap**: Telemetry emits a notification-opened event with the deep-link URI and notification ID.
   - From: `androidConsumer_featureModules`
   - To: `androidConsumer_telemetryAndCrash`
   - Protocol: Direct

### Path B: Direct Deep-link Intent

1. **Android fires deep-link intent**: User taps a `groupon://` or `https://www.groupon.com/*` (App Link) URL in browser, email, or external app.
   - From: Android OS
   - To: `androidConsumer_appEntryPoints` (intent filter)
   - Protocol: Android intent

2. **Activity receives intent**: The registered Activity captures the intent and passes the URI to the Feature Module for resolution.
   - From: `androidConsumer_appEntryPoints`
   - To: `androidConsumer_featureModules`
   - Protocol: Direct

3. **URI resolved to in-app screen**: Feature module maps the URI path to the appropriate screen and parameters (e.g., `/deals/123` → deal detail for deal 123).
   - From: `androidConsumer_featureModules`
   - To: `androidConsumer_appEntryPoints` (navigation)
   - Protocol: Direct

4. **Session state checked**: If the target screen requires authentication, Local Persistence Layer is queried for a valid session token.
   - From: `androidConsumer_featureModules`
   - To: `continuumAndroidLocalStorage`
   - Protocol: Direct (Room/SharedPreferences)

5. **Navigate to target screen or redirect to sign-in**: User is navigated to the target, or to the sign-in screen if unauthenticated.
   - From: `androidConsumer_featureModules`
   - To: UI layer
   - Protocol: Direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Malformed notification payload | Silent drop; notification not displayed | User receives no notification |
| Deep-link URI not recognised | Fall through to app home screen | User lands on home screen |
| Target screen requires auth, user is not signed in | Redirect to sign-in flow | After sign-in, user navigates to target |
| FCM token expired or invalid | FCM SDK refreshes token automatically | Next push delivered after token update |
| App terminated — FCM in data-only mode | Android OS delivers intent when app next launches | Notification handled on next launch |

## Sequence Diagram

```
FCM --> appEntryPoints: onMessageReceived(payload)
appEntryPoints -> featureModules: Handle notification payload
featureModules -> Android OS: Post system notification (NotificationManager)
featureModules -> telemetryAndCrash: Emit push_received event

User -> Android OS: Tap notification
Android OS -> appEntryPoints: PendingIntent with deep-link URI
appEntryPoints -> featureModules: Resolve deep-link URI
featureModules -> continuumAndroidLocalStorage: Check session state
featureModules -> UI: Navigate to target screen
featureModules -> telemetryAndCrash: Emit notification_opened event
```

## Related

- Architecture dynamic view: `dynamic-android-consumer-push-deeplink` (not yet modeled in DSL)
- Related flows: [Analytics and Telemetry Collection](analytics-telemetry-collection.md), [User Authentication](user-authentication.md)
