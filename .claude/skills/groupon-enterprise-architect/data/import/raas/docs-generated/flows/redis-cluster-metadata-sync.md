---
service: "raas"
title: "Redis Cluster Metadata Sync"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "redis-cluster-metadata-sync"
flow_type: scheduled
trigger: "Periodic job schedule (API Caching Service collection run)"
participants:
  - "continuumRaasApiCachingService"
  - "continuumRaasRedislabsApi"
  - "continuumRaasGithubSecrets"
  - "continuumRaasInfoService"
  - "continuumRaasMetadataMysql"
architecture_ref: "dynamic-raas-telemetry-flow"
---

# Redis Cluster Metadata Sync

## Summary

The Redis Cluster Metadata Sync flow collects live cluster and database telemetry from the Redislabs Control Plane API, writes atomic JSON snapshots to the local filesystem cache, and then synchronizes the parsed data into the MySQL metadata store. This ensures the RaaS Info Service serves up-to-date cluster, node, DB, endpoint, and shard inventory to operators.

## Trigger

- **Type**: schedule
- **Source**: Periodic job scheduler that invokes the API Cache Collector
- **Frequency**: Scheduled (interval not specified in architecture model; runs on a recurring basis)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Cache Collector | Fetches Redislabs API payloads and writes filesystem snapshots | `continuumRaasApiCachingService` |
| API Cache Storage | Stores atomic JSON snapshots for downstream consumers | `continuumRaasApiCachingService` (component) |
| Redislabs Control Plane API | Provides cluster, node, DB, and status telemetry | `continuumRaasRedislabsApi` |
| GitHub Raw Secrets | Provides bootstrapped API credentials at startup | `continuumRaasGithubSecrets` |
| RaaS Info Updater Job | Reads cached snapshots and upserts normalized entities | `continuumRaasInfoService` |
| RaaS Info Persistence Layer | ActiveRecord store for clusters, nodes, DBs, endpoints, shards | `continuumRaasInfoService` |
| RaaS Metadata MySQL | Persists synchronized inventory metadata | `continuumRaasMetadataMysql` |

## Steps

1. **Bootstrap API credentials**: The API Cache Collector reads Redislabs API credentials from GitHub Secrets at startup.
   - From: `continuumRaasApiCachingService`
   - To: `continuumRaasGithubSecrets`
   - Protocol: HTTPS

2. **Fetch cluster and DB telemetry**: The API Cache Collector sends requests to the Redislabs Control Plane API for cluster, node, DB, and status payloads.
   - From: `continuumRaasApiCachingService`
   - To: `continuumRaasRedislabsApi`
   - Protocol: REST/HTTPS

3. **Write atomic JSON snapshots**: The API Cache Collector writes parsed API responses as atomic JSON files to the `api_cache/` and `raas_info/` directories.
   - From: `continuumRaasApiCachingService_raasApiCacheCollector`
   - To: `continuumRaasApiCachingService_raasApiCacheStorage`
   - Protocol: Filesystem write

4. **Read cached snapshots**: The RaaS Info Updater Job reads the latest JSON snapshots from the filesystem cache.
   - From: `continuumRaasInfoService_raasInfoUpdaterJob`
   - To: `continuumRaasApiCachingService_raasApiCacheStorage`
   - Protocol: Filesystem read

5. **Parse and upsert normalized entities**: The Info Updater Job parses rladmin and API JSON snapshots, then upserts cluster, node, DB, endpoint, and shard records via the ActiveRecord persistence layer.
   - From: `continuumRaasInfoService_raasInfoUpdaterJob`
   - To: `continuumRaasInfoService_raasInfoPersistence`
   - Protocol: ActiveRecord (in-process)

6. **Persist to MySQL**: The persistence layer writes normalized entities to the MySQL metadata store.
   - From: `continuumRaasInfoService_raasInfoPersistence`
   - To: `continuumRaasMetadataMysql`
   - Protocol: SQL

7. **Serve refreshed metadata**: Operators query the Info Service Web UI or REST API and receive up-to-date cluster inventory data.
   - From: Administrator
   - To: `continuumRaasInfoService_raasInfoWebUi`
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Redislabs API unreachable | Collection job fails; existing filesystem cache retained | Info Updater and Monitoring Service continue operating on last-known-good snapshots |
| GitHub Secrets bootstrap fails | API Cache Collector cannot authenticate; collection halts | All telemetry collection stops; cache becomes stale |
| MySQL write failure | ActiveRecord raises exception; upsert fails | Existing MySQL data remains unchanged; next scheduled run retries |
| Corrupt/incomplete JSON snapshot | Info Updater Job parse error; upsert skipped for affected entities | Partial update; stale entities remain until next successful run |

## Sequence Diagram

```
Administrator     -> continuumRaasApiCachingService : Schedule collection job
continuumRaasApiCachingService -> continuumRaasGithubSecrets  : Bootstrap API credentials
continuumRaasApiCachingService -> continuumRaasRedislabsApi   : Fetch cluster/DB telemetry
continuumRaasRedislabsApi      --> continuumRaasApiCachingService : Return JSON payloads
continuumRaasApiCachingService -> FilesystemCache             : Write atomic JSON snapshots
continuumRaasInfoService       -> FilesystemCache             : Read cached snapshots
continuumRaasInfoService       -> continuumRaasMetadataMysql  : Upsert normalized cluster entities
Administrator     -> continuumRaasInfoService                 : View refreshed cluster metadata
continuumRaasInfoService       --> Administrator              : Return cluster/DB/node/endpoint/shard data
```

## Related

- Architecture dynamic view: `dynamic-raas-telemetry-flow`
- Related flows: [Cluster Health Monitoring](cluster-health-monitoring.md)
