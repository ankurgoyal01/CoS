---
service: "pricing-control-center-ui"
title: "Product Search"
generated: "2026-03-03"
type: flow
flow_name: "product-search"
flow_type: synchronous
trigger: "Authenticated operator requests the search page or submits an inventory_product_id query"
participants:
  - "continuumPricingControlCenterUi"
  - "pricingControlCenterJtierApi_9b3f4a1e"
architecture_ref: "dynamic-pccUiAuthAndSearchFlow"
---

# Product Search

## Summary

An authenticated pricing operator navigates to the search page, enters an `inventory_product_id`, and submits the search. The UI renders a result page by making two parallel calls to `pricing-control-center-jtier`: one for product details (`GET /search/{inventory_product_id}`) and one for price history (`GET /pricehistory?inventory_product_id=...&productType=DEAL_OPTION_INVENTORY_UUID`). Results are composed into a Preact server-rendered HTML page returned to the browser.

## Trigger

- **Type**: user-action
- **Source**: Operator navigates to `/search-box-jtier` and submits a search; browser requests `GET /search-result?inventory_product_id=<id>`
- **Frequency**: On-demand (per search action)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser (operator) | Initiates search; displays results | N/A |
| Pricing Control Center UI | Receives search request; calls jtier; renders result page | `continuumPricingControlCenterUi` |
| pricing-control-center-jtier | Provides product data and price history | `pricingControlCenterJtierApi_9b3f4a1e` |

## Steps

1. **Render search input page**: Authenticated operator requests `GET /search-box-jtier`.
   - From: Browser
   - To: `continuumPricingControlCenterUi` (`routeAndPageHandlers`)
   - Protocol: HTTPS

2. **Guard check**: Route handler validates `authn_token` cookie is present; if absent, redirects to home (`/`).
   - From: `routeAndPageHandlers`
   - To: `authRedirectGateway`
   - Protocol: Direct (in-process)

3. **Serve search form page**: `pageCompositionRenderer` renders the search input Preact page with user and token context.
   - From: `continuumPricingControlCenterUi`
   - To: Browser
   - Protocol: HTTPS (200 text/html)

4. **Submit search query**: Operator enters `inventory_product_id` and submits; browser requests `GET /search-result?inventory_product_id=<id>`.
   - From: Browser
   - To: `continuumPricingControlCenterUi` (`routeAndPageHandlers`)
   - Protocol: HTTPS

5. **Fetch product details from jtier**: `pricingControlCenterApiClient` calls `GET /search/{inventory_product_id}` with `authn-token` header (10,000 ms timeout).
   - From: `pricingControlCenterApiClient`
   - To: `pricingControlCenterJtierApi_9b3f4a1e`
   - Protocol: HTTPS/JSON

6. **Fetch price history from jtier**: `pricingControlCenterApiClient` calls `GET /pricehistory?inventory_product_id=<id>&productType=DEAL_OPTION_INVENTORY_UUID` with `authn-token` header (10,000 ms timeout).
   - From: `pricingControlCenterApiClient`
   - To: `pricingControlCenterJtierApi_9b3f4a1e`
   - Protocol: HTTPS/JSON

7. **Compose and render result page**: `pageCompositionRenderer` composes product data and price history into the search result Preact view and returns the rendered HTML.
   - From: `continuumPricingControlCenterUi`
   - To: Browser
   - Protocol: HTTPS (200 text/html)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing `authn_token` cookie | Redirect to `homeMain` (`/`) | User is prompted to authenticate |
| jtier returns error on product lookup | JSON error object propagated; UI renders error state | Error displayed in search result page |
| jtier returns error on price history | JSON error object propagated; UI renders error state | Error displayed in price history section |
| Connect timeout (10,000 ms exceeded) | Exception caught and returned as JSON error | Error displayed to operator |

## Sequence Diagram

```
Browser -> PricingControlCenterUI: GET /search-box-jtier (authn_token cookie)
PricingControlCenterUI -> PricingControlCenterUI: validate authn_token
PricingControlCenterUI --> Browser: 200 search form HTML
Browser -> PricingControlCenterUI: GET /search-result?inventory_product_id=<id>
PricingControlCenterUI -> pricingControlCenterJtier: GET /search/<id> (authn-token: <token>)
PricingControlCenterUI -> pricingControlCenterJtier: GET /pricehistory?inventory_product_id=<id>&productType=DEAL_OPTION_INVENTORY_UUID
pricingControlCenterJtier --> PricingControlCenterUI: product details JSON
pricingControlCenterJtier --> PricingControlCenterUI: price history JSON
PricingControlCenterUI --> Browser: 200 search result HTML
```

## Related

- Architecture dynamic view: `dynamic-pccUiAuthAndSearchFlow` (disabled pending external stub federation)
- Related flows: [Authentication and Token Handoff](authentication-token-handoff.md), [Sale Lifecycle Management](sale-lifecycle-management.md)
