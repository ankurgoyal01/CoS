---
service: "mailman"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for Mailman.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Submit Transactional Email](submit-transactional-email.md) | synchronous | HTTP POST to `/mailman/mail` | API-driven submission of a transactional email request, enrichment, and MBus publication |
| [MBus Message Consumption](mbus-message-consumption.md) | event-driven | Message arrives on `MailmanQueue` | Consumes inbound MBus queue message, enriches with domain context, publishes to Rocketman |
| [Manual Retry](manual-retry.md) | synchronous | HTTP POST to `/mailman/retry` | Operator-triggered re-submission of a previously failed email request |
| [Deduplication Check](deduplication-check.md) | synchronous | HTTP POST to `/mailman/duplicate-check` | Checks `mailmanPostgres` to determine whether an equivalent request has already been processed |
| [Scheduled Retry Batch](scheduled-retry-batch.md) | scheduled | Quartz 2.2.1 trigger | Batch re-submission of all pending retry payloads from `mailmanPostgres` |
| [Health Check Actuator](health-check-actuator.md) | synchronous | HTTP GET to `/manage/info` | Returns service health and build metadata via Spring Boot Actuator |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

- **Mail Processing Flow** spans `continuumMailmanService`, `messageBus`, `continuumOrdersService`, `continuumUsersService`, `continuumDealCatalogService`, `continuumRelevanceApi`, `continuumUniversalMerchantApi`, and Rocketman. See architecture dynamic view `dynamic-mail-processing-flow`.
- [Submit Transactional Email](submit-transactional-email.md) and [MBus Message Consumption](mbus-message-consumption.md) both invoke the same workflow engine and outbound context enrichment path.
