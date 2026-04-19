---
service: "wishlist-service"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

The Wishlist Service participates in Groupon's MBus (STOMP-based) messaging fabric. It consumes three MBus destination subscriptions on the worker component: `ItemPurchases` (order transactions), `DynamicPricing` (price-change notifications), and `WishlistMailman` (email dispatch workflow). It also publishes to the `WishlistMailman` destination during background item processing. All MBus connections are managed by the `jtier-messagebus-client` (version 0.4.6) using durable subscriptions. MBus consumers are activated on the worker component only when the `ENABLE_MBUS` environment variable is set to `"true"`.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `WishlistMailman` (MBus destination) | Wishlist email notification request | Background `EmailNotifyExpiryAndNewTask` detects expiring or recently-added items | `userUuid`, `dealsExpiringSoon` (list of deal UUIDs), `recentlyAddedDeals` (list of deal UUIDs), `locale` |

### Wishlist Email Notification Request Detail

- **Topic**: `WishlistMailman` MBus destination
- **Trigger**: The `EmailNotifyExpiryAndNewTask` background item processor runs per user and identifies wishlisted deals within configured expiry windows (`minExpiryWindow`, `maxExpiryWindow`) or recently-added windows (`minCreatedWindow`, `maxCreatedWindow`). Notification is suppressed if the user has received an email within `minTimeSinceLastNotification`.
- **Payload**: JSON-serialized `MailmanRequest<NewAndExpiredMailmanRequestData>` containing `userUuid`, lists of expiring deal UUIDs (`dealsExpiringSoon`), recently-added deal UUIDs (`recentlyAddedDeals`), and `locale` string.
- **Consumers**: `continuumEmailService` (Mailman) subscribes to this destination to render and dispatch notification emails.
- **Guarantees**: At-least-once (durable MBus subscription).

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `ItemPurchases` (MBus destination) | Order transaction event | `ItemPurchasesProcessor` | Marks matching wishlist items as purchased or gifted in PostgreSQL |
| `DynamicPricing` (MBus destination) | Price update events | `DynamicPricingProcessor` | Detects price drops and caches price-drop state in Redis (`priceDrops:<dealId>`) |
| `WishlistMailman` (MBus destination) | Wishlist mail requests | `MailmanRequestProcessor` | Triggers outbound email dispatch via Mailman HTTP client |

### Order Transaction Event Detail

- **Topic**: `ItemPurchases` MBus destination
- **Handler**: `ItemPurchasesProcessor` — deserializes `OrderTransaction` payload, fetches full order from the Orders Service, looks up deal IDs from Deal Catalog by option ID, then updates `purchased` or `gifted` timestamp on matching wishlist list items in PostgreSQL. Processes only items with status `"collected"`.
- **Idempotency**: Not explicitly enforced; duplicate messages may result in duplicate `purchased`/`gifted` timestamp updates.
- **Error handling**: Exceptions are logged via Steno; message is `nack`'d on error.
- **Processing order**: Unordered (parallel thread pool, configurable size via `messageBusConfig.itemPurchasesProcessorConfig.threadPoolSize`).

### Dynamic Pricing Event Detail

- **Topic**: `DynamicPricing` MBus destination
- **Handler**: `DynamicPricingProcessor` — deserializes a list of `PricingUpdate` objects (keyed by `productId`), fetches pricing history from the Pricing Service, and fetches deal metadata from Deal Catalog. If the price has dropped beyond `dropThreshold`, stores a `PriceDrop` record in Redis under key `priceDrops:<dealId>` with configurable expiry (`priceDropCacheExpiry`, default 24 hours).
- **Idempotency**: Redis key overwrite on duplicate price-drop events.
- **Error handling**: Exceptions are logged; message is `nack`'d on error.
- **Processing order**: Unordered (parallel thread pool, configurable via `messageBusConfig.dynamicPricingProcessorConfig.threadPoolSize`).

### Wishlist Mail Request Detail

- **Topic**: `WishlistMailman` MBus destination
- **Handler**: `MailmanRequestProcessor` — drives outbound email dispatch via the `wishlistExternalClients` Mailman HTTP client.
- **Idempotency**: Not explicitly documented; durable subscription prevents message loss on restart.
- **Error handling**: Errors logged to Steno / Kibana index `wishlist-service`.
- **Processing order**: Unordered.

## Dead Letter Queues

> No evidence found in codebase of DLQ configuration for any MBus destinations.
