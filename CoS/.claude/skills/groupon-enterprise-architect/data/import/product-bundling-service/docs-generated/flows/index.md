---
service: "product-bundling-service"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Product Bundling Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Create Bundle](create-bundle.md) | synchronous | API call `POST /v1/bundles/{dealUuid}/{bundleType}` | Validates, persists, and synchronizes a new bundle set with Deal Catalog |
| [Delete Bundle](delete-bundle.md) | synchronous | API call `DELETE /v1/bundles/{dealUuid}/{bundleType}` | Removes bundle records and deletes the Deal Catalog bundle node |
| [Recommendations Refresh](recommendations-refresh.md) | scheduled | Quartz cron trigger (daily, per recommendation type) | Reads HDFS input, scores via Flux, publishes recommendation events to Kafka |
| [Warranty Refresh](warranty-refresh.md) | scheduled | Quartz cron trigger (daily) | Scans eligible deals, queries inventory services, creates warranty bundles |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

- **Create Bundle** and **Delete Bundle** span `continuumProductBundlingService` and `continuumDealCatalogService`. See architecture dynamic view `dynamic-pbs-create-bundle`.
- **Recommendations Refresh** spans `continuumProductBundlingService`, Flux API, HDFS (Cerebro + Gdoop), and Watson KV Kafka. See architecture dynamic view `dynamic-pbs-recommendations-refresh`.
- **Warranty Refresh** spans `continuumProductBundlingService`, `continuumDealCatalogService`, `continuumVoucherInventoryService`, and `continuumGoodsInventoryService`.
