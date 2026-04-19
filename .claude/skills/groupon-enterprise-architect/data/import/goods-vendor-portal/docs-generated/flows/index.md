---
service: "goods-vendor-portal"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for Goods Vendor Portal.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Merchant Login](merchant-login.md) | synchronous | User submits credentials on the login page | Authenticates a merchant and establishes a session to gate access to protected portal routes |
| [Product Catalog Management](product-catalog-management.md) | synchronous | Merchant navigates to and interacts with the catalog section | Merchant browses, creates, and edits product listings via the portal and GPAPI |
| [Contract and Agreement Management](contract-and-agreement-management.md) | synchronous | Merchant navigates to contracts or co-op agreements section | Merchant views contracts and co-op agreements retrieved from GPAPI |
| [Deal and Promotion Creation](deal-and-promotion-creation.md) | synchronous | Merchant submits a new deal or promotion form | Merchant creates a deal or promotion that is persisted in GPAPI |
| [Vendor Profile Self-Service](vendor-profile-self-service.md) | synchronous | Merchant navigates to and updates their vendor profile | Merchant updates addresses, contacts, and banking information via the self-service section |
| [Analytics and Insights Reporting](analytics-and-insights-reporting.md) | synchronous | Merchant navigates to the analytics or insights section | Merchant views business performance metrics and reports fetched from GPAPI insights endpoints |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 6 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

All portal flows traverse the following cross-service path:

1. Browser (`emberApp`) initiates the action.
2. `goodsVendorPortal_apiClient` issues an HTTPS call to the Nginx proxy at `/goods-gateway/*`.
3. `continuumGoodsVendorPortalWeb` (Nginx) forwards the request to `gpapiApi_unk_1d2b` (GPAPI).
4. For financial flows (contracts, co-op agreements, pricing), GPAPI additionally communicates with `continuumAccountingService`.

No dynamic views are currently defined in the architecture DSL for this service. Cross-service flow diagrams are pending in the central architecture model under `continuumSystem`.
