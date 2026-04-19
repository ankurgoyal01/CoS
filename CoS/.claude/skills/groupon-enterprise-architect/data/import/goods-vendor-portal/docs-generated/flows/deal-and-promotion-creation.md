---
service: "goods-vendor-portal"
title: "Deal and Promotion Creation"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deal-and-promotion-creation"
flow_type: synchronous
trigger: "Merchant initiates a new deal or promotion from the deals section of the portal"
participants:
  - "emberApp"
  - "goodsVendorPortal_apiClient"
  - "continuumGoodsVendorPortalWeb"
  - "gpapiApi_unk_1d2b"
architecture_ref: "dynamic-deal-and-promotion-creation"
---

# Deal and Promotion Creation

## Summary

The Deal and Promotion Creation flow enables goods merchants to create new deals and promotional offers through the vendor portal. Merchants configure deal parameters (products, pricing, discount rates, validity periods) and submit them to GPAPI for persistence and downstream deal lifecycle processing. Promotions are associated with existing deals to apply time-limited discounts or special offers. Both flows follow the same proxy pattern through Nginx to GPAPI.

## Trigger

- **Type**: user-action
- **Source**: Authenticated merchant clicks "Create Deal" or "Create Promotion" in the deals section
- **Frequency**: On-demand; during active deal management periods

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant (browser) | Configures and submits the deal or promotion form | — |
| Ember UI | Renders deal/promotion creation forms, manages form validation and state | `emberApp` |
| API Client | Submits deal and promotion payloads to the proxy endpoints | `goodsVendorPortal_apiClient` |
| Nginx (portal) | Proxies deal and promotion requests to GPAPI | `continuumGoodsVendorPortalWeb` |
| GPAPI | Validates and persists deal and promotion records; manages deal lifecycle | `gpapiApi_unk_1d2b` |

## Steps

1. **Loads deals route**: Ember routes the merchant to the deals section; `emberApp` fetches the existing deals list via `GET /goods-gateway/deals`.
   - From: `goodsVendorPortal_apiClient`
   - To: `continuumGoodsVendorPortalWeb` (Nginx) → `gpapiApi_unk_1d2b`
   - Protocol: REST/HTTPS

2. **Renders deal list**: `emberApp` renders the list of existing deals with their statuses.
   - From: `emberApp`
   - To: Merchant browser
   - Protocol: In-browser rendering

3. **Initiates deal creation**: Merchant clicks "Create Deal"; Ember routes to the deal creation form.
   - From: Merchant browser
   - To: `emberApp`
   - Protocol: DOM event / Ember routing

4. **Loads product and pricing context**: `emberApp` fetches available products via `GET /goods-gateway/products` and pricing rules via `GET /goods-gateway/pricing` to populate deal form dropdowns.
   - From: `goodsVendorPortal_apiClient`
   - To: `continuumGoodsVendorPortalWeb` (Nginx) → `gpapiApi_unk_1d2b`
   - Protocol: REST/HTTPS

5. **Merchant completes deal form**: Merchant selects products, sets discount/price, configures validity dates, and optionally uploads deal assets via `POST /goods-gateway/files`.
   - From: Merchant browser
   - To: `emberApp`
   - Protocol: DOM events

6. **Submits deal**: `goodsVendorPortal_apiClient` issues `POST /goods-gateway/deals` with the complete deal payload.
   - From: `goodsVendorPortal_apiClient`
   - To: `continuumGoodsVendorPortalWeb` (Nginx)
   - Protocol: REST/HTTPS

7. **Proxies and persists deal**: Nginx forwards to GPAPI; GPAPI validates the deal configuration, persists the deal record, and initiates internal deal lifecycle processing.
   - From: `continuumGoodsVendorPortalWeb`
   - To: `gpapiApi_unk_1d2b`
   - Protocol: REST/HTTPS

8. **Returns created deal**: GPAPI responds with the created deal record including its assigned ID and status; `emberApp` updates the ember-data store and displays a success notification.
   - From: `gpapiApi_unk_1d2b`
   - To: `emberApp` (via Nginx and apiClient)
   - Protocol: REST/HTTPS

9. **Creates promotion (optional)**: If the merchant creates a promotion linked to the deal, `goodsVendorPortal_apiClient` issues `POST /goods-gateway/promotions` with the deal ID and promotion parameters.
   - From: `goodsVendorPortal_apiClient`
   - To: `continuumGoodsVendorPortalWeb` (Nginx) → `gpapiApi_unk_1d2b`
   - Protocol: REST/HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Validation error on deal form | GPAPI returns 422 with field-level errors; portal displays inline validation messages | Merchant corrects the form and resubmits |
| Product not eligible for deal | GPAPI returns a business rule error (422); portal surfaces the error message | Merchant must select a different product or adjust deal parameters |
| File upload fails for deal asset | `POST /goods-gateway/files` errors; portal shows upload failure message | Deal save is blocked; merchant must resolve the upload before submitting |
| GPAPI unavailable | Nginx returns 502/503; portal displays a generic error banner | Deal is not created; merchant may retry |
| Deal update conflict | `PUT /goods-gateway/deals/:id` returns 409; portal informs the merchant of a conflicting update | Merchant refreshes to see latest state and resubmits |

## Sequence Diagram

```
Merchant -> emberApp: Clicks "Create Deal"
emberApp -> goodsVendorPortal_apiClient: Fetch products and pricing context
goodsVendorPortal_apiClient -> continuumGoodsVendorPortalWeb: GET /goods-gateway/products, /goods-gateway/pricing
continuumGoodsVendorPortalWeb -> gpapiApi_unk_1d2b: GET /products, /pricing (proxied)
gpapiApi_unk_1d2b --> continuumGoodsVendorPortalWeb: Product and pricing data
continuumGoodsVendorPortalWeb --> goodsVendorPortal_apiClient: Proxy responses
goodsVendorPortal_apiClient --> emberApp: Populate form dropdowns
Merchant -> emberApp: Submits completed deal form
goodsVendorPortal_apiClient -> continuumGoodsVendorPortalWeb: POST /goods-gateway/deals
continuumGoodsVendorPortalWeb -> gpapiApi_unk_1d2b: POST /deals (proxied)
gpapiApi_unk_1d2b --> continuumGoodsVendorPortalWeb: 201 Created { deal }
continuumGoodsVendorPortalWeb --> goodsVendorPortal_apiClient: Proxy response
goodsVendorPortal_apiClient --> emberApp: Update store, show confirmation
emberApp --> Merchant: "Deal created successfully"
```

## Related

- Architecture dynamic view: `dynamic-deal-and-promotion-creation`
- Related flows: [Product Catalog Management](product-catalog-management.md), [Contract and Agreement Management](contract-and-agreement-management.md)
