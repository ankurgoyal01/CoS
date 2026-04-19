---
service: "vouchercloud-idl"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for Vouchercloud IDL.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Offer Discovery and Search](offer-discovery-and-search.md) | synchronous | API request (GET /offers, /offers/search) | Consumer searches or browses offers; Redis cache checked first, then MongoDB/Algolia |
| [User Authentication](user-authentication.md) | synchronous | API request (POST /auth/*) | User authenticates via credentials, Facebook, Google, or Apple Sign-In; session created in Redis/SQL |
| [Offer Redemption (Wallet)](offer-redemption-wallet.md) | synchronous | API request (POST /users/{id}/offers/{offerId}/redeem) | Authenticated user redeems/clips an offer to their wallet; analytics event published to SQS |
| [Affiliate Outlink and Click Tracking](affiliate-outlink-click-tracking.md) | synchronous | API request (GET /out/offer/{OfferId}) | User clicks affiliate link; click tracked in SQL; user redirected to merchant site |
| [Reward Redemption (Giftcloud)](reward-redemption-giftcloud.md) | synchronous | API request (POST /users/{id}/rewards/redeem) | Authenticated user redeems accumulated reward; Giftcloud API called; SNS published on failure |
| [Merchant Sync Queue](merchant-sync-queue.md) | synchronous (internal) | Internal service call (POST /syncqueue/merchant/*) | Internal services enqueue, acquire, resolve, and fail merchant synchronisation jobs via the sync queue API |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 6 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

- The [Offer Redemption flow](offer-redemption-wallet.md) publishes analytics events to `VcEventQueue` (AWS SQS), which are consumed by a downstream Lambda-backed analytics pipeline outside this service.
- The [Reward Redemption flow](reward-redemption-giftcloud.md) publishes `Vouchercloud-{env}-RewardsInitialiseFailed` to AWS SNS on failure, triggering downstream alerting and monitoring pipelines.
- The [Affiliate Outlink flow](affiliate-outlink-click-tracking.md) stores click data in `continuumVcSqlDb` consumed by affiliate reporting services.
- The `continuumVcWebSite`, `continuumWhiteLabelWebSite`, and `continuumHoldingPagesWebSite` containers all participate in the Offer Discovery flow as upstream callers of `continuumVcApi` / `continuumRestfulApi`.
