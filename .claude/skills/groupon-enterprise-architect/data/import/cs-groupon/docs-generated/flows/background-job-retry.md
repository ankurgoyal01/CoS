---
service: "cs-groupon"
title: "Background Job Retry"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "background-job-retry"
flow_type: asynchronous
trigger: "A Resque job raises an unhandled exception during execution"
participants:
  - "continuumCsBackgroundJobs"
  - "continuumCsRedisCache"
  - "loggingStack"
  - "metricsStack"
architecture_ref: "dynamic-cs-groupon"
---

# Background Job Retry

## Summary

cyclops uses Resque (v1.27.4) backed by Redis for all background job processing. When a job fails due to an unhandled exception, Resque automatically retries the job up to a configured maximum attempt count with backoff. If all retries are exhausted, the job is moved to the Resque `:failed` queue for manual inspection and replay. This flow is critical for GDPR erasure jobs, where permanent failure risks SLA breach.

## Trigger

- **Type**: event
- **Source**: A `csJobWorkers` Resque worker raises an exception while processing a queued job
- **Frequency**: On demand (triggered by job failures; frequency depends on error rate)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| CS Background Jobs | Hosts Resque workers that execute jobs and handle retry logic | `continuumCsBackgroundJobs` |
| CS Redis Cache | Backs Resque job queues and `:failed` queue storage | `continuumCsRedisCache` |
| Logging Stack | Receives error logs from failed job attempts | `loggingStack` |
| Metrics Stack | Receives failure count and queue depth metrics | `metricsStack` |

## Steps

1. **Worker dequeues job**: A `csJobWorkers` Resque worker picks up a job payload from the Redis-backed queue.
   - From: `continuumCsRedisCache` (Resque queue)
   - To: `continuumCsBackgroundJobs` (worker process)
   - Protocol: Redis LPOP (Resque)

2. **Job execution fails**: Worker encounters an unhandled exception during job processing.
   - From: `continuumCsBackgroundJobs` (job code)
   - To: Resque worker runtime
   - Protocol: Ruby exception

3. **Error logged**: Resque captures the exception and sends error details to `loggingStack`.
   - From: `continuumCsBackgroundJobs`
   - To: `loggingStack`
   - Protocol: Internal logging

4. **Failure metric recorded**: Job failure counter incremented in `metricsStack`.
   - From: `continuumCsBackgroundJobs`
   - To: `metricsStack`
   - Protocol: Internal (sonoma-metrics)

5. **Retry enqueued**: Resque re-enqueues the job with a retry delay (exponential backoff if resque-retry plugin is active).
   - From: Resque worker runtime
   - To: `continuumCsRedisCache` (retry queue)
   - Protocol: Redis RPUSH (Resque)

6. **Worker retries job**: On next dequeue cycle, a worker picks up the retried job payload.
   - From: `continuumCsRedisCache`
   - To: `continuumCsBackgroundJobs`
   - Protocol: Redis LPOP (Resque)

7. **Retry succeeds or exhausts**: If the retry succeeds, the job completes normally. If all retries are exhausted, the job is written to the Resque `:failed` queue.
   - From: `continuumCsBackgroundJobs`
   - To: `continuumCsRedisCache` (`:failed` queue on exhaustion)
   - Protocol: Redis (Resque failure backend)

8. **Manual intervention for failed jobs**: GSO Engineering inspects the `:failed` queue via the Resque web UI and replays or discards failed jobs.
   - From: GSO Engineering operator
   - To: `continuumCsBackgroundJobs` (via Resque web UI)
   - Protocol: HTTP (Resque web interface)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Transient downstream error (e.g., DB timeout) | Retry with backoff; often resolves on retry | Job completes on a later attempt |
| Persistent downstream unavailability | All retries exhausted; job lands in `:failed` queue | Manual replay required once dependency recovers |
| GDPR erasure job permanently failed | Alert raised via `metricsStack` failure count | GDPR SLA at risk; immediate escalation to GSO Engineering required |
| Redis unavailable | Resque cannot enqueue retries; workers stall | All job processing halted; Redis recovery required |

## Sequence Diagram

```
continuumCsRedisCache -> continuumCsBackgroundJobs: Dequeue job
continuumCsBackgroundJobs -> continuumCsBackgroundJobs: Execute job (raises exception)
continuumCsBackgroundJobs -> loggingStack: Log failure details
continuumCsBackgroundJobs -> metricsStack: Increment failure counter
continuumCsBackgroundJobs -> continuumCsRedisCache: Re-enqueue job (retry)
continuumCsRedisCache -> continuumCsBackgroundJobs: Dequeue retried job
continuumCsBackgroundJobs -> continuumCsBackgroundJobs: Execute job (success OR final failure)
continuumCsBackgroundJobs -> continuumCsRedisCache: Write to :failed queue (if exhausted)
operator -> continuumCsBackgroundJobs: Manual replay via Resque web UI
```

## Related

- Architecture dynamic view: `dynamic-cs-groupon`
- Related flows: [Async Event Consumption](async-event-consumption.md), [Scheduled Cron Jobs](scheduled-cron-jobs.md), [Bulk Data Export](bulk-data-export.md)
- Runbook guidance: [Runbook](../runbook.md)
