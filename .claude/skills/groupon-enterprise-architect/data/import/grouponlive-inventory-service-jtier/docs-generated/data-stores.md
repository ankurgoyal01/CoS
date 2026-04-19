---
service: "grouponlive-inventory-service-jtier"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumGliveInventoryDatabase"
    type: "mysql"
    purpose: "Primary store for products, events, reservations, orders, units, and venue credentials"
  - id: "continuumRedisCache"
    type: "redis"
    purpose: "Caches partner API OAuth access tokens and transient data"
---

# Data Stores

## Overview

The service owns a single MySQL database (`glive_inventory`) as its primary data store, managed via Flyway migrations. A shared Redis instance is used as a cache for partner API authentication tokens and transient session data. The MySQL database persists the full inventory domain: products (Groupon Live deals), their events (specific showings/slots), reservations, orders, inventory units, customers, and venue credentials for each third-party ticketing partner.

## Stores

### Glive Inventory MySQL (`continuumGliveInventoryDatabase`)

| Property | Value |
|----------|-------|
| Type | MySQL |
| Architecture ref | `continuumGliveInventoryDatabase` |
| Purpose | Primary store for all inventory, commerce, and partner credential data |
| Ownership | Owned |
| Migrations path | `src/main/resources/db/migration/` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `products` | Represents Groupon Live deal products linked to third-party vendors | `uuid`, `inventory_product_id`, `merchant`, `merchant_uuid`, `third_party_vendor_id`, `state`, `type`, `vendor_id`, `currency_code`, `global_max` |
| `events` | Individual showings or time slots belonging to a product | `uuid`, `product_id`, `event_starts_at`, `event_ends_at`, `section`, `venue_name`, `third_party_remaining_quantity`, `active`, `enabled`, `type`, `merchant_product_id` |
| `reservations` | Seat holds created against a third-party partner on behalf of a customer | `uuid`, `customer_id`, `state`, `expires_at`, `type`, `third_party_params` |
| `reservation_units` | Individual units (seats/tickets) within a reservation | `uuid`, `reservation_id`, `unit_id`, `event_id`, `state`, `groupon_code`, `redemption_code`, `third_party_token`, `row`, `seat` |
| `units` | Available inventory units associated with an event | `event_id`, `state` |
| `orders` | Purchase records linking a customer, reservation, and product | `uuid`, `customer_id`, `reservation_id`, `product_id`, `state`, `response`, `third_party_error_message`, `type`, `tax_amount_cents` |
| `customers` | Customer records referenced during reservation and purchase | `uuid`, `brand`, `metadata` |
| `venues_credentials` | Stores authentication credentials for each third-party ticketing partner per venue | `uuid`, `venue_name`, `merchant`, `username`, `password`, `third_party_params` |
| `custom_checkout_field_responses` | Custom field values collected at checkout for an order | `order_id`, `key`, `value` |
| `templates` | Voucher templates linked to products | `uuid`, `product_id`, `name`, `country` |
| `janus_message` | Message relay records (payload, processing status, destination) | `uuid_id`, `payload`, `processing_status`, `destination`, `attempts` |

#### Access Patterns

- **Read**: Products fetched by UUID or `inventory_product_id`; events fetched by `product_id` with filters on `active`, `event_starts_at`; reservations fetched by UUID; units fetched by UUID or event; venue credentials fetched by type or UUID.
- **Write**: Reservations and orders created on purchase flow; reservation units written per seat allocated; venue credentials created and updated via the credentials API.
- **Indexes**: `events.uuid` (unique), `events.event_starts_at`, `events.merchant_product_id`+`active`, `reservations.uuid`, `reservations.expires_at`+`state`, `orders.uuid` (unique), `products.uuid` (unique), `products.inventory_product_id`, `reservation_units.groupon_code` (unique), `reservation_units.state`.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumRedisCache` | Redis | Stores OAuth access tokens obtained from Provenue partner API to avoid repeated authentication round-trips | Not configured in code (token validity driven by partner token expiry) |

- **Staging endpoint**: `glive-inventory-memorystore.us-central1.caches.stable.gcp.groupondev.com:6379`
- **Production endpoint**: `glive-inventory-memorystore.us-central1.caches.prod.gcp.groupondev.com:6379`
- **SSL**: Disabled (internal GCP VPC communication)
- **Timeout**: 2000 ms

## Data Flows

All data originates from two sources:
1. **Partner APIs** — event availability, reservation confirmations, and purchase responses are fetched from Provenue/Telecharge/AXS/Ticketmaster and persisted to MySQL via the Data Access Layer.
2. **Inbound API calls** — upstream Groupon services create reservations and purchases by posting to the service's REST API; the service writes resulting records to MySQL.

There is no CDC, ETL, or replication from MySQL. The `glive-inventory-rails` service maintains a parallel inventory in a separate Rails database; this service calls back to Rails via the `GliveInventoryRailsClient` to keep customer reservation state and event data synchronized.
