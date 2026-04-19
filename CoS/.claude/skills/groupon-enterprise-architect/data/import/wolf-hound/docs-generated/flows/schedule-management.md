---
service: "wolf-hound"
title: "Schedule Management Flow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "schedule-management"
flow_type: synchronous
trigger: "Editor creates or modifies a scheduled publish entry for an editorial page"
participants:
  - "bffApiLayer"
  - "routeControllers"
  - "domainServiceAdapters"
  - "outboundHttpClient"
  - "continuumWolfhoundApi"
architecture_ref: "components-wolf-hound"
---

# Schedule Management Flow

## Summary

Content editors schedule editorial pages for future publish at a specified date and time using the Wolfhound workboard. Schedule CRUD operations are routed through the BFF to `continuumWolfhoundApi`, which stores the schedule entry. The scheduling engine within `continuumWolfhoundApi` is responsible for executing the publish action at the configured time; the BFF's role is limited to creating, updating, and deleting schedule entries.

## Trigger

- **Type**: user-action
- **Source**: Editor creates, updates, or deletes a schedule entry in the workboard (`bffApiLayer`)
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Frontend API Layer | Submits schedule CRUD request; displays confirmation or error | `bffApiLayer` |
| Route Controllers | Receives, validates, and routes the schedule operation | `routeControllers` |
| Domain Service Adapters | Proxies schedule operation to `continuumWolfhoundApi` | `domainServiceAdapters` |
| Outbound HTTP Client | Executes instrumented HTTP request to `continuumWolfhoundApi` | `outboundHttpClient` |
| Wolfhound API | Persists schedule entry; owns the scheduling engine that triggers publish | `continuumWolfhoundApi` |

## Steps

1. **Submit schedule request**: Editor specifies a future publish date/time and submits the schedule form; the frontend API layer sends the request to the BFF schedules endpoint.
   - From: `bffApiLayer`
   - To: `routeControllers`
   - Protocol: REST (GET `/schedules`, POST `/schedules`, PUT `/schedules/:id`, DELETE `/schedules/:id`)

2. **Validate and route**: The route controller validates the session and schedule payload (e.g., valid future timestamp, associated page ID), then delegates to the domain service adapter.
   - From: `routeControllers`
   - To: `domainServiceAdapters`
   - Protocol: direct (in-process)

3. **Build upstream schedule request**: The domain service adapter constructs the schedule payload for `continuumWolfhoundApi`.
   - From: `domainServiceAdapters`
   - To: `outboundHttpClient`
   - Protocol: direct (in-process)

4. **Write schedule entry to Wolfhound API**: The outbound HTTP client sends the schedule create/update/delete request to `continuumWolfhoundApi`.
   - From: `outboundHttpClient`
   - To: `continuumWolfhoundApi`
   - Protocol: REST (HTTP)

5. **Return schedule confirmation**: `continuumWolfhoundApi` stores the schedule entry and returns a confirmation with the scheduled time and associated page reference.
   - From: `continuumWolfhoundApi`
   - To: `domainServiceAdapters` -> `routeControllers` -> `bffApiLayer`
   - Protocol: REST (HTTP)

6. **Scheduled publish execution** (out-of-band): At the configured time, `continuumWolfhoundApi`'s internal scheduling engine triggers the publish operation. This step occurs entirely within `continuumWolfhoundApi` and is not mediated by the BFF.
   - From: `continuumWolfhoundApi` (scheduler)
   - To: `continuumWolfhoundApi` (publish logic)
   - Protocol: internal

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Session expired | `routeControllers` rejects request | BFF returns 401; editor redirected to login |
| Invalid schedule time (past timestamp) | `routeControllers` validates and rejects | BFF returns 400; UI displays validation error |
| `continuumWolfhoundApi` unavailable | `outboundHttpClient` error propagated | BFF returns 500/503; schedule entry not created |
| Schedule entry not found (PUT/DELETE) | `continuumWolfhoundApi` returns 404 | BFF returns 404; UI displays not-found error |

## Sequence Diagram

```
bffApiLayer           -> routeControllers       : POST/PUT/DELETE /schedules[/:id]
routeControllers      -> domainServiceAdapters  : validate and invoke schedule workflow
domainServiceAdapters -> outboundHttpClient     : build schedule operation request
outboundHttpClient    -> continuumWolfhoundApi  : HTTP schedule CRUD request
continuumWolfhoundApi --> outboundHttpClient    : schedule confirmation or error
outboundHttpClient    --> domainServiceAdapters : result
domainServiceAdapters --> routeControllers      : result
routeControllers      --> bffApiLayer           : HTTP response (schedule confirmation or error)
[at scheduled time]
continuumWolfhoundApi  -> continuumWolfhoundApi : internal scheduler triggers publish
```

## Related

- Architecture dynamic view: `dynamic-editorial-publish-flow`
- Related flows: [Editorial Publish](editorial-publish.md), [Page Create and Save](page-create-save.md)
