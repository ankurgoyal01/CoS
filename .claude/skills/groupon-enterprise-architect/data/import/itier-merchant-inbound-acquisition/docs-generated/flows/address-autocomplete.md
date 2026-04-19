---
service: "itier-merchant-inbound-acquisition"
title: "Address Autocomplete"
generated: "2026-03-03"
type: flow
flow_name: "address-autocomplete"
flow_type: synchronous
trigger: "User types into the city/address field in the merchant signup form"
participants:
  - "Browser (prospective merchant)"
  - "miaWebRoutes"
  - "miaLeadAndValidationHandlers"
  - "miaIntegrationClients"
  - "continuumApiLazloService"
architecture_ref: "components-merchant-inbound-acquisition-service"
---

# Address Autocomplete

## Summary

This flow proxies address autocomplete suggestions from Groupon's V2 address API (`continuumApiLazloService`) to the merchant signup form's city/address type-ahead field. It enables merchants to find and confirm their business location. A second endpoint retrieves full place details once the merchant selects a suggestion, populating the remaining address fields in the form.

## Trigger

- **Type**: user-action
- **Source**: Browser fires debounced AJAX call to `GET /merchant/inbound/api/geo` as the merchant types; fires `GET /merchant/inbound/api/place` when a suggestion is selected
- **Frequency**: Per keystroke (debounced client-side); once per place selection

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser (prospective merchant) | Types in address field; selects a suggestion | — |
| Web Routes and Page Composition | Routes `GET /merchant/inbound/api/geo` and `GET /merchant/inbound/api/place` | `miaWebRoutes` |
| Lead and Validation Handlers | `geo.js` and `place.js` handlers call the grouponV2 address autocomplete client | `miaLeadAndValidationHandlers` |
| Integration Clients | Holds `grouponV2.addressAutocomplete` client reference | `miaIntegrationClients` |
| Groupon V2 Address API | Returns address suggestions and place details | `continuumApiLazloService` |

## Steps

### Autocomplete Suggestions

1. **Type-ahead query**: Browser sends `GET /merchant/inbound/api/geo?input=<text>&lat=<lat>&lng=<lng>&session_token=<token>&locale=<locale>&type=<type>`.
   - From: Browser
   - To: `miaWebRoutes`
   - Protocol: REST / HTTPS

2. **Delegate to geo handler**: Route handler invokes `geo(_params, deps)` from `modules/index/js/geo.js`.
   - From: `miaWebRoutes`
   - To: `miaLeadAndValidationHandlers`
   - Protocol: In-process function call

3. **Call Groupon V2 address autocomplete**: `grouponV2.addressAutocomplete.results({ input, lat, lng, session_token, locale, type }).json()` is called via `itier-groupon-v2-client`.
   - From: `miaIntegrationClients`
   - To: `continuumApiLazloService`
   - Protocol: REST via `itier-groupon-v2-client`

4. **Return suggestions to browser**: On success, address suggestions JSON is returned; request metadata is logged with `itier-tracing`. On failure, `{ message }` error JSON is returned.
   - From: `continuumApiLazloService`
   - To: Browser
   - Protocol: REST JSON

### Place Details

1. **Place selection**: Browser sends `GET /merchant/inbound/api/place?placeid=<id>&session_token=<token>` after merchant selects an autocomplete suggestion.
   - From: Browser
   - To: `miaWebRoutes`
   - Protocol: REST / HTTPS

2. **Delegate to place handler**: Route handler invokes `place(_params, deps)` from `modules/index/js/place.js`.
   - From: `miaWebRoutes`
   - To: `miaLeadAndValidationHandlers`
   - Protocol: In-process function call

3. **Call Groupon V2 place details**: `grouponV2.addressAutocomplete.details({ place_id, session_token }).json()` retrieves full address components.
   - From: `miaIntegrationClients`
   - To: `continuumApiLazloService`
   - Protocol: REST via `itier-groupon-v2-client`

4. **Populate form fields**: Place details JSON returned to browser; form auto-fills street, city, postal code, state fields.
   - From: `continuumApiLazloService`
   - To: Browser
   - Protocol: REST JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Groupon V2 API unavailable | Exception caught in handler; `itier-tracing` error logged; `{ message }` JSON returned | Autocomplete suggestions disappear; merchant can still type address manually |
| Invalid session token | Error propagated from upstream API | Browser receives error JSON; form degrades gracefully |
| Missing `input` parameter | Handled by upstream API response | Empty suggestions list returned |

## Sequence Diagram

```
Browser -> miaWebRoutes: GET /merchant/inbound/api/geo?input=<text>&session_token=<token>
miaWebRoutes -> miaLeadAndValidationHandlers: geo(params, deps)
miaLeadAndValidationHandlers -> continuumApiLazloService: addressAutocomplete.results({ input, lat, lng, session_token, locale, type })
continuumApiLazloService --> miaLeadAndValidationHandlers: address suggestions JSON
miaLeadAndValidationHandlers --> Browser: JSON suggestions

Browser -> miaWebRoutes: GET /merchant/inbound/api/place?placeid=<id>&session_token=<token>
miaWebRoutes -> miaLeadAndValidationHandlers: place(params, deps)
miaLeadAndValidationHandlers -> continuumApiLazloService: addressAutocomplete.details({ place_id, session_token })
continuumApiLazloService --> miaLeadAndValidationHandlers: place details JSON
miaLeadAndValidationHandlers --> Browser: JSON place details (street, city, postal code, state)
```

## Related

- Architecture ref: `continuumApiLazloService`
- Related flows: [Lead Capture — Account Creation Path](lead-capture-account-creation.md)
- See [Integrations](../integrations.md) for Groupon V2 client configuration
