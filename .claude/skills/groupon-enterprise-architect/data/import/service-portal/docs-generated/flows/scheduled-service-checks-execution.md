---
service: "service-portal"
title: "Scheduled Service Checks Execution"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "scheduled-service-checks-execution"
flow_type: scheduled
trigger: "Sidekiq-Cron schedule — recurring check execution job"
participants:
  - "continuumServicePortalWorker"
  - "continuumServicePortalDb"
  - "continuumServicePortalRedis"
  - "Google Chat"
---

# Scheduled Service Checks Execution

## Summary

On a cron schedule managed by sidekiq-cron, the Sidekiq worker process retrieves all registered services from MySQL, evaluates each service against the defined set of governance checks, records pass/fail results per check per service, and sends Google Chat notifications for any newly failing checks. This flow is the core governance enforcement mechanism of Service Portal.

## Trigger

- **Type**: schedule
- **Source**: sidekiq-cron schedule defined in `config/sidekiq.yml`
- **Frequency**: Recurring on a configured cron expression (exact schedule defined in `config/sidekiq.yml`)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| sidekiq-cron | Enqueues the check runner job at the scheduled time | `continuumServicePortalRedis` |
| Sidekiq Worker | Dequeues and executes the check runner job | `continuumServicePortalWorker` |
| MySQL Database | Source of service records and check definitions; target for check results | `continuumServicePortalDb` |
| Google Chat | Receives alert notifications for failing checks | external system |

## Steps

1. **Enqueue check run job**: sidekiq-cron fires at the configured cron interval and enqueues the check runner job into the Sidekiq queue.
   - From: sidekiq-cron (running in `continuumServicePortalWorker`)
   - To: `continuumServicePortalRedis`
   - Protocol: Redis protocol

2. **Dequeue job**: Sidekiq worker thread dequeues the check runner job.
   - From: `continuumServicePortalRedis`
   - To: `continuumServicePortalWorker`
   - Protocol: Redis protocol

3. **Fetch all registered services**: Worker queries `continuumServicePortalDb` to retrieve all active service records.
   - From: `continuumServicePortalWorker`
   - To: `continuumServicePortalDb`
   - Protocol: MySQL (ActiveRecord)

4. **Fetch check definitions**: Worker queries `continuumServicePortalDb` for all defined governance checks.
   - From: `continuumServicePortalWorker`
   - To: `continuumServicePortalDb`
   - Protocol: MySQL (ActiveRecord)

5. **Evaluate checks per service**: For each service, the worker evaluates each check (e.g., required metadata fields present, repository linked, ORR completed, dependency declarations up to date). Each check produces a pass/fail result with an optional message.
   - From: `continuumServicePortalWorker`
   - To: `continuumServicePortalWorker` (internal logic)
   - Protocol: direct

6. **Write check results**: Worker bulk-writes or upserts check result records to the `check_results` table in MySQL.
   - From: `continuumServicePortalWorker`
   - To: `continuumServicePortalDb`
   - Protocol: MySQL (ActiveRecord)

7. **Identify newly failing checks**: Worker compares current results against previous results to identify newly introduced failures.
   - From: `continuumServicePortalWorker`
   - To: `continuumServicePortalDb` (read previous results)
   - Protocol: MySQL (ActiveRecord)

8. **Send Google Chat alerts**: For each newly failing check, the worker sends an alert notification to the owning team's Google Chat space.
   - From: `continuumServicePortalWorker`
   - To: Google Chat
   - Protocol: HTTPS REST via `google-apis-chat_v1`

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MySQL connectivity failure | Sidekiq job raises exception | Job retried by Sidekiq with backoff; check run delayed |
| Individual check evaluation error | Exception caught per check; remaining checks continue | Failed check recorded with error message; other services/checks unaffected |
| Google Chat notification failure | Sidekiq notification job retried | Alert delivery delayed; check results still written to DB |
| Sidekiq worker pod crash during run | Sidekiq marks job as failed; retry on next available worker | Check run partially complete; retried in full on next attempt |

## Sequence Diagram

```
sidekiq-cron -> continuumServicePortalRedis: enqueue CheckRunnerJob
continuumServicePortalRedis -> continuumServicePortalWorker: dequeue CheckRunnerJob
continuumServicePortalWorker -> continuumServicePortalDb: SELECT all active services
continuumServicePortalDb --> continuumServicePortalWorker: service records
continuumServicePortalWorker -> continuumServicePortalDb: SELECT check definitions
continuumServicePortalDb --> continuumServicePortalWorker: check definitions
continuumServicePortalWorker -> continuumServicePortalWorker: evaluate checks per service
continuumServicePortalWorker -> continuumServicePortalDb: UPSERT check_results
continuumServicePortalDb --> continuumServicePortalWorker: results persisted
continuumServicePortalWorker -> Google Chat: POST notification (for each failing check)
Google Chat --> continuumServicePortalWorker: 200 OK
```

## Related

- Architecture dynamic view: `dynamic-scheduled-checks`
- Related flows: [Operational Readiness Review](operational-readiness-review.md), [Service Registration and Metadata Sync](service-registration-and-metadata-sync.md)
