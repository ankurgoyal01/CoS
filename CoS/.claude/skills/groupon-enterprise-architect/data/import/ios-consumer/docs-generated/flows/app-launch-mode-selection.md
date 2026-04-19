---
service: "ios-consumer"
title: "App Launch and Mode Selection"
generated: "2026-03-03"
type: flow
flow_name: "app-launch-mode-selection"
flow_type: synchronous
trigger: "User opens the Groupon app on iPhone or iPad"
participants:
  - "continuumIosConsumerApp"
  - "next-pwa-app (mobile-expo)"
  - "LegacyDataStore (NSUserDefaults bridge)"
architecture_ref: "components-continuum-ios-consumer-app"
---

# App Launch and Mode Selection

## Summary

When the Groupon iOS app launches, the MBNXT mobile shell (`next-pwa-app/apps/mobile-expo`) reads the legacy app's NSUserDefaults state to determine whether to display the new MBNXT React Native experience or fall back to the legacy native Swift app. The decision is based on bucketing flags, user opt-out preferences, and onboarding completion state. This flow enables the gradual migration from the legacy `ios-consumer` app to the MBNXT platform.

## Trigger

- **Type**: user-action
- **Source**: User taps the Groupon app icon on iPhone or iPad
- **Frequency**: Per app launch

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| iOS Consumer App (legacy) | Provides NSUserDefaults state and legacy UI experience | `continuumIosConsumerApp` |
| MBNXT mobile shell (mobile-expo) | Reads legacy state via `LegacyDataStore`; decides which experience to render | `next-pwa-app` |
| LegacyDataStore (NSUserDefaults bridge) | TypeScript bridge module reading iOS Settings API | `continuumIosConsumerApp` (on-device store) |
| iOS Keychain | Provides secure credentials (auth token, bcookie) to MBNXT | `continuumIosConsumerApp` (on-device store) |

## Steps

1. **App process starts**: The MBNXT shell (`mobile-expo`) initializes as the primary app entry point.
   - From: iOS OS
   - To: `continuumIosConsumerApp` (App Shell / `iosConsumer_appShell`)
   - Protocol: iOS app lifecycle

2. **Reads legacy NSUserDefaults state**: `LegacyDataStore` calls `Settings.get(key)` for bucketing and preference keys including `useLegacyApp`, `optOutMbnxt`, `isLocallyBucketedToMbnxt`, `didFinishOnboarding`, `launchCount`, `lastLaunchCountOnMbnxt`.
   - From: `next-pwa-app` (mobile-expo) `LegacyDataStore`
   - To: iOS NSUserDefaults (via `Platform.OS === 'ios'` guard)
   - Protocol: direct (iOS Settings API)

3. **Reads Keychain credentials**: `LegacyDataStore` reads auth token, user ID, user details, and bcookie from iOS Keychain via `RNKeychain.getPlistForKey()` and `RNKeychain.getBCookie()`.
   - From: `next-pwa-app` (mobile-expo) `LegacyDataStore`
   - To: iOS Keychain
   - Protocol: direct (iOS Keychain framework via `rn-keychain`)

4. **Determines mode**: MBNXT evaluates:
   - If `useLegacyApp === true` → launch legacy experience
   - If `optOutMbnxt === true` (and value is 1) → launch legacy experience
   - If `isLocallyBucketedToMbnxt === true` → launch MBNXT experience
   - If `isLocallyBucketedToMbnxt === null` → not bucketed; use default mode
   - From: `next-pwa-app` (mobile-expo) bucketing logic
   - To: local decision
   - Protocol: direct

5. **Detects legacy launch since last MBNXT session**: Compares `launchCount` with `lastLaunchCountOnMbnxt`. If `launchCount > lastLaunchCountOnMbnxt`, the legacy app was opened since the last MBNXT launch. Updates `lastLaunchCountOnMbnxt` to current `launchCount`.
   - From: `next-pwa-app` (mobile-expo)
   - To: NSUserDefaults (via `Settings.set()`)
   - Protocol: direct

6. **Renders selected experience**: Displays either MBNXT React Native UI or hands off to embedded legacy `groupon-legacy` Swift app.
   - From: `next-pwa-app` (mobile-expo)
   - To: User (iOS screen)
   - Protocol: UI render

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| NSUserDefaults read fails | `Settings.get()` returns `undefined`; defaults to null/unset state | Falls back to default mode (MBNXT or legacy per build configuration) |
| Keychain read fails | `RNKeychain.getPlistForKey()` resolves to `{}` (empty dict) catch handler | App launches unauthenticated; prompts user to log in |
| Legacy app process crash | iOS OS restarts app process | MBNXT shell re-initializes on next launch |

## Sequence Diagram

```
User           iOS OS         MBNXT Shell         LegacyDataStore     NSUserDefaults     Keychain
 |               |                |                       |                   |               |
 |--tap icon---> |                |                       |                   |               |
 |               |--launch app--> |                       |                   |               |
 |               |                |--Settings.get()------> |                   |               |
 |               |                |                       |--get keys-------->|               |
 |               |                |                       |<--values----------|               |
 |               |                |--RNKeychain.get()----> |                   |               |
 |               |                |                       |--get plist/bcookie--------------> |
 |               |                |                       |<--credentials---------------------|
 |               |                |<--legacy state+creds--|                   |               |
 |               |                |--evaluate bucketing--> (local decision)   |               |
 |               |                |--Settings.set(lastLaunchCountOnMbnxt)---> |               |
 |               |                |--render experience --> |                   |               |
 |<--app UI------|                |                       |                   |               |
```

## Related

- Architecture dynamic view: `components-continuum-ios-consumer-app`
- Related flows: [Push Notification Registration](push-notification-registration.md), [Deal Browse and Discovery](deal-browse-discovery.md)
