---
service: "leadminer"
title: "View Input History"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "view-input-history"
flow_type: synchronous
trigger: "Operator navigates to the input history section for a place or merchant"
participants:
  - "continuumM3LeadminerService"
  - "continuumInputHistoryService"
architecture_ref: "dynamic-place-edit-flow"
---

# View Input History

## Summary

An operator navigates to `/i` to review the audit trail of changes made to a Place or Merchant record. Leadminer queries the Input History Service for the relevant history records and renders a paginated list of past changes, including timestamps, change types, and operator identities.

## Trigger

- **Type**: user-action
- **Source**: Operator navigates to `/i` or clicks through to input history from a Place or Merchant detail view
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator (browser) | Requests and reviews input history | — |
| Leadminer Web App | Receives request, queries Input History Service, renders history list | `continuumM3LeadminerService` |
| Input History Service | Stores and serves input history records for places and merchants | `continuumInputHistoryService` |

## Steps

1. **Operator requests input history**: Operator navigates to `/i` (optionally with a place or merchant ID filter)
   - From: Operator browser
   - To: `continuumM3LeadminerService`
   - Protocol: REST (HTTP GET)

2. **Leadminer queries Input History Service**: Leadminer calls the Input History Service via m3_client with the relevant entity ID and/or filters
   - From: `continuumM3LeadminerService`
   - To: `continuumInputHistoryService`
   - Protocol: REST/HTTP

3. **Input History Service returns history records**: Input History Service returns a paginated list of historical change records
   - From: `continuumInputHistoryService`
   - To: `continuumM3LeadminerService`
   - Protocol: REST/HTTP (JSON response)

4. **Leadminer renders history page**: Leadminer renders the paginated input history list using HAML templates and `will_paginate`
   - From: `continuumM3LeadminerService`
   - To: Operator browser
   - Protocol: HTTP (HTML response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Input History Service unavailable | HTTP error from m3_client | Rails error page shown |
| No history found | Empty result set returned | Operator sees empty history list |

## Sequence Diagram

```
Operator -> LeadminerApp: GET /i?entity_id=X
LeadminerApp -> InputHistoryService: Fetch input history for entity X (m3_client)
InputHistoryService --> LeadminerApp: Paginated history records (JSON)
LeadminerApp --> Operator: Rendered history page (HTML)
```

## Related

- Architecture dynamic view: `dynamic-place-edit-flow`
- Related flows: [Edit Place](edit-place.md), [Edit Merchant](edit-merchant.md)
