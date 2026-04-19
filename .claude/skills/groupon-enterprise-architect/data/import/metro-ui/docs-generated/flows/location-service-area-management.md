---
service: "metro-ui"
title: "Location and Service Area Management"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "location-service-area-management"
flow_type: synchronous
trigger: "Merchant adds or modifies location/service area data in the deal creation UI"
participants:
  - "continuumMetroUiService"
  - "metroUi_routing"
  - "metroUi_integrationAdapters"
  - "continuumGeoDetailsService"
  - "continuumM3PlacesService"
  - "apiProxy"
  - "continuumDealManagementApi"
architecture_ref: "dynamic-metro-ui-draft-edit-flow"
---

# Location and Service Area Management

## Summary

This flow covers how merchants add, search, and manage location and service area data as part of deal creation. The merchant enters a location in the deal form; Metro UI calls `continuumGeoDetailsService` for geo autocomplete suggestions and `continuumM3PlacesService` to retrieve existing merchant place records. Once the merchant confirms a location, the selection is persisted to the deal via `continuumDealManagementApi`.

## Trigger

- **Type**: user-action
- **Source**: Merchant interacts with the location/service area input fields in the deal creation form
- **Frequency**: On-demand (per location search or service area update during deal editing)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant (Browser) | Types a location query or selects a merchant place | External user |
| Routing and Controllers | Receives location lookup requests and dispatches integration actions | `metroUi_routing` |
| Integration Adapters | Orchestrates geo autocomplete, place lookup, and deal update calls | `metroUi_integrationAdapters` |
| Geo Details Service | Provides geo/place autocomplete suggestions for location queries | `continuumGeoDetailsService` |
| M3 Places Service | Provides existing merchant place records for selection | `continuumM3PlacesService` |
| API Proxy | Routes deal update traffic to Deal Management API | `apiProxy` |
| Deal Management API | Persists the merchant's confirmed location/service area selection to the deal | `continuumDealManagementApi` |

## Steps

1. **Enter Location Query**: Merchant types a location name or address into the location input field.
   - From: Merchant Browser
   - To: `metroUi_routing` (debounced autocomplete request)
   - Protocol: HTTPS/JSON

2. **Dispatch Geo Autocomplete Lookup**: Route handler calls integration adapters to fetch autocomplete suggestions.
   - From: `metroUi_routing`
   - To: `metroUi_integrationAdapters`
   - Protocol: Internal

3. **Fetch Geo Autocomplete Suggestions**: Integration adapters call `continuumGeoDetailsService` with the query string.
   - From: `metroUi_integrationAdapters`
   - To: `continuumGeoDetailsService`
   - Protocol: HTTPS/JSON

4. **Return Autocomplete Results**: Geo Details Service returns matching place suggestions.
   - From: `continuumGeoDetailsService`
   - To: `metroUi_integrationAdapters`
   - Protocol: HTTPS/JSON

5. **Display Suggestions to Merchant**: Autocomplete suggestions are returned to the browser and displayed in the location input dropdown.
   - From: `metroUi_routing`
   - To: Merchant Browser
   - Protocol: HTTPS/JSON

6. **Fetch Merchant Places**: In parallel (or on page load), integration adapters fetch existing merchant place records from `continuumM3PlacesService`.
   - From: `metroUi_integrationAdapters`
   - To: `continuumM3PlacesService`
   - Protocol: HTTPS/JSON

7. **Return Merchant Places**: M3 Places Service returns the merchant's registered places.
   - From: `continuumM3PlacesService`
   - To: `metroUi_integrationAdapters`
   - Protocol: HTTPS/JSON

8. **Merchant Selects Location**: Merchant selects a suggested location or an existing merchant place.
   - From: Merchant Browser
   - To: Deal form (client-side Redux state)
   - Protocol: In-browser

9. **Persist Location to Deal**: Integration adapters update the deal record with the selected location/service area via `apiProxy` -> `continuumDealManagementApi`.
   - From: `metroUi_integrationAdapters`
   - To: `apiProxy` -> `continuumDealManagementApi`
   - Protocol: HTTPS/JSON

10. **Confirm Location Saved**: Deal Management API confirms the location update.
    - From: `continuumDealManagementApi`
    - To: Merchant Browser (via Metro UI response)
    - Protocol: HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `continuumGeoDetailsService` unreachable | Error returned to browser | Geo autocomplete unavailable; merchant must enter location manually if supported |
| `continuumM3PlacesService` unreachable | Error returned; places list empty | Merchant place selection unavailable in the form |
| `continuumDealManagementApi` error on location save | Error propagated to browser | Location not saved; merchant retains previously confirmed location |
| Geo service returns no results | Empty suggestions list returned | Merchant sees "no results" in autocomplete dropdown |

## Sequence Diagram

```
Merchant Browser -> metroUi_routing: Location autocomplete query (HTTPS/JSON)
metroUi_routing -> metroUi_integrationAdapters: Fetch geo autocomplete
metroUi_integrationAdapters -> continuumGeoDetailsService: Geo autocomplete request (HTTPS/JSON)
continuumGeoDetailsService --> metroUi_integrationAdapters: Autocomplete suggestions
metroUi_integrationAdapters -> continuumM3PlacesService: Fetch merchant places (HTTPS/JSON)
continuumM3PlacesService --> metroUi_integrationAdapters: Merchant place records
metroUi_integrationAdapters --> metroUi_routing: Aggregated location data
metroUi_routing --> Merchant Browser: Suggestions and merchant places
Merchant Browser -> metroUi_routing: Confirm location selection (HTTPS/JSON)
metroUi_routing -> metroUi_integrationAdapters: Persist location to deal
metroUi_integrationAdapters -> apiProxy: Update deal location (HTTPS/JSON)
apiProxy -> continuumDealManagementApi: Save location/service area (HTTPS/JSON)
continuumDealManagementApi --> apiProxy: Confirmed update
apiProxy --> metroUi_integrationAdapters: Confirmed update
metroUi_integrationAdapters --> Merchant Browser: Location saved confirmation
```

## Related

- Architecture dynamic view: `dynamic-metro-ui-draft-edit-flow`
- Related flows: [Deal Creation and Draft](deal-creation-and-draft.md), [Deal Publication](deal-publication.md)
