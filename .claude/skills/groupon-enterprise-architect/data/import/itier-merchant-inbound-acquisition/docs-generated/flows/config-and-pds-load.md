---
service: "itier-merchant-inbound-acquisition"
title: "Merchant Configuration and PDS Load"
generated: "2026-03-03"
type: flow
flow_name: "config-and-pds-load"
flow_type: synchronous
trigger: "Signup form page load or locale change"
participants:
  - "Browser (prospective merchant)"
  - "miaWebRoutes"
  - "miaLeadAndValidationHandlers"
  - "miaIntegrationClients"
  - "continuumMetroPlatform"
architecture_ref: "components-merchant-inbound-acquisition-service"
---

# Merchant Configuration and PDS Load

## Summary

This flow loads two categories of locale-specific data that the signup form requires before the merchant can complete registration: merchant onboarding configuration (from Metro's config API) and the Product Deal Service (PDS) business category taxonomy (from Metro's PDS API). Both are fetched on demand via BFF endpoints that the React form calls on initialization or locale change.

## Trigger

- **Type**: api-call
- **Source**: React form on mount calls `GET /merchant/inbound/api/loadconfig` and `GET /merchant/inbound/api/pds`
- **Frequency**: Per page load / per locale change

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser (signup form) | Fetches config and PDS taxonomy on form initialization | — |
| Web Routes and Page Composition | Routes `GET /merchant/inbound/api/loadconfig` and `GET /merchant/inbound/api/pds` | `miaWebRoutes` |
| Lead and Validation Handlers | `loadconfig.js` and `pds.js` handlers proxy calls to Metro | `miaLeadAndValidationHandlers` |
| Integration Clients | Executes `metro.getConfig()` and `metro.getPDS()` | `miaIntegrationClients` |
| Metro Platform | Returns locale-specific merchant configuration and PDS category taxonomy | `continuumMetroPlatform` |

## Steps

### Configuration Load

1. **Request configuration**: Browser sends `GET /merchant/inbound/api/loadconfig?locale=<locale>&loadconfigbasedonlocale=<bool>`.
   - From: Browser
   - To: `miaWebRoutes`
   - Protocol: REST / HTTPS

2. **Delegate to loadconfig handler**: Route handler invokes `loadconfig(_params, deps)` from `modules/index/js/loadconfig.js`.
   - From: `miaWebRoutes`
   - To: `miaLeadAndValidationHandlers`
   - Protocol: In-process function call

3. **Fetch Metro config**: `metro.getConfig({ client_id, locale, loadConfigBasedOnLocale })` is called via `@grpn/metro-client`.
   - From: `miaIntegrationClients`
   - To: `continuumMetroPlatform`
   - Protocol: REST via `@grpn/metro-client`

4. **Return config to browser**: Metro config JSON is returned; logged with `itier-tracing` on success or failure.
   - From: `continuumMetroPlatform`
   - To: Browser
   - Protocol: REST JSON

### PDS Taxonomy Load

1. **Request PDS taxonomy**: Browser sends `GET /merchant/inbound/api/pds`.
   - From: Browser
   - To: `miaWebRoutes`
   - Protocol: REST / HTTPS

2. **Delegate to PDS handler**: Route handler invokes `pds(_params, deps)` from `modules/index/js/pds.js`.
   - From: `miaWebRoutes`
   - To: `miaLeadAndValidationHandlers`
   - Protocol: In-process function call

3. **Fetch Metro PDS**: `metro.getPDS({ source: 'mia', category: 'activities,food,hbw,other,home,goods', client_id, locale, lang })` is called, with `country_code` header injected from `metro.defaults.country`.
   - From: `miaIntegrationClients`
   - To: `continuumMetroPlatform`
   - Protocol: REST via `@grpn/metro-client`

4. **Return PDS taxonomy to browser**: Category taxonomy JSON (for business type dropdown) is returned. Logged on success or failure.
   - From: `continuumMetroPlatform`
   - To: Browser
   - Protocol: REST JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Metro config API unavailable | Exception caught; error logged; `{ message }` JSON returned | Form may not render country-specific configuration correctly |
| Metro PDS API unavailable | Exception caught; error logged; `{ message }` JSON returned | Business category dropdown may be empty or use fallback values |
| Invalid locale parameter | Passed through to Metro | Metro returns error; propagated to browser |

## Sequence Diagram

```
Browser -> miaWebRoutes: GET /merchant/inbound/api/loadconfig?locale=en_US&loadconfigbasedonlocale=true
miaWebRoutes -> miaLeadAndValidationHandlers: loadconfig(params, deps)
miaLeadAndValidationHandlers -> continuumMetroPlatform: metro.getConfig({ client_id, locale, loadConfigBasedOnLocale })
continuumMetroPlatform --> miaLeadAndValidationHandlers: merchant config JSON
miaLeadAndValidationHandlers --> Browser: JSON config

Browser -> miaWebRoutes: GET /merchant/inbound/api/pds
miaWebRoutes -> miaLeadAndValidationHandlers: pds(params, deps)
miaLeadAndValidationHandlers -> continuumMetroPlatform: metro.getPDS({ source: 'mia', category: 'activities,food,...', client_id, locale, lang })
continuumMetroPlatform --> miaLeadAndValidationHandlers: PDS taxonomy JSON
miaLeadAndValidationHandlers --> Browser: JSON category taxonomy
```

## Related

- Related flows: [Lead Capture — Account Creation Path](lead-capture-account-creation.md)
- See [Integrations](../integrations.md) for Metro client configuration
- See [API Surface](../api-surface.md) for endpoint parameters
