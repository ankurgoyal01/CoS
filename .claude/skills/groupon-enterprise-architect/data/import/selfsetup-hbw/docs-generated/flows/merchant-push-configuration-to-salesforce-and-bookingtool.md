---
service: "selfsetup-hbw"
title: "Merchant Push Configuration to Salesforce and BookingTool"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "merchant-push-configuration-to-salesforce-and-bookingtool"
flow_type: synchronous
trigger: "Merchant submits the final wizard step (POST /sf)"
participants:
  - "ssuWebUi"
  - "selfsetupHbw_ssuSalesforceClient"
  - "selfsetupHbw_ssuBookingToolClient"
  - "ssuPersistence"
  - "continuumSsuDatabase"
  - "salesForce"
  - "bookingToolApi"
  - "ssuMetricsReporter"
  - "ssuLogger"
architecture_ref: "dynamic-selfsetup-hbw"
---

# Merchant Push Configuration to Salesforce and BookingTool

## Summary

This is the terminal step of the self-setup wizard. When the merchant confirms their configuration and submits the final form, the application reads the complete setup from `continuumSsuDatabase`, pushes it to Salesforce as an update to the merchant's opportunity record, and then delivers the availability and capacity data to the BookingTool API for the merchant's feature country. On success the merchant is presented with a confirmation page and the setup record is marked complete.

## Trigger

- **Type**: user-action
- **Source**: Merchant submits the final setup confirmation (HTTP POST to `/sf`)
- **Frequency**: On-demand (once per successful setup; may be retried on failure)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant browser | Initiates final submission | — |
| Web UI / Controllers | Orchestrates the push sequence | `ssuWebUi` |
| Salesforce API Client | Updates the Salesforce opportunity with final configuration | `selfsetupHbw_ssuSalesforceClient` |
| BookingTool API Client | Delivers availability and capacity to BookingTool | `selfsetupHbw_ssuBookingToolClient` |
| Data Access | Reads finalised config; updates setup record status | `ssuPersistence` |
| SSU HBW Database | Source of truth for local config; updated to status = complete | `continuumSsuDatabase` |
| Salesforce | Receives configuration update | `salesForce` |
| BookingTool API | Receives availability and capacity configuration | `bookingToolApi` |
| Metrics Reporter | Emits completion metrics | `ssuMetricsReporter` |
| Logging | Records push outcomes and errors | `ssuLogger` |

## Steps

1. **Receives final submission**: Merchant sends HTTP POST to `/sf` confirming the completed setup.
   - From: Merchant browser
   - To: `ssuWebUi`
   - Protocol: REST / HTTPS (form POST)

2. **Reads finalised configuration**: `ssuWebUi` calls `ssuPersistence` to load the complete setup record (availability, capping, service details, opportunity ID, country) from `continuumSsuDatabase`.
   - From: `ssuWebUi` via `ssuPersistence`
   - To: `continuumSsuDatabase`
   - Protocol: TCP / MySQL

3. **Pushes configuration to Salesforce**: `ssuWebUi` calls `selfsetupHbw_ssuSalesforceClient` with the finalised configuration. The client authenticates via OAuth 2.0 and sends a REST API update to the merchant's Salesforce opportunity record.
   - From: `selfsetupHbw_ssuSalesforceClient`
   - To: `salesForce`
   - Protocol: REST / HTTPS (Salesforce REST API PATCH/POST)

4. **Receives Salesforce confirmation**: Salesforce returns a success response confirming the opportunity record has been updated.
   - From: `salesForce`
   - To: `selfsetupHbw_ssuSalesforceClient`
   - Protocol: REST / HTTPS

5. **Pushes availability to BookingTool**: `ssuWebUi` calls `selfsetupHbw_ssuBookingToolClient` to deliver the merchant's weekly availability schedule. The client uses the per-country BookingTool API endpoint with `BOOKINGTOOL_CREDENTIALS` (BasicAuth).
   - From: `selfsetupHbw_ssuBookingToolClient`
   - To: `bookingToolApi`
   - Protocol: REST / HTTPS (BasicAuth)

6. **Pushes capacity/capping to BookingTool**: `selfsetupHbw_ssuBookingToolClient` delivers the merchant's capacity cap configuration to the BookingTool API.
   - From: `selfsetupHbw_ssuBookingToolClient`
   - To: `bookingToolApi`
   - Protocol: REST / HTTPS (BasicAuth)

