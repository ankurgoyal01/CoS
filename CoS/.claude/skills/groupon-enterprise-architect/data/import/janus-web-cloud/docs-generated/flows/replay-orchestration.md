---
service: "janus-web-cloud"
title: "Replay Orchestration Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "replay-orchestration"
flow_type: scheduled
trigger: "API call to POST /replay/ to submit a replay request; Quartz scheduler drives job execution"
participants:
  - "jwc_apiResources"
  - "jwc_replayOrchestration"
  - "jwc_mysqlDaos"
  - "janusOperationalSchema"
  - "quartzSchedulerTables"
  - "jwc_integrationAdapters"
architecture_ref: "dynamic-replay-orchestration"
---

# Replay Orchestration Flow

## Summary

The Replay Orchestration flow enables operators to re-process historical Janus event data by submitting a replay request that specifies a source, time range, and target destination. The service accepts the request via REST, persists it to MySQL, splits it into manageable job chunks, and schedules each chunk as a Quartz job. Quartz executes the jobs asynchronously against the configured data source. The operator can poll job status via the `/replay/{id}` endpoint throughout processing.

## Trigger

- **Type**: api-call (submission) + schedule (execution)
- **Source**: Operator or internal tool calls `POST /replay/`; Quartz scheduler drives job execution from `quartzSchedulerTables`
- **Frequency**: On demand (submission); per Quartz trigger schedule (execution)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Resources | Receives replay submission and status query requests; routes to Replay Orchestration | `jwc_apiResources` |
| Replay Orchestration | Validates, splits, persists, and schedules replay jobs; tracks job lifecycle | `jwc_replayOrchestration` |
| MySQL DAOs | Persists replay requests, job splits, and status updates | `jwc_mysqlDaos` |
| Janus Operational Schema | Stores replay request entities, job records, and status fields | `janusOperationalSchema` |
| Quartz Scheduler Tables | Holds persistent Quartz trigger records for scheduled replay job execution | `quartzSchedulerTables` |
| Integration Adapters | Interfaces with GDOOP resource manager (stubbed) for cluster execution coordination | `jwc_integrationAdapters` |

## Steps

1. **Receive replay request**: An operator submits a replay request via `POST /replay/` specifying source, time range, and configuration parameters. API Resources receives and validates the HTTP request.
   - From: External caller
   - To: `jwc_apiResources`
   - Protocol: REST / HTTP

2. **Validate and split replay request**: Replay Orchestration validates the request parameters (source existence, time range sanity) and splits the replay window into smaller job chunks suitable for parallel execution.
   - From: `jwc_apiResources`
   - To: `jwc_replayOrchestration`
   - Protocol: Direct (in-process)

3. **Persist replay request and job records**: MySQL DAOs write the parent replay request and each job chunk record to `janusOperationalSchema`, setting initial status to `PENDING`.
   - From: `jwc_replayOrchestration`
   - To: `jwc_mysqlDaos` -> `janusOperationalSchema`
   - Protocol: Direct / JDBC

4. **Schedule Quartz jobs**: Replay Orchestration registers a Quartz trigger for each job chunk, persisting trigger state to `quartzSchedulerTables`.
   - From: `jwc_replayOrchestration`
   - To: `quartzSchedulerTables` (via Quartz API)
   - Protocol: Direct / JDBC

5. **Return acceptance response**: API Resources returns a `202 Accepted` response to the caller with the replay request ID for subsequent status polling.
   - From: `jwc_apiResources`
   - To: External caller
   - Protocol: REST / HTTP

6. **Quartz fires job execution**: Quartz scheduler reads a trigger from `quartzSchedulerTables` and invokes the replay job processor for each chunk.
   - From: `quartzSchedulerTables`
   - To: `jwc_replayOrchestration`
   - Protocol: Direct (in-process Quartz callback)

7. **Execute replay job chunk**: Replay Orchestration coordinates with Integration Adapters to execute the replay chunk against the data source (GDOOP resource manager / cluster).
   - From: `jwc_replayOrchestration`
   - To: `jwc_integrationAdapters`
   - Protocol: Direct (in-process); SSH via sshj 0.15.0 for GDOOP resource manager (stubbed)

8. **Update job status**: MySQL DAOs write the job outcome (COMPLETED, FAILED) and any metrics back to `janusOperationalSchema`.
   - From: `jwc_replayOrchestration`
   - To: `jwc_mysqlDaos` -> `janusOperationalSchema`
   - Protocol: Direct / JDBC

9. **Operator polls status**: The operator calls `GET /replay/{id}` at any point to retrieve the current status of the replay request and its constituent jobs.
   - From: External caller
   - To: `jwc_apiResources` -> `jwc_replayOrchestration` -> `jwc_mysqlDaos` -> `janusOperationalSchema`
   - Protocol: REST / HTTP / JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid replay parameters | Validation error returned at submission time | `400 Bad Request` returned; no job records created |
| MySQL write failure during job creation | Exception propagated; transaction rolled back | Replay request not persisted; caller receives error response |
| Quartz misfire (job not executed on schedule) | Quartz misfire policy (defined in scheduler config) | Job rescheduled or retried per misfire instruction |
| Job chunk execution failure | Exception caught in replay processor; status written as FAILED | Job marked FAILED in `janusOperationalSchema`; other chunks continue; operator can inspect via `/replay/{id}` |
| GDOOP resource manager unreachable | Exception from Integration Adapters | Job chunk fails; status set to FAILED; retry depends on Quartz misfire policy |

## Sequence Diagram

```
Operator -> jwc_apiResources: POST /replay/ (source, time range, config)
jwc_apiResources -> jwc_replayOrchestration: Validate and split replay request
jwc_replayOrchestration -> jwc_mysqlDaos: Persist replay request + job chunks (PENDING)
jwc_mysqlDaos -> janusOperationalSchema: INSERT replay_request, replay_jobs
jwc_replayOrchestration -> quartzSchedulerTables: Register Quartz triggers for each job chunk
jwc_apiResources --> Operator: 202 Accepted (replayId)
...async...
quartzSchedulerTables -> jwc_replayOrchestration: Quartz fires job execution
jwc_replayOrchestration -> jwc_integrationAdapters: Execute replay chunk (GDOOP resource manager)
jwc_integrationAdapters --> jwc_replayOrchestration: Execution result
jwc_replayOrchestration -> jwc_mysqlDaos: Update job status (COMPLETED / FAILED)
jwc_mysqlDaos -> janusOperationalSchema: UPDATE replay_job status
...polling...
Operator -> jwc_apiResources: GET /replay/{id}
jwc_apiResources -> jwc_mysqlDaos: Load replay request + job statuses
jwc_mysqlDaos -> janusOperationalSchema: SELECT replay status
janusOperationalSchema --> jwc_apiResources: Status data
jwc_apiResources --> Operator: Replay status response
```

## Related

- Architecture dynamic view: `dynamic-replay-orchestration`
- Related flows: [Metadata Management](metadata-management.md) (source/event metadata referenced in replay config)
- See [API Surface](../api-surface.md) for `/replay/*` endpoint details
- See [Data Stores](../data-stores.md) for `quartzSchedulerTables` and `janusOperationalSchema` details
