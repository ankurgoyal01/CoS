---
service: "leadminer"
title: "Merge Places"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "merge-places"
flow_type: synchronous
trigger: "Operator initiates a merge of two duplicate Place records"
participants:
  - "continuumM3LeadminerService"
  - "continuumPlaceReadService"
  - "continuumPlaceWriteService"
architecture_ref: "dynamic-place-edit-flow"
---

# Merge Places

## Summary

An operator identifies two Place records as duplicates and initiates a merge via `/p/merge`. Leadminer presents both records for confirmation, then sends a merge instruction to the Place Write Service. The surviving canonical record is retained and the duplicate is removed or redirected in the M3 data store.

## Trigger

- **Type**: user-action
- **Source**: Operator selects two Place records and triggers merge at `/p/merge`
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator (browser) | Identifies duplicates, confirms merge | — |
| Leadminer Web App | Orchestrates merge request, renders confirmation, calls write service | `continuumM3LeadminerService` |
| Place Read Service | Provides full records for both places for confirmation display | `continuumPlaceReadService` |
| Place Write Service | Executes the merge operation in M3 data store | `continuumPlaceWriteService` |

## Steps

1. **Operator selects places to merge**: Operator selects two Place records from search results or detail views and navigates to `/p/merge`
   - From: Operator browser
   - To: `continuumM3LeadminerService`
   - Protocol: REST (HTTP GET with place IDs)

2. **Leadminer fetches both place records**: Leadminer calls Place Read Service to retrieve full details of both places for the confirmation screen
   - From: `continuumM3LeadminerService`
   - To: `continuumPlaceReadService`
   - Protocol: REST/HTTP

3. **Leadminer renders merge confirmation screen**: Leadminer presents both place records side-by-side for operator review and confirmation
   - From: `continuumM3LeadminerService`
   - To: Operator browser
   - Protocol: HTTP (HTML response)

4. **Operator confirms merge**: Operator selects the canonical (surviving) record and confirms the merge
   - From: Operator browser
   - To: `continuumM3LeadminerService`
   - Protocol: REST (HTTP POST)

5. **Leadminer sends merge instruction to Place Write Service**: Leadminer submits the merge request (canonical ID, duplicate ID) to the Place Write Service via m3_client
   - From: `continuumM3LeadminerService`
   - To: `continuumPlaceWriteService`
   - Protocol: REST/HTTP

6. **Leadminer confirms result to operator**: Leadminer redirects operator to the surviving canonical place record with a success message
   - From: `continuumM3LeadminerService`
   - To: Operator browser
   - Protocol: HTTP (redirect)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Place Write Service rejects merge | Error surfaced as Rails flash message | No merge performed; operator notified |
| One or both place IDs not found | Place Read Service returns 404 | Rails error page displayed |
| Operator cancels at confirmation | Redirect back to search results | No action taken |

## Sequence Diagram

```
Operator -> LeadminerApp: GET /p/merge?ids[]=A&ids[]=B
LeadminerApp -> PlaceReadService: Fetch place A (m3_client)
LeadminerApp -> PlaceReadService: Fetch place B (m3_client)
PlaceReadService --> LeadminerApp: Place A data
PlaceReadService --> LeadminerApp: Place B data
LeadminerApp --> Operator: Merge confirmation screen (HTML)
Operator -> LeadminerApp: POST /p/merge (confirm, canonical=A)
LeadminerApp -> PlaceWriteService: Merge places A + B (m3_client)
PlaceWriteService --> LeadminerApp: Success / Error
LeadminerApp --> Operator: Redirect to canonical place A
```

## Related

- Architecture dynamic view: `dynamic-place-edit-flow`
- Related flows: [Search Places](search-places.md), [Edit Place](edit-place.md), [Defrank Place](defrank-place.md)
