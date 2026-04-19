---
service: "clo-ita"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 8
---

# Flows

Process and flow documentation for CLO I-Tier Frontend.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Single Deal Claim](single-deal-claim.md) | synchronous | User initiates claim on a CLO deal page | User claims a single Card Linked Offer deal through the I-Tier frontend |
| [Card Enrollment](card-enrollment.md) | synchronous | User submits card enrollment form | User enrolls a payment card for Card Linked Offers via the enrollment flow |
| [View Claims](view-claims.md) | synchronous | User navigates to linked deals page | User views all CLO deals currently linked to their account |
| [Claim Details and Transaction](claim-details-transaction.md) | synchronous | User navigates to a claimed deal's detail page | User views details and transaction history for a specific CLO claim |
| [Transaction Summary](transaction-summary.md) | synchronous | User views CLO transaction summary page | User views an aggregated cashback and transaction summary for their CLO account |
| [Card Management](card-management.md) | synchronous | User manages enrolled cards | User un-enrolls a payment card or updates card enrollment preferences |
| [Bulk Claim](bulk-claim.md) | synchronous | User triggers bulk claim action | User claims multiple CLO deals at once via the bulk claims endpoint |
| [Missing Cashback Support](missing-cashback-support.md) | synchronous | User submits missing cashback request | User reports a missing cashback transaction and submits a support request |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 8 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

All flows in `clo-ita` span multiple Continuum platform services. The canonical dynamic architecture view for the claim flow is `dynamic-claim-flow` in the Structurizr model. All flows share the same participant set (`continuumCloItaService`, `apiProxy`, and a combination of `continuumMarketingDealService`, `continuumUsersService`, `continuumOrdersService`, `continuumGeoDetailsService`, `continuumDealCatalogService`), varying by which downstream services are called.
