---
service: "itier-merchant-inbound-acquisition"
title: "Lead Capture — Account Creation Path"
generated: "2026-03-03"
type: flow
flow_name: "lead-capture-account-creation"
flow_type: synchronous
trigger: "Merchant submits signup form for an account-creation-enabled country (US, GB, AU, FR, IT, PL, AE, DE, ES, BE, NL, IE)"
participants:
  - "Browser (prospective merchant)"
  - "miaWebRoutes"
  - "miaLeadAndValidationHandlers"
  - "miaIntegrationClients"
  - "continuumMetroPlatform"
architecture_ref: "dynamic-merchant-lead-capture-flow"
---

# Lead Capture — Account Creation Path

## Summary

This flow handles merchant lead submission for countries where the `enableAccountCreation` feature flag is active. The merchant completes the signup form, the service transforms the payload into a Metro draft merchant record, calls `createDraftMerchant` or `createDraftMerchantV2` (depending on the `treatment` A/B variant), and returns the draft merchant ID to the browser. This is the primary lead-creation path for major markets (US, GB, AU, and EMEA).

## Trigger

- **Type**: user-action
- **Source**: Merchant clicks submit on the `/merchant/signup` React form; browser POSTs to `POST /merchant/inbound/api/lead`
- **Frequency**: On demand (per merchant submission)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser (prospective merchant) | Initiates signup form submission | — |
| Web Routes and Page Composition | Receives inbound HTTP POST, extracts `Referer` header, delegates to lead handler | `miaWebRoutes` |
| Lead and Validation Handlers | Builds Metro payload, applies feature-flag logic, calls Metro via integration client | `miaLeadAndValidationHandlers` |
| Integration Clients | Executes Metro draft merchant API call; fires GA tracking event | `miaIntegrationClients` |
| Metro Platform (draft merchant service) | Creates draft merchant record; returns merchant ID | `continuumMetroPlatform` |

## Steps

1. **Receive lead submission**: Browser POSTs form fields to `POST /merchant/inbound/api/lead` with `Referer` header.
   - From: Browser
   - To: `miaWebRoutes`
   - Protocol: REST / HTTPS

2. **Determine routing and opt-in flags**: `miaWebRoutes` reads the `Referer` header, parses `itier_merchant_center_acquasition_country_code` query parameter, evaluates `enableHeaderParam` and `enableAccountCreation` feature flags, and resolves the `promotionOptIn` value from the `isRegionEMEA` flag.
   - From: `miaWebRoutes`
   - To: `miaLeadAndValidationHandlers`
   - Protocol: In-process function call

3. **Build Metro payload**: The `createDraftServiceLeadData` helper maps raw form fields (business name, contact details, location, UTM fields, business vertical, incentive data, treatment variant) into the Metro `createDraftMerchant` payload schema. Country-specific adjustments are applied (e.g. AE postal code default, IT province code, US platform type, CA billing country).
   - From: `miaLeadAndValidationHandlers`
   - To: `miaIntegrationClients`
   - Protocol: In-process

4. **Select Metro endpoint by treatment variant**: If the payload `treatment` flag is truthy and `isWidget` is false, call `metro.createDraftMerchantV2(merchantData)`. Otherwise call `metro.createDraftMerchant(merchantData)`.
   - From: `miaIntegrationClients`
   - To: `continuumMetroPlatform` (Metro draft service)
   - Protocol: REST via `@grpn/metro-client`

5. **Handle Metro response**: On success, fire `web2lead-submit-draft success` Google Analytics event and return Metro's response JSON (including draft merchant ID) to browser. On failure, fire `web2lead-submit-draft err` GA event, log error with `itier-tracing`, return error JSON.
   - From: `continuumMetroPlatform`
   - To: Browser (via `miaIntegrationClients` → `miaLeadAndValidationHandlers` → `miaWebRoutes`)
   - Protocol: REST JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Metro API unavailable | Exception caught; error logged; `web2lead-submit-draft err` GA event fired | JSON error response returned to browser; merchant sees submission failure |
| Metro returns validation error | Error propagated as JSON response | Browser form shows error message |
| Feature flag misconfiguration | Defaults to account-creation path if `enableLeadCreation` is not active | May result in incorrect routing; requires config fix |

## Sequence Diagram

```
Browser -> miaWebRoutes: POST /merchant/inbound/api/lead (form fields, Referer header)
miaWebRoutes -> miaLeadAndValidationHandlers: create(params, deps)
miaLeadAndValidationHandlers -> miaLeadAndValidationHandlers: evaluate enableAccountCreation, isRegionEMEA, treatment flags
miaLeadAndValidationHandlers -> miaIntegrationClients: makeDraftServiceRequest(deps, routeLeadToDraft, promotionOptIn, newFormRequest)
miaIntegrationClients -> continuumMetroPlatform: metro.createDraftMerchant(merchantData) OR metro.createDraftMerchantV2(merchantData)
continuumMetroPlatform --> miaIntegrationClients: { draftMerchantId, ... }
miaIntegrationClients -> GoogleAnalytics: visitor.event('web2lead-submit-draft', 'success').send()
miaIntegrationClients --> Browser: JSON response with draft merchant data
```

## Related

- Architecture dynamic view: `dynamic-merchant-lead-capture-flow`
- Related flows: [Lead Capture — Salesforce Path](lead-capture-salesforce.md)
- See [Configuration](../configuration.md) for `enableAccountCreation` flag country list
