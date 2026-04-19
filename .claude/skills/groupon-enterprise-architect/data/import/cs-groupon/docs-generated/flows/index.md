---
service: "cs-groupon"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 7
---

# Flows

Process and flow documentation for cyclops (cs-groupon).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Customer Issue Resolution](customer-issue-resolution.md) | synchronous | CS agent action in Web App | Agent looks up order/user, diagnoses issue, applies resolution (refund/voucher/email) |
| [Async Event Consumption](async-event-consumption.md) | event-driven | Message Bus event received | Background job consumes user update or GDPR erasure event from MBus |
| [Scheduled Cron Jobs](scheduled-cron-jobs.md) | scheduled | Cron schedule | Periodic maintenance tasks run by `csCronTasks` (cleanup, sync, reporting) |
| [Web UI Session Management](web-ui-session-management.md) | synchronous | CS agent login/logout | Warden authenticates agent, creates session in Redis, authorizes via CanCan |
| [Search and Filter Workflow](search-and-filter-workflow.md) | synchronous | CS agent search query | Agent submits fuzzy search; Elasticsearch returns results; agent filters and selects record |
| [Background Job Retry](background-job-retry.md) | asynchronous | Resque job failure | Failed Resque job is retried with backoff; permanently failed jobs land in `:failed` queue |
| [Bulk Data Export](bulk-data-export.md) | batch | CS agent or scheduled trigger | Large CS dataset is exported asynchronously via background job and delivered to agent |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

- **Customer Issue Resolution** spans `continuumCsWebApp`, `continuumOrdersService`, `continuumUsersService`, `continuumDealCatalogService`, `continuumInventoryService`, `continuumEmailService`, and `continuumVoucherInventoryService`. See [Architecture Context](../architecture-context.md) for relationship details.
- **Async Event Consumption** spans `continuumCsBackgroundJobs` and `messageBus`. The GDPR erasure sub-flow also writes to `continuumCsAppDb` and calls `continuumRegulatoryConsentLogApi`. See [Events](../events.md) for topic details.
- **Bulk Data Export** may involve `continuumCsBackgroundJobs` calling `continuumEmailService` to deliver export results. See [Integrations](../integrations.md).
