---
service: "android-consumer"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Firebase Crashlytics dashboard | Manual review | Continuous (real-time) | — |
| Firebase Analytics — active users | Dashboard metric | Continuous | — |
| Google Play Store crash rate | Play Console metric | Continuous | — |
| Google Play Store ANR rate | Play Console metric | Continuous | — |

> Mobile apps do not have traditional HTTP health check endpoints. Health is monitored via Firebase Crashlytics, Firebase Analytics, and Google Play Console vitals.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Crash-free users rate | gauge | Percentage of sessions without a crash (Firebase Crashlytics) | < 99.5% triggers investigation |
| ANR rate | gauge | Application Not Responding rate (Google Play Console) | > 0.47% (Play Console threshold) |
| Daily active users | counter | Unique active users per day (Firebase Analytics) | Significant drop triggers investigation |
| Checkout conversion rate | gauge | Orders completed / checkout initiated | Significant drop triggers investigation |
| API error rate | counter | HTTP 4xx/5xx responses from `apiProxy` (OkHttp logging) | > No evidence found in codebase — threshold to be defined by team |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Crash and stability overview | Firebase Crashlytics | Firebase Console |
| User analytics and funnels | Firebase Analytics | Firebase Console |
| App vitals (ANR, crash rate) | Google Play Console | Google Play Console |
| Attribution and installs | AppsFlyer Dashboard | AppsFlyer Console |
| Customer engagement events | Bloomreach Dashboard | Bloomreach Console |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Crash spike | Crash-free users rate drops > 1% in rolling 24h | critical | Identify failing version; initiate Play Store rollback or halt rollout |
| ANR spike | ANR rate exceeds Play Console policy threshold | critical | Profile main thread blocking; deploy hotfix |
| Checkout failure spike | Checkout error rate rises significantly | critical | Check `apiProxy` health; check Adyen service status; escalate to Commerce team |
| FCM push delivery failure | Push notification delivery rate drops | warning | Check Firebase Cloud Messaging service status; verify FCM token registration flow |
| Play Store rating drop | App rating drops significantly | warning | Review recent crash reports and user reviews |

## Common Operations

### Restart Service

> Not applicable for a mobile app. Users restart the app via the Android system (kill process + relaunch). To force all users to restart with a new version, publish a new release via Google Play Store.

### Scale Up / Down

> Not applicable. Distribution infrastructure is managed by Google Play Store.

### Database Operations

- Room database schema migrations are defined in code via `@Migration` annotations in the `androidConsumer_localPersistence` module.
- To clear the on-device Room database for a specific user, the user must clear app data via Android Settings, or a new build that increments the Room database version and provides a destructive migration must be shipped.
- SharedPreferences can be cleared via Android Settings > Apps > Groupon > Clear Data.

## Troubleshooting

### Elevated Crash Rate After Release

- **Symptoms**: Firebase Crashlytics shows increased crash count; Play Console crash rate rises above 0.5%
- **Cause**: Regression introduced in the new build version
- **Resolution**: Identify the failing stack trace in Firebase Crashlytics; if a known version is stable, halt the Play Store rollout or initiate a rollback to the last stable version; deploy a hotfix build if rollback is not feasible

### Authentication Failures (Login Loop)

- **Symptoms**: Users report being unable to log in or being repeatedly logged out
- **Cause**: Okta token endpoint down, OAuth PKCE flow misconfigured, or SharedPreferences token corruption
- **Resolution**: Check `oktaIdentity` service status; verify OAuth configuration in `gradle.properties`; if token corruption is suspected, a new app version that clears corrupted SharedPreferences may be required

### Checkout Payment Failures

- **Symptoms**: Adyen 3DS screen fails to load or returns error; users cannot complete purchases
- **Cause**: Adyen service outage, expired Adyen merchant token, or `apiProxy` checkout endpoint errors
- **Resolution**: Check Adyen service status page; verify Adyen SDK version compatibility; check `apiProxy` checkout endpoint health; escalate to Commerce / Checkout team

### Push Notifications Not Delivered

- **Symptoms**: Users do not receive push notifications; FCM token registration may be failing
- **Cause**: FCM service disruption, invalid FCM token, or push notification backend not registering new tokens
- **Resolution**: Check Firebase Cloud Messaging service status; verify FCM token registration flow in `androidConsumer_telemetryAndCrash`; check push notification backend service

### Offline Mode Not Working

- **Symptoms**: App shows errors or blank screens when device has no connectivity
- **Cause**: Room cache TTL has expired or cache was never populated
- **Resolution**: Ensure users have used the app while online first to populate the cache; check TTL configuration in `androidConsumer_localPersistence`

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | App unlaunchable or checkout down for all users | Immediate | Mobile / Android Consumer Team + Commerce Team |
| P2 | Crash rate > 1% or major feature broken for many users | 30 min | Mobile / Android Consumer Team |
| P3 | Minor feature degradation, cosmetic issue | Next business day | Mobile / Android Consumer Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `apiProxy` | HTTP response codes in OkHttp logs / Firebase Analytics API error events | Serve cached content from `continuumAndroidLocalStorage` |
| `oktaIdentity` | Login flow success rate in Firebase Analytics | Allow read-only browsing if valid cached session exists |
| Firebase | Firebase Console status page | Events queued locally; no user-facing impact |
| Adyen | Adyen status page | Checkout fails gracefully with user-facing error message |
| Google Maps | Google Maps SDK status | Map component shows error state; search unaffected |
| Bloomreach | Bloomreach Console | Events queued by SDK; no user-facing impact |
