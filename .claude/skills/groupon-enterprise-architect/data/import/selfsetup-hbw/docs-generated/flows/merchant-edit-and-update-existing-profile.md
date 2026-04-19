---
service: "selfsetup-hbw"
title: "Merchant Edit and Update Existing Profile"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "merchant-edit-and-update-existing-profile"
flow_type: synchronous
trigger: "Returning merchant navigates to the setup portal to modify an existing configuration"
participants:
  - "ssuWebUi"
  - "selfsetupHbw_ssuSalesforceClient"
  - "selfsetupHbw_ssuBookingToolClient"
  - "ssuPersistence"
  - "continuumSsuDatabase"
  - "salesForce"
  - "bookingToolApi"
  - "ssuLogger"
  - "ssuMetricsReporter"
architecture_ref: "dynamic-selfsetup-hbw"
---

# Merchant Edit and Update Existing Profile

## Summary

A merchant who has previously completed setup may return to the portal to modify their availability, capacity, or service profile details. The application detects that an existing completed (or in-progress) setup record exists for the merchant's opportunity, pre-populates all wizard forms with the current values, and allows the merchant to update any section. On submission, the updated configuration is re-pushed to Salesforce and BookingTool following the same push flow as initial setup.

## Trigger

- **Type**: user-action
- **Source**: Returning merchant follows an invitation or bookmark link to the setup portal; the application detects an existing setup record
- **Frequency**: On-demand (whenever a merchant needs to update their profile)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant browser | Navigates to the portal and submits updated form data | — |
| Web UI / Controllers | Detects existing setup, pre-populates forms, routes updates | `ssuWebUi` |
| Salesforce API Client | Re-authenticates and fetches current opportunity state; pushes updated config | `selfsetupHbw_ssuSalesforceClient` |
| BookingTool API Client | Delivers updated availability and capacity to BookingTool | `selfsetupHbw_ssuBookingToolClient` |
| Data Access | Reads existing setup record; writes updates | `ssuPersistence` |
| SSU HBW Database | Source of existing configuration; updated with new values | `continuumSsuDatabase` |
| Salesforce | Provides current opportunity state; receives updated configuration | `salesForce` |
| BookingTool API | Receives updated availability and capacity | `bookingToolApi` |
| Logging | Records edit and update outcomes | `ssuLogger` |
| Metrics Reporter | Emits edit/update metrics | `ssuMetricsReporter` |

## Steps

1. **Receives return visit**: Merchant browser sends HTTP GET to `/` (or `/front`) with an opportunity token. `ssuWebUi` extracts the token and calls `selfsetupHbw_ssuSalesforceClient` to resolve the opportunity.
   - From: Merchant browser
   - To: `ssuWebUi`
   - Protocol: REST / HTTPS

2. **Detects existing setup record**: `ssuPersistence` queries `continuumSsuDatabase` for a setup record matching the opportunity ID. An existing record is found (status = complete or in-progress).
   - From: `ssuWebUi` via `ssuPersistence`
   - To: `continuumSsuDatabase`
   - Protocol: TCP / MySQL

3. **Pre-populates wizard forms**: `ssuWebUi` loads the existing configuration values into the `/front`, `/week`, and `/capping` form views, presenting the merchant with their current settings.
   - From: `ssuWebUi`
   - To: Merchant browser
   - Protocol: REST / HTTPS (HTTP 200 HTML)

4. **Merchant edits and submits sections**: The merchant updates one or more sections (service profile at `/front`, availability at `/week`, capacity at `/capping`) and submits each form.
   - From: Merchant browser
   - To: `ssuWebUi`
   - Protocol: REST / HTTPS (form POST)

5. **Validates updated data**: `ssuWebUi` applies the same validation rules as initial setup to the changed fields.
   - From: `ssuWebUi`
   - To: (in-process validation logic)
   - Protocol: Direct

6. **Writes updated configuration**: `ssuPersistence` updates the existing setup record in `continuumSsuDatabase` with the new values.
   - From: `ssuWebUi` via `ssuPersistence`
   - To: `continuumSsuDatabase`
   - Protocol: TCP / MySQL

