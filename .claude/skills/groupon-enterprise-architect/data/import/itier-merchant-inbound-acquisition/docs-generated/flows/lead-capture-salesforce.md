---
service: "itier-merchant-inbound-acquisition"
title: "Lead Capture — Salesforce Path"
generated: "2026-03-03"
type: flow
flow_name: "lead-capture-salesforce"
flow_type: synchronous
trigger: "Merchant submits signup form for a country where enableLeadCreation is active (countries NOT in the enableAccountCreation list)"
participants:
  - "Browser (prospective merchant)"
  - "miaWebRoutes"
  - "miaLeadAndValidationHandlers"
  - "miaIntegrationClients"
  - "salesForce"
architecture_ref: "dynamic-merchant-lead-capture-flow"
---

# Lead Capture — Salesforce Path

## Summary

This flow handles merchant signups in countries where the `enableLeadCreation` feature flag is active — i.e. countries not covered by the Metro account-creation flow. The service authenticates to Salesforce via the `jsforce` SDK, transforms the form payload into a Salesforce `Lead` sObject, creates the CRM record, and returns the Salesforce lead ID to the browser.

## Trigger

- **Type**: user-action
- **Source**: Merchant clicks submit on the `/merchant/signup` React form; browser POSTs to `POST /merchant/inbound/api/lead`
- **Frequency**: On demand (per merchant submission)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser (prospective merchant) | Initiates signup form submission | — |
| Web Routes and Page Composition | Receives inbound HTTP POST, extracts `Referer` header, evaluates routing flags | `miaWebRoutes` |
| Lead and Validation Handlers | Determines Salesforce routing, builds sObject payload, authenticates and writes to Salesforce | `miaLeadAndValidationHandlers` |
| Integration Clients | Holds Salesforce configuration; `jsforce` connection logic lives in `lead.js` via integration deps | `miaIntegrationClients` |
| Salesforce CRM | Creates `Lead` sObject; returns lead ID and success/error status | `salesForce` |

## Steps

1. **Receive lead submission**: Browser POSTs form fields to `POST /merchant/inbound/api/lead` with `Referer` header.
   - From: Browser
   - To: `miaWebRoutes`
   - Protocol: REST / HTTPS

2. **Evaluate routing flags**: `miaWebRoutes` evaluates `enableLeadCreation` (active for non-account-creation countries), `isRegionEMEA` (sets promotion opt-in logic), and `enableHeaderParam` (Referer-based account-creation override). Determines `promotionOptIn` boolean.
   - From: `miaWebRoutes`
   - To: `miaLeadAndValidationHandlers`
   - Protocol: In-process function call

3. **Authenticate to Salesforce**: `createLeadOnSF` opens a `jsforce.Connection` using the configured `salesforce.loginUrl` and calls `connection.login(username, password)`. Credentials are loaded from keldor-config (`serviceClientConfig.salesforce`).
   - From: `miaLeadAndValidationHandlers`
   - To: `salesForce`
   - Protocol: REST (jsforce SDK)

4. **Build Salesforce Lead payload**: `createSFLeadData` maps form fields to Salesforce field names — `Company`, `FirstName`, `LastName`, `Email`, `Phone`, `Street`, `City`, `PostalCode`, `State`, `Country`, `Feature_Country__c`, `Category_v3__c`, `of_Locations__c`, `LeadSource`, `Web_To_Lead_Channel__c`, `Campaign_Name__c`, `Details__c`, UTM fields, and promotion opt-in flags.
   - From: `miaLeadAndValidationHandlers`
   - To: (in-process data transformation)
   - Protocol: In-process

5. **Resolve feature country**: If the page locale is US but `data.country` is CA (Canadian merchant on US page), `featureCountry` is set to CA. Otherwise `featureCountry` equals the page locale country.
   - From: `miaLeadAndValidationHandlers`
   - Protocol: In-process logic

6. **Create Salesforce Lead**: `connection.sobject('Lead').create(leadData)` writes the Lead record to Salesforce.
   - From: `miaLeadAndValidationHandlers`
   - To: `salesForce`
   - Protocol: REST (jsforce SDK)

7. **Handle response**: On success, fire `web2lead-submit-salesforce success` GA event, log with `itier-tracing`, return `{ errors, sf_id, success }` JSON to browser. On failure, fire `web2lead-submit-salesforce error` GA event, log error, return `{ message }` JSON.
   - From: `salesForce`
   - To: Browser (via handlers → web routes)
   - Protocol: REST JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Salesforce connection failure (login error) | Exception thrown from `connection.login()`; caught in `createLeadOnSF`; logged; GA error event fired | JSON error response to browser |
| Salesforce `sobject.create()` failure | Exception caught; logged with request metadata; GA error event fired | JSON error response to browser |
| Salesforce credentials expired | Login fails; error propagated as above | Salesforce lead creation fails until credentials are rotated |
| No retry mechanism | Single attempt only | Merchant must re-submit form |

## Sequence Diagram

```
Browser -> miaWebRoutes: POST /merchant/inbound/api/lead (form fields)
miaWebRoutes -> miaLeadAndValidationHandlers: create(params, deps)
miaLeadAndValidationHandlers -> miaLeadAndValidationHandlers: evaluate enableLeadCreation flag -> true
miaLeadAndValidationHandlers -> salesForce: jsforce.Connection.login(username, password)
salesForce --> miaLeadAndValidationHandlers: Salesforce session established
miaLeadAndValidationHandlers -> miaLeadAndValidationHandlers: createSFLeadData(data, featureCountry, promotionOptIn)
miaLeadAndValidationHandlers -> salesForce: connection.sobject('Lead').create(leadData)
salesForce --> miaLeadAndValidationHandlers: { id: sf_id, success: true, errors: [] }
miaLeadAndValidationHandlers -> GoogleAnalytics: visitor.event('web2lead-submit-salesforce', 'success').send()
miaLeadAndValidationHandlers --> Browser: JSON { errors, sf_id, success }
```

## Related

- Architecture dynamic view: `dynamic-merchant-lead-capture-flow`
- Related flows: [Lead Capture — Account Creation Path](lead-capture-account-creation.md)
- Architecture ref: `salesForce` (stub container in Continuum system)
- See [Integrations](../integrations.md) for Salesforce credential and URL configuration
