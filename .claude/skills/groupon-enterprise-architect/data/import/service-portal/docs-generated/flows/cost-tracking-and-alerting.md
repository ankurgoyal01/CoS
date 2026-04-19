---
service: "service-portal"
title: "Cost Tracking and Alerting"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "cost-tracking-and-alerting"
flow_type: scheduled
trigger: "Sidekiq-Cron schedule — recurring cost tracking job"
participants:
  - "continuumServicePortalWorker"
  - "continuumServicePortalDb"
  - "continuumServicePortalRedis"
  - "Google Chat"
---

# Cost Tracking and Alerting

## Summary

On a recurring cron schedule, the Sidekiq worker process collects cost data for each registered service, evaluates the recorded costs against configured alert thresholds, persists cost records to MySQL, and sends Google Chat alerts for any services that exceed their thresholds. This flow provides engineering leadership and service owners with visibility into per-service cost trends.

## Trigger

- **Type**: schedule
- **Source**: sidekiq-cron schedule defined in `config/sidekiq.yml`
- **Frequency**: Recurring on a configured cron expression (exact schedule defined in `config/sidekiq.yml`)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| sidekiq-cron | Enqueues the cost tracking job at the scheduled interval | `continuumServicePortalRedis` |
| Sidekiq Worker | Dequeues and executes cost collection and threshold evaluation | `continuumServicePortalWorker` |
| MySQL Database | Source of service records and cost thresholds; target for cost records | `continuumServicePortalDb` |
| Google Chat | Receives cost threshold alert notifications | external system |

## Steps

1. **Enqueue cost tracking job**: sidekiq-cron fires at the configured interval and enqueues the cost tracking job.
   - From: sidekiq-cron (running in `continuumServicePortalWorker`)
   - To: `continuumServicePortalRedis`
   - Protocol: Redis protocol

2. **Dequeue job**: Sidekiq worker thread dequeues the cost tracking job.
   - From: `continuumServicePortalRedis`
   - To: `continuumServicePortalWorker`
   - Protocol: Redis protocol

3. **Fetch all registered services with cost configuration**: Worker queries `continuumServicePortalDb` for all services that have cost tracking enabled and their configured alert thresholds.
   - From: `continuumServicePortalWorker`
   - To: `continuumServicePortalDb`
   - Protocol: MySQL (ActiveRecord)

4. **Collect cost data per service**: Worker retrieves or calculates the current cost figures for each service (from internal cost data or metadata).
   - From: `continuumServicePortalWorker`
   - To: `continuumServicePortalDb`
   - Protocol: MySQL (ActiveRecord)

5. **Persist cost records**: Worker writes cost records (amount, period, timestamp) to the `costs` table in MySQL for each evaluated service.
   - From: `continuumServicePortalWorker`
   - To: `continuumServicePortalDb`
   - Protocol: MySQL (ActiveRecord)

6. **Evaluate thresholds**: Worker compares recorded cost amounts against each service's configured threshold. Services exceeding their threshold are flagged for alerting.
   - From: `continuumServicePortalWorker`
   - To: `continuumServicePortalWorker` (internal logic)
   - Protocol: direct

7. **Send Google Chat alerts**: For each service exceeding its cost threshold, the worker sends an alert notification to the owning team's Google Chat space including service name, current cost, and threshold.
   - From: `continuumServicePortalWorker`
   - To: Google Chat
   - Protocol: HTTPS REST via `google-apis-chat_v1`

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MySQL connectivity failure | Sidekiq job raises exception | Job retried with backoff; cost run delayed |
| Individual service cost collection error | Exception caught per service; processing continues for remaining services | Affected service cost record skipped; error logged |
| Google Chat notification failure | Sidekiq notification job retried | Alert delivery delayed; cost data still persisted in DB |
| Sidekiq worker crash mid-run | Job marked failed; Sidekiq retry | Cost run partially complete; full retry on next attempt |

## Sequence Diagram

```
sidekiq-cron -> continuumServicePortalRedis: enqueue CostTrackingJob
continuumServicePortalRedis -> continuumServicePortalWorker: dequeue CostTrackingJob
continuumServicePortalWorker -> continuumServicePortalDb: SELECT services with cost config
continuumServicePortalDb --> continuumServicePortalWorker: service records + thresholds
continuumServicePortalWorker -> continuumServicePortalDb: SELECT/compute cost data per service
continuumServicePortalDb --> continuumServicePortalWorker: cost figures
continuumServicePortalWorker -> continuumServicePortalDb: INSERT costs records
continuumServicePortalDb --> continuumServicePortalWorker: records persisted
continuumServicePortalWorker -> continuumServicePortalWorker: evaluate thresholds
continuumServicePortalWorker -> Google Chat: POST alert notification (for each over-threshold service)
Google Chat --> continuumServicePortalWorker: 200 OK
```

## Related

- Architecture dynamic view: `dynamic-cost-tracking`
- Related flows: [Scheduled Service Checks Execution](scheduled-service-checks-execution.md), [Service Inactivity Report Generation](service-inactivity-report-generation.md)
