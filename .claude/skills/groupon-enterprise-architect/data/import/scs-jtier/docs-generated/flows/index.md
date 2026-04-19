---
service: "scs-jtier"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Shopping Cart Service JTier.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Get Cart](get-cart.md) | synchronous | API call from GAPI/Lazlo — `GET /api/v2/cart` | Retrieves full cart contents for a user by bCookie or consumer ID, optionally running purchasability checks |
| [Add or Update Cart Items](add-update-cart-items.md) | synchronous | API call from GAPI/Lazlo — `PUT /api/v2/cart/add_items` or `PUT /api/v2/cart/update_items` | Adds new items or updates quantities in the cart, validates purchasability, persists changes, and publishes an `updated_cart` event |
| [Remove Cart Items](remove-cart-items.md) | synchronous | API call from GAPI/Lazlo — `PUT /api/v2/cart/remove_items` | Removes specified items from the cart, optionally auto-removes unavailable items, persists changes, and publishes an `updated_cart` event |
| [Checkout Cart](checkout-cart.md) | synchronous | API call from GAPI/Lazlo — `PUT /api/v2/cart/checkout_cart` | Marks the cart as checked out (deactivated) and publishes an `updated_cart` event |
| [Abandoned Cart Detection](abandoned-cart-detection.md) | scheduled | Quartz job — every 30 minutes on `worker` pods | Scans for carts abandoned for 4+ hours and publishes `abandoned_cart` events to Mbus for downstream re-engagement processing |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

- The [Add or Update Cart Items](add-update-cart-items.md) and [Get Cart](get-cart.md) flows call `continuumDealService` and inventory services (`continuumGoodsInventoryService`, `continuumVoucherInventoryService`) synchronously during purchasability validation.
- The [Abandoned Cart Detection](abandoned-cart-detection.md) flow publishes events consumed by the Regla (Push Marketing) team's service.
- All synchronous cart mutation flows produce `updated_cart` events that propagate to downstream consumers tracking cart state.
