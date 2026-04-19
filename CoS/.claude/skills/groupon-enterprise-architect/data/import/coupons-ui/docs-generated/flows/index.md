---
service: "coupons-ui"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Coupons UI.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Merchant Page SSR](merchant-page-ssr.md) | synchronous | HTTP GET from browser | Renders a merchant coupon page server-side, reading cached offer data from Redis and composing the full HTML response |
| [Coupon Redemption](coupon-redemption.md) | synchronous | User clicks "Get Code" in browser | Client-side orchestration triggers a server API call to VoucherCloud to reveal a coupon code and open an affiliate link |
| [Offer Redirect](offer-redirect.md) | synchronous | User clicks an offer link | Server API route resolves the affiliate redirect URL from VoucherCloud and returns it to the browser for navigation |
| [Request Middleware Initialization](request-middleware-init.md) | synchronous | Every inbound HTTP request | Astro middleware initializes configuration, request context, logging, Redis, in-memory cache, and VoucherCloud clients before any handler executes |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The `dynamic-coupons-ui-request-redemption-flow` dynamic view in the architecture DSL captures the end-to-end flow across `continuumCouponsUi`, `continuumCouponsRedis`, `voucherCloudApi`, `googleTagManager`, `loggingStack`, and `metricsStack`. See [Architecture Context](../architecture-context.md) for diagram references.
