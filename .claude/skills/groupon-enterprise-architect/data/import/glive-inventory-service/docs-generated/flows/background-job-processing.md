---
service: "glive-inventory-service"
title: "Background Job Processing"
generated: "2026-03-03"
type: flow
flow_name: "background-job-processing"
flow_type: asynchronous
trigger: "Jobs enqueued by API controllers or scheduled triggers into Resque/ActiveJob queues"
participants:
  - "continuumGliveInventoryService_httpApi"
  - "continuumGliveInventoryService_backgroundJobs"
  - "continuumGliveInventoryWorkers_jobsRunner"
  - "continuumGliveInventoryWorkers_externalClients"
  - "continuumGliveInventoryService_domainServices"
  - "continuumGliveInventoryService_externalClients"
  - "continuumGliveInventoryDb"
  - "continuumGliveInventoryRedis"
  - "messageBus"
architecture_ref: "dynamic-background-job-processing"
---

# Background Job Processing

## Summary

GLive Inventory Service uses Resque/ActiveJob workers to offload long-running, failure-prone, and scheduled operations from the synchronous API tier. The worker tier (`continuumGliveInventoryWorkers`) pulls jobs from Redis-backed Resque queues and executes them using the same codebase and shared components (domain services, external clients, ORM) as the main service. Key background operations include third-party ticketing integration flows (purchase confirmation, inventory sync), cache refresh cycles, GDPR compliance processing, merchant payment report generation, and inventory update propagation. This design decouples API response time from third-party provider latency and enables retry logic for transient failures.

## Trigger

- **Type**: Event-driven (job enqueue) and scheduled
- **Source**: API controllers enqueue jobs during request processing; scheduled jobs triggered by cron-like configuration or periodic Resque schedulers
- **Frequency**: Continuous -- workers process jobs as fast as they are enqueued; scheduled jobs run on configured intervals

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| HTTP API Controllers | Enqueue jobs during request handling for async processing | `continuumGliveInventoryService_httpApi` |
| Background Job Definitions | Define job classes (what to execute, queue name, retry policy) | `continuumGliveInventoryService_backgroundJobs` |
| Background Job Runners | Resque worker processes that dequeue and execute jobs | `continuumGliveInventoryWorkers_jobsRunner` |
| External Clients (Workers) | Shared HTTP clients for calling external services from workers | `continuumGliveInventoryWorkers_externalClients` |
| Domain & Application Services | Business logic invoked by background jobs | `continuumGliveInventoryService_domainServices` |
| External Service Clients | HTTP clients for third-party providers and internal services | `continuumGliveInventoryService_externalClients` |
| GLive Inventory DB | Persistence for job side-effects | `continuumGliveInventoryDb` |
| GLive Inventory Redis | Job queues, coordination, caching, and locking | `continuumGliveInventoryRedis` |
| MessageBus | Event publishing from background jobs | `messageBus` |

## Steps

1. **Job enqueue**: An API controller (or scheduled trigger) creates a job payload and enqueues it to a named Resque queue in Redis. The job class defines the queue name, parameters, and retry policy.
   - From: `continuumGliveInventoryService_httpApi` (or scheduler)
   - To: `continuumGliveInventoryRedis` (Resque queue)
   - Protocol: Resque/ActiveJob (Redis LPUSH)

2. **Worker polls queue**: A Resque worker process (`continuumGliveInventoryWorkers_jobsRunner`) continuously polls its assigned queue(s) in Redis for pending jobs.
   - From: `continuumGliveInventoryWorkers_jobsRunner`
   - To: `continuumGliveInventoryRedis`
   - Protocol: TCP (Redis BRPOP)

3. **Job deserialization and execution**: The worker deserializes the job payload, instantiates the job class (`continuumGliveInventoryService_backgroundJobs`), and calls its `perform` method.
   - From: `continuumGliveInventoryWorkers_jobsRunner`
   - To: `continuumGliveInventoryService_backgroundJobs`
   - Protocol: in-process

4. **Domain logic execution**: The job invokes domain services and/or external clients to perform the business operation.
   - From: `continuumGliveInventoryService_backgroundJobs`
   - To: `continuumGliveInventoryService_domainServices` / `continuumGliveInventoryService_externalClients`
   - Protocol: in-process / HTTP/JSON

