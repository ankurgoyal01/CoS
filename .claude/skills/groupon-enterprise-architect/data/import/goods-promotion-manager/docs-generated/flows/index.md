---
service: "goods-promotion-manager"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Goods Promotion Manager.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Promotion Lifecycle](promotion-lifecycle.md) | synchronous | API call (internal user) | Create, update, lock, submit, and complete a promotion through its four status stages |
| [Deal Eligibility Check](deal-eligibility-check.md) | synchronous | API call (internal user) | Evaluate whether a set of deal permalinks are eligible and pre-qualified for a given promotion, including ILS 50% Rule and Resting Rule checks |
| [Promotion Deal Management](promotion-deal-management.md) | synchronous | API call (internal user) | Associate, update, and remove deals from a promotion |
| [Import Product Job](import-product-job.md) | scheduled / on-demand | Quartz scheduler or manual API trigger | Fetch deal and inventory product data from Deal Management API and persist locally |
| [Promotion CSV Export](promotion-csv-export.md) | synchronous | API call (internal user) | Stream ILS pricing data for one or more promotions as a downloadable CSV file |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 1 |
| On-demand triggered job | 1 |

## Cross-Service Flows

- [Import Product Job](import-product-job.md) spans `continuumGoodsPromotionManagerService` and `continuumDealManagementApi`
- The Update Established Price Job (not fully documented as a separate flow; see [Import Product Job](import-product-job.md) for the pattern) spans `continuumGoodsPromotionManagerService` and `corePricingServiceSystem`
- [Promotion CSV Export](promotion-csv-export.md) triggers the Import Product Job inline, creating an on-demand cross-service sub-flow
