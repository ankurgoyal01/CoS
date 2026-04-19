---
service: "deal-management-api"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 8
---

# Flows

Process and flow documentation for Deal Management API (DMAPI).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Deal Create (Sync)](deal-create-sync.md) | synchronous | POST /v1/deals or /v3/deals | Synchronous deal creation: validates, persists to MySQL, calls downstream services inline |
| [Deal Create (Async)](deal-create-async.md) | asynchronous | POST /v2/deals (async path) | Async deal creation: validates, persists, enqueues background job for downstream sync |
| [Deal Publish Workflow](deal-publish-workflow.md) | synchronous | POST /v1/deals/:id/publish | Transitions a deal from draft to published state, triggering catalog and Salesforce sync |
| [Merchant and Place Sync](merchant-place-sync.md) | synchronous | GET /v1/merchants, GET /v1/places | Retrieves merchant and place data from m3 to associate with deal records |
| [Contract Party Management](contract-party-management.md) | synchronous | POST/PUT/DELETE /v2/contract_data_service/contract_parties | Creates, updates, or removes contract parties via Contract Data Service |
| [Deal Approval Workflow](deal-approval-workflow.md) | synchronous | POST /v1/deals/:id/approve | Submits a deal for internal approval and updates deal state |
| [Inventory Product and Pricing Update](inventory-product-pricing-update.md) | synchronous | POST/PUT /v2/inventory_products | Configures or updates inventory products and pricing for a deal |
| [Write Request Tracking](write-request-tracking.md) | synchronous | Any write operation (POST/PUT/DELETE) | Records an audit log entry for every tracked write operation against deal resources |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 7 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The following flows involve multiple Continuum services and can be traced in the central architecture dynamic views:

- [Deal Publish Workflow](deal-publish-workflow.md) — spans `continuumDealManagementApi`, `continuumDealManagementWorker`, `continuumDealCatalogService`, and `salesForce`
- [Deal Create (Async)](deal-create-async.md) — spans `continuumDealManagementApi`, `continuumDealManagementRedis`, and `continuumDealManagementWorker`
- [Inventory Product and Pricing Update](inventory-product-pricing-update.md) — spans `continuumDealManagementApi`, `continuumPricingService`, and inventory services
- [Contract Party Management](contract-party-management.md) — spans `continuumDealManagementApi` and `continuumContractDataService`
