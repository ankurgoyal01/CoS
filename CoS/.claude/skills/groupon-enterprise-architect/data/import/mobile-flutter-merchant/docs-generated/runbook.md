---
service: "mobile-flutter-merchant"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Firebase Crashlytics crash-free rate | SDK monitoring | Continuous (real-time dashboard) | — |
| Firebase Analytics active users | SDK monitoring | Continuous | — |
| Play Store / App Store crash rate | Store console | Continuous | — |

> There are no HTTP health check endpoints — this is a mobile client application. Health is monitored through Firebase Crashlytics, Firebase Analytics, and app store crash reporting dashboards.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Crash-free users rate | gauge | Percentage of users who did not experience a crash (Firebase Crashlytics) | Below 99% triggers investigation |
| Firebase Analytics events | counter | User action and flow completion events (login, redemption, deal views) | Abnormal drop indicates client-side regression |
| App store rating / crash rate | gauge | Google Play and App Store reported crash rate and user rating | Play Store crash rate > 1.09% triggers review |
| FCM delivery rate | gauge | Proportion of push notifications successfully delivered | Monitored via Firebase console |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Crash reporting | Firebase Crashlytics console | Configured in Firebase project |
| Analytics | Firebase Analytics console | Configured in Firebase project |
| App stability | Google Play Console | Play Store developer console |
| App stability | App Store Connect | Apple developer console |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Crash spike | Crashlytics crash-free rate drops below threshold | critical | Identify crashing release version; roll back via store or hotfix build |
| FCM delivery failure | Push notifications not delivered across device population | warning | Verify FCM configuration and NOTS Service health |
| API connectivity failure | `mmaApiOrchestrator` errors spike (surfaced via Crashlytics non-fatal events) | warning | Check Continuum API health; verify OAuth token validity |

## Common Operations

### Restart Service

> Not applicable for a mobile app. To recover a misbehaving app version:
> 1. Identify the crashing build version in Firebase Crashlytics
> 2. If critical, publish a patch release via Jenkins pipeline and promote to the appropriate store track
> 3. For Android: use Google Play staged rollout halt to stop a bad release
> 4. For iOS: use App Store Connect to remove the affected build from sale

### Scale Up / Down

> Not applicable — mobile app distribution scales automatically through store delivery infrastructure.

### Database Operations

> Local SQLite (Drift) schema migrations are managed by the Drift ORM:
> 1. Increment the `schemaVersion` in the Drift database class
> 2. Define migration steps in the `migration` callback
> 3. Build and distribute a new app version; migrations run on first launch after update
> 4. Monitor Crashlytics for migration-related crashes post-release

## Troubleshooting

### App Crashes on Launch

- **Symptoms**: Crashlytics reports high crash rate immediately after a new release; users report app does not open
- **Cause**: Likely a null-safety violation, missing build configuration, or Drift schema migration failure
- **Resolution**: Check Crashlytics stack traces; if migration-related, ship a hotfix with corrected migration steps; if configuration-related, verify `google-services.json` / `GoogleService-Info.plist` are correctly embedded

### Push Notifications Not Received

- **Symptoms**: Merchants report missing deal or inbox notifications
- **Cause**: FCM token registration failure, NOTS Service outage, or device-level notification permission revoked
- **Resolution**: Verify NOTS Service health; check Firebase Messaging dashboard for delivery failures; ask affected users to check device notification permissions and re-log in to refresh FCM token

### API Calls Failing (No Data Displayed)

- **Symptoms**: Dashboard, deals, or payments screens show empty state or error messages
- **Cause**: `continuumUniversalMerchantApi`, `continuumDealManagementApi`, or `continuumPaymentsService` unavailable; or OAuth token expired
- **Resolution**: Verify Continuum service health via internal dashboards; confirm OAuth tokens are valid; app will fall back to cached Drift SQLite data for read-only views

### Feature Flag Not Taking Effect

- **Symptoms**: A newly enabled Firebase Remote Config flag is not reflected in the app
- **Cause**: Remote Config fetch interval not elapsed; app caches config between fetches
- **Resolution**: Verify flag is published in the Firebase console; force-fetch by asking user to restart the app; confirm default values are set correctly for fallback behaviour

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | App completely unusable (crashes on launch or core flow broken) | Immediate | Merchant Mobile team (mobile-mx@groupon.com), abhishekkumar |
| P2 | Major feature degraded (redemptions, payments, or deals unavailable) | 30 min | Merchant Mobile team |
| P3 | Minor feature impact (advisor, inbox, maps degraded) | Next business day | Merchant Mobile team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumUniversalMerchantApi` | Monitor via Continuum API health dashboards | Serve cached Drift SQLite data for read views |
| `continuumDealManagementApi` | Monitor via Continuum API health dashboards | Deal creation/edit flows show error state |
| `continuumPaymentsService` | Monitor via Continuum API health dashboards | Payment screens show cached data or error state |
| `continuumM3PlacesService` | Monitor via Continuum API health dashboards | Places screens show error state |
| `merchantAdvisorService` | Monitor via service health dashboards | Advisor section shows error or empty state |
| `notsService` | Monitor via service health dashboards | Onboarding todos not displayed |
| `salesForce` | Salesforce status page | Support/inbox chat unavailable; error state shown |
| `googleOAuth` | Google status dashboard | Login blocked; app is inaccessible until resolved |
| Firebase (FCM / Remote Config) | Firebase status page | Push notifications not delivered; feature flags use embedded defaults |
