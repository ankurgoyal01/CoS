---
service: "leadminer"
title: "Search Places"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "search-places"
flow_type: synchronous
trigger: "Operator submits a place search query via the /p route"
participants:
  - "continuumM3LeadminerService"
  - "continuumPlaceReadService"
architecture_ref: "dynamic-place-edit-flow"
---

# Search Places

## Summary

An internal operator navigates to `/p` and submits a search query for Place records. Leadminer forwards the query to the Place Read Service, receives a paginated list of matching places, and renders the results as an HTML page. The operator can then click through to view or edit an individual place.

## Trigger

- **Type**: user-action
- **Source**: Operator submits search form at `/p` in the browser
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator (browser) | Initiates search, views results | — |
| Leadminer Web App | Receives HTTP request, forwards query to Place Read Service, renders results | `continuumM3LeadminerService` |
| Place Read Service | Executes place search, returns paginated results | `continuumPlaceReadService` |

## Steps

1. **Operator submits search**: Operator enters search terms (name, address, etc.) in the `/p` form and submits
   - From: Operator browser
   - To: `continuumM3LeadminerService`
   - Protocol: REST (HTTP GET with query params)

2. **Leadminer forwards query to Place Read Service**: Leadminer constructs a search request using m3_client and calls the Place Read Service
   - From: `continuumM3LeadminerService`
   - To: `continuumPlaceReadService`
   - Protocol: REST/HTTP

3. **Place Read Service returns results**: Place Read Service executes the search and returns a paginated list of matching Place records
   - From: `continuumPlaceReadService`
   - To: `continuumM3LeadminerService`
   - Protocol: REST/HTTP (JSON response)

4. **Leadminer renders results page**: Leadminer renders the paginated results as an HTML view using HAML templates and `will_paginate`
   - From: `continuumM3LeadminerService`
   - To: Operator browser
   - Protocol: HTTP (HTML response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Place Read Service unavailable | HTTP error returned from m3_client | Rails error page shown to operator |
| No results found | Empty result set returned | Operator sees empty results list |
| Invalid search parameters | Rails parameter validation | Form re-rendered with validation errors |

## Sequence Diagram

```
Operator -> LeadminerApp: GET /p?query=...
LeadminerApp -> PlaceReadService: Search places (m3_client)
PlaceReadService --> LeadminerApp: Paginated place results (JSON)
LeadminerApp --> Operator: Rendered HTML results page
```

## Related

- Architecture dynamic view: `dynamic-place-edit-flow`
- Related flows: [Edit Place](edit-place.md), [Merge Places](merge-places.md)
