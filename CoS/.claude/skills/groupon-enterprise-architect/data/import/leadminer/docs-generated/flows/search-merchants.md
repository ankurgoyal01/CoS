---
service: "leadminer"
title: "Search Merchants"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "search-merchants"
flow_type: synchronous
trigger: "Operator submits a merchant search query via the /m route"
participants:
  - "continuumM3LeadminerService"
  - "continuumM3MerchantService"
architecture_ref: "dynamic-place-edit-flow"
---

# Search Merchants

## Summary

An internal operator navigates to `/m` and submits a search query to find Merchant records. Leadminer forwards the query to the M3 Merchant Service, receives a paginated list of matching merchants, and renders the results as an HTML page. The operator can then click through to view or edit an individual merchant.

## Trigger

- **Type**: user-action
- **Source**: Operator submits search form at `/m` in the browser
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator (browser) | Initiates search, views results | — |
| Leadminer Web App | Receives HTTP request, forwards query, renders results | `continuumM3LeadminerService` |
| M3 Merchant Service | Executes merchant search, returns paginated results | `continuumM3MerchantService` |

## Steps

1. **Operator submits merchant search**: Operator enters search criteria at `/m` and submits
   - From: Operator browser
   - To: `continuumM3LeadminerService`
   - Protocol: REST (HTTP GET with query params)

2. **Leadminer forwards query to M3 Merchant Service**: Leadminer constructs a search request via m3_client and calls the M3 Merchant Service
   - From: `continuumM3LeadminerService`
   - To: `continuumM3MerchantService`
   - Protocol: REST/HTTP

3. **M3 Merchant Service returns results**: M3 Merchant Service executes the search and returns a paginated list of matching Merchant records
   - From: `continuumM3MerchantService`
   - To: `continuumM3LeadminerService`
   - Protocol: REST/HTTP (JSON response)

4. **Leadminer renders results page**: Leadminer renders the paginated merchant results as an HTML view using HAML and `will_paginate`
   - From: `continuumM3LeadminerService`
   - To: Operator browser
   - Protocol: HTTP (HTML response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| M3 Merchant Service unavailable | HTTP error from m3_client | Rails error page shown to operator |
| No results found | Empty result set returned | Operator sees empty results list |
| Invalid search parameters | Rails parameter validation | Form re-rendered with errors |

## Sequence Diagram

```
Operator -> LeadminerApp: GET /m?query=...
LeadminerApp -> M3MerchantService: Search merchants (m3_client)
M3MerchantService --> LeadminerApp: Paginated merchant results (JSON)
LeadminerApp --> Operator: Rendered HTML results page
```

## Related

- Architecture dynamic view: `dynamic-place-edit-flow`
- Related flows: [Edit Merchant](edit-merchant.md), [Search Places](search-places.md)
