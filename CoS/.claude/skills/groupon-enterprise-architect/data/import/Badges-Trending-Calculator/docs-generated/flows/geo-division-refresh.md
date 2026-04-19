---
service: "badges-trending-calculator"
title: "Geo Division Refresh"
generated: "2026-03-03"
type: flow
flow_name: "geo-division-refresh"
flow_type: scheduled
trigger: "Hourly scheduled executor in GeoServiceTask"
participants:
  - "continuumBadgesTrendingCalculator"
  - "continuumBhuvanService"
  - "continuumBadgesRedisStore"
architecture_ref: "dynamic-deal-purchase-badge-computation"
---

# Geo Division Refresh

## Summary

At service startup, a background `ScheduledExecutorService` is initialized in `GeoServiceTask.triggerScheduler` and fires every hour. Each execution calls the Bhuvan geo-places API to retrieve all supported division permalinks for each whitelisted country, then stores the result as a comma-separated string in the Redis key `Divison_Supported` with a 1-hour TTL. The `BadgeCalculatorProcessor` reads this key once per micro-batch to filter out purchases from unsupported divisions.

## Trigger

- **Type**: schedule
- **Source**: `GeoServiceTask` — `ScheduledExecutorService` with a fixed-rate of 1 hour
- **Frequency**: Every 60 minutes, starting immediately at job startup (initial delay = 0)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Badges Trending Calculator (GeoServiceTask) | Scheduler — triggers and orchestrates the refresh | `continuumBadgesTrendingCalculator` |
| Bhuvan geo-places service | Data source — provides division permalinks by country | `continuumBhuvanService` |
| Badges Redis Store | Cache — stores the `Divison_Supported` string | `continuumBadgesRedisStore` |

## Steps

1. **Trigger hourly refresh**: The `ScheduledExecutorService` in `GeoServiceTask` fires `run()` every 60 minutes.
   - From: JVM scheduler thread
   - To: `GeoServiceTask.run()`
   - Protocol: in-process (Java scheduled executor)

2. **Read country whitelist from config**: `GeoServiceTask` reads `app.country_whitelist` (e.g., `US,CA` in production) from the CDE Configuration service.
   - From: `GeoServiceTask`
   - To: CDE `Configuration` utility
   - Protocol: in-process

3. **Fetch divisions per country**: `GeoServiceClient.getAllDivisons` issues an HTTPS GET to `{geoServiceConfig.host}{geoServiceConfig.path}` with query parameters `client_id`, `country`, and `limit`. The `Host` header is set to the Bhuvan service domain. The response JSON is parsed to extract `divisionLocalizedAttributes.{defaultLocale}.permalink` for each division.
   - From: `geoServiceAdapter`
   - To: `continuumBhuvanService` (edge proxy)
   - Protocol: HTTPS (mTLS)

4. **Cache divisions in Redis**: If the fetched division set is non-empty, it is joined into a comma-separated string and written to the `Divison_Supported` Redis key with a TTL of 3600 seconds using `DBHandle.setWithExpiration`.
   - From: `geoDivisionScheduler`
   - To: `continuumBadgesRedisStore` (SETEX `Divison_Supported` 3600)
   - Protocol: Redis

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Bhuvan `IOException` | Caught in `GeoServiceClient.getAllDivisons`; empty set returned | Redis key not updated; existing cached value continues to be used for the next hour |
| Bhuvan `SocketTimeoutException` | Caught as `IOException`; empty set returned | Same as above |
| Empty division set returned | Guarded by `divisions != null && !divisions.isEmpty` check | Redis key not overwritten; stale cached value is retained |
| Redis connection failure | Not explicitly caught in `GeoServiceTask.run()`; exception propagates and is logged by executor | Refresh attempt fails; next scheduled run will retry |

## Sequence Diagram

```
GeoServiceTask    GeoServiceClient    BhuvanService    Redis
      |                  |                 |              |
      |--every 1hr------>|                 |              |
      |                  |--HTTPS GET /geoplaces/v1.3/divisions?country=US,CA-->|
      |                  |<--JSON divisions list-----------|              |
      |                  |  parse permalink set            |              |
      |<--divisionSet----|                 |              |
      |--SETEX Divison_Supported 3600---------------------->|
```

## Related

- Architecture dynamic view: `dynamic-deal-purchase-badge-computation`
- Related flows: [Deal Purchase Badge Computation](deal-purchase-badge-computation.md)
