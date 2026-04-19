---
service: "pricing-control-center-ui"
title: "Custom Sale Creation"
generated: "2026-03-03"
type: flow
flow_name: "custom-sale-creation"
flow_type: synchronous
trigger: "Authenticated operator submits the custom sale creation form"
participants:
  - "continuumPricingControlCenterUi"
  - "pricingControlCenterJtierApi_9b3f4a1e"
architecture_ref: "dynamic-pccUiAuthAndSearchFlow"
---

# Custom Sale Creation

## Summary

An authenticated pricing operator navigates to the custom sale creation form, enters sale metadata (name, start/end dates with timezones), and submits. The UI validates the session, posts the data to `pricing-control-center-jtier` at `POST /custom-sales`, and returns the newly created sale object as JSON. Optionally, the operator can request the Custom ILS Flux Model for a given start date to inform sale planning.

## Trigger

- **Type**: user-action
- **Source**: Operator navigates to `GET /custom-sale-new` and submits the form via `POST /custom-sale-post`
- **Frequency**: On-demand (per sale creation action)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser (operator) | Navigates to form; submits sale data | N/A |
| Pricing Control Center UI | Serves form page; accepts POST; calls jtier to create sale | `continuumPricingControlCenterUi` |
| pricing-control-center-jtier | Creates the custom sale record and returns the result | `pricingControlCenterJtierApi_9b3f4a1e` |

## Steps

1. **Render custom sale form**: Authenticated operator requests `GET /custom-sale-new`.
   - From: Browser
   - To: `continuumPricingControlCenterUi` (`routeAndPageHandlers`)
   - Protocol: HTTPS

2. **Guard check**: Route handler validates `authn_token` cookie; if absent, redirects to `homeMain` (`/`).
   - From: `routeAndPageHandlers`
   - To: `authRedirectGateway`
   - Protocol: Direct (in-process)

3. **Serve custom sale creation form**: `pageCompositionRenderer` renders the custom sale Preact page passing `user` and `authn_token` as props.
   - From: `continuumPricingControlCenterUi`
   - To: Browser
   - Protocol: HTTPS (200 text/html)

4. **Optionally fetch Custom ILS Flux Model**: Client-side JavaScript calls `GET /customILSFluxModel?startDate=<date>` for sale scheduling guidance.
   - From: Browser (in-page fetch)
   - To: `continuumPricingControlCenterUi` (which proxies to jtier `GET /customILSFluxModel?startDate=<date>`)
   - Protocol: HTTPS/JSON

5. **Operator submits sale form**: Browser posts `POST /custom-sale-post` with JSON body: `{ saleName, startDate, endDate, startTimezone, endTimezone }`.
   - From: Browser
   - To: `continuumPricingControlCenterUi` (`routeAndPageHandlers` — `custom-sale-new#upload`)
   - Protocol: HTTPS/JSON

6. **Call jtier to create custom sale**: `pricingControlCenterApiClient.createCustomSale()` posts to `POST /custom-sales` with the sale payload and `authn-token` header (10,000 ms timeout).
   - From: `pricingControlCenterApiClient`
   - To: `pricingControlCenterJtierApi_9b3f4a1e`
   - Protocol: HTTPS/JSON (Content-Type: application/json)

7. **Return creation result**: jtier returns the created sale object; UI returns it as JSON to the browser.
   - From: `pricingControlCenterJtierApi_9b3f4a1e`
   - To: `continuumPricingControlCenterUi`
   - Protocol: HTTPS/JSON

8. **Browser renders confirmation**: Browser receives the JSON result and updates the UI to reflect the new sale.
   - From: `continuumPricingControlCenterUi`
   - To: Browser
   - Protocol: HTTPS (200 application/json)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing `authn_token` cookie on form load | Redirect to `homeMain` (`/`) | User must re-authenticate |
| Missing `authn_token` cookie on POST | Redirect to `homeMain` (`/`) | Submission rejected; user redirected |
| jtier returns error on `POST /custom-sales` | Exception caught; JSON error returned | Error surfaced to operator in browser |
| Connect timeout (10,000 ms) | Exception caught; JSON error returned | Operator informed of timeout |

## Sequence Diagram

```
Browser -> PricingControlCenterUI: GET /custom-sale-new (authn_token cookie)
PricingControlCenterUI -> PricingControlCenterUI: validate authn_token
PricingControlCenterUI --> Browser: 200 custom sale form HTML
Browser -> PricingControlCenterUI: GET /customILSFluxModel?startDate=<date> (optional)
PricingControlCenterUI -> pricingControlCenterJtier: GET /customILSFluxModel?startDate=<date>
pricingControlCenterJtier --> PricingControlCenterUI: flux model JSON
PricingControlCenterUI --> Browser: 200 flux model JSON
Browser -> PricingControlCenterUI: POST /custom-sale-post {saleName, startDate, endDate, startTimezone, endTimezone}
PricingControlCenterUI -> pricingControlCenterJtier: POST /custom-sales {name, startTime, endTime, startTimezone, endTimezone}
pricingControlCenterJtier --> PricingControlCenterUI: created sale JSON
PricingControlCenterUI --> Browser: 200 created sale JSON
```

## Related

- Architecture dynamic view: `dynamic-pccUiAuthAndSearchFlow`
- Related flows: [Manual ILS CSV Upload](manual-ils-csv-upload.md), [Sale Lifecycle Management](sale-lifecycle-management.md)
