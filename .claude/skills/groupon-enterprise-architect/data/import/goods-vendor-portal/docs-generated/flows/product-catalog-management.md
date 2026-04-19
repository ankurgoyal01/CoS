---
service: "goods-vendor-portal"
title: "Product Catalog Management"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "product-catalog-management"
flow_type: synchronous
trigger: "Merchant navigates to the catalog section and performs create, edit, or browse actions"
participants:
  - "emberApp"
  - "goodsVendorPortal_apiClient"
  - "continuumGoodsVendorPortalWeb"
  - "gpapiApi_unk_1d2b"
architecture_ref: "dynamic-product-catalog-management"
---

# Product Catalog Management

## Summary

The Product Catalog Management flow enables goods merchants to browse their existing product inventory, create new product listings, and update product details such as descriptions, pricing, images, and availability. All catalog data is stored in GPAPI; the portal fetches, displays, and submits changes through the `/goods-gateway/products` proxy. File uploads (product images and assets) use the `/goods-gateway/files` endpoint.

## Trigger

- **Type**: user-action
- **Source**: Authenticated merchant navigates to the catalog section of the portal
- **Frequency**: On-demand; during normal merchant operations

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant (browser) | Browses, creates, and edits product listings | — |
| Ember UI | Renders catalog list and product detail/edit views; manages form state | `emberApp` |
| API Client | Issues HTTPS requests to the products and files proxy endpoints | `goodsVendorPortal_apiClient` |
| Nginx (portal) | Proxies product and file requests to GPAPI | `continuumGoodsVendorPortalWeb` |
| GPAPI | Persists and retrieves product catalog data | `gpapiApi_unk_1d2b` |

## Steps

1. **Loads catalog route**: Ember router transitions to the catalog route; `emberApp` initiates a product list fetch.
   - From: `emberApp`
   - To: `goodsVendorPortal_apiClient`
   - Protocol: In-process (ember-data model hook)

2. **Fetches product list**: `goodsVendorPortal_apiClient` issues `GET /goods-gateway/products` with optional pagination and filter query parameters.
   - From: `goodsVendorPortal_apiClient`
   - To: `continuumGoodsVendorPortalWeb` (Nginx)
   - Protocol: REST/HTTPS

3. **Proxies to GPAPI**: Nginx forwards the products request to GPAPI.
   - From: `continuumGoodsVendorPortalWeb`
   - To: `gpapiApi_unk_1d2b`
   - Protocol: REST/HTTPS

4. **Returns product list**: GPAPI returns paginated product records; Nginx proxies the response back to the portal.
   - From: `gpapiApi_unk_1d2b`
   - To: `goodsVendorPortal_apiClient` (via Nginx)
   - Protocol: REST/HTTPS

5. **Renders product list**: `emberApp` populates the ember-data store with the returned products and renders the catalog list view.
   - From: `emberApp`
   - To: Merchant browser
   - Protocol: In-browser rendering

6. **Navigates to create or edit**: Merchant clicks "Create Product" or selects an existing product; Ember routes to the product form.
   - From: Merchant browser
   - To: `emberApp`
   - Protocol: DOM event / Ember routing

7. **Submits product form**: Merchant completes the form and submits; `goodsVendorPortal_apiClient` issues `POST /goods-gateway/products` (create) or `PUT /goods-gateway/products/:id` (update).
   - From: `goodsVendorPortal_apiClient`
   - To: `continuumGoodsVendorPortalWeb` (Nginx)
   - Protocol: REST/HTTPS

8. **Uploads assets (optional)**: If the merchant attaches an image or file, a separate `POST /goods-gateway/files` request is issued to upload the asset before or during product submission.
   - From: `goodsVendorPortal_apiClient`
   - To: `continuumGoodsVendorPortalWeb` (Nginx) → `gpapiApi_unk_1d2b`
   - Protocol: REST/HTTPS (multipart form data)

9. **Persists and confirms**: GPAPI persists the product record and returns the created/updated resource; `emberApp` updates the ember-data store and displays a success notification.
   - From: `gpapiApi_unk_1d2b`
   - To: `emberApp` (via Nginx and apiClient)
   - Protocol: REST/HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Validation error from GPAPI | GPAPI returns 422 with field-level error details; portal displays inline validation messages on the form | Merchant corrects fields and resubmits |
| File upload fails | `POST /goods-gateway/files` returns an error; portal displays upload error | Merchant may retry the upload; product save is blocked until assets are resolved |
| GPAPI unavailable during save | 502/503 from Nginx proxy; portal shows generic error banner | Product is not saved; merchant may retry |
| Pagination / empty catalog | GPAPI returns an empty product list; portal renders an empty state with a prompt to create the first product | Normal UX — no error |

## Sequence Diagram

```
Merchant -> emberApp: Navigates to catalog
emberApp -> goodsVendorPortal_apiClient: Request product list
goodsVendorPortal_apiClient -> continuumGoodsVendorPortalWeb: GET /goods-gateway/products[?page[number]=N]
continuumGoodsVendorPortalWeb -> gpapiApi_unk_1d2b: GET /products (proxied)
gpapiApi_unk_1d2b --> continuumGoodsVendorPortalWeb: 200 OK { products[] }
continuumGoodsVendorPortalWeb --> goodsVendorPortal_apiClient: Proxy response
goodsVendorPortal_apiClient --> emberApp: Populate ember-data store
emberApp --> Merchant: Render catalog list
Merchant -> emberApp: Submit create/edit form
goodsVendorPortal_apiClient -> continuumGoodsVendorPortalWeb: POST/PUT /goods-gateway/products[/:id]
continuumGoodsVendorPortalWeb -> gpapiApi_unk_1d2b: POST/PUT /products (proxied)
gpapiApi_unk_1d2b --> continuumGoodsVendorPortalWeb: 201 Created / 200 OK { product }
continuumGoodsVendorPortalWeb --> goodsVendorPortal_apiClient: Proxy response
goodsVendorPortal_apiClient --> emberApp: Update store, show success
emberApp --> Merchant: Confirmation notification
```

## Related

- Architecture dynamic view: `dynamic-product-catalog-management`
- Related flows: [Deal and Promotion Creation](deal-and-promotion-creation.md), [Vendor Profile Self-Service](vendor-profile-self-service.md)
