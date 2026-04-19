---
service: "leadminer"
title: "Defrank Place"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "defrank-place"
flow_type: synchronous
trigger: "Operator triggers a defrank action on a Place record"
participants:
  - "continuumM3LeadminerService"
  - "continuumPlaceWriteService"
architecture_ref: "dynamic-place-edit-flow"
---

# Defrank Place

## Summary

An operator identifies a Place record as a stub or low-quality duplicate (a "frank") and triggers the defrank action at `/p/defrank`. Leadminer sends a defrank instruction to the Place Write Service, which updates the place's status in the M3 data store to indicate it is no longer a canonical or active record.

## Trigger

- **Type**: user-action
- **Source**: Operator triggers defrank from a Place record at `/p/defrank`
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator (browser) | Identifies place to defrank, confirms action | — |
| Leadminer Web App | Receives defrank request, forwards instruction to Place Write Service | `continuumM3LeadminerService` |
| Place Write Service | Applies defrank status update to the Place record in M3 | `continuumPlaceWriteService` |

## Steps

1. **Operator triggers defrank**: Operator selects a Place record and triggers the defrank action at `/p/defrank`
   - From: Operator browser
   - To: `continuumM3LeadminerService`
   - Protocol: REST (HTTP POST)

2. **Leadminer sends defrank instruction to Place Write Service**: Leadminer calls the Place Write Service via m3_client with the place ID and defrank operation
   - From: `continuumM3LeadminerService`
   - To: `continuumPlaceWriteService`
   - Protocol: REST/HTTP

3. **Place Write Service applies defrank**: Place Write Service updates the place record's status to defrankened in the M3 data store
   - From: `continuumPlaceWriteService`
   - To: M3 data store (internal to Place Write Service)
   - Protocol: direct (internal)

4. **Leadminer confirms result to operator**: Leadminer redirects operator with a success or error flash message
   - From: `continuumM3LeadminerService`
   - To: Operator browser
   - Protocol: HTTP (redirect)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Place Write Service returns error | Rails flash error message rendered | Defrank not applied; operator notified |
| Place ID not found | HTTP 404 from m3_client | Rails error page displayed |

## Sequence Diagram

```
Operator -> LeadminerApp: POST /p/defrank (place_id=X)
LeadminerApp -> PlaceWriteService: Defrank place X (m3_client)
PlaceWriteService --> LeadminerApp: Success / Error
LeadminerApp --> Operator: Redirect with result message
```

## Related

- Architecture dynamic view: `dynamic-place-edit-flow`
- Related flows: [Merge Places](merge-places.md), [Edit Place](edit-place.md)
