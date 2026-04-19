---
service: "raas"
title: "Cluster Health Monitoring"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "cluster-health-monitoring"
flow_type: scheduled
trigger: "Periodic job schedule (Monitoring Service updater and Checks Runner)"
participants:
  - "continuumRaasMonitoringService"
  - "continuumRaasChecksRunnerService"
  - "continuumRaasApiCachingService"
  - "continuumRaasMetadataMysql"
  - "continuumRaasMetadataPostgres"
architecture_ref: "dynamic-raas-telemetry-flow"
---

# Cluster Health Monitoring

## Summary

The Cluster Health Monitoring flow runs two parallel tracks. The Monitoring Service reads cached telemetry to build monitor configurations, aggregate cluster states, and synchronize metadata into MySQL and PostgreSQL. In parallel, the Checks Runner reads cached cluster state and executes Nagios health check plugins to evaluate the real-time health of Redis databases and clusters.

## Trigger

- **Type**: schedule
- **Source**: Periodic job scheduler that invokes Monitoring Service jobs and the Checks Runner
- **Frequency**: Scheduled (interval not specified in architecture model; runs on a recurring basis)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Monitoring Updater Job | Builds monitor definitions from host inventory and DB metadata | `continuumRaasMonitoringService` |
| RaaS Mons Aggregator Job | Aggregates cluster states across monitoring hosts | `continuumRaasMonitoringService` |
| Monitoring DB Sync Job | Swaps temporary tables and writes to MySQL/PostgreSQL | `continuumRaasMonitoringService` |
| API Cache Storage | Provides cached telemetry and rladmin snapshots | `continuumRaasApiCachingService` |
| Checks Orchestrator | Loads check definitions and orchestrates child check workers | `continuumRaasChecksRunnerService` |
| Check Plugins | Nagios health check scripts for Redis and cluster health | `continuumRaasChecksRunnerService` |
| RaaS Metadata MySQL | Receives refreshed monitoring metadata | `continuumRaasMetadataMysql` |
| RaaS Metadata PostgreSQL | Receives mirrored monitoring metadata | `continuumRaasMetadataPostgres` |

## Steps

### Track A: Monitoring Metadata Refresh

1. **Read cached telemetry**: The Monitoring Updater Job reads cached telemetry from the API Cache Storage filesystem.
   - From: `continuumRaasMonitoringService_raasMonUpdaterJob`
   - To: `continuumRaasApiCachingService_raasApiCacheStorage`
   - Protocol: Filesystem read

2. **Build monitor definitions**: The Monitoring Updater Job constructs monitor configuration definitions from host inventory and DB metadata.
   - From: `continuumRaasMonitoringService_raasMonUpdaterJob`
   - To: (internal processing)
   - Protocol: In-process

3. **Aggregate cluster states**: The RaaS Mons Aggregator Job reads remote-monitor snapshots from the cache and aggregates cluster health states across monitoring hosts.
   - From: `continuumRaasMonitoringService_raasMonAggregatorJob`
   - To: `continuumRaasApiCachingService_raasApiCacheStorage`
   - Protocol: Filesystem read

4. **Read rladmin snapshots**: The Monitoring DB Sync Job reads rladmin snapshot aggregates from the cache.
   - From: `continuumRaasMonitoringService_raasMonDbSyncJob`
   - To: `continuumRaasApiCachingService_raasApiCacheStorage`
   - Protocol: Filesystem read

5. **Sync MySQL metadata**: The Monitoring DB Sync Job swaps temporary tables and writes refreshed monitoring metadata to MySQL.
   - From: `continuumRaasMonitoringService_raasMonDbSyncJob`
   - To: `continuumRaasMetadataMysql`
   - Protocol: SQL

6. **Mirror to PostgreSQL**: The Monitoring DB Sync Job writes mirrored monitoring metadata to PostgreSQL.
   - From: `continuumRaasMonitoringService_raasMonDbSyncJob`
   - To: `continuumRaasMetadataPostgres`
   - Protocol: SQL

### Track B: Health Check Execution

1. **Load cached db and rladmin state**: The Checks Orchestrator reads cached database and rladmin status from the API Cache Storage.
   - From: `continuumRaasChecksRunnerService_raasChecksOrchestrator`
   - To: `continuumRaasApiCachingService_raasApiCacheStorage`
   - Protocol: Filesystem read

2. **Execute health check plugins**: The Checks Orchestrator forks and executes Nagios check plugins against the loaded cluster state.
   - From: `continuumRaasChecksRunnerService_raasChecksOrchestrator`
   - To: `continuumRaasChecksRunnerService_raasCheckPlugins`
   - Protocol: Process fork (exec)

3. **Publish check results**: Check outcomes (pass/fail/warning) are published to the metrics stack.
   - From: `continuumRaasChecksRunnerService`
   - To: `metricsStack`
   - Protocol: Metrics push

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Stale or missing filesystem cache | Monitoring jobs and Checks Orchestrator operate on outdated state | Monitor configs and check results reflect last-known-good snapshot |
| MySQL table-swap failure | DB Sync Job aborts; temporary table left in place | MySQL retains previous metadata; next job run retries |
| PostgreSQL connection failure | DB Sync Job logs error and continues | PostgreSQL mirror is stale; MySQL remains authoritative |
| Nagios check plugin failure | Checks Orchestrator records check failure; publishes failure metric | Alert triggers based on failure threshold configuration |

## Sequence Diagram

```
Scheduler -> continuumRaasMonitoringService  : Trigger monitoring updater jobs
continuumRaasMonitoringService -> continuumRaasApiCachingService : Read cached telemetry
continuumRaasMonitoringService -> continuumRaasApiCachingService : Read rladmin snapshot aggregates
continuumRaasMonitoringService -> continuumRaasMetadataMysql     : Write refreshed monitoring metadata
continuumRaasMonitoringService -> continuumRaasMetadataPostgres  : Mirror monitoring metadata

Scheduler -> continuumRaasChecksRunnerService : Trigger health checks
continuumRaasChecksRunnerService -> continuumRaasApiCachingService : Load cached db and rladmin state
continuumRaasChecksRunnerService -> CheckPlugins                   : Fork and execute Nagios checks
CheckPlugins --> continuumRaasChecksRunnerService                  : Return check results
continuumRaasChecksRunnerService -> metricsStack                   : Publish check metrics
```

## Related

- Architecture dynamic view: `dynamic-raas-telemetry-flow`
- Related flows: [Redis Cluster Metadata Sync](redis-cluster-metadata-sync.md)
