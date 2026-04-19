---
service: "sponsored-campaign-itier"
title: Flows
generated: "2026-03-02"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for Sponsored Campaign iTier.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Create Sponsored Campaign](create-sponsored-campaign.md) | synchronous | Merchant initiates campaign creation in Merchant Center | Multi-step wizard guiding merchant through deal selection, targeting, budget, and submission to UMAPI |
| [View Campaign Performance](view-campaign-performance.md) | synchronous | Merchant opens performance dashboard | Fetches campaign metrics, billing records, and wallet balance from UMAPI and renders analytics |
| [Wallet Top-Up](wallet-topup.md) | synchronous | Merchant adds funds to sponsored campaign wallet | Creates or selects payment method, posts top-up to UMAPI wallet via API proxy |
| [Campaign Status Toggle](campaign-status-toggle.md) | synchronous | Merchant pauses or resumes a campaign | Posts status change to API proxy, forwarded to UMAPI status endpoint |
| [Delete Campaign](delete-campaign.md) | synchronous | Merchant confirms campaign deletion | Deletes active or draft campaign via API proxy to UMAPI |
| [Merchant Auth Validation](merchant-auth-validation.md) | synchronous | Every inbound request | itier-user-auth validates authToken, layout service checks feature flags, guards route access |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 6 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

All flows in this service cross into `continuumUniversalMerchantApi` for persistence. Authentication for every flow passes through `continuumMerchantApi`. The [Create Sponsored Campaign](create-sponsored-campaign.md) and [View Campaign Performance](view-campaign-performance.md) flows additionally touch `continuumGeoDetailsService` and `continuumBirdcageService` respectively. An architecture dynamic view for the campaign update flow is defined at `dynamic-update_campaign_flow` (currently disabled pending active relations — see `views/dynamics/update-campaign-flow.dsl`).
