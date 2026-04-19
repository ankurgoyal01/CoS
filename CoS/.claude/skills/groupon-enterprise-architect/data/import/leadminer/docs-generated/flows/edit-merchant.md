---
service: "leadminer"
title: "Edit Merchant"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "edit-merchant"
flow_type: synchronous
trigger: "Operator opens and submits an edit form for a Merchant record"
participants:
  - "continuumM3LeadminerService"
  - "continuumM3MerchantService"
  - "continuumTaxonomyService"
  - "salesForce"
architecture_ref: "dynamic-place-edit-flow"
---

# Edit Merchant

## Summary

An operator selects a Merchant record and opens its edit form. Leadminer fetches the current merchant data from the M3 Merchant Service and populates the form with taxonomy reference data. On form submission, Leadminer validates the input, applies phone number normalization, and writes the updated record back to the M3 Merchant Service. Salesforce external UUID mapping is available for cross-system identity linking.

## Trigger

- **Type**: user-action
- **Source**: Operator clicks edit on a Merchant record at `/m/:id/edit`
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator (browser) | Initiates edit, submits form | — |
| Leadminer Web App | Orchestrates data fetch, validation, and write | `continuumM3LeadminerService` |
| M3 Merchant Service | Provides current merchant record; persists updated record | `continuumM3MerchantService` |
| Taxonomy Service | Provides business category reference data for dropdowns | `continuumTaxonomyService` |
| Salesforce | Provides or receives external UUID for merchant identity mapping | `salesForce` |

## Steps

1. **Operator opens edit form**: Operator navigates to `/m/:id/edit`
   - From: Operator browser
   - To: `continuumM3LeadminerService`
   - Protocol: REST (HTTP GET)

2. **Leadminer fetches current merchant record**: Leadminer calls M3 Merchant Service via m3_client to retrieve the current merchant data
   - From: `continuumM3LeadminerService`
   - To: `continuumM3MerchantService`
   - Protocol: REST/HTTP

3. **Leadminer fetches taxonomy data**: Leadminer calls Taxonomy Service to populate business category dropdowns
   - From: `continuumM3LeadminerService`
   - To: `continuumTaxonomyService`
   - Protocol: REST/HTTP

4. **Leadminer renders edit form**: Leadminer renders the populated merchant edit form
   - From: `continuumM3LeadminerService`
   - To: Operator browser
   - Protocol: HTTP (HTML response)

5. **Operator submits form with changes**: Operator fills in edits and submits the form
   - From: Operator browser
   - To: `continuumM3LeadminerService`
   - Protocol: REST (HTTP POST)

6. **Leadminer validates inputs**: Leadminer validates and normalizes phone numbers via `global_phone`, checks required fields
   - From: `continuumM3LeadminerService`
   - To: `continuumM3LeadminerService` (internal)
   - Protocol: direct

7. **Leadminer resolves Salesforce UUID** (if external mapping needed): Leadminer calls Salesforce API to map or retrieve the merchant's external UUID
   - From: `continuumM3LeadminerService`
   - To: `salesForce`
   - Protocol: REST/HTTP

8. **Leadminer writes updated merchant to M3 Merchant Service**: Leadminer submits the validated, updated merchant record via m3_client
   - From: `continuumM3LeadminerService`
   - To: `continuumM3MerchantService`
   - Protocol: REST/HTTP

9. **Leadminer redirects operator**: Leadminer redirects the operator to the merchant detail view with a success message
   - From: `continuumM3LeadminerService`
   - To: Operator browser
   - Protocol: HTTP (redirect)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Validation failure (e.g., invalid phone) | Form re-rendered with inline errors | Operator corrects and resubmits |
| M3 Merchant Service rejects update | Rails flash error shown | No data written; operator notified |
| Salesforce API unavailable | External UUID mapping skipped or error surfaced | Merchant saved without external UUID update |
| M3 Merchant Service unavailable on load | Rails error page | Edit form cannot be loaded |

## Sequence Diagram

```
Operator -> LeadminerApp: GET /m/:id/edit
LeadminerApp -> M3MerchantService: Fetch merchant record (m3_client)
M3MerchantService --> LeadminerApp: Merchant data (JSON)
LeadminerApp -> TaxonomyService: Fetch categories
TaxonomyService --> LeadminerApp: Taxonomy data (JSON)
LeadminerApp --> Operator: Rendered edit form (HTML)
Operator -> LeadminerApp: POST /m/:id/edit (form submission)
LeadminerApp -> LeadminerApp: Validate inputs (global_phone)
LeadminerApp -> Salesforce: Resolve external UUID
Salesforce --> LeadminerApp: External UUID
LeadminerApp -> M3MerchantService: Write updated merchant (m3_client)
M3MerchantService --> LeadminerApp: Success / Error
LeadminerApp --> Operator: Redirect to merchant detail view
```

## Related

- Architecture dynamic view: `dynamic-place-edit-flow`
- Related flows: [Search Merchants](search-merchants.md), [Edit Place](edit-place.md)
