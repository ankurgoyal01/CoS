---
service: "itier-merchant-inbound-acquisition"
title: "Field Deduplication Validation"
generated: "2026-03-03"
type: flow
flow_name: "field-deduplication"
flow_type: synchronous
trigger: "Form field loses focus (client-side blur event) or form is partially submitted"
participants:
  - "Browser (prospective merchant)"
  - "miaWebRoutes"
  - "miaLeadAndValidationHandlers"
  - "miaIntegrationClients"
  - "continuumMetroPlatform"
architecture_ref: "components-merchant-inbound-acquisition-service"
---

# Field Deduplication Validation

## Summary

This flow checks whether a merchant's entered field value (e.g. business name, email, or phone) already exists in the Metro draft service, detecting potential duplicate leads before full submission. The browser POSTs a single field type and value to the validation endpoint; the service proxies the check to Metro's `validateField` API and returns the deduplication result.

## Trigger

- **Type**: user-action
- **Source**: Browser sends `POST /merchant/inbound/api/validatefieldbyname` with a field `type` and `value`
- **Frequency**: Per field interaction (on demand)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser (prospective merchant) | Triggers field validation during form fill | — |
| Web Routes and Page Composition | Routes `POST /merchant/inbound/api/validatefieldbyname` to dedupe handler | `miaWebRoutes` |
| Lead and Validation Handlers | `dedupe.js` handler builds validation payload and calls Metro | `miaLeadAndValidationHandlers` |
| Integration Clients | Executes `metro.validateField()`; fires GA tracking event | `miaIntegrationClients` |
| Metro Platform | Checks field value for duplicate merchant records; returns validation result | `continuumMetroPlatform` |

## Steps

1. **Submit field for validation**: Browser sends `POST /merchant/inbound/api/validatefieldbyname` with body `{ type: "<fieldType>", value: "<fieldValue>" }`.
   - From: Browser
   - To: `miaWebRoutes`
   - Protocol: REST / HTTPS

2. **Delegate to dedupe handler**: Route handler invokes `dedupe(_params, deps)` from `modules/index/js/dedupe.js`.
   - From: `miaWebRoutes`
   - To: `miaLeadAndValidationHandlers`
   - Protocol: In-process function call

3. **Build validation payload**: `createDraftServiceDedupeData(request.body)` extracts `{ type, value }` from the request body.
   - From: `miaLeadAndValidationHandlers`
   - Protocol: In-process

4. **Call Metro validateField**: `metro.validateField(requestBody, { client_id, locale: metro.defaults.country })` is called via `@grpn/metro-client`.
   - From: `miaIntegrationClients`
   - To: `continuumMetroPlatform`
   - Protocol: REST via `@grpn/metro-client`

5. **Handle validation response**: On success, fire `web2dedupe-submit-draft success` GA event, log with `itier-tracing`, return Metro validation result JSON to browser. On failure, fire `web2dedupe-submit-draft error` GA event, log error, return `{ message }` JSON.
   - From: `continuumMetroPlatform`
   - To: Browser
   - Protocol: REST JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Metro validateField unavailable | Exception caught; error logged; `web2dedupe-submit-draft error` GA event fired | `{ message }` error JSON returned; form may proceed without deduplication check |
| Metro returns duplicate found | Validation result JSON returned to browser | Browser form displays duplicate warning to merchant |
| Missing field type/value | Passed through to Metro; Metro returns validation error | Error response propagated to browser |

## Sequence Diagram

```
Browser -> miaWebRoutes: POST /merchant/inbound/api/validatefieldbyname { type, value }
miaWebRoutes -> miaLeadAndValidationHandlers: dedupe(params, deps)
miaLeadAndValidationHandlers -> miaLeadAndValidationHandlers: createDraftServiceDedupeData({ type, value })
miaLeadAndValidationHandlers -> continuumMetroPlatform: metro.validateField({ type, value }, { client_id, locale })
continuumMetroPlatform --> miaLeadAndValidationHandlers: validation result JSON
miaLeadAndValidationHandlers -> GoogleAnalytics: visitor.event('web2dedupe-submit-draft', 'success').send()
miaLeadAndValidationHandlers --> Browser: JSON validation result
```

## Related

- Related flows: [Lead Capture — Account Creation Path](lead-capture-account-creation.md)
- See [API Surface](../api-surface.md) for endpoint specification
