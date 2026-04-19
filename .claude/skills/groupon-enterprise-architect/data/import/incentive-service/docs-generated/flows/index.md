---
service: "incentive-service"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for the Incentive Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Promo Code Validation](promo-code-validation.md) | synchronous | API call — `GET /incentives/validate` | Validates a promo code for a user and deal context at checkout, checking eligibility, prior redemptions, and pricing rules |
| [Audience Qualification](audience-qualification.md) | batch | API call — `POST /audience/qualify` | Sweeps campaign audience by evaluating qualification rules for each user, writing results to Cassandra, and publishing a completion event |
| [Incentive Redemption](incentive-redemption.md) | event-driven | MBus event — `order.confirmed` | Processes order confirmation to mark promo code redemption, update quota counters, and publish a redemption event |
| [Bulk Data Export](bulk-data-export.md) | batch | API call — `POST /bulk-export/start` | Exports all redemption and qualification records for a date range as a CSV file, with async job status polling |
| [Campaign Approval Workflow](campaign-approval-workflow.md) | synchronous | API call — `POST /admin/campaigns/:id/approve` | Admin-driven workflow to approve and activate a campaign, updating state in PostgreSQL and notifying downstream services |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

The following flows span multiple Continuum services and are referenced in the central architecture model:

- **Promo Code Validation** — spans `continuumIncentiveService`, `continuumPricingService`, `continuumDealCatalogService`, `continuumIncentivePostgres`, `continuumIncentiveCassandra`. Architecture dynamic view: `dynamic-incentive-request-flow`
- **Incentive Redemption** — spans `continuumIncentiveService`, `continuumIncentiveCassandra`, `continuumIncentivePostgres`, `continuumKafkaBroker`, `messageBus`
- **Audience Qualification** — spans `continuumIncentiveService`, `extBigtableInstance_0f21`, `continuumIncentiveCassandra`, `continuumKafkaBroker`, `messageBus`
- **Campaign Approval Workflow** — spans `continuumIncentiveService`, `continuumIncentivePostgres`, `messageBus`, `continuumMessagingService`
