---
service: "ckod-backend-jtier"
title: "Keboola Job Polling"
generated: "2026-03-03"
type: flow
flow_name: "keboola-job-polling"
flow_type: scheduled
trigger: "Worker background scheduled loop"
participants:
  - "continuumCkodBackendJtier"
  - "keboola"
  - "continuumCkodMySql"
architecture_ref: "dynamic-ckod-deployment-tracking-flow"
---

# Keboola Job Polling

## Summary

The worker component of `continuumCkodBackendJtier` periodically polls Keboola's job queue API to collect pipeline run data for all onboarded projects. For each project registered in the `keboola_project` table, the worker fetches newly created jobs and updates the status of non-terminal (in-progress) jobs already stored in MySQL. This is the primary mechanism by which CKOD accumulates Keboola pipeline observability data.

## Trigger

- **Type**: schedule
- **Source**: JTier worker scheduled task (internal timer)
- **Frequency**: Periodic (interval defined by JTier worker configuration; exact cron not exposed in source)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| CKOD Worker (background) | Orchestrates polling; reads project tokens from DB; writes job records | `continuumCkodBackendJtier` |
| Keboola Cloud (job queue) | Source of job run records | `keboola` |
| Keboola Cloud (storage API) | Source of component/pipeline metadata for name resolution | `keboola` |
| CKOD MySQL | Reads project registry and token map; writes job run records | `continuumCkodMySql` |

## Steps

1. **Read project registry**: Reads all active (non-soft-deleted) records from `keboola_project` table, building a map of project IDs to API tokens.
   - From: `continuumCkodBackendJtier` (worker)
   - To: `continuumCkodMySql`
   - Protocol: JDBC/MySQL

2. **Identify non-terminal jobs**: Queries `DataReadDao` for job IDs in non-terminal states across all registered projects, building a `projectNonTerminalJobIdMappings` map.
   - From: `continuumCkodBackendJtier` (worker)
   - To: `continuumCkodMySql`
   - Protocol: JDBC/MySQL

3. **Fetch new jobs from Keboola**: For each project, calls `GET https://queue.groupon.keboola.cloud/search/jobs?branchId[]=null&sortBy=createdTime&sortOrder=asc&limit=25&offset={N}` with the project's API token. Paginates in batches of 25 until no more results are returned.
   - From: `continuumCkodBackendJtier` (worker)
   - To: `keboola`
   - Protocol: HTTPS/REST

4. **Fetch updated status for non-terminal jobs**: Calls `GET https://queue.groupon.keboola.cloud/search/jobs?branchId[]=null&runId[]={id}...` to refresh status of existing in-progress jobs.
   - From: `continuumCkodBackendJtier` (worker)
   - To: `keboola`
   - Protocol: HTTPS/REST

5. **Resolve pipeline names**: For job records with unrecognised component/config combinations, calls `GET https://connection.groupon.keboola.cloud/v2/storage/branch/default/components/{component}/configs/{config}` to look up pipeline names. Falls back to the deleted-configs endpoint if the primary call fails.
   - From: `continuumCkodBackendJtier` (worker)
   - To: `keboola`
   - Protocol: HTTPS/REST

6. **Persist job records**: Writes new and updated job run records to MySQL via `DataWriteDao`. Logs each step before and after execution to assist in debugging.
   - From: `continuumCkodBackendJtier` (worker)
   - To: `continuumCkodMySql`
   - Protocol: JDBC/MySQL

7. **Record metrics**: Marks success/failure counters via `KeboolaRequestMetrics` for each polling call, including batch size histograms for non-terminal job updates.
   - From: `continuumCkodBackendJtier` (worker)
   - To: Wavefront (via JTier metrics pipeline)
   - Protocol: Internal metric emission

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Keboola API returns non-2xx | `IOException` thrown; `markFailedJobsRequestEvent()` called | Current polling cycle aborted for affected project; retried on next scheduled run |
| Pipeline name resolution fails (primary) | Falls back to `?isDeleted=true` query | Deleted pipeline name resolved if available |
| Pipeline name resolution fails (both) | `IOException` propagated | Worker logs error; step skipped for this component/config |
| MySQL write failure | Exception propagated | Current polling cycle step fails; logged via Steno |

## Sequence Diagram

```
Worker -> continuumCkodMySql: Read keboola_project records (tokens)
Worker -> continuumCkodMySql: Read non-terminal job IDs
Worker -> keboola (queue): GET /search/jobs (new jobs, per project, paginated)
keboola (queue) --> Worker: KeboolaJobResponseObject[]
Worker -> keboola (queue): GET /search/jobs?runId[]=... (non-terminal updates)
keboola (queue) --> Worker: Updated KeboolaJobResponseObject[]
Worker -> keboola (storage): GET /v2/storage/branch/default/components/{comp}/configs/{cfg}
keboola (storage) --> Worker: KeboolaPipelineModel
Worker -> continuumCkodMySql: Write new and updated job records
```

## Related

- Architecture dynamic view: `dynamic-ckod-deployment-tracking-flow`
- Related flows: [Deployment Tracking — Keboola](deployment-tracking-keboola.md)
