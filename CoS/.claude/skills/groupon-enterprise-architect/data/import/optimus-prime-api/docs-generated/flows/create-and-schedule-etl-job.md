---
service: "optimus-prime-api"
title: "Create and Schedule ETL Job"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "create-and-schedule-etl-job"
flow_type: synchronous
trigger: "HTTP POST /v2/users/{username}/jobs"
participants:
  - "apiEndpoints"
  - "orchestrationEngine"
  - "opApi_persistenceLayer"
  - "continuumOptimusPrimeApiDb"
architecture_ref: "dynamic-job-run-orchestration"
---

# Create and Schedule ETL Job

## Summary

This flow handles a request from a data engineer or API consumer to define a new ETL job. The service validates the job definition, persists it to PostgreSQL, and registers a Quartz Scheduler trigger so the job will fire on its configured cron schedule. The flow is synchronous — a success response is returned once the job is persisted and the trigger is registered.

## Trigger

- **Type**: api-call
- **Source**: Data engineer or internal tool sending `POST /v2/users/{username}/jobs`
- **Frequency**: on-demand (whenever a new ETL job is created)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Endpoints | Receives HTTP request; delegates to orchestration | `apiEndpoints` |
| Orchestration Engine | Validates job definition and coordinates persistence and scheduling | `orchestrationEngine` |
| Persistence Layer | Persists job definition to PostgreSQL | `opApi_persistenceLayer` |
| Optimus Prime Postgres DB | Stores the new job record | `continuumOptimusPrimeApiDb` |

## Steps

1. **Receives job creation request**: API consumer sends `POST /v2/users/{username}/jobs` with a job definition payload (schedule cron, NiFi template reference, source/target configuration).
   - From: API consumer
   - To: `apiEndpoints`
   - Protocol: REST / HTTP

2. **Delegates to orchestration**: `apiEndpoints` routes the request to `orchestrationEngine`.
   - From: `apiEndpoints`
   - To: `orchestrationEngine`
   - Protocol: direct (in-process)

3. **Validates job definition**: `orchestrationEngine` validates the cron expression (via Cron-Utils), checks that the referenced connection IDs exist, and confirms the user has permission to create jobs.
   - From: `orchestrationEngine`
   - To: `opApi_persistenceLayer` (for connection/user lookup)
   - Protocol: direct (in-process)

4. **Persists job definition**: `opApi_persistenceLayer` writes the new job record to the `jobs` table in `continuumOptimusPrimeApiDb`.
   - From: `opApi_persistenceLayer`
   - To: `continuumOptimusPrimeApiDb`
   - Protocol: JDBC/SQL

5. **Registers Quartz trigger**: `orchestrationEngine` registers a new Quartz trigger for the job's cron schedule so future runs will fire automatically.
   - From: `orchestrationEngine`
   - To: Quartz Scheduler (in-process)
   - Protocol: direct (in-process)

6. **Returns success response**: `apiEndpoints` returns the created job resource (HTTP 201) to the caller.
   - From: `apiEndpoints`
   - To: API consumer
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid cron expression | Cron-Utils validation fails in `orchestrationEngine` | HTTP 400 returned; job not persisted |
| Referenced connection not found | `opApi_persistenceLayer` lookup fails | HTTP 422 or 400 returned; job not persisted |
| PostgreSQL unavailable | JDBI throws exception; `orchestrationEngine` propagates | HTTP 500 returned; no Quartz trigger registered |
| Quartz trigger registration failure | `orchestrationEngine` catches exception | Job is persisted but not scheduled; manual re-registration required |

## Sequence Diagram

```
APIConsumer -> apiEndpoints: POST /v2/users/{username}/jobs
apiEndpoints -> orchestrationEngine: createJob(definition)
orchestrationEngine -> opApi_persistenceLayer: lookupConnections(ids)
opApi_persistenceLayer -> continuumOptimusPrimeApiDb: SELECT connections
continuumOptimusPrimeApiDb --> opApi_persistenceLayer: connection records
orchestrationEngine -> opApi_persistenceLayer: persistJob(definition)
opApi_persistenceLayer -> continuumOptimusPrimeApiDb: INSERT INTO jobs
continuumOptimusPrimeApiDb --> opApi_persistenceLayer: job id
orchestrationEngine -> QuartzScheduler: registerTrigger(jobId, cronExpr)
QuartzScheduler --> orchestrationEngine: trigger registered
orchestrationEngine --> apiEndpoints: created job
apiEndpoints --> APIConsumer: HTTP 201 Created
```

## Related

- Architecture dynamic view: `dynamic-job-run-orchestration`
- Related flows: [Execute ETL Job via NiFi](execute-etl-job-via-nifi.md)