5. **External API calls**: For third-party integration jobs, external clients call Ticketmaster, AXS, Telecharge, or ProVenue APIs. For internal integration jobs, clients call GTX, Accounting, or Mailman services.
   - From: `continuumGliveInventoryService_externalClients`
   - To: `continuumTicketmasterApi` / `continuumAxsApi` / `continuumTelechargePartner` / `continuumProvenuePartner` / `continuumGtxService` / `continuumAccountingService` / `continuumMailmanService`
   - Protocol: HTTP/JSON

6. **Persist results to MySQL**: Job side-effects (order updates, inventory changes, report records, GDPR processing results) are persisted to the relational database.
   - From: `continuumGliveInventoryService_backgroundJobs` / `continuumGliveInventoryService_domainServices`
   - To: `continuumGliveInventoryDb`
   - Protocol: SQL

7. **Update Redis state**: Cache entries updated, locks released, coordination keys adjusted.
   - From: `continuumGliveInventoryService_backgroundJobs`
   - To: `continuumGliveInventoryRedis`
   - Protocol: TCP

8. **Publish events to MessageBus**: If the job resulted in an inventory or availability change, an event is published to MessageBus.
   - From: `continuumGliveInventoryWorkers`
   - To: `messageBus`
   - Protocol: STOMP/JMS

9. **Job completion**: Worker marks the job as complete and returns to polling the queue for the next job.
   - From: `continuumGliveInventoryWorkers_jobsRunner`
   - To: `continuumGliveInventoryRedis`
   - Protocol: TCP

### Job Types

The following categories of background jobs are processed:

| Job Category | Examples | Queue | Frequency |
|-------------|---------|-------|-----------|
| Third-party purchase | Purchase confirmation with Ticketmaster/AXS/TC/PV | purchase | On demand (per purchase) |
| Inventory sync | Sync availability from third-party provider | inventory_sync | Scheduled / on demand |
| Cache refresh | Refresh Redis and Varnish caches | cache | Scheduled (periodic) |
| GDPR compliance | Process data deletion/export requests | gdpr | On demand (per GDPR request) |
| Reporting | Generate merchant payment reports | reporting | Scheduled (daily/weekly) |
| Notifications | Send emails via Mailman, publish alerts | notifications | On demand |
| Reservation expiry | Release expired reservations and restore inventory | reservations | Continuous (check on interval) |

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Job execution failure (transient) | Resque retry with exponential backoff (configurable per job class) | Job retried up to max attempts |
| Job execution failure (permanent) | Moved to Resque failed queue after max retries exhausted | Job available in failed queue for manual inspection/retry |
| External provider timeout | Job-level timeout; counted as transient failure; retried | Job retried with backoff |
| MySQL connection failure | Connection pool recovery; job retried | Job retried after connection restored |
| Redis unavailable | Worker cannot dequeue; blocks until Redis recovers | No jobs processed until Redis available; jobs remain in queue |
| Worker process crash | Kubernetes restarts pod; in-flight job may be re-executed | At-least-once processing; jobs should be idempotent |
| MessageBus publish failure | Logged as error; job marked as complete (core side-effects already persisted to MySQL) | Event may be missed; MySQL is source of truth |

## Sequence Diagram

```
APIController -> Redis: LPUSH resque:queue:purchase (job payload)
WorkerRunner -> Redis: BRPOP resque:queue:purchase
Redis --> WorkerRunner: job payload
WorkerRunner -> BackgroundJobs: instantiate + perform()
BackgroundJobs -> DomainServices: execute business logic
DomainServices -> ExternalClients: call third-party provider
ExternalClients -> TicketmasterAPI: POST /orders (or equivalent)
TicketmasterAPI --> ExternalClients: response
ExternalClients --> DomainServices: result
DomainServices -> MySQL: persist side-effects (transaction)
DomainServices -> Redis: update cache, release locks
DomainServices -> MessageBus: publish inventory event
BackgroundJobs --> WorkerRunner: job complete
WorkerRunner -> Redis: poll next job
```

## Related

- Architecture dynamic view: `dynamic-background-job-processing`
- Related flows: [Third-Party Ticket Purchase](third-party-ticket-purchase.md), [Event Reservation Flow](event-reservation-flow.md), [Ticket Inventory Creation](ticket-inventory-creation.md)
