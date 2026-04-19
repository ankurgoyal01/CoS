---
service: "android-consumer"
title: "Deal Discovery and Browse"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deal-discovery-browse"
flow_type: synchronous
trigger: "User opens the app, navigates to browse, or performs a search"
participants:
  - "androidConsumer_appEntryPoints"
  - "androidConsumer_featureModules"
  - "androidConsumer_localPersistence"
  - "androidConsumer_networkIntegration"
  - "continuumAndroidLocalStorage"
  - "apiProxy"
  - "androidConsumer_telemetryAndCrash"
architecture_ref: "dynamic-android-consumer-deal-discovery"
---

# Deal Discovery and Browse

## Summary

When a user opens the Groupon Android app or navigates to the deals browse or search screens, the app checks the local Room cache for valid (non-expired) deal data before making a network request. On a cache hit the results are rendered immediately; on a miss or TTL expiry the Feature Modules request fresh data from `apiProxy`, store the response in `continuumAndroidLocalStorage`, and render the results. User interactions (views, taps, searches) are emitted as analytics events to Firebase Analytics.

## Trigger

- **Type**: user-action
- **Source**: User launches app, taps the Browse tab, or enters a search query
- **Frequency**: On demand — each browse session and search interaction

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| App Entry Points | Receives navigation intent; routes to browse/search fragment | `androidConsumer_appEntryPoints` |
| Feature Modules (Deals/Search) | Orchestrates data fetch, cache check, and UI rendering | `androidConsumer_featureModules` |
| Local Persistence Layer | Reads cached deal data; writes fresh API payloads | `androidConsumer_localPersistence` |
| Android Local Storage | Stores deal cache (Room/SQLite) | `continuumAndroidLocalStorage` |
| Network Integration Layer | Calls `/deals/*` and `/search/*` endpoints via Retrofit | `androidConsumer_networkIntegration` |
| Groupon Backend APIs | Returns deal listings, search results, and collection data | `apiProxy` |
| Telemetry and Crash Reporting | Emits screen view and interaction analytics events | `androidConsumer_telemetryAndCrash` |

## Steps

1. **User navigates to browse or search**: User taps the Browse tab or enters a search term.
   - From: `androidConsumer_appEntryPoints`
   - To: `androidConsumer_featureModules`
   - Protocol: Direct (Android navigation component)

2. **Feature Module checks local cache**: Deals/Search feature module queries Room via `androidConsumer_localPersistence` for cached results matching the current query and location.
   - From: `androidConsumer_featureModules`
   - To: `androidConsumer_localPersistence`
   - Protocol: Direct (Room DAO)

3. **Local Persistence Layer reads from Room**: Reads cached deal records from `continuumAndroidLocalStorage`; checks TTL timestamp.
   - From: `androidConsumer_localPersistence`
   - To: `continuumAndroidLocalStorage`
   - Protocol: Direct (SQLite/Room)

4. **Cache hit path — render from cache**: If cache is valid and TTL has not expired, feature module receives cached deal list and proceeds to step 8 (render).
   - From: `androidConsumer_localPersistence`
   - To: `androidConsumer_featureModules`
   - Protocol: Direct

5. **Cache miss / TTL expired path — fetch from API**: Feature module instructs Network Integration Layer to fetch fresh deal data.
   - From: `androidConsumer_featureModules`
   - To: `androidConsumer_networkIntegration`
   - Protocol: Direct (Kotlin Coroutine / RxJava2 observable)

6. **Network Integration Layer calls `apiProxy`**: Retrofit issues `GET /deals/*` or `GET /search/*` with OAuth 2.0 bearer token; Approov interceptor attaches attestation token.
   - From: `androidConsumer_networkIntegration`
   - To: `apiProxy`
   - Protocol: HTTPS/REST

7. **Store API response in Room**: Network Integration Layer writes the fresh deal payload to `continuumAndroidLocalStorage` via `androidConsumer_localPersistence`; TTL timestamp is updated.
   - From: `androidConsumer_networkIntegration`
   - To: `androidConsumer_localPersistence` → `continuumAndroidLocalStorage`
   - Protocol: Direct (Room DAO)

8. **Render deal listings to user**: Feature module binds deal data to the RecyclerView/Compose UI; user sees the deal list.
   - From: `androidConsumer_featureModules`
   - To: UI layer (in-process)
   - Protocol: Direct (Android UI binding)

9. **Emit analytics events**: Feature module emits screen view and deal impression events to `androidConsumer_telemetryAndCrash` for dispatch to Firebase Analytics.
   - From: `androidConsumer_featureModules`
   - To: `androidConsumer_telemetryAndCrash`
   - Protocol: Direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| API call fails (no connectivity) | Serve stale cache if available; otherwise show empty/error state | User sees cached content or empty screen with retry option |
| API returns HTTP 4xx/5xx | Show error state with retry option; log error via Crashlytics | User sees error message; no crash |
| Cache read fails (Room error) | Fall through to network fetch | API is called as if cache was empty |
| Network timeout | OkHttp timeout fires; Retrofit returns error | Feature module shows retry prompt |
| Approov attestation failure | Request is blocked by Approov interceptor | User sees connectivity error |

## Sequence Diagram

```
User -> appEntryPoints: Navigate to Browse/Search
appEntryPoints -> featureModules: Start deals/search flow
featureModules -> localPersistence: Query cached deals (TTL check)
localPersistence -> continuumAndroidLocalStorage: SELECT from Room
continuumAndroidLocalStorage --> localPersistence: Cached records (or empty)
localPersistence --> featureModules: Cache hit / miss result

alt Cache miss or TTL expired
  featureModules -> networkIntegration: Fetch deals/search
  networkIntegration -> apiProxy: GET /deals/* or GET /search/*
  apiProxy --> networkIntegration: Deal listing JSON
  networkIntegration -> localPersistence: Write fresh payload to Room
  localPersistence -> continuumAndroidLocalStorage: INSERT/UPDATE
end

featureModules -> UI: Bind deal data to list
featureModules -> telemetryAndCrash: Emit screen_view + impression events
```

## Related

- Architecture dynamic view: `dynamic-android-consumer-deal-discovery` (not yet modeled in DSL)
- Related flows: [Shopping Cart and Checkout](shopping-cart-checkout.md), [Analytics and Telemetry Collection](analytics-telemetry-collection.md), [Offline Support and Cache Invalidation](offline-support-cache-invalidation.md)
