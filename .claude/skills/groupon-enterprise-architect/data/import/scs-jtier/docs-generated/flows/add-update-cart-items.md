---
service: "scs-jtier"
title: "Add or Update Cart Items"
generated: "2026-03-03"
type: flow
flow_name: "add-update-cart-items"
flow_type: synchronous
trigger: "API call — PUT /api/v2/cart/add_items or PUT /api/v2/cart/update_items"
participants:
  - "GAPI/Lazlo"
  - "scsJtierService"
  - "scsJtier_apiResource"
  - "addUpdateService"
  - "cartService"
  - "purchasabilityChecker"
  - "dealServiceClient"
  - "inventoryServiceClient"
  - "shoppingCartReadDao"
  - "shoppingCartWriteDao"
  - "scsJtier_messageBusPublisher"
  - "continuumScsJtierReadMysql"
  - "continuumScsJtierWriteMysql"
  - "continuumDealService"
  - "continuumGoodsInventoryService"
architecture_ref: "dynamic-scsJtier"
---

# Add or Update Cart Items

## Summary

This flow handles adding one or more items to the cart or updating the quantity of existing items. `PUT /api/v2/cart/add_items` and `PUT /api/v2/cart/update_items` share the same upsert semantics: items are inserted if absent or updated in place if already present. After validating purchasability against deal and inventory services, the cart is persisted to the MySQL primary and an `updated_cart` event is published to the Mbus message bus.

## Trigger

- **Type**: api-call
- **Source**: GAPI/Lazlo API gateway forwarding a user action (e.g., "Add to Cart" button click)
- **Frequency**: On-demand, per user action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GAPI/Lazlo | Upstream gateway — authenticates the consumer and forwards the request | External |
| `scsJtier_apiResource` | Receives `PUT /api/v2/cart/add_items` or `/update_items` and delegates to AddUpdateService | `scsJtier_apiResource` |
| `addUpdateService` | Orchestrates the add/update flow: loads cart, validates purchasability, persists | `addUpdateService` |
| `cartService` | Loads and persists cart records; publishes the updated cart event | `cartService` |
| `purchasabilityChecker` | Validates each requested item against deal data and inventory | `purchasabilityChecker` |
| `dealServiceClient` | Fetches deal metadata | `dealServiceClient` |
| `inventoryServiceClient` | Checks inventory availability | `inventoryServiceClient` |
| `shoppingCartReadDao` | Loads existing cart from the read replica | `shoppingCartReadDao` |
| `shoppingCartWriteDao` | Persists the updated cart to the MySQL primary | `shoppingCartWriteDao` |
| `scsJtier_messageBusPublisher` | Publishes `updated_cart` event to Mbus | `scsJtier_messageBusPublisher` |
| `continuumScsJtierReadMysql` | MySQL read replica | `continuumScsJtierReadMysql` |
| `continuumScsJtierWriteMysql` | MySQL primary (write target) | `continuumScsJtierWriteMysql` |
| `continuumDealService` | Provides deal metadata for purchasability | `continuumDealService` |
| `continuumGoodsInventoryService` | Provides inventory availability | `continuumGoodsInventoryService` |

## Steps

1. **Receive request**: GAPI/Lazlo sends `PUT /api/v2/cart/add_items` with required headers (`b`, `ACCEPT-LANGUAGE`, `X-Country-Code`) and a JSON body containing `cart_data.items` (array of `deal_uuid`, `option_uuid`, `quantity`, optional `booking_attributes`, optional `extra_attributes`), optional `consumer_id`, and optional `disable_auto_update`.
   - From: GAPI/Lazlo
   - To: `scsJtier_apiResource`
   - Protocol: REST/HTTP

2. **Load existing cart**: `AddUpdateService` calls `CartService` to load the current cart state for the user from the read replica, using `ShoppingCartReadDAO.findCartByBCookie` or `findCartByConsumerId`.
   - From: `addUpdateService` → `cartService`
   - To: `shoppingCartReadDao` → `continuumScsJtierReadMysql`
   - Protocol: JDBC