7. **Pushes updated config to Salesforce**: On final submission (`/sf`), `selfsetupHbw_ssuSalesforceClient` authenticates via OAuth 2.0 and sends a PATCH/POST to the merchant's Salesforce opportunity record with the updated values.
   - From: `selfsetupHbw_ssuSalesforceClient`
   - To: `salesForce`
   - Protocol: REST / HTTPS

8. **Pushes updated availability and capping to BookingTool**: `selfsetupHbw_ssuBookingToolClient` delivers the updated schedule and capping configuration to the per-country BookingTool API endpoint (BasicAuth).
   - From: `selfsetupHbw_ssuBookingToolClient`
   - To: `bookingToolApi`
   - Protocol: REST / HTTPS (BasicAuth)

9. **Marks setup record as updated**: `ssuPersistence` updates the record timestamp and status in `continuumSsuDatabase`.
   - From: `ssuWebUi` via `ssuPersistence`
   - To: `continuumSsuDatabase`
   - Protocol: TCP / MySQL

10. **Emits metrics and logs**: `ssuMetricsReporter` records the update event; `ssuLogger` writes a structured update log.
    - From: `ssuMetricsReporter` / `ssuLogger`
    - To: `telegrafAgent` / `logAggregation`
    - Protocol: InfluxDB line protocol / Splunk HEC

11. **Renders update confirmation**: `ssuWebUi` returns a localised confirmation page to the merchant's browser.
    - From: `ssuWebUi`
    - To: Merchant browser
    - Protocol: REST / HTTPS (HTTP 200 HTML)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Existing record not found (merchant arrives without prior setup) | `ssuPersistence` returns empty; `ssuWebUi` routes to initial signup flow | Merchant proceeds through the standard onboarding flow |
| Validation failure on updated field | `ssuWebUi` re-renders the relevant form with error messages | Updated value not persisted; merchant corrects and resubmits |
| Salesforce push failure | Same as initial setup push flow | Error logged; merchant retries; previously-saved config in MySQL is preserved |
| BookingTool push failure | Same as initial setup push flow | Error logged; Salesforce already updated; BookingTool retry required |

## Sequence Diagram

```
Merchant -> ssuWebUi: GET /front (opportunity token)
ssuWebUi -> selfsetupHbw_ssuSalesforceClient: resolveOpportunity(token)
selfsetupHbw_ssuSalesforceClient -> salesForce: SOQL query
salesForce --> selfsetupHbw_ssuSalesforceClient: opportunityData
ssuWebUi -> ssuPersistence: findExistingSetup(opportunityId)
ssuPersistence -> continuumSsuDatabase: SELECT setup WHERE opportunity_id=X
continuumSsuDatabase --> ssuPersistence: existingSetupRecord
ssuWebUi --> Merchant: HTTP 200 (pre-populated edit form)
Merchant -> ssuWebUi: POST /week (updated schedule)
ssuWebUi -> ssuPersistence: updateAvailability(setupId, newSchedule)
ssuPersistence -> continuumSsuDatabase: UPDATE availability
Merchant -> ssuWebUi: POST /sf (confirm changes)
ssuWebUi -> selfsetupHbw_ssuSalesforceClient: pushToSalesforce(updatedConfig)
selfsetupHbw_ssuSalesforceClient -> salesForce: PATCH opportunity
salesForce --> selfsetupHbw_ssuSalesforceClient: 200 OK
ssuWebUi -> selfsetupHbw_ssuBookingToolClient: pushUpdates(country, schedule, caps)
selfsetupHbw_ssuBookingToolClient -> bookingToolApi: POST /week + POST /capping
bookingToolApi --> selfsetupHbw_ssuBookingToolClient: 200 OK
ssuPersistence -> continuumSsuDatabase: UPDATE status, updated_at
ssuMetricsReporter -> telegrafAgent: setup_update_count++
ssuWebUi --> Merchant: HTTP 200 (confirmation page)
```

## Related

- Architecture dynamic view: `dynamic-selfsetup-hbw`
- Related flows: [Merchant Signup and Opportunity Lookup](merchant-signup-and-opportunity-lookup.md), [Merchant Push Configuration to Salesforce and BookingTool](merchant-push-configuration-to-salesforce-and-bookingtool.md)
