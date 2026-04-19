---
service: "clo-service"
title: "Scheduled Health Reporting"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "scheduled-health-reporting"
flow_type: scheduled
trigger: "sidekiq-scheduler recurring job (cron)"
participants:
  - "continuumCloServiceWorker"
  - "cloWorkerSchedulers"
  - "cloWorkerAsyncJobs"
  - "continuumCloServicePostgres"
  - "continuumCloServiceRedis"
  - "messageBus"
architecture_ref: "components-clo-service-worker"
---

# Scheduled Health Reporting

## Summary

CLO Service runs a set of recurring background jobs via sidekiq-scheduler to generate and publish health and status reports. These jobs query CLO domain data, aggregate metrics, and publish status updates to Message Bus or internal monitoring endpoints. This flow supports operational visibility, partner reporting obligations, and internal SLA tracking.

## Trigger

- **Type**: schedule
- **Source**: `cloWorkerSchedulers` component using sidekiq-scheduler cron configuration (`config/schedule.yml`)
- **Frequency**: Periodic (specific intervals defined in sidekiq-scheduler config; not enumerated in architecture inventory)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| CLO Service Worker | Hosts the scheduler and executes reporting jobs | `continuumCloServiceWorker` |
| Schedulers | Triggers recurring job execution on cron schedule | `cloWorkerSchedulers` |
| Async Job Processors | Executes the health and reporting job logic | `cloWorkerAsyncJobs` |
| CLO Service PostgreSQL | Source of aggregated CLO domain data for reports | `continuumCloServicePostgres` |
| CLO Service Redis | Provides Sidekiq queue health data | `continuumCloServiceRedis` |
| Message Bus | Receives published health/status events if applicable | `messageBus` |

## Steps

1. **Scheduler triggers job**: `cloWorkerSchedulers` fires a recurring job based on the cron schedule in `config/schedule.yml`.
   - From: `cloWorkerSchedulers` (sidekiq-scheduler)
   - To: `cloWorkerAsyncJobs`
   - Protocol: Sidekiq job enqueue

2. **Queries CLO domain metrics**: `cloWorkerAsyncJobs` queries `continuumCloServicePostgres` for relevant metrics: pending claim counts, enrollment counts, statement credit statuses, and error rates.
   - From: `cloWorkerAsyncJobs`
   - To: `continuumCloServicePostgres`
   - Protocol: ActiveRecord / SQL

3. **Inspects queue health**: `cloWorkerAsyncJobs` reads Sidekiq queue depth and dead job counts from `continuumCloServiceRedis`.
   - From: `cloWorkerAsyncJobs`
   - To: `continuumCloServiceRedis`
   - Protocol: Redis

4. **Aggregates report data**: `cloWorkerAsyncJobs` compiles the queried data into a health or status report payload.
   - From: `cloWorkerAsyncJobs`
   - To: (internal computation)
   - Protocol: Direct

5. **Publishes or stores report**: `cloWorkerAsyncJobs` either publishes the report to Message Bus, writes it to `continuumCloServicePostgres`, or pushes it to an external monitoring endpoint.
   - From: `cloWorkerAsyncJobs`
   - To: `messageBus` and/or `continuumCloServicePostgres`
   - Protocol: Message Bus / ActiveRecord / SQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Database query failure | Sidekiq retry with backoff | Report delayed; no data loss |
| Redis connection failure | Sidekiq retry | Queue health data unavailable for this cycle |
| Message Bus publish failure | Sidekiq retry | Report delivery delayed; eventually delivered |
| Scheduler does not fire | sidekiq-scheduler self-healing on worker restart | Gap in reporting; detected by monitoring |

## Sequence Diagram

```
cloWorkerSchedulers -> cloWorkerAsyncJobs: enqueue health report job (cron)
cloWorkerAsyncJobs -> continuumCloServicePostgres: query claim / enrollment metrics
continuumCloServicePostgres --> cloWorkerAsyncJobs: metric results
cloWorkerAsyncJobs -> continuumCloServiceRedis: read Sidekiq queue health
continuumCloServiceRedis --> cloWorkerAsyncJobs: queue stats
cloWorkerAsyncJobs -> messageBus: publish health/status report event
```

## Related

- Architecture dynamic view: `components-clo-service-worker`
- Related flows: [Claim Processing and Statement Credit](claim-processing-statement-credit.md), [Card Network File Transfer and Settlement](card-network-file-transfer-settlement.md)
