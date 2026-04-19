---
service: "goods-inventory-service-routing"
title: "Get Inventory Products (Read Routing)"
generated: "2026-03-03"
type: flow
flow_name: "get-inventory-products"
flow_type: synchronous
trigger: "HTTP GET /inventory/v1/products?ids=<uuid>[,<uuid>,...] from an upstream Groupon service"
participants:
  - "continuumGoodsInventoryServiceRouting"
  - "continuumGoodsInventoryServiceRoutingDb"
  - "continuumGoodsInventoryService"
architecture_ref: "dynamic-continuumGoodsInventoryServiceRouting"
---

# Get Inventory Products (Read Routing)

## Summary

This flow handles read requests for one or more inventory products by their UUIDs. The routing service looks up the previously recorded shipping regions for the requested UUIDs from its local PostgreSQL store, resolves which regional GIS endpoint owns those products, and forwards the GET request to that endpoint. The GIS response (status + body) is streamed back to the caller unchanged.

## Trigger

- **Type**: api-call
- **Source**: Upstream Groupon backend service (HTTP client)
- **Frequency**: On demand, per consumer request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Routing API Resource | Receives inbound GET, validates `ids` parameter, orchestrates routing lookup and GIS proxy | `continuumGoodsInventoryServiceRouting` / `routingResource` |
| Routing Service | Queries local DB for shipping regions; resolves GIS region from shipping regions | `continuumGoodsInventoryServiceRouting` / `routingService` |
| Inventory Product Shipping Regions DAO | Executes SQL SELECT against `inventory_product_shipping_regions` | `continuumGoodsInventoryServiceRouting` / `inventoryProductShippingRegionsDao` |
| GIS Client | Constructs and executes HTTP GET to the resolved regional GIS | `continuumGoodsInventoryServiceRouting` / `gisClient` |
| Goods Inventory Service (regional) | Returns the canonical inventory product data | `continuumGoodsInventoryService` |
| Routing DB | Stores product-to-shipping-region index | `continuumGoodsInventoryServiceRoutingDb` |

## Steps

1. **Receive GET request**: Upstream caller sends `GET /inventory/v1/products?ids=<uuid>[,<uuid>,...]` to the routing service.
   - From: upstream caller
   - To: `routingResource`
   - Protocol: REST (HTTP)

2. **Validate `ids` parameter**: Routing resource checks that `ids` is present and non-empty; parses the comma-separated string into a `List<UUID>`. Returns HTTP 400 with `MISSING_PRODUCT_ID` or `INVALID_PRODUCT_ID` if validation fails.
   - From: `routingResource`
   - To: (local validation, no network call)
   - Protocol: in-process

3. **Look up shipping regions for UUIDs**: Routing service queries the DAO for all `inventory_product_shipping_regions` rows matching the provided UUIDs.
   - From: `routingService`
   - To: `inventoryProductShippingRegionsDao` → `continuumGoodsInventoryServiceRoutingDb`
   - Protocol: JDBC (SQL SELECT)

4. **Resolve GIS region**: Routing service reads the first shipping region from the first result row, finds the matching `GisRegion` config entry, and validates that all products' shipping regions belong to the same region. Returns `Either.left(ERROR_INVENTORY_PRODUCT_NOT_FOUND)` if the DB had no rows, `ERROR_NO_GIS_REGION_FOUND` if no configured region matches, or `ERROR_MIXED_SHIPPING_REGIONS` if products span multiple regions.
   - From: `routingService`
   - To: (in-process, config lookup)
   - Protocol: in-process

5. **Forward GET to regional GIS**: GIS client builds the URL `http://{gisRegion.gisUrl}/inventory/v1/products?{original query params}`, injects `X-HB-Region: {hybridBoundaryRegion}`, propagates all other caller headers (except `host` and `accept-encoding`), and executes the HTTP GET.
   - From: `gisClient`
   - To: `continuumGoodsInventoryService`
   - Protocol: HTTP GET

6. **Return GIS response**: GIS client captures the response status code and body and returns them as a `GisResponse`. Routing resource builds an HTTP response with the same status and body and returns it to the upstream caller.
   - From: `continuumGoodsInventoryService` → `gisClient` → `routingResource`
   - To: upstream caller
   - Protocol: REST (HTTP)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `ids` param missing or empty | Return immediately with HTTP 400 | `{"httpCode":400,"errors":[{"code":"MISSING_PRODUCT_ID",...}]}` |
| `ids` cannot be parsed as UUIDs | Return immediately with HTTP 400 | `{"httpCode":400,"errors":[{"code":"INVALID_PRODUCT_ID",...}]}` |
| No shipping-region record in DB | Return HTTP 200 with empty `inventoryProducts` | `EmptyInventoryProductsResponse` — GIS is not called |
| No configured GIS region matches | Return HTTP 400 | `{"httpCode":400,"errors":[{"code":"NO_GIS_REGION_FOUND",...}]}` |
| Products span multiple regions | Return HTTP 400 | `{"httpCode":400,"errors":[{"code":"MIXED_SHIPPING_REGIONS",...}]}` |
| GIS call throws IOException | Return HTTP 500 | `{"httpCode":500,"errors":[{"code":"UNABLE_TO_REACH_GIS",...}]}` |

## Sequence Diagram

```
Caller -> routingResource: GET /inventory/v1/products?ids=<uuid>
routingResource -> routingService: getGisRegionByUUID([uuid])
routingService -> inventoryProductShippingRegionsDao: get([uuid])
inventoryProductShippingRegionsDao -> RoutingDB: SELECT ... WHERE inventory_product_uuid = ANY(...)
RoutingDB --> inventoryProductShippingRegionsDao: [InventoryProductShippingRegions]
inventoryProductShippingRegionsDao --> routingService: [InventoryProductShippingRegions]
routingService --> routingResource: Either.right(GisRegion)
routingResource -> gisClient: getInventoryProduct(gisRegion, headers, queryParams)
gisClient -> GoodsInventoryService: GET http://{gisUrl}/inventory/v1/products?ids=<uuid> [X-HB-Region: us-central1]
GoodsInventoryService --> gisClient: HTTP 200 {inventoryProducts:[...]}
gisClient --> routingResource: Either.right(GisResponse{200, body})
routingResource --> Caller: HTTP 200 {inventoryProducts:[...]}
```

## Related

- Architecture dynamic view: `dynamic-continuumGoodsInventoryServiceRouting`
- Related flows: [Upsert Inventory Products](upsert-inventory-products.md), [Update Inventory Product](update-inventory-product.md)
