---
service: "selfsetup-hbw"
title: "Merchant Signup and Opportunity Lookup"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "merchant-signup-and-opportunity-lookup"
flow_type: synchronous
trigger: "Merchant follows a Salesforce-generated invitation URL"
participants:
  - "ssuWebUi"
  - "selfsetupHbw_ssuSalesforceClient"
  - "salesForce"
  - "ssuPersistence"
  - "continuumSsuDatabase"
architecture_ref: "dynamic-selfsetup-hbw"
---

# Merchant Signup and Opportunity Lookup

## Summary

When a Health & Beauty merchant receives a Groupon invitation and navigates to the self-setup portal, this flow validates the inbound token, retrieves the merchant's opportunity and account data from Salesforce, and initialises a setup session. It is the entry point for all subsequent wizard steps and ensures the merchant's identity and contract details are resolved before any configuration is accepted.

## Trigger

- **Type**: user-action
- **Source**: Merchant clicks Salesforce-generated invitation link containing an opportunity token
- **Frequency**: On-demand (once per merchant onboarding, or on each return visit)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant browser | Initiates HTTP GET to the portal | — |
| Web UI / Controllers | Receives the request, extracts token, orchestrates lookup | `ssuWebUi` |
| Salesforce API Client | Exchanges OAuth token and executes SOQL opportunity lookup | `selfsetupHbw_ssuSalesforceClient` |
| Salesforce | Authoritative source of merchant opportunity and account data | `salesForce` |
| Data Access | Persists resolved session state and initial setup record | `ssuPersistence` |
| SSU HBW Database | Stores initialised merchant setup record | `continuumSsuDatabase` |

## Steps

1. **Receives invitation request**: Merchant browser sends HTTP GET to `/` with Salesforce opportunity token embedded in the URL.
   - From: Merchant browser
   - To: `ssuWebUi`
   - Protocol: REST / HTTPS

2. **Validates token and initiates session**: `ssuWebUi` extracts and validates the opportunity token from the request. Establishes a PHP session for the merchant.
   - From: `ssuWebUi`
   - To: (internal session store / PHP session)
   - Protocol: Direct

3. **Requests Salesforce opportunity data**: `ssuWebUi` calls `selfsetupHbw_ssuSalesforceClient` to fetch the merchant's opportunity and account record.
   - From: `ssuWebUi`
   - To: `selfsetupHbw_ssuSalesforceClient`
   - Protocol: Direct (in-process)

4. **Authenticates with Salesforce**: `selfsetupHbw_ssuSalesforceClient` performs OAuth 2.0 token acquisition using `SALESFORCE_CLIENT_ID`, `SALESFORCE_CLIENT_SECRET`, `SALESFORCE_USERNAME`, `SALESFORCE_PASSWORD`.
   - From: `selfsetupHbw_ssuSalesforceClient`
   - To: `salesForce`
   - Protocol: REST / HTTPS (OAuth 2.0 token endpoint)

5. **Executes SOQL opportunity lookup**: `selfsetupHbw_ssuSalesforceClient` sends a SOQL query to the `/api/opportunity` data endpoint to retrieve the merchant's opportunity, account, and contract details.
   - From: `selfsetupHbw_ssuSalesforceClient`
   - To: `salesForce`
   - Protocol: REST / HTTPS (Salesforce REST API)

6. **Returns opportunity data**: Salesforce returns the opportunity and account record as JSON.
   - From: `salesForce`
   - To: `selfsetupHbw_ssuSalesforceClient`
   - Protocol: REST / HTTPS

7. **Initialises setup record in database**: `ssuWebUi` calls `ssuPersistence` to write an initial setup record for the merchant (opportunity ID, country, locale, status = in-progress).
   - From: `ssuWebUi` via `ssuPersistence`
   - To: `continuumSsuDatabase`
   - Protocol: TCP / MySQL

8. **Renders setup landing page**: `ssuWebUi` renders the localised home page (`/`) or redirects to `/front` based on setup state, presenting the merchant with the first wizard step.
   - From: `ssuWebUi`
   - To: Merchant browser
   - Protocol: REST / HTTPS (HTTP 200 HTML)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid or expired invitation token | `ssuWebUi` rejects the request | Merchant receives an HTML error page; no session is created |
| Salesforce OAuth failure | `selfsetupHbw_ssuSalesforceClient` catches exception | Error logged via `ssuLogger`; merchant sees a generic error page |
| Salesforce SOQL returns no opportunity | `selfsetupHbw_ssuSalesforceClient` returns empty result | `ssuWebUi` renders an "opportunity not found" error page |
| MySQL write failure | `ssuPersistence` throws exception | Error logged; merchant sees a generic error page |

## Sequence Diagram

```
Merchant -> ssuWebUi: GET / (opportunity token in URL)
ssuWebUi -> selfsetupHbw_ssuSalesforceClient: lookupOpportunity(token)
selfsetupHbw_ssuSalesforceClient -> salesForce: POST /oauth/token (client credentials)
salesForce --> selfsetupHbw_ssuSalesforceClient: access_token
selfsetupHbw_ssuSalesforceClient -> salesForce: GET /services/data/vXX/query?q=SELECT ... (SOQL)
salesForce --> selfsetupHbw_ssuSalesforceClient: opportunity + account JSON
selfsetupHbw_ssuSalesforceClient --> ssuWebUi: OpportunityData
ssuWebUi -> ssuPersistence: createSetupRecord(opportunityId, country, locale)
ssuPersistence -> continuumSsuDatabase: INSERT setup_record
continuumSsuDatabase --> ssuPersistence: OK
ssuWebUi --> Merchant: HTTP 200 (setup wizard landing page)
```

## Related

- Architecture dynamic view: `dynamic-selfsetup-hbw`
- Related flows: [Merchant Complete Availability and Capacity Setup](merchant-complete-availability-and-capacity-setup.md), [Merchant Push Configuration to Salesforce and BookingTool](merchant-push-configuration-to-salesforce-and-bookingtool.md)
