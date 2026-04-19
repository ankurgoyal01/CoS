---
service: "scs-jtier"
title: "Checkout Cart"
generated: "2026-03-03"
type: flow
flow_name: "checkout-cart"
flow_type: synchronous
trigger: "API call — PUT /api/v2/cart/checkout_cart"
participants:
  - "GAPI/Lazlo"
  - "scsJtier_apiResource"
  - "cartService"
  - "shoppingCartReadDao"
  - "shoppingCartWriteDao"
  - "scsJtier_messageBusPublisher"
  - "continuumScsJtierReadMysql"
  - "continuumScsJtierWriteMysql"
architecture_ref: "dynamic-scsJtier"
---

# Checkout Cart

## Summary

The Checkout Cart flow marks a user's active cart as checked out or deactivated. This is called by the upstream gateway when the user completes a purchase or when the cart needs to be deactivated for another reason. The cart is located by bCookie and/or consumer ID, its `active` flag is set to `0` (deactivated), and an `updated_cart` event is published to Mbus with `is_empty: true`. No purchasability validation is performed during checkout.

## Trigger

- **Type**: api-call
- **Source**: GAPI/Lazlo API gateway, typically called at the conclusion of a successful purchase
- **Frequency**: On-demand, per cart checkout event

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GAPI/Lazlo | Upstream gateway — authenticates consumer and initiates checkout | External |
| `scsJtier_apiResource` | Receives `PUT /api/v2/cart/checkout_cart` | `scsJtier_apiResource` |
| `cartService` | Loads cart, deactivates it, and publishes the event | `cartService` |
| `shoppingCartReadDao` | Finds the active cart from the read replica | `shoppingCartReadDao` |
| `shoppingCartWriteDao` | Sets `active = 0` via `deactivateCart` | `shoppingCartWriteDao` |
| `scsJtier_messageBusPublisher` | Publishes `updated_cart` event | `scsJtier_messageBusPublisher` |
| `continuumScsJtierReadMysql` | MySQL read replica | `continuumScsJtierReadMysql` |
| `continuumScsJtierWriteMysql` | MySQL primary | `continuumScsJtierWriteMysql` |

## Steps

1. **Receive request**: GAPI/Lazlo sends `PUT /api/v2/cart/checkout_cart` with required headers (`b`, `ACCEPT-LANGUAGE`, `X-Country-Code`) and an optional JSON body containing `consumer_id`.
   - From: GAPI/Lazlo
   - To: `scsJtier_apiResource`
   - Protocol: REST/HTTP

2. **Find active cart**: `CartService` calls `ShoppingCartReadDAO` to locate the user's active cart by bCookie or consumer ID and country code.
   - From: `cartService`
   - To: `shoppingCartReadDao` → `continuumScsJtierReadMysql`
   - Protocol: JDBC

3. **Deactivate cart**: `CartService` calls `ShoppingCartWriteDAO.deactivateCart(cartId, currentTime)`, which executes `UPDATE shopping_carts SET active = 0, updated_at = ? WHERE id = ? AND active = 1`.
   - From: `cartService`
   - To: `shoppingCartWriteDao` → `continuumScsJtierWriteMysql`
   - Protocol: JDBC

4. **Publish updated_cart event**: `CartService` publishes an `UpdatedCartPublishMessage` with `event = "updated_cart"` and `is_empty = true` to inform downstream consumers that this cart is no longer active.
   - From: `cartService`
   - To: `scsJtier_messageBusPublisher` → Mbus
   - Protocol: Mbus

5. **Return response**: Success response returned to the caller.
   - From: `scsJtier_apiResource`
   - To: GAPI/Lazlo
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Cart not found for bCookie/consumer_id | No update executed | HTTP response may still return success (idempotent behavior) |
| Database write failure | Exception propagates | HTTP 500; no event published |
| Mbus publish failure | Cart deactivation still succeeds | Cart is deactivated; downstream consumers may miss the event |

## Sequence Diagram

```
GAPI/Lazlo -> scsJtier_apiResource: PUT /api/v2/cart/checkout_cart (b, ACCEPT-LANGUAGE, X-Country-Code, ?consumer_id)
scsJtier_apiResource -> cartService: checkoutCart(bCookie, consumerId, countryCode)
cartService -> shoppingCartReadDao: findCartBy*(bCookie/consumerId, countryCode)
shoppingCartReadDao -> continuumScsJtierReadMysql: SELECT * FROM shopping_carts WHERE active=1 AND ...
continuumScsJtierReadMysql --> shoppingCartReadDao: ShoppingCartModel
shoppingCartReadDao --> cartService: cart (with cartId)
cartService -> shoppingCartWriteDao: deactivateCart(cartId, now)
shoppingCartWriteDao -> continuumScsJtierWriteMysql: UPDATE shopping_carts SET active=0 WHERE id=?
continuumScsJtierWriteMysql --> shoppingCartWriteDao: OK
cartService -> scsJtier_messageBusPublisher: publish(UpdatedCartPublishMessage{is_empty:true})
scsJtier_messageBusPublisher --> cartService: OK
cartService --> scsJtier_apiResource: success
scsJtier_apiResource --> GAPI/Lazlo: 200 OK (application/json)
```

## Related

- Architecture dynamic view: `dynamic-scsJtier`
- Related flows: [Add or Update Cart Items](add-update-cart-items.md), [Remove Cart Items](remove-cart-items.md)