7. **Receives BookingTool confirmation**: BookingTool API returns success for both the availability and capping calls.
   - From: `bookingToolApi`
   - To: `selfsetupHbw_ssuBookingToolClient`
   - Protocol: REST / HTTPS

8. **Marks setup as complete**: `ssuPersistence` updates the setup record in `continuumSsuDatabase` to status = complete.
   - From: `ssuWebUi` via `ssuPersistence`
   - To: `continuumSsuDatabase`
   - Protocol: TCP / MySQL

9. **Emits completion metrics and logs**: `ssuMetricsReporter` records a successful setup completion event; `ssuLogger` writes a structured success log.
   - From: `ssuMetricsReporter` / `ssuLogger`
   - To: `telegrafAgent` / `logAggregation`
   - Protocol: InfluxDB line protocol / Splunk HEC

10. **Renders confirmation page**: `ssuWebUi` returns a localised confirmation page to the merchant's browser.
    - From: `ssuWebUi`
    - To: Merchant browser
    - Protocol: REST / HTTPS (HTTP 200 HTML)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Salesforce OAuth failure | `selfsetupHbw_ssuSalesforceClient` catches exception | Error logged; setup remains in-progress; merchant receives error page with retry option |
| Salesforce API update failure | `selfsetupHbw_ssuSalesforceClient` catches HTTP error | Error logged; BookingTool push is NOT attempted; merchant retries |
| BookingTool API unavailable | `selfsetupHbw_ssuBookingToolClient` catches exception | Error logged; Salesforce update already committed; operator must manually trigger BookingTool retry or merchant retries full submission |
| BookingTool returns 4xx (invalid data) | `selfsetupHbw_ssuBookingToolClient` catches error | Error logged with response body; merchant receives error page; data remains in MySQL for investigation |
| MySQL read/write failure | `ssuPersistence` throws exception | Error logged; setup cannot be completed; merchant retries |

## Sequence Diagram

```
Merchant -> ssuWebUi: POST /sf (confirm submission)
ssuWebUi -> ssuPersistence: loadSetupRecord(sessionId)
ssuPersistence -> continuumSsuDatabase: SELECT setup WHERE session=X
continuumSsuDatabase --> ssuPersistence: setupRecord
ssuWebUi -> selfsetupHbw_ssuSalesforceClient: pushToSalesforce(setupRecord)
selfsetupHbw_ssuSalesforceClient -> salesForce: POST /oauth/token
salesForce --> selfsetupHbw_ssuSalesforceClient: access_token
selfsetupHbw_ssuSalesforceClient -> salesForce: PATCH /services/data/vXX/sobjects/Opportunity/Id
salesForce --> selfsetupHbw_ssuSalesforceClient: 200 OK
selfsetupHbw_ssuSalesforceClient --> ssuWebUi: success
ssuWebUi -> selfsetupHbw_ssuBookingToolClient: pushAvailability(country, schedule)
selfsetupHbw_ssuBookingToolClient -> bookingToolApi: POST /week (BasicAuth)
bookingToolApi --> selfsetupHbw_ssuBookingToolClient: 200 OK
ssuWebUi -> selfsetupHbw_ssuBookingToolClient: pushCapping(country, caps)
selfsetupHbw_ssuBookingToolClient -> bookingToolApi: POST /capping (BasicAuth)
bookingToolApi --> selfsetupHbw_ssuBookingToolClient: 200 OK
ssuWebUi -> ssuPersistence: markComplete(sessionId)
ssuPersistence -> continuumSsuDatabase: UPDATE setup SET status=complete
ssuMetricsReporter -> telegrafAgent: setup_complete_count++
ssuLogger -> logAggregation: INFO setup completed
ssuWebUi --> Merchant: HTTP 200 (confirmation page)
```

## Related

- Architecture dynamic view: `dynamic-selfsetup-hbw`
- Related flows: [Merchant Signup and Opportunity Lookup](merchant-signup-and-opportunity-lookup.md), [Merchant Complete Availability and Capacity Setup](merchant-complete-availability-and-capacity-setup.md), [Merchant Edit and Update Existing Profile](merchant-edit-and-update-existing-profile.md)
