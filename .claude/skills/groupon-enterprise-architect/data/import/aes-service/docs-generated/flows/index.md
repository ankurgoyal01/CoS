---
service: "aes-service"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for the Audience Export Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Scheduled Audience Export](scheduled-audience-export.md) | scheduled | Daily Quartz cron (configurable via `audienceJobCronExpression`) | Materialises audience delta, resolves customer info, and pushes membership updates to all active ad partners |
| [Scheduled Audience Creation](scheduled-audience-creation.md) | synchronous | `POST /api/v1/scheduledAudiences` | Creates a new AES scheduled audience record, registers it with CIA, and schedules the Quartz export job |
| [Published Audience Creation](published-audience-creation.md) | synchronous | `POST /api/v1/publishedAudiences` | Creates a one-time published audience record and triggers an immediate export run |
| [GDPR Customer Erasure](gdpr-customer-erasure.md) | event-driven | MBus erasure topic OR `DELETE /api/v1/utils/erasure/deleteCustomer/{customerId}` | Removes a customer from all AES Postgres tables and requests deletion from every configured ad-platform audience |
| [Audience Pause and Resume](audience-pause-resume.md) | synchronous | `PUT /api/v1/scheduledAudiences/{id}/pause` or `/resume` | Suspends or re-activates a scheduled audience's Quartz trigger and records the lifecycle state change |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

- The **Scheduled Audience Export** flow spans `continuumAudienceExportService`, `continuumCIAService`, `continuumCerebroWarehouse`, `continuumAudienceExportPostgres`, `continuumAudienceExportPostgresS2S`, and all four ad-network targets. The authoritative dynamic view definition is in `architecture/views/dynamics/audience-export-flow.dsl` (currently disabled in federation due to stub-only dependency resolution).
- The **GDPR Customer Erasure** flow spans `continuumAudienceExportService`, `messageBus`, all four ad-network targets, and both Postgres stores.
