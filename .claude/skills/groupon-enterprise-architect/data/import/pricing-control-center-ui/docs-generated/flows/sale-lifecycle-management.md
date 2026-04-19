---
service: "pricing-control-center-ui"
title: "Sale Lifecycle Management"
generated: "2026-03-03"
type: flow
flow_name: "sale-lifecycle-management"
flow_type: synchronous
trigger: "Authenticated operator views a sale detail page and triggers a lifecycle action"
participants:
  - "continuumPricingControlCenterUi"
  - "pricingControlCenterJtierApi_9b3f4a1e"
architecture_ref: "dynamic-pccUiAuthAndSearchFlow"
---

# Sale Lifecycle Management

## Summary

The sale detail view (`/sale-uploader-show`) is the primary control plane for managing individual sales. Operators load a sale by `sale_id`, view its current state (progress counts, exclusion reasons), and can trigger lifecycle transitions: schedule, unschedule, cancel, retry (for stuck sales), or unschedule specific products. Each action posts to the corresponding `pricing-control-center-jtier` endpoint, and the result is returned as JSON to update the page without a full reload. Operators can also download the original sale CSV from this view.

## Trigger

- **Type**: user-action
- **Source**: Operator navigates to `GET /sale-uploader-show?sale_id=<id>` and clicks a lifecycle action button
- **Frequency**: On-demand (per operator action)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser (operator) | Views sale detail; triggers lifecycle actions | N/A |
| Pricing Control Center UI | Serves sale detail page; proxies lifecycle actions to jtier | `continuumPricingControlCenterUi` |
| pricing-control-center-jtier | Executes sale lifecycle transitions; returns updated state | `pricingControlCenterJtierApi_9b3f4a1e` |

## Steps

1. **Render sale list page**: Operator navigates to `GET /sale-uploader` to view the list of all sales.
   - From: Browser
   - To: `continuumPricingControlCenterUi` (`routeAndPageHandlers`)
   - Protocol: HTTPS

2. **Fetch all sales**: The page loads the sales list by calling `GET /sales` on jtier (via `pricingControlCenterApiClient.listAllSales()`).
   - From: `pricingControlCenterApiClient`
   - To: `pricingControlCenterJtierApi_9b3f4a1e`
   - Protocol: HTTPS/JSON

3. **Navigate to sale detail**: Operator clicks a sale to navigate to `GET /sale-uploader-show?sale_id=<id>`.
   - From: Browser
   - To: `continuumPricingControlCenterUi` (`routeAndPageHandlers`)
   - Protocol: HTTPS

4. **Load sale detail data**: In-page JavaScript calls the following jtier endpoints in parallel via the UI's data routes:
   - `GET /sales/{sale_id}` — fetches sale detail
   - `GET /sales/{sale_id}/progress` — fetches progress counts
   - `GET /sales/{sale_id}/exclusion_reasons` — fetches exclusion reasons
   - From: `pricingControlCenterApiClient`
   - To: `pricingControlCenterJtierApi_9b3f4a1e`
   - Protocol: HTTPS/JSON

5. **Operator triggers lifecycle action**: Operator clicks Schedule / Unschedule / Cancel / Retry / Unschedule Products. Browser sends a request to the appropriate UI endpoint.

   | Action | UI Endpoint | jtier Endpoint |
   |--------|------------|----------------|
   | Schedule | in-page API call | `POST /sales/{sale_id}/schedule` |
   | Unschedule | in-page API call | `POST /sales/{sale_id}/unschedule` |
   | Cancel | in-page API call | `POST /sales/{sale_id}/cancel` |
   | Retry stuck | in-page API call | `POST /sales/{sale_id}/retry` |
   | Unschedule products | in-page API call | `POST /sales/{sale_id}/unschedule-products?productIds=<ids>` (with `userEmail` header) |

   - From: Browser
   - To: `continuumPricingControlCenterUi` (`routeAndPageHandlers`)
   - Protocol: HTTPS/JSON

6. **Forward action to jtier**: `pricingControlCenterApiClient` calls the corresponding jtier endpoint with `authn-token` header and empty JSON body (10,000 ms timeout).
   - From: `pricingControlCenterApiClient`
   - To: `pricingControlCenterJtierApi_9b3f4a1e`
   - Protocol: HTTPS/JSON

7. **Return result**: jtier returns the updated sale state or success confirmation. UI returns it as JSON to the browser.
   - From: `continuumPricingControlCenterUi`
   - To: Browser
   - Protocol: HTTPS (200 application/json)

8. **Download sale CSV** (optional): Operator requests `GET /sale-csv-download?sale_id=<id>`. UI calls `GET /download/original/{sale_id}` on jtier and streams the response back as `text/csv`.
   - From: `pricingControlCenterApiClient`
   - To: `pricingControlCenterJtierApi_9b3f4a1e`
   - Protocol: HTTPS streaming

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing `authn_token` cookie on page load | Redirect to `homeMain` (`/`) | User must re-authenticate |
| jtier returns error on any lifecycle action | Exception caught; JSON error returned | Operator sees error; action not applied |
| jtier returns error on sale detail load | JSON error propagated; page renders partial data | Operator informed; may retry |
| Connect timeout (10,000 ms) | Exception caught; JSON error returned | Operator informed of timeout |

## Sequence Diagram

```
Browser -> PricingControlCenterUI: GET /sale-uploader-show?sale_id=<id>
PricingControlCenterUI -> PricingControlCenterUI: validate authn_token
PricingControlCenterUI --> Browser: 200 sale detail HTML
Browser -> PricingControlCenterUI: in-page fetch: GET /sales/<id>/detail
PricingControlCenterUI -> pricingControlCenterJtier: GET /sales/<id>
PricingControlCenterUI -> pricingControlCenterJtier: GET /sales/<id>/progress
PricingControlCenterUI -> pricingControlCenterJtier: GET /sales/<id>/exclusion_reasons
pricingControlCenterJtier --> PricingControlCenterUI: sale data JSON
PricingControlCenterUI --> Browser: sale data JSON
Browser -> PricingControlCenterUI: POST lifecycle action (e.g., schedule)
PricingControlCenterUI -> pricingControlCenterJtier: POST /sales/<id>/schedule (authn-token)
pricingControlCenterJtier --> PricingControlCenterUI: result JSON
PricingControlCenterUI --> Browser: 200 result JSON
```

## Related

- Architecture dynamic view: `dynamic-pccUiAuthAndSearchFlow`
- Related flows: [Custom Sale Creation](custom-sale-creation.md), [Manual ILS CSV Upload](manual-ils-csv-upload.md), [Product Search](product-search.md)
