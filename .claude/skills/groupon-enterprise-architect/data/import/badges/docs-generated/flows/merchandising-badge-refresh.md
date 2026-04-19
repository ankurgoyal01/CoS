---
service: "badges-service"
title: "Merchandising Badge Refresh Job"
generated: "2026-03-03"
type: flow
flow_name: "merchandising-badge-refresh"
flow_type: scheduled
trigger: "Quartz schedule — MerchandisingBadgeJob (ENABLE_JOBS=true)"
participants:
  - "badgeEngine"
  - "externalClientGateway"
  - "continuumDealCatalogApi"
  - "continuumBadgesRedis"
architecture_ref: "dynamic-badgeLookupFlow"
---

# Merchandising Badge Refresh Job

## Summary

This scheduled batch flow keeps the Redis badge cache populated with current merchandising badge assignments. For each configured merchandising badge type (mapped to a Deal Catalog taxonomy UUID), the job fetches the current list of matching deal UUIDs from the Deal Catalog Service, then writes `SetItemBadgeEntry` records to Redis with a 6-hour expiry. This ensures that badge lookups can be served from cache without on-demand DCS calls.

## Trigger

- **Type**: schedule
- **Source**: Quartz scheduler within the `jobs` deployment component (`ENABLE_JOBS=true`); schedule configured via `quartz` block in the per-environment YAML run config
- **Frequency**: Scheduled (cron interval defined in YAML run config)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Badge Engine / MerchandisingBadgeJob | Orchestrates the refresh: iterates over merchandising tag config, dispatches DCS calls, writes badge entries | `badgeEngine` (via `MerchandisingBadgeJob`) |
| External Client Gateway / DealCatalogClient | Issues HTTP calls to the Deal Catalog Service | `externalClientGateway` (via `DealCatalogClient`) |
| Deal Catalog Service (DCS) | Returns deal UUIDs associated with a given merchandising taxonomy UUID | `continuumDealCatalogApi` |
| Badges Redis | Receives written badge-item entries with TTL | `continuumBadgesRedis` |

## Steps

1. **Job triggered by Quartz scheduler**: The Quartz scheduler fires the `MerchandisingBadgeJob` on its configured schedule within the `jobs` pod.
   - From: Quartz scheduler
   - To: `MerchandisingBadgeJob`
   - Protocol: In-process (JTier Quartz bundle)

2. **Check job enabled flag**: The job checks `isBadgeJobEnabled` (derived from YAML run config). If `false`, the job exits immediately with no side effects.
   - From/To: `MerchandisingBadgeJob` (internal guard)
   - Protocol: Direct (in-process)

3. **Iterate over merchandising tag configuration**: For each entry in `merchandisingTagConfig` (a map of `badgeType -> taxonomyUUID`), the job submits a parallel task to an `ExecutorService` thread pool sized to the number of configured badge types.
   - From/To: `MerchandisingBadgeJob` (internal loop)
   - Protocol: Direct (in-process)

4. **Fetch deals from Deal Catalog Service**: For each badge type, the task calls `DealCatalogClient.getDealCatalogResponse(taxonomyId)` to retrieve all deal UUIDs associated with that taxonomy.
   - From: `DealCatalogClient`
   - To: `continuumDealCatalogApi`
   - Protocol: HTTPS/JSON

5. **Build SetItemBadgeEntry list**: For each deal UUID returned by DCS, the task constructs a `SetItemBadgeEntry(dealId, badgeType, badgeType, 21_600)` with a 6-hour (21,600-second) TTL.
   - From/To: `MerchandisingBadgeJob` task (internal)
   - Protocol: Direct (in-process)

6. **Write badge entries to Redis**: The task calls `BadgesController.setItemBadgesInCache(setItemBadgeEntries)` to write all badge entries for this badge type atomically to Redis.
   - From: `BadgesController` (via `MerchandisingBadgeJob` task)
   - To: `continuumBadgesRedis`
   - Protocol: RESP

7. **Await all parallel tasks**: The `ExecutorService.shutdown()` is called after launching all tasks; the job waits for all badge-type threads to complete.
   - From/To: `MerchandisingBadgeJob` (internal)
   - Protocol: Direct (in-process)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `IOException` from DCS call | Caught in the Runnable task; error logged with `badgeType` and `taxonomyId`; task exits for this badge type | Other badge types continue processing; stale Redis entries for failed type remain until TTL expiry |
| DCS returns empty response | `responseOpt.isEmpty()` check; cache write skipped | Redis entries for this badge type are not updated; previously cached entries remain until expiry |
| Redis write failure | Not explicitly caught in job; propagates as runtime exception | Badge entries for this type not written; job may fail for subsequent types |
| `isBadgeJobEnabled = false` | Explicit guard check at job entry | Job exits silently with no calls to DCS or Redis |

## Sequence Diagram

```
QuartzScheduler -> MerchandisingBadgeJob: Fire scheduled job
MerchandisingBadgeJob -> MerchandisingBadgeJob: Check isBadgeJobEnabled
MerchandisingBadgeJob -> ExecutorService: Submit task for each badgeType
loop for each badgeType in merchandisingTagConfig
  ExecutorService task -> DealCatalogClient: getDealCatalogResponse(taxonomyUUID)
  DealCatalogClient -> continuumDealCatalogApi: HTTPS GET deals by taxonomy
  continuumDealCatalogApi --> DealCatalogClient: DealCatalogResponse {dealIds[]}
  DealCatalogClient --> ExecutorService task: Optional<DealCatalogResponse>
  ExecutorService task -> BadgesController: setItemBadgesInCache([{dealId, badgeType, TTL=21600}])
  BadgesController -> continuumBadgesRedis: Write badge entries (RESP, TTL 6h)
  continuumBadgesRedis --> BadgesController: OK
end
MerchandisingBadgeJob -> ExecutorService: shutdown()
```

## Related

- Architecture dynamic view: `dynamic-badgeLookupFlow`
- Related flows: [Badge Lookup Request](badge-lookup-request.md), [Localization Cache Refresh Job](localization-cache-refresh.md)
- Configuration: [Configuration](../configuration.md) — `merchandisingTagConfig`, `quartz`, `ENABLE_JOBS`
- Data stores: [Data Stores](../data-stores.md)
