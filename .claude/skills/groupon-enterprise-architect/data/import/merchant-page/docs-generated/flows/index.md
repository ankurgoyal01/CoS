---
service: "merchant-page"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Merchant Place Pages.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Merchant Page Request](merchant-page-request.md) | synchronous | HTTP GET `/biz/{citySlug}/{merchantSlug}` | Full merchant place page render: orchestrates merchant data, deal cards, reviews, and map signing, then SSR-renders the complete HTML response |
| [RAPI Deal Cards Fragment](rapi-deal-cards.md) | synchronous | HTTP GET `/merchant-page/rapi/{city}/{permalink}` | Fetches geo-filtered related deal cards from the Relevance API and returns rendered card HTML for client-side injection |
| [Reviews Fragment](reviews-fragment.md) | synchronous | HTTP GET `/merchant-page/reviews` | Fetches paginated merchant reviews from the UGC Service and returns JSON for client-side rendering |
| [Map Image Signing](map-image-signing.md) | synchronous | HTTP GET `/merchant-page/maps/image` | Generates a signed static map image URL via GIMS and issues a redirect |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The primary merchant page request flow spans multiple internal Continuum services and is documented in the architecture dynamic view:

- Architecture dynamic view: `dynamic-merchant-page-request-flow`
- Participants: `continuumMerchantPageService`, `continuumUniversalMerchantApi`, `continuumRelevanceApi`, `continuumUgcService`, `gims`

See [Merchant Page Request flow](merchant-page-request.md) for the full step-by-step breakdown.
