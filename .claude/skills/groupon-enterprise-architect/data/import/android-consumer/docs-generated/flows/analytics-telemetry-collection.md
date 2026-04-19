---
service: "android-consumer"
title: "Analytics and Telemetry Collection"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "analytics-telemetry-collection"
flow_type: asynchronous
trigger: "User interaction or system event occurs within the app"
participants:
  - "androidConsumer_featureModules"
  - "androidConsumer_networkIntegration"
  - "androidConsumer_telemetryAndCrash"
  - "firebase"
  - "bloomreach"
  - "appsFlyer"
architecture_ref: "dynamic-android-consumer-telemetry"
---

# Analytics and Telemetry Collection

## Summary

The analytics and telemetry collection flow is a cross-cutting concern triggered by any significant user interaction or system event throughout the app. Feature modules emit events to the `androidConsumer_telemetryAndCrash` component, which routes them to four destinations: Firebase Analytics (user behaviour and conversion funnels), Firebase Crashlytics (errors and crashes), AppsFlyer (attribution and install conversion), and Bloomreach/Exponea (customer engagement and CDP). Microsoft Clarity session recordings run passively in the background. All SDKs buffer events locally and batch-transmit when connectivity allows.

## Trigger

- **Type**: user-action or system-event
- **Source**: Any in-app interaction (screen view, tap, purchase, search, notification tap) or system event (crash, API error, app lifecycle)
- **Frequency**: Continuous — every interaction and system event during a session

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Feature Modules | Emit business and behavioral events at interaction points | `androidConsumer_featureModules` |
| Network Integration Layer | Emits API request timing and error telemetry | `androidConsumer_networkIntegration` |
| Telemetry and Crash Reporting | Routes events to the appropriate SDK destinations | `androidConsumer_telemetryAndCrash` |
| Firebase Analytics | Ingests user behavior and conversion events | `firebase` |
| Firebase Crashlytics | Ingests crash reports and non-fatal error events | `firebase` |
| AppsFlyer | Ingests attribution and in-app event signals | `appsFlyer` |
| Bloomreach (Exponea) | Ingests customer engagement events for segmentation | `bloomreach` |

## Steps

1. **Feature module detects trackable event**: A user taps a UI element, views a screen, completes a purchase, or a system error occurs.
   - From: `androidConsumer_featureModules` (or `androidConsumer_networkIntegration` for API errors)
   - To: `androidConsumer_telemetryAndCrash`
   - Protocol: Direct (in-process function call)

2. **Telemetry component routes event to Firebase Analytics**: Structured event (name + parameter map) is passed to the Firebase Analytics SDK; the SDK adds it to its local queue.
   - From: `androidConsumer_telemetryAndCrash`
   - To: Firebase Analytics SDK (in-process)
   - Protocol: Direct (SDK API)

3. **Telemetry component routes event to Bloomreach (Exponea)**: Engagement event with customer ID and properties is passed to the Bloomreach SDK queue for the appropriate tenant (UK or US token).
   - From: `androidConsumer_telemetryAndCrash`
   - To: Bloomreach SDK (in-process)
   - Protocol: Direct (SDK API)

4. **Telemetry component routes event to AppsFlyer**: In-app event (event name + revenue if applicable) is passed to the AppsFlyer SDK.
   - From: `androidConsumer_telemetryAndCrash`
   - To: AppsFlyer SDK (in-process)
   - Protocol: Direct (SDK API)

5. **Crash or error: routes to Firebase Crashlytics**: On unhandled exception or explicit `recordException()`, the crash report (stack trace + context) is passed to the Crashlytics SDK.
   - From: `androidConsumer_telemetryAndCrash`
   - To: Firebase Crashlytics SDK (in-process)
   - Protocol: Direct (SDK API / uncaught exception handler)

6. **SDK batches events locally**: Each SDK stores events in its own internal queue/buffer on disk. Transmission is deferred until connectivity is available and batching thresholds are met.
   - From: Firebase/Bloomreach/AppsFlyer SDKs (in-process)
   - To: SDK internal local queue
   - Protocol: Direct (in-process)

7. **SDK transmits batch to remote endpoint**: When network connectivity is available, each SDK sends queued events to its respective backend over HTTPS.
   - From: Firebase SDK → `https://firebaselogging.googleapis.com/*`
   - From: Bloomreach SDK → Bloomreach API (per tenant token)
   - From: AppsFlyer SDK → AppsFlyer attribution API
   - Protocol: HTTPS

8. **Microsoft Clarity records session passively**: Clarity SDK passively records user interaction gestures and screen recordings; no explicit event emission is required from feature modules.
   - From: Microsoft Clarity SDK (passive background process)
   - To: Clarity backend
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Network unavailable during SDK flush | SDK retains events in local buffer; retries when connectivity resumes | Events delivered with delay; no user-facing impact |
| Firebase Analytics event exceeds parameter limits | Event silently dropped by SDK if over 500 parameters or 100 chars | Event lost; no crash |
| Bloomreach SDK rate limit hit | SDK queues and retries after backoff | Minor event delay |
| AppsFlyer SDK initialization failure | Attribution events lost for that session | Install/conversion attribution may be incomplete |
| Crashlytics crash report upload fails | Report retained locally; retried on next app start | Crash report delivered on next launch |

## Sequence Diagram

```
featureModules -> telemetryAndCrash: trackEvent(name, params)
telemetryAndCrash -> FirebaseAnalyticsSDK: logEvent(name, bundle)
telemetryAndCrash -> BloomreachSDK: trackEvent(type, properties)
telemetryAndCrash -> AppsFlyerSDK: logEvent(name, values)

networkIntegration -> telemetryAndCrash: trackApiError(endpoint, code)
telemetryAndCrash -> CrashlyticsSDK: recordException(error)

FirebaseAnalyticsSDK -> firebase: HTTPS batch upload (async, when connected)
BloomreachSDK -> bloomreach: HTTPS batch upload (async, when connected)
AppsFlyerSDK -> appsFlyer: HTTPS batch upload (async, when connected)
```

## Related

- Architecture dynamic view: `dynamic-android-consumer-telemetry` (not yet modeled in DSL)
- Related flows: [Deal Discovery and Browse](deal-discovery-browse.md), [Shopping Cart and Checkout](shopping-cart-checkout.md), [Push Notification and Deep-link](push-notification-deeplink.md)