3. **Validate purchasability**: `AddUpdateService` calls `PurchasabilityChecker` with the new items and the existing cart. The checker fetches deal data from `DealServiceClient` and then calls `InventoryServiceClient` to verify availability. If `disable_auto_update` is false, items that fail validation may be flagged for removal or quantity adjustment.
   - From: `purchasabilityChecker`
   - To: `dealServiceClient` → `continuumDealService`; `inventoryServiceClient` → inventory service
   - Protocol: HTTPS

4. **Apply upsert logic**: Requested items are merged into the existing cart — items not present are inserted; items already present have their quantity updated. The merged cart respects the configured `maxCartSize` limit.
   - From: `addUpdateService`
   - To: `cartService`
   - Protocol: direct

5. **Persist updated cart**: `CartService` calls `ShoppingCartWriteDAO` to persist the updated cart. If the cart already exists, `updateLoggedInCart` or `updateLoggedOutCart` is called; if new, `insertLoggedInCart` or `insertLoggedOutCart` is called.
   - From: `cartService`
   - To: `shoppingCartWriteDao` → `continuumScsJtierWriteMysql`
   - Protocol: JDBC

6. **Publish updated_cart event**: `CartService` calls `MessageBusPublisher` to publish an `UpdatedCartPublishMessage` to the Mbus, including `consumer_id`, `is_empty`, `updated_at`, `b_cookie`, and `country_code`.
   - From: `cartService`
   - To: `scsJtier_messageBusPublisher` → Mbus
   - Protocol: Mbus

7. **Return response**: `ScsJtierResource` returns the updated cart contents as `application/json` to the caller.
   - From: `scsJtier_apiResource`
   - To: GAPI/Lazlo
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Requested item fails purchasability check | If `disable_auto_update=false`, item may be auto-removed or quantity adjusted; if `true`, items added as-is | Partial success possible |
| Deal service unavailable | Validation skipped or fails | Items may be added without validation; depends on feature flag and `disable_auto_update` |
| Inventory service unavailable | Validation skipped or fails | Same as deal service |
| Cart at `maxCartSize` limit | Request rejected or truncated | Error response or items not added |
| Database write failure | Exception propagates | HTTP 500; no event published |

## Sequence Diagram

```
GAPI/Lazlo -> scsJtier_apiResource: PUT /api/v2/cart/add_items (JSON body)
scsJtier_apiResource -> addUpdateService: processAddUpdate(request)
addUpdateService -> cartService: loadCart(bCookie, consumerId, countryCode)
cartService -> shoppingCartReadDao: findCartBy*(bCookie/consumerId, countryCode)
shoppingCartReadDao -> continuumScsJtierReadMysql: SELECT * FROM shopping_carts WHERE ...
continuumScsJtierReadMysql --> shoppingCartReadDao: ShoppingCartModel
shoppingCartReadDao --> cartService: ShoppingCartModel
cartService --> addUpdateService: existing cart
addUpdateService -> purchasabilityChecker: validateItems(newItems, countryCode)
purchasabilityChecker -> dealServiceClient: getDealData(dealUuids)
dealServiceClient -> continuumDealService: GET /deals (HTTPS)
continuumDealService --> dealServiceClient: deal data
purchasabilityChecker -> inventoryServiceClient: checkAvailability(optionUuids)
inventoryServiceClient -> continuumGoodsInventoryService: POST /availability (HTTPS)
continuumGoodsInventoryService --> inventoryServiceClient: availability data
purchasabilityChecker --> addUpdateService: CartWithCategorizedItems
addUpdateService -> cartService: persistCart(updatedCart)
cartService -> shoppingCartWriteDao: insert/update shopping_carts
shoppingCartWriteDao -> continuumScsJtierWriteMysql: INSERT/UPDATE shopping_carts
continuumScsJtierWriteMysql --> shoppingCartWriteDao: OK
cartService -> scsJtier_messageBusPublisher: publish(UpdatedCartPublishMessage)
scsJtier_messageBusPublisher --> cartService: OK
cartService --> addUpdateService: CartContentsAddUpdate
addUpdateService --> scsJtier_apiResource: CartContentsAddUpdate
scsJtier_apiResource --> GAPI/Lazlo: 200 OK (application/json)
```

## Related

- Architecture dynamic view: `dynamic-scsJtier`
- Related flows: [Get Cart](get-cart.md), [Remove Cart Items](remove-cart-items.md), [Checkout Cart](checkout-cart.md)
