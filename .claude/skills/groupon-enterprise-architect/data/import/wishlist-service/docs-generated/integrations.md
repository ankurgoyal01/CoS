---
service: "wishlist-service"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 0
internal_count: 9
---

# Integrations

## Overview

The Wishlist Service integrates with nine internal Groupon/Continuum services via outbound HTTP (using JTier's Retrofit-based `jtier-retrofit` client) and one shared asynchronous messaging infrastructure (MBus). All outbound HTTP integrations use JTier's standard retry and timeout configuration. There are no external (non-Groupon) integrations. Dependencies on push token service, Rocketman Commercial, and Localize are configured but not included in the central federated architecture model.

## External Dependencies

> No evidence found in codebase of integrations with systems outside the Groupon internal network.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Deal Catalog Service | HTTP (Retrofit) | Fetches deal metadata, creative data, and deal-to-option mappings for wishlist item enrichment | `continuumDealCatalogService` |
| Orders Service | HTTP (Retrofit) | Fetches order history and purchased item context to mark wishlist items as purchased or gifted | `continuumOrdersService` |
| Pricing Service | HTTP (Retrofit) | Fetches dynamic pricing history for price-drop detection (threshold-based) | `continuumPricingService` |
| Taxonomy Service | HTTP (Retrofit) | Fetches taxonomy/channel hierarchy for item channel categorization | `continuumTaxonomyService` |
| Voucher Inventory Service | HTTP (Retrofit) | Fetches inventory product and redemption data per vertical | `continuumVoucherInventoryService` |
| Mailman (Email Service) | HTTP (Retrofit) | Sends wishlist notification email payloads for expiry and new item alerts | `continuumEmailService` |
| Localize Service | HTTP (Retrofit) | Loads localized notification templates from package `list-management` | Not in federated model |
| Push Token Service | HTTP (Retrofit) | Fetches device push tokens for push notification dispatch | Not in federated model |
| Rocketman Commercial | HTTP (Retrofit) | Sends expiry push notifications to mobile devices via Goodyear client | Not in federated model |
| MBus | STOMP/MBus | Consumes `ItemPurchases`, `DynamicPricing`, and `WishlistMailman` destinations; publishes to `WishlistMailman` | `messageBus` |

### Deal Catalog Service Detail

- **Protocol**: HTTP (Retrofit)
- **Config key**: `dealCatalogServiceRetrofitConfig`
- **Purpose**: Enriches wishlist item responses with deal metadata and creative data; results cached in Redis to meet 40ms SLA. Also used during background processing to look up deals by option ID (`lookUpDeal`) and by inventory product ID (`lookupDealsByInventoryProductId`).
- **Failure mode**: Cache hit may serve stale data; cache miss on downstream failure may degrade response content or cause a timeout.
- **Circuit breaker**: Not documented in available configuration.

### Orders Service Detail

- **Protocol**: HTTP (Retrofit)
- **Config key**: `ordersServiceRetrofitConfig`
- **Purpose**: Fetches full order details (items, status, creation date) for a given `orderId` and `consumerId` during item-purchase event processing.
- **Failure mode**: Purchased state may not be reflected in wishlist item records; processing skipped gracefully.
- **Circuit breaker**: Not documented in available configuration.

### Pricing Service Detail

- **Protocol**: HTTP (Retrofit)
- **Config key**: `pricingServiceRetrofitConfig`
- **Purpose**: Fetches pricing history for a given `productId` to determine whether a price drop has occurred beyond the configured `dropThreshold` percentage.
- **Failure mode**: Price-drop detection skipped; no push notification sent for affected items.
- **Circuit breaker**: Not documented in available configuration.

### Taxonomy Service Detail

- **Protocol**: HTTP (Retrofit)
- **Config key**: `taxonomyServiceRetrofitConfig`
- **Purpose**: Fetches channel/taxonomy hierarchy for assigning a `channelId` to wishlist items during background `ChannelUpdateTask` processing.
- **Failure mode**: Channel categorization unavailable; item channel filters may not resolve until next background cycle.
- **Circuit breaker**: Not documented.

### Voucher Inventory Service Detail

- **Protocol**: HTTP (Retrofit)
- **Config key**: `voucherInventoryServiceRetrofitConfig`
- **Purpose**: Fetches inventory product and redemption data per vertical (getaways, goods, VIS, gLive, CLO, TPIS) for wishlist item enrichment and expiry calculation.
- **Failure mode**: Inventory data unavailable; item enrichment degraded.
- **Circuit breaker**: Not documented.

### Mailman (Email Service) Detail

- **Protocol**: HTTP (Retrofit)
- **Config key**: `mailmanServiceRetrofitConfig`
- **Purpose**: Sends rendered notification emails for wishlisted items that are expiring soon or newly added. Triggered by the `EmailNotifyExpiryAndNewTask` background processor via the `WishlistMailman` MBus topic.
- **Failure mode**: Email notification not sent; item reprocessed on next background cycle if conditions still met.
- **Circuit breaker**: Not documented.

### MBus Detail

- **Protocol**: STOMP over TCP (port 61613)
- **Config key**: `messageBusClientConfig`
- **Purpose**: Consumes `ItemPurchases` (order events), `DynamicPricing` (price change events), and `WishlistMailman` (email workflow) destinations. Publishes to `WishlistMailman` during background processing.
- **Failure mode**: Worker cannot consume or publish events; MBus enablement controlled by `ENABLE_MBUS` env var on worker component.
- **Circuit breaker**: Not documented.

## Consumed By

> Upstream consumers are tracked in the central architecture model. Known consumers based on owners manual: GAPI (via iTier wishlist front-end app), deal page, layout service, iOS app, Android app, Marketing Service batch jobs.

## Dependency Health

- All outbound HTTP integrations use Retrofit with JTier standard retry and timeout configuration.
- The `featureToggleConfig` provides `enableDbCache` and `enableClientCache` flags to control caching behavior per environment.
- MBus consumer enablement on the worker is controlled by the `ENABLE_MBUS` environment variable (`"true"` to activate).
- If the Redis cluster is unavailable, the user bucket queue and price-drop cache are inaccessible; background processing will be impaired.
- If PostgreSQL (DaaS) is unavailable, all wishlist read and write operations fail; GAPI will receive empty or timeout responses and discard them per its 40ms SLA.
