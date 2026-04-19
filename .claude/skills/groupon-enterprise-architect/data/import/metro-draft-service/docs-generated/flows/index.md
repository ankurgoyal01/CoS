---
service: "metro-draft-service"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for Metro Draft Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Merchant Deal Draft Creation](merchant-deal-draft-creation.md) | synchronous | API call — POST /api/deals | A merchant deal draft is created, validated, enriched with pricing defaults, and persisted |
| [Deal Publishing Orchestration](deal-publishing-orchestration.md) | synchronous | API call — POST /api/deals/{id}/publish | A validated draft deal is published to DMAPI, MDS, Deal Catalog, with inventory reservation |
| [Dynamic Pricing and Structure Generation](dynamic-pricing-and-structure-generation.md) | synchronous | Internal call during deal creation or product update | Dynamic PDS defaults and fine print are generated using taxonomy, geo, and Infer PDS data |
| [Deal Change Tracking and Approvals](deal-change-tracking-and-approvals.md) | synchronous | API call — POST/PUT /api/mcm/* | Merchandising changes to live deals are submitted, logged, and routed for approval |
| [Deal Score Batch Calculation](deal-score-batch-calculation.md) | scheduled | Quartz scheduler (Deal Score Calculator Job) | Deal scores are computed from deal data and persisted; results synced to Salesforce |
| [Signed Deal Event Consumption](signed-deal-event-consumption.md) | event-driven | MBus event — signed-deal-event on continuumMetroDraftMessageBus | Signed deal events trigger downstream deal orchestration workflow |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 1 |
| Internal (synchronous, called within other flows) | 1 |

## Cross-Service Flows

- **Deal Publishing Orchestration** spans `continuumMetroDraftService`, `continuumDealManagementService`, `continuumMarketingDealService`, `continuumDealCatalogService`, and `continuumVoucherInventoryService`. See architecture dynamic view: `dynamic-continuum-metro-draft-continuumMetroDraftService_dealService-deal-creation`
- **Deal Score Batch Calculation** spans `continuumMetroDraftService` and `salesForce`. See architecture dynamic view: `dynamic-continuum-metro-draft-continuumMetroDraftService_dealService-deal-scoring`
