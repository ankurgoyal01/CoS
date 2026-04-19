---
service: "next-pwa-app"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for next-pwa-app (MBNXT).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Consumer Browse and Search](consumer-browse-and-search.md) | synchronous | User navigates to browse/search page | SSR page render with deal feed data from Relevance API and Booster |
| [Deal Page View](deal-page-view.md) | synchronous | User clicks a deal link | Deal detail page render with data from API Proxy, UGC, and related services |
| [Checkout and Order](checkout-and-order.md) | synchronous | User adds to cart and completes purchase | Cart management and order creation via API Proxy and Orders Service |
| [SSR Request Middleware Chain](ssr-request-middleware-chain.md) | synchronous | Every incoming HTTP request | Middleware stack processing for routing, auth, locale, and security |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

- **Consumer Browse and Checkout** (`dynamic-consumer-browse-and-checkout`): Spans mbnxtGraphQL, continuumRelevanceApi, continuumDealManagementApi, continuumApiLazloService, and continuumOrdersService. Defined in the central architecture model.
