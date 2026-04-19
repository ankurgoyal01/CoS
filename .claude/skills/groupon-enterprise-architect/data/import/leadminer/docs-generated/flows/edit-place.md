---
service: "leadminer"
title: "Edit Place"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "edit-place"
flow_type: synchronous
trigger: "Operator opens and submits an edit form for a Place record"
participants:
  - "continuumM3LeadminerService"
  - "continuumPlaceReadService"
  - "continuumPlaceWriteService"
  - "continuumTaxonomyService"
  - "continuumGeoDetailsService"
architecture_ref: "dynamic-place-edit-flow"
---

# Edit Place

## Summary

An operator selects a Place record and opens its edit form. Leadminer fetches the current place data from the Place Read Service and enriches the form with taxonomy (business categories, services) and geocode reference data. On form submission, Leadminer validates the input (including phone number normalization via `global_phone`) and writes the updated record to the Place Write Service.

## Trigger

- **Type**: user-action
- **Source**: Operator clicks edit on a Place record at `/p/:id/edit`
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator (browser) | Initiates edit, submits form | — |
| Leadminer Web App | Orchestrates data fetch, form render, validation, and write | `continuumM3LeadminerService` |
| Place Read Service | Provides current place record data | `continuumPlaceReadService` |
| Place Write Service | Persists validated place edits | `continuumPlaceWriteService` |
| Taxonomy Service | Provides business category and service taxonomy options | `continuumTaxonomyService` |
| GeoDetails Service | Resolves geocoordinates for address validation | `continuumGeoDetailsService` |

## Steps

1. **Operator opens edit form**: Operator navigates to `/p/:id/edit`
   - From: Operator browser
   - To: `continuumM3LeadminerService`
   - Protocol: REST (HTTP GET)

2. **Leadminer fetches current place record**: Leadminer calls Place Read Service via m3_client to retrieve the current place data
   - From: `continuumM3LeadminerService`
   - To: `continuumPlaceReadService`
   - Protocol: REST/HTTP

3. **Leadminer fetches taxonomy reference data**: Leadminer calls Taxonomy Service to populate business category and service dropdowns
   - From: `continuumM3LeadminerService`
   - To: `continuumTaxonomyService`
   - Protocol: REST/HTTP

4. **Leadminer renders edit form**: Leadminer renders the populated edit form using HAML templates
   - From: `continuumM3LeadminerService`
   - To: Operator browser
   - Protocol: HTTP (HTML response)

5. **Operator submits form with changes**: Operator fills in edits and submits the form
   - From: Operator browser
   - To: `continuumM3LeadminerService`
   - Protocol: REST (HTTP POST)

6. **Leadminer validates inputs**: Leadminer validates phone numbers via `global_phone`, checks required fields, and normalizes data
   - From: `continuumM3LeadminerService`
   - To: `continuumM3LeadminerService` (internal)
   - Protocol: direct

7. **Leadminer resolves geocode** (if address changed): Leadminer calls GeoDetails Service to validate/resolve the updated address
   - From: `continuumM3LeadminerService`
   - To: `continuumGeoDetailsService`
   - Protocol: REST/HTTP

8. **Leadminer writes updated place to Place Write Service**: Leadminer submits the validated, updated place record to the Place Write Service via m3_client
   - From: `continuumM3LeadminerService`
   - To: `continuumPlaceWriteService`
   - Protocol: REST/HTTP

9. **Leadminer redirects operator**: Leadminer redirects the operator to the place detail view with a success message
   - From: `continuumM3LeadminerService`
   - To: Operator browser
   - Protocol: HTTP (redirect)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Validation failure (e.g., invalid phone) | Form re-rendered with inline error messages | Operator corrects and resubmits |
| Place Write Service rejects update | HTTP error from m3_client surfaced as Rails flash error | Operator sees error; no data written |
| GeoDetails Service unavailable | Geocode step skipped or error surfaced | Address may not be validated; operator notified |
| Place Read Service unavailable | Rails error page | Edit form cannot be loaded |

## Sequence Diagram

```
Operator -> LeadminerApp: GET /p/:id/edit
LeadminerApp -> PlaceReadService: Fetch place record (m3_client)
PlaceReadService --> LeadminerApp: Place data (JSON)
LeadminerApp -> TaxonomyService: Fetch categories/services
TaxonomyService --> LeadminerApp: Taxonomy data (JSON)
LeadminerApp --> Operator: Rendered edit form (HTML)
Operator -> LeadminerApp: POST /p/:id/edit (form submission)
LeadminerApp -> LeadminerApp: Validate inputs (global_phone, required fields)
LeadminerApp -> GeoDetailsService: Resolve geocode (if address changed)
GeoDetailsService --> LeadminerApp: Geocoordinates
LeadminerApp -> PlaceWriteService: Write updated place (m3_client)
PlaceWriteService --> LeadminerApp: Success / Error
LeadminerApp --> Operator: Redirect to place detail view
```

## Related

- Architecture dynamic view: `dynamic-place-edit-flow`
- Related flows: [Search Places](search-places.md), [Merge Places](merge-places.md), [Defrank Place](defrank-place.md)
