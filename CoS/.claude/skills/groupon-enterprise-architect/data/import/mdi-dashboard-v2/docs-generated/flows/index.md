---
service: "mdi-dashboard-v2"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 7
---

# Flows

Process and flow documentation for Marketing Deal Intelligence Dashboard.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Deal Intelligence Search](deal-intelligence-search.md) | synchronous | User submits search query in the deal browser | User searches for deals; dashboard queries Marketing Deal Service and returns results |
| [Deal Cluster Analytics](deal-cluster-analytics.md) | synchronous | User navigates to the clusters view | Dashboard fetches deal clustering data from the Deals Cluster API and renders analytics |
| [Merchant Insights](merchant-insights.md) | synchronous | User navigates to the merchant insights view | Dashboard aggregates merchant performance data from Marketing Deal Service and Salesforce |
| [API Key Management](api-key-management.md) | synchronous | User creates, lists, or revokes an API key | Dashboard performs CRUD operations on API keys persisted in PostgreSQL |
| [Feed Creation and Generation](feed-creation-generation.md) | synchronous | User creates a feed configuration and triggers generation | Dashboard stores feed config in PostgreSQL and submits a generation job to MDS Feed Service |
| [Search Taxonomy Discovery](search-taxonomy-discovery.md) | synchronous | User types in a taxonomy/city/location search field | Dashboard queries Taxonomy Service and returns matching categories, cities, or locations |
| [Deal Performance Tracking](deal-performance-tracking.md) | synchronous | User views deal detail and options | Dashboard retrieves deal options from Deal Catalog and voucher inventory from Voucher Inventory Service |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 7 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

All flows in mdi-dashboard-v2 span multiple Continuum services. The primary cross-service interactions are:

- Deal intelligence search spans `continuumMarketingDealServiceDashboard` and `continuumMarketingDealService` (via `apiProxy`). See [Deal Intelligence Search](deal-intelligence-search.md).
- Feed generation spans `continuumMarketingDealServiceDashboard`, `mdiDashboardPostgres`, and the MDS Feed Service. See [Feed Creation and Generation](feed-creation-generation.md).
- Merchant insights spans `continuumMarketingDealServiceDashboard`, `continuumMarketingDealService`, and `salesForce`. See [Merchant Insights](merchant-insights.md).

Cross-service dynamic views are referenced in the central architecture model under `continuumMarketingDealServiceDashboard`.
