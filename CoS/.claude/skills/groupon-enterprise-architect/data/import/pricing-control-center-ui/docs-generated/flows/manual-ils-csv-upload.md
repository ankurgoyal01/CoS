---
service: "pricing-control-center-ui"
title: "Manual ILS CSV Upload"
generated: "2026-03-03"
type: flow
flow_name: "manual-ils-csv-upload"
flow_type: synchronous
trigger: "Authenticated operator uploads a CSV file via the manual sale form"
participants:
  - "continuumPricingControlCenterUi"
  - "pricingControlCenterJtierApi_9b3f4a1e"
architecture_ref: "dynamic-pccUiAuthAndSearchFlow"
---

# Manual ILS CSV Upload

## Summary

An authenticated pricing operator navigates to the manual sale page (`/manual-sale-new`), selects an ILS (Inventory and Listing Service) CSV price file, and uploads it. The UI proxies the multipart form upload directly to `pricing-control-center-jtier` at `POST /ils_upload`, forwarding the stream body and Doorman token. The jtier service processes the file and returns a JSON result indicating success or failure. This flow replaces manual data entry with bulk CSV-driven pricing updates.

## Trigger

- **Type**: user-action
- **Source**: Operator navigates to `GET /manual-sale-new` and uploads a CSV file via `POST /manual-sale-post/upload-proxy`
- **Frequency**: On-demand (per upload action)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser (operator) | Navigates to upload page; selects and uploads CSV | N/A |
| Pricing Control Center UI | Serves upload form; proxies multipart stream to jtier | `continuumPricingControlCenterUi` |
| pricing-control-center-jtier | Receives and processes the ILS CSV upload | `pricingControlCenterJtierApi_9b3f4a1e` |

## Steps

1. **Render manual sale upload page**: Authenticated operator requests `GET /manual-sale-new`.
   - From: Browser
   - To: `continuumPricingControlCenterUi` (`routeAndPageHandlers`)
   - Protocol: HTTPS

2. **Guard check**: Route handler validates `authn_token` cookie; if absent, redirects to `homeMain` (`/`).
   - From: `routeAndPageHandlers`
   - To: `authRedirectGateway`
   - Protocol: Direct (in-process)

3. **Serve upload page with channel context**: `pageCompositionRenderer` renders the manual sale Preact page, passing `channels` (extracted from `user` cookie) to filter available sale channels.
   - From: `continuumPricingControlCenterUi`
   - To: Browser
   - Protocol: HTTPS (200 text/html)

4. **Operator selects and uploads CSV**: Operator selects a CSV file and submits the multipart form via `POST /manual-sale-post/upload-proxy`.
   - From: Browser
   - To: `continuumPricingControlCenterUi` (`routeAndPageHandlers` — `manual-sale-new#proxy`)
   - Protocol: HTTPS multipart/form-data

5. **Proxy upload to jtier**: `pricingControlCenterApiClient.proxyUpload()` forwards the request body stream to `POST /ils_upload` on jtier, passing the `authn-token` and `content-type` headers. The request body is streamed directly (not buffered).
   - From: `pricingControlCenterApiClient`
   - To: `pricingControlCenterJtierApi_9b3f4a1e`
   - Protocol: HTTPS multipart/form-data

6. **jtier processes upload**: jtier receives and processes the CSV, triggering ILS pricing ingestion.
   - From: `pricingControlCenterJtierApi_9b3f4a1e`
   - Internal processing
   - Protocol: N/A

7. **Return upload result**: jtier returns a JSON result; UI returns it to the browser.
   - From: `pricingControlCenterJtierApi_9b3f4a1e`
   - To: `continuumPricingControlCenterUi`
   - Protocol: HTTPS/JSON

8. **Browser displays result**: Browser receives JSON and updates the upload UI with success or error details.
   - From: `continuumPricingControlCenterUi`
   - To: Browser
   - Protocol: HTTPS (200 application/json)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing `authn_token` cookie on form load | Redirect to `homeMain` (`/`) | User must re-authenticate |
| jtier upload endpoint error | Exception caught; JSON error returned to browser | Operator sees error message; may retry |
| Malformed or oversized CSV | jtier returns error; propagated as JSON | Operator informed of file format issue |
| Connect timeout (10,000 ms) | Exception caught; JSON error returned | Operator informed of timeout |

## Sequence Diagram

```
Browser -> PricingControlCenterUI: GET /manual-sale-new (authn_token cookie)
PricingControlCenterUI -> PricingControlCenterUI: validate authn_token; extract channels from user cookie
PricingControlCenterUI --> Browser: 200 upload form HTML (with channel options)
Browser -> PricingControlCenterUI: POST /manual-sale-post/upload-proxy (multipart/form-data CSV)
PricingControlCenterUI -> pricingControlCenterJtier: POST /ils_upload (stream body, authn-token: <token>, content-type: multipart/...)
pricingControlCenterJtier -> pricingControlCenterJtier: process ILS CSV
pricingControlCenterJtier --> PricingControlCenterUI: upload result JSON
PricingControlCenterUI --> Browser: 200 upload result JSON
```

## Related

- Architecture dynamic view: `dynamic-pccUiAuthAndSearchFlow`
- Related flows: [Custom Sale Creation](custom-sale-creation.md), [Sale Lifecycle Management](sale-lifecycle-management.md)
