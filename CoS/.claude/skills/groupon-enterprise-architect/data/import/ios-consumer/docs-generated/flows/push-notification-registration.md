---
service: "ios-consumer"
title: "Push Notification Registration"
generated: "2026-03-03"
type: flow
flow_name: "push-notification-registration"
flow_type: synchronous
trigger: "App launches for the first time or user grants notification permission"
participants:
  - "continuumIosConsumerApp"
  - "api-lazlo-sox"
  - "APNS (Apple Push Notification service)"
architecture_ref: "components-continuum-ios-consumer-app"
---

# Push Notification Registration

## Summary

When the Groupon iOS app launches and the user has granted push notification permission, the app registers with APNS to obtain a device token. This token is then submitted to the Groupon backend via `api-lazlo-sox` so that the push notification infrastructure (`gaurun`) can target the specific device for future promotional and transactional push messages.

## Trigger

- **Type**: user-action / app-lifecycle
- **Source**: App first launch after installation, or user grants notification permission via iOS system alert
- **Frequency**: On first launch or when push permission state changes

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| iOS Consumer App | Requests push permission; registers with APNS; submits token to backend | `continuumIosConsumerApp` |
| APNS (Apple Push Notification service) | Issues a unique device push token | External |
| `api-lazlo-sox` | Receives and stores device token registration with Continuum user account | `continuumSystem` |

## Steps

1. **Presents push permission prompt**: App displays iOS system notification permission dialog controlled by `pushNotificationsEnabled` and `lastPushContractVersion` NSUserDefaults tracking.
   - From: `continuumIosConsumerApp` (App Shell)
   - To: iOS OS / User
   - Protocol: iOS UserNotifications framework

2. **User grants permission**: User taps "Allow" on the system dialog.
   - From: User
   - To: iOS OS
   - Protocol: User interaction

3. **Registers with APNS**: iOS OS calls APNS to obtain a device-specific push token for `com.groupon.grouponapp`.
   - From: iOS OS
   - To: APNS (Apple servers)
   - Protocol: APNS protocol (Apple-managed)

4. **APNS returns device token**: APNS issues a unique device token tied to the app + device combination.
   - From: APNS
   - To: iOS OS → App delegate
   - Protocol: APNS callback

5. **App submits device token to backend**: App posts the device token to `api-lazlo-sox`, associating it with the authenticated user account.
   - From: `continuumIosConsumerApp`
   - To: `api-lazlo-sox`
   - Protocol: HTTPS / REST

6. **Records registration success**: App sets `didSuccessfullyPostDeviceToken = true` in NSUserDefaults.
   - From: `continuumIosConsumerApp`
   - To: NSUserDefaults (on-device)
   - Protocol: direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| User denies notification permission | App records consent state in `pushNotificationsEnabled` | No device token obtained; `didSuccessfullyPostDeviceToken` remains false; app continues normally without push |
| APNS token registration fails | iOS OS retries automatically; app does not set `didSuccessfullyPostDeviceToken` | Device is not reachable for push notifications until next successful registration |
| Backend token submission fails | Token submission failure; `didSuccessfullyPostDeviceToken` remains false | App retries on next launch; push notifications not delivered to this device until resolved |

## Sequence Diagram

```
iOS Consumer App    iOS OS        APNS          api-lazlo-sox     NSUserDefaults
       |               |            |                  |                |
       |--request perm->|            |                  |                |
       |               |--show dialog to user          |                |
       |<--user allows--|            |                  |                |
       |               |--register->|                  |                |
       |               |            |--issue token---->|                |
       |               |<--token----|                  |                |
       |<--token callback|           |                  |                |
       |--POST /device-token-------->|                  |                |
       |                            |                  |--store token-->|
       |<--200 OK--------------------|                  |                |
       |--set didSuccessfullyPostDeviceToken=true------->               |
```

## Related

- Architecture dynamic view: `components-continuum-ios-consumer-app`
- Related flows: [App Launch and Mode Selection](app-launch-mode-selection.md)
