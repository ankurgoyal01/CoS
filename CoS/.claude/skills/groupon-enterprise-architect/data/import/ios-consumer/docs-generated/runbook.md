---
service: "ios-consumer"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Apple App Store review status | manual (App Store Connect) | Per release | N/A |
| TestFlight build availability | manual (App Store Connect) | Per release | N/A |
| Push notification delivery | manual (device test) | Per release | N/A |

> Operational procedures to be defined by service owner. The iOS Consumer App does not expose HTTP health check endpoints — it is a mobile client application.

## Monitoring

### Metrics

> No evidence found in codebase. Crash reporting and analytics integrations are not specified in the available DSL or architecture files.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| App crash rate | gauge | Tracked via crash reporting tool (not identified in inventory) | Not specified |
| Push token registration success | counter | `didSuccessfullyPostDeviceToken` flag tracks registration outcome | Not specified |
| Launch count | counter | `launchCount` NSUserDefaults key — incremented on each legacy app launch | Not specified |

### Dashboards

> No evidence found in codebase.

### Alerts

> No evidence found in codebase.

## Common Operations

### Trigger a CI Build

Use mobilebot in the `#mobile-ios-release` Slack channel:

```
@mobilebot upload release/Major.Minor
```

This triggers Jenkins at `https://cloud-jenkins.groupondev.com/job/mobile/job/ios-consumer/buildWithParameters` with the specified branch.

### Create a Release (GPROD) Ticket

Use mobilebot to create a Jira GPROD change ticket:

```
@mobilebot gprod ios {Major.Minor} {BuildNumber}
```

This creates a ticket in the IOSCON Jira project, includes QA verification from TestRail milestone, and sends to the iOS team distribution list `iphone@groupon.com`.

### Check Current Release Branch

```
@mobilebot release_branch
```

Responds with the currently tracked release branch. To reset from GitHub:

```
@mobilebot release_branch reset
```

To manually override:

```
@mobilebot release_branch set release/Major.Minor
```

### Cut a Release Branch

A branch cut triggers mobilebot auto-update when the message `HURRAY.. New release branch "{branch}" has been cut` is detected in Slack.

### Restart Service

> Not applicable — the iOS Consumer App is a mobile client. "Restarting" means asking users to close and reopen the app.

### Scale Up / Down

> Not applicable — scaling is managed by Apple App Store infrastructure and iOS OS on end-user devices.

### Database Operations

On-device data can be cleared by:
- Deleting and reinstalling the app (clears all NSUserDefaults and Keychain data)
- Using debug flags: `clearImageAndUrlCacheOnStartup` (NSUserDefaults) to clear image/URL cache on next launch

## Troubleshooting

### Build Fails — Code Signing Error

- **Symptoms**: Jenkins build fails with code signing or provisioning profile error
- **Cause**: Provisioning profiles may be stale after adding new UDIDs; Fastlane Match certificates may be expired
- **Resolution**:
  1. Delete local provisioning profiles: `rm -rf ~/Library/MobileDevice/Provisioning\ Profiles/`
  2. Refresh profiles in Xcode
  3. Run `nx reinstall` and retry the build

### Push Notifications Not Received

- **Symptoms**: Users report not receiving push notifications
- **Cause**: APNS device token not registered, push consent not granted, or `gaurun` delivery failure
- **Resolution**:
  1. Check `pushNotificationsEnabled` and `didSuccessfullyPostDeviceToken` NSUserDefaults values on affected device
  2. Check `gaurun` service health and Kafka `APNSConsumerQueueNotification` consumer lag
  3. Verify APNS certificates are valid and not expired (managed via Fastlane Match)

### App Launches in Wrong Mode (Legacy vs MBNXT)

- **Symptoms**: App launches in legacy mode when MBNXT is expected, or vice versa
- **Cause**: `useLegacyApp`, `optOutMbnxt`, or `isLocallyBucketedToMbnxt` NSUserDefaults flags are in unexpected state
- **Resolution**:
  1. Check NSUserDefaults via the MBNXT Dev Screen > Updates panel
  2. Use `simulateNewUserEachStart` debug flag to reset state for testing
  3. Check `isLocallyBucketedToMbnxt` via `LegacyDataStore.isLocallyBucketedToMbnxt()`

### Jenkins Build Not Triggering

- **Symptoms**: mobilebot reports "Failed to start build" in `#mobile-ios-release`
- **Cause**: Jenkins API token invalid, wrong room permissions, or Jenkins unavailable
- **Resolution**:
  1. Verify command is issued from `#mobile-ios-release` channel (room permission validation enforced)
  2. Check Jenkins at `https://cloud-jenkins.groupondev.com`
  3. Verify mobilebot has valid Jenkins API credentials

### mobilebot upload only allowed in specific channels

- **Symptoms**: mobilebot replies with warning emoji
- **Cause**: `upload` command issued from wrong Slack channel
- **Resolution**: Issue command only from `#mobile-ios-release` for iOS uploads

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | App Store unavailability or critical crash affecting all users | Immediate | Mobile Consumer Team (`iphone@groupon.com`) |
| P2 | Checkout or authentication broken for majority of users | 30 min | Mobile Consumer Team |
| P3 | Minor feature degradation or push notification issues | Next business day | Mobile Consumer Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `api-lazlo-sox` | Check backend API availability via Groupon monitoring | App displays offline state or cached content |
| APNS | Apple System Status page (`developer.apple.com/system-status`) | No push notifications delivered; app functions normally for browsing |
| Apple App Store | App Store Connect dashboard | Previous app version remains available to users |
| Jenkins CI | `https://cloud-jenkins.groupondev.com` | Manual Fastlane build from local developer machine |
