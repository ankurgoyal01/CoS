---
service: "scs-jtier"
title: "Remove Cart Items"
generated: "2026-03-03"
type: flow
flow_name: "remove-cart-items"
flow_type: synchronous
trigger: "API call — PUT /api/v2/cart/remove_items"
participants:
  - "GAPI/Lazlo"
  - "scsJtier_apiResource"
  - "addUpdateService"
  - "cartService"
  - "purchasabilityChecker"
  - "shoppingCartReadDao"
  - "shoppingCartWriteDao"
  - "scsJtier_messageBusPublisher"
  - "continuumScsJtierReadMysql"
  - "continuumScsJtierWriteMysql"
architecture_ref: "dynamic-scsJtier"
---

# Remove Cart Items

## Summary

The Remove Cart Items flow removes one or more items from the user's active cart. Items are identified by `option_uuid`. When `disable_auto_update` is false, the service may also automatically remove other items in the cart that have become unavailable at the time of the request. After updating the cart, the changes are persisted to the MySQL primary and an `updated_cart` event is published to Mbus.

## Trigger

- **Type**: api-call
- **Source**: GAPI/Lazlo API gateway forwarding a user action (e.g., "Remove from Cart" button click)
- **Frequency**: On-demand, per user action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GAPI/Lazlo | Upstream gateway — authenticates consumer and forwards the request | External |
| `scsJtier_apiResource` | Receives `PUT /api/v2/cart/remove_items` | `scsJtier_apiResource` |
| `addUpdateService` | Orchestrates the remove operation | `addUpdateService` |
| `cartService` | Loads and persists cart; publishes event | `cartService` |
| `purchasabilityChecker` | Optionally validates remaining items if `disable_auto_update=false` | `purchasabilityChecker` |
| `shoppingCartReadDao` | Loads existing cart from read replica | `shoppingCartReadDao` |
| `shoppingCartWriteDao` | Persists updated cart to primary | `shoppingCartWriteDao` |
| `scsJtier_messageBusPublisher` | Publishes `updated_cart` event | `scsJtier_messageBusPublisher` |
| `continuumScsJtierReadMysql` | MySQL read replica | `continuumScsJtierReadMysql` |
| `continuumScsJtierWriteMysql` | MySQL primary | `continuumScsJtierWriteMysql` |

## Steps

1. **Receive request**: GAPI/Lazlo sends `PUT /api/v2/cart/remove_items` with required headers and a JSON body containing `cart_data.items` (array of `option_uuid` to remove), optional `consumer_id`, and `disable_auto_update`.
   - From: GAPI/Lazlo
   - To: `scsJtier_apiResource`
   - Protocol: REST/HTTP

2. **Load existing cart**: `AddUpdateService` calls `CartService` to load the current cart from the read replica.
   - From: `addUpdateService` → `cartService`
   - To: `shoppingCartReadDao` → `continuumScsJtierReadMysql`
   - Protocol: JDBC

3. **Apply removal**: The specified `option_uuid` values are removed from the cart's item list. If `disable_auto_update=false`, the `PurchasabilityChecker` may also evaluate remaining items and remove any that are no longer available.
   - From: `addUpdateService`
   - To: `purchasabilityChecker` (conditional)
   - Protocol: direct

4. **Persist updated cart**: `CartService` calls `ShoppingCartWriteDAO` to persist the modified cart (either via UPDATE or, in edge cases, INSERT if the cart row was not found).
   - From: `cartService`
   - To: `shoppingCartWriteDao` → `continuumScsJtierWriteMysql`
   - Protocol: JDBC

5. **Publish updated_cart event**: `CartService` publishes an `UpdatedCartPublishMessage` to Mbus with the new cart state (including `is_empty` flag).
   - From: `cartService`
   - To: `scsJtier_messageBusPublisher` → Mbus
   - Protocol: Mbus

6. **Return response**: Updated cart contents returned to the caller as `application/json`.
   - From: `scsJtier_apiResource`
   - To: GAPI/Lazlo
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Requested `option_uuid` not in cart | Item silently ignored — no error | Remaining items removed; response reflects actual cart state |
| Database write failure | Exception propagates | HTTP 500; no event published |
| Purchasability check failure (when `disable_auto_update=false`) | Graceful degradation — removal still proceeds | Items removed; auto-removal of unavailable items may be skipped |

## Sequence Diagram

```
GAPI/Lazlo -> scsJtier_apiResource: PUT /api/v2/cart/remove_items (JSON body)
scsJtier_apiResource -> addUpdateService: processRemove(request)
addUpdateService -> cartService: loadCart(bCookie, consumerId, countryCode)
cartService -> shoppingCartReadDao: findCartBy*(...)
shoppingCartReadDao -> continuumScsJtierReadMysql: SELECT * FROM shopping_carts WHERE ...
continuumScsJtierReadMysql --> shoppingCartReadDao: ShoppingCartModel
shoppingCartReadDao --> cartService: ShoppingCartModel
cartService --> addUpdateService: existing cart
addUpdateService -> purchasabilityChecker: validateRemainingItems (if disable_auto_update=false)
purchasabilityChecker --> addUpdateService: categorized items
addUpdateService -> cartService: persistCart(updatedCart)
cartService -> shoppingCartWriteDao: UPDATE shopping_carts SET items=...
shoppingCartWriteDao -> continuumScsJtierWriteMysql: UPDATE shopping_carts
continuumScsJtierWriteMysql --> shoppingCartWriteDao: OK
cartService -> scsJtier_messageBusPublisher: publish(UpdatedCartPublishMessage)
scsJtier_messageBusPublisher --> cartService: OK
cartService --> addUpdateService: RemovedItem list
addUpdateService --> scsJtier_apiResource: response
scsJtier_apiResource --> GAPI/Lazlo: 200 OK (application/json)
```

## Related

- Architecture dynamic view: `dynamic-scsJtier`
- Related flows: [Add or Update Cart Items](add-update-cart-items.md), [Checkout Cart](checkout-cart.md)
