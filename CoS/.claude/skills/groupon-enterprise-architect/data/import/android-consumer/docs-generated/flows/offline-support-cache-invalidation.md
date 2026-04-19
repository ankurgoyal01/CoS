---
service: "android-consumer"
title: "Offline Support and Cache Invalidation"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "offline-support-cache-invalidation"
flow_type: event-driven
trigger: "Network connectivity change detected, or TTL check fails on a cache read"
participants:
  - "androidConsumer_featureModules"
  - "androidConsumer_localPersistence"
  - "androidConsumer_networkIntegration"
  - "continuumAndroidLocalStorage"
  - "apiProxy"
architecture_ref: "dynamic-android-consumer-offline"
---

# Offline Support and Cache Invalidation

## Summary

The offline support and cache invalidation flow ensures the app remains usable during connectivity loss by serving TTL-checked Room cache data, and recovers gracefully when connectivity is restored by flushing a pending sync queue via Android WorkManager. When a user action triggers a data read and the cache is expired or empty, the app attempts a network fetch. If the device is offline the stale cache (or an error state) is served. Mutations (cart updates, account changes) attempted while offline are queued in Room and replayed when connectivity returns.

## Trigger

- **Type**: event (network state change) or implicit (TTL expiry on cache read)
- **Source**: Android `ConnectivityManager` network callback; or Feature Module TTL check during a data read
- **Frequency**: Continuous background monitoring; triggered on every data read and on network state transitions

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Feature Modules | Initiates data reads; queues offline mutations; handles connectivity-aware UI state | `androidConsumer_featureModules` |
| Local Persistence Layer | Reads/writes Room cache; manages sync queue; evaluates TTL | `androidConsumer_localPersistence` |
| Android Local Storage | Stores cache records, sync queue, and TTL metadata | `continuumAndroidLocalStorage` |
| Network Integration Layer | Executes API calls when online; skips when offline | `androidConsumer_networkIntegration` |
| Groupon Backend APIs | Provides fresh data on cache miss when online | `apiProxy` |

## Steps

### Path A: Connectivity Loss — Serve from Cache

1. **Feature module requests data**: User navigates to a screen requiring data (deals, cart, account).
   - From: `androidConsumer_featureModules`
   - To: `androidConsumer_localPersistence`
   - Protocol: Direct

2. **Local Persistence reads cache with TTL check**: Room is queried; the TTL timestamp on the cached record is compared to the current time.
   - From: `androidConsumer_localPersistence`
   - To: `continuumAndroidLocalStorage`
   - Protocol: Direct (Room DAO)

3. **TTL not expired — serve from cache**: Fresh cached data is returned to the Feature Module; no network call is made.
   - From: `continuumAndroidLocalStorage` → `androidConsumer_localPersistence`
   - To: `androidConsumer_featureModules`
   - Protocol: Direct

4. **TTL expired — attempt network fetch**: Feature module calls Network Integration Layer; connectivity check determines the device is offline.
   - From: `androidConsumer_featureModules`
   - To: `androidConsumer_networkIntegration`
   - Protocol: Direct

5. **Network unavailable — serve stale cache**: Network Integration Layer detects no connectivity (via ConnectivityManager or OkHttp failure); Local Persistence falls back to serving the stale cached record.
   - From: `androidConsumer_networkIntegration`
   - To: `androidConsumer_featureModules`
   - Protocol: Direct (error/fallback callback)

6. **UI shows offline indicator**: Feature module renders stale data with an offline banner or shows an empty state with a "No connection" message.
   - From: `androidConsumer_featureModules`
   - To: UI layer
   - Protocol: Direct

### Path B: Offline Mutation — Sync Queue

1. **User performs a mutation while offline** (e.g., taps "Add to Cart" with no connectivity):
   - From: `androidConsumer_featureModules`
   - To: `androidConsumer_networkIntegration`
   - Protocol: Direct

2. **Network Integration Layer detects offline state**: API call fails immediately; Feature Module is notified.
   - From: `androidConsumer_networkIntegration`
   - To: `androidConsumer_featureModules`
   - Protocol: Direct (error callback)

3. **Mutation queued in sync queue**: Feature module writes the pending operation (operation type, payload, timestamp, retry count) to the sync queue table in `continuumAndroidLocalStorage`.
   - From: `androidConsumer_featureModules` → `androidConsumer_localPersistence`
   - To: `continuumAndroidLocalStorage`
   - Protocol: Direct (Room DAO)

