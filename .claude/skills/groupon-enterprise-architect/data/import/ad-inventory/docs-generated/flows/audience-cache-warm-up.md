---
service: "ad-inventory"
title: "Audience Cache Warm-Up"
generated: "2026-03-03"
type: flow
flow_name: "audience-cache-warm-up"
flow_type: scheduled
trigger: "Quartz scheduler cron — triggers AudienceLoadJob to populate audience caches"
participants:
  - "continuumAdInventoryService_schedulerApi"
  - "continuumAdInventoryService_audienceApi"
  - "continuumAdInventoryService_abstractAudienceService"
  - "continuumAdInventoryMySQL"
  - "continuumAdInventoryService_gcpClient"
  - "continuumAdInventoryGcs"
  - "continuumAdInventoryRedis"
architecture_ref: "dynamic-ad-inventory-reporting-ingestion-flow"
---

# Audience Cache Warm-Up

## Summary

The Audience Cache Warm-Up flow loads audience definitions, targeting rules, and bloom filter data from MySQL and GCS into the Redis cache and Guava in-memory caches. This flow runs on a Quartz-scheduled cron and ensures that the ad placement serving path has low-latency access to audience membership data without hitting the database on every request. The same refresh is also triggered on demand via the `DELETE /admin/v1/caches` admin endpoint.

## Trigger

- **Type**: schedule (also triggerable via admin API)
- **Source**: Quartz scheduler (`AudienceLoadJob`)
- **Frequency**: On Quartz cron schedule (configured in Quartz config); on-demand via `DELETE /admin/v1/caches?amsecret=<secret>`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Scheduler API | Triggers `AudienceLoadJob` on cron schedule | `continuumAdInventoryService_schedulerApi` |
| Audience API | Orchestrates cache population; resolves audience membership | `continuumAdInventoryService_audienceApi` |
| Audience Service (JDBI) | Reads all active audience definitions and targeting records from MySQL | `continuumAdInventoryService_abstractAudienceService` |
| Ad Inventory MySQL | Source of audience definitions, targeting rules, and bloom filter GCS paths | `continuumAdInventoryMySQL` |
| GCP Client | Downloads bloom filter binary files from GCS | `continuumAdInventoryService_gcpClient` |
| Ad Inventory GCS Bucket | Stores the bloom filter files per audience/segment | `continuumAdInventoryGcs` |
| Ad Inventory Redis | Destination cache for audience membership (bloom filters) and audience target lists | `continuumAdInventoryRedis` |

## Steps

1. **Quartz triggers AudienceLoadJob**: `SchedulerApi` fires `AudienceLoadJob` per configured cron schedule (or on admin cache-flush request).
   - From: `continuumAdInventoryService_schedulerApi`
   - To: `continuumAdInventoryService_audienceApi`
   - Protocol: Quartz in-process trigger

2. **Load all audience definitions from MySQL**: `AbstractAudienceService` executes a JDBI DAO query to retrieve all active `Audience` records including their segment keys and GCS bloom filter file paths.
   - From: `continuumAdInventoryService_abstractAudienceService`
   - To: `continuumAdInventoryMySQL`
   - Protocol: JDBI / SQL

3. **Load audience targets from MySQL**: `AbstractAudienceService` queries audience-target records (mapping of placement ID + country + ad format → audience ID + segment) to populate the `audienceTargetCache`.
   - From: `continuumAdInventoryService_abstractAudienceService`
   - To: `continuumAdInventoryMySQL`
   - Protocol: JDBI / SQL

4. **Download bloom filter files from GCS**: For each audience, `GCPClient` downloads the corresponding bloom filter binary file from GCS.
   - From: `continuumAdInventoryService_gcpClient`
   - To: `continuumAdInventoryGcs`
   - Protocol: GCS SDK

5. **Populate audienceCache in Redis and in-memory**: `AudienceApi` serializes each `Audience` object (with its bloom filter) into the `audienceCache` keyed by `(audienceId, audienceSegment)`.
   - From: `continuumAdInventoryService_audienceApi`
   - To: `continuumAdInventoryRedis`
   - Protocol: Redis (Redisson)

6. **Populate audienceTargetCache in Redis and in-memory**: `AudienceApi` writes the list of `AudienceTargetContent` objects for each `(placementId, country, adFormat)` combination into `audienceTargetCache`.
   - From: `continuumAdInventoryService_audienceApi`
   - To: `continuumAdInventoryRedis`
   - Protocol: Redis (Redisson)

7. **Update audience targeting state**: `AudienceApi` calls `AbstractAudienceService.updateAudienceTargetingState()` to persist any cache-derived state changes back to MySQL.
   - From: `continuumAdInventoryService_audienceApi`
   - To: `continuumAdInventoryService_abstractAudienceService`
   - Protocol: in-process call

8. **Cache ready for placement serving**: After completion, `AdInventoryPlacementResource` can serve placement requests using the freshly loaded cache entries without touching MySQL or GCS.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MySQL unavailable | `AbstractAudienceService` fails; job logs error | Cache not refreshed; stale entries used for placement serving |
| GCS download failure for specific audience | Error logged per audience; remaining audiences still loaded | Affected audience's bloom filter cache entry not updated; placement targeting may be stale for that audience |
| Redis write failure | Error logged; Guava in-memory cache still populated | Redis misses fall back to in-memory cache until next warm-up |
| Full cache refresh failure | No audiences loaded; stale cache entries expire over time | Placement serving degrades to no audience targeting; alert recommended |

## Sequence Diagram

```
QuartzScheduler -> AudienceLoadJob: trigger (cron / admin flush)
AudienceLoadJob -> AbstractAudienceService: getAllAudiences()
AbstractAudienceService -> MySQL: SELECT audience records
MySQL --> AbstractAudienceService: List<Audience>
AudienceLoadJob -> AbstractAudienceService: getAllAudienceTargets()
AbstractAudienceService -> MySQL: SELECT audience_target records
MySQL --> AbstractAudienceService: List<AudienceTargetContent>
AudienceLoadJob -> GCPClient: downloadBloomFilter(audienceId, segment) [for each]
GCPClient -> GCS: GET bloom filter file
GCS --> GCPClient: bloom filter bytes
AudienceLoadJob -> Redis: PUT audienceCache[audienceId+segment] = Audience (for each)
AudienceLoadJob -> Redis: PUT audienceTargetCache[placementId+country+format] = targets
AudienceLoadJob -> AbstractAudienceService: updateAudienceTargetingState()
AbstractAudienceService -> MySQL: UPDATE targeting state
```

## Related

- Architecture dynamic view: `dynamic-ad-inventory-reporting-ingestion-flow`
- Related flows: [Ad Placement Serving](ad-placement-serving.md), [Audience Lifecycle Management](audience-lifecycle-management.md)
