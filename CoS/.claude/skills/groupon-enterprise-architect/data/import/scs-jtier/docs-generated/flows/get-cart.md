---
service: "scs-jtier"
title: "Get Cart"
generated: "2026-03-03"
type: flow
flow_name: "get-cart"
flow_type: synchronous
trigger: "API call — GET /api/v2/cart or GET /api/v2/cart/size"
participants:
  - "GAPI/Lazlo"
  - "scsJtierService"
  - "scsJtier_apiResource"
  - "cartService"
  - "purchasabilityChecker"
  - "dealServiceClient"
  - "inventoryServiceClient"
  - "shoppingCartReadDao"
  - "continuumScsJtierReadMysql"
  - "continuumDealService"
  - "continuumGoodsInventoryService"
architecture_ref: "dynamic-scsJtier"
---

# Get Cart

## Summary

The Get Cart flow retrieves the current cart contents (or cart size) for a user. The caller is identified by the `b` header (bCookie); an optional `consumer_id` query parameter further scopes the lookup to an authenticated user's cart. When `disable_auto_update` is not set to `true`, the service may run purchasability validation on the returned items before responding, calling Deal Catalog and Inventory services to detect items that are no longer valid.

## Trigger

- **Type**: api-call
- **Source**: GAPI/Lazlo API gateway forwarding a request from web, touch, or mobile app
- **Frequency**: On-demand, per user page load or cart interaction

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GAPI/Lazlo | Upstream gateway — authenticates the consumer and forwards the request | External |
| `scsJtierService` | Receives and routes the HTTP request | `scsJtierService` |
| `scsJtier_apiResource` | JAX-RS endpoint handling `GET /api/v2/cart` and `GET /api/v2/cart/size` | `scsJtier_apiResource` |
| `cartService` | Loads cart from database and orchestrates purchasability validation | `cartService` |
| `purchasabilityChecker` | Validates each cart item against deal and inventory data | `purchasabilityChecker` |
| `dealServiceClient` | Fetches deal metadata via HTTP | `dealServiceClient` |
| `inventoryServiceClient` | Fetches inventory availability via HTTP | `inventoryServiceClient` |
| `shoppingCartReadDao` | Executes SQL SELECT against the read replica | `shoppingCartReadDao` |
| `continuumScsJtierReadMysql` | MySQL read replica storing cart records | `continuumScsJtierReadMysql` |
| `continuumDealService` | Downstream deal catalog service | `continuumDealService` |
| `continuumGoodsInventoryService` | Downstream inventory service | `continuumGoodsInventoryService` |

## Steps

1. **Receive request**: GAPI/Lazlo sends `GET /api/v2/cart` (or `/api/v2/cart/size`) with required headers `b`, `ACCEPT-LANGUAGE`, `X-Country-Code`, and optional query params `consumer_id`, `disable_auto_update`.
   - From: GAPI/Lazlo
   - To: `scsJtier_apiResource`
   - Protocol: REST/HTTP

2. **Load cart from database**: `ScsJtierResource` delegates to `CartService`, which calls `ShoppingCartReadDAO` to look up the cart. If `consumer_id` is present, the query uses `findCartByConsumerId`; otherwise it uses `findCartByBCookie`. For size requests, `findSizeByConsumerId` or `findSizeByBCookie` is used.
   - From: `cartService`
   - To: `shoppingCartReadDao` → `continuumScsJtierReadMysql`
   - Protocol: JDBC

3. **Run purchasability validation** (if `disable_auto_update` is false and the country code is in `featureFlags.countriesForCheckAvailability`): `CartService` invokes `PurchasabilityChecker`, which calls `DealServiceClient` to fetch deal metadata and `InventoryServiceClient` to check availability for each item in the cart.
   - From: `purchasabilityChecker`
   - To: `dealServiceClient` → `continuumDealService`
   - Protocol: HTTPS

4. **Check inventory availability**: `PurchasabilityChecker` calls `InventoryServiceClient` to verify stock and purchase controls for each item.
   - From: `purchasabilityChecker`
   - To: `inventoryServiceClient` → `continuumGoodsInventoryService` (or voucher/specialty inventory service depending on deal type)
   - Protocol: HTTPS

5. **Return cart response**: `ScsJtierResource` serializes the cart contents (or size) and returns the `application/json` response to the caller.
   - From: `scsJtier_apiResource`
   - To: GAPI/Lazlo
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Cart not found for bCookie/consumer_id | Returns empty cart state | HTTP 200 with empty items |
| Deal service unavailable | Purchasability validation skipped or fails gracefully | Cart returned without validation; items not auto-removed |
| Inventory service unavailable | Purchasability validation skipped or fails gracefully | Cart returned without validation |
| Database read error | Exception propagates | HTTP 500 or Dropwizard error response |

## Sequence Diagram

```
GAPI/Lazlo -> scsJtier_apiResource: GET /api/v2/cart (b, ACCEPT-LANGUAGE, X-Country-Code, ?consumer_id)
scsJtier_apiResource -> cartService: loadCart(bCookie, consumerId, countryCode)
cartService -> shoppingCartReadDao: findCartByBCookie / findCartByConsumerId
shoppingCartReadDao -> continuumScsJtierReadMysql: SELECT * FROM shopping_carts WHERE ...
continuumScsJtierReadMysql --> shoppingCartReadDao: ShoppingCartModel
shoppingCartReadDao --> cartService: ShoppingCartModel
cartService -> purchasabilityChecker: validateItems(cartItems, countryCode)
purchasabilityChecker -> dealServiceClient: getDealData(dealUuids)
dealServiceClient -> continuumDealService: GET /deals (HTTPS)
continuumDealService --> dealServiceClient: DealServiceResponse
dealServiceClient --> purchasabilityChecker: deal metadata
purchasabilityChecker -> inventoryServiceClient: checkAvailability(optionUuids)
inventoryServiceClient -> continuumGoodsInventoryService: POST /availability (HTTPS)
continuumGoodsInventoryService --> inventoryServiceClient: InventoryServiceResponse
inventoryServiceClient --> purchasabilityChecker: availability info
purchasabilityChecker --> cartService: CartWithCategorizedItems
cartService --> scsJtier_apiResource: CartContents
scsJtier_apiResource --> GAPI/Lazlo: 200 OK (application/json)
```

## Related

- Architecture dynamic view: `dynamic-scsJtier`
- Related flows: [Add or Update Cart Items](add-update-cart-items.md), [Remove Cart Items](remove-cart-items.md)
