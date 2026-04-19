---
service: "coupons-itier-global"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Coupons I-Tier Global.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Merchant Redirect](merchant-redirect.md) | synchronous | GET `/redirect/merchant/{id}` | Resolves a merchant affiliate redirect URL from cache or Vouchercloud and issues an HTTP redirect |
| [Offer Redemption](offer-redemption.md) | synchronous | GET `/redirect/offers/{id}` | Resolves a coupon offer redirect URL from cache or Vouchercloud and issues an HTTP redirect to the offer destination |
| [Redirect Cache Refresh](redirect-cache-refresh.md) | scheduled | node-schedule cron | Periodically fetches all current redirect rules from Vouchercloud and writes them into Redis |
| [Coupon Browse](coupon-browse.md) | synchronous | GET `/coupons` or `/category/{category}` | Fetches coupon and deal data, assembles a server-side rendered page, and returns it to the browser |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

- The [Merchant Redirect](merchant-redirect.md) and [Offer Redemption](offer-redemption.md) flows both depend on `vouchercloudApi_5b7d2e` (external stub) for redirect rule resolution on cache miss.
- The [Coupon Browse](coupon-browse.md) flow spans `continuumCouponsItierGlobalService`, `continuumCouponsRedisCache`, `vouchercloudApi_5b7d2e`, and `gapi_1f2a9c`.
- Central architecture dynamic views for these flows are not yet defined (see `views/dynamics.dsl`).