4. **User is shown optimistic UI**: Feature module applies the change optimistically to the local cache so the UI appears responsive.
   - From: `androidConsumer_featureModules`
   - To: UI layer
   - Protocol: Direct

### Path C: Connectivity Restored — Sync Queue Flush

1. **ConnectivityManager fires network-available callback**: Android system detects connectivity restored.
   - From: Android OS
   - To: `androidConsumer_featureModules` (network listener)
   - Protocol: Android ConnectivityManager callback

2. **WorkManager job scheduled to flush sync queue**: Feature module enqueues a `OneTimeWorkRequest` via Android WorkManager for the sync queue worker.
   - From: `androidConsumer_featureModules`
   - To: Android WorkManager (in-process)
   - Protocol: Direct (WorkManager API)

3. **Sync worker reads pending operations from queue**: WorkManager executes the sync worker; it reads all queued sync operations from `continuumAndroidLocalStorage`.
   - From: WorkManager sync worker → `androidConsumer_localPersistence`
   - To: `continuumAndroidLocalStorage`
   - Protocol: Direct (Room DAO)

4. **Worker replays mutations against `apiProxy`**: Each queued operation is submitted to `apiProxy` via Network Integration Layer in order.
   - From: `androidConsumer_networkIntegration`
   - To: `apiProxy`
   - Protocol: HTTPS/REST

5. **Successful operations removed from queue**: On `apiProxy` success response, the corresponding sync queue record is deleted from Room.
   - From: `androidConsumer_localPersistence`
   - To: `continuumAndroidLocalStorage`
   - Protocol: Direct (Room DAO)

6. **Failed operations retried or discarded**: On failure, the retry count is incremented; operations exceeding the retry threshold are discarded and the user may be notified.
   - From: WorkManager sync worker
   - To: `continuumAndroidLocalStorage`
   - Protocol: Direct

7. **Cache refresh triggered**: After sync queue flush, feature modules refresh their cache by fetching updated data from `apiProxy`.
   - From: `androidConsumer_featureModules`
   - To: `androidConsumer_networkIntegration` → `apiProxy`
   - Protocol: HTTPS/REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No cache and no connectivity | Show empty state with offline message | User cannot browse; prompted to connect |
| Sync queue operation fails after max retries | Operation discarded; user notified | Mutation is lost; user may need to repeat action |
| Connectivity restored but `apiProxy` returns error | WorkManager retries with exponential backoff | Sync delayed; eventual consistency maintained |
| Room database corruption | Room fallback or destructive migration | Cache cleared; fresh data fetched when online |
| WorkManager job killed by OS (low memory) | WorkManager reschedules on next app launch | Sync delayed to next launch |

## Sequence Diagram

```
User -> featureModules: Request data (browsing, TTL expired)
featureModules -> localPersistence: Read cache + TTL check
localPersistence -> continuumAndroidLocalStorage: SELECT (Room)
continuumAndroidLocalStorage --> localPersistence: Stale or empty

alt Online
  featureModules -> networkIntegration: Fetch from API
  networkIntegration -> apiProxy: GET /deals/* or /cart/*
  apiProxy --> networkIntegration: Fresh data
  networkIntegration -> localPersistence: Update Room cache + TTL
else Offline
  featureModules -> UI: Show stale data or offline state
end

User -> featureModules: Mutation while offline (e.g., add to cart)
featureModules -> networkIntegration: POST /cart/* (fails — offline)
featureModules -> localPersistence: Enqueue mutation in sync_queue (Room)
featureModules -> UI: Apply optimistic update

Android OS -> featureModules: Network available callback
featureModules -> WorkManager: Schedule sync queue flush
WorkManager -> localPersistence: Read sync_queue
localPersistence -> continuumAndroidLocalStorage: SELECT pending ops
WorkManager -> networkIntegration: Replay mutations
networkIntegration -> apiProxy: POST/PATCH/DELETE (replay)
apiProxy --> networkIntegration: Success
WorkManager -> localPersistence: Remove completed ops from queue
```

## Related

- Architecture dynamic view: `dynamic-android-consumer-offline` (not yet modeled in DSL)
- Related flows: [Deal Discovery and Browse](deal-discovery-browse.md), [Shopping Cart and Checkout](shopping-cart-checkout.md)
