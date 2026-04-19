---
service: "wolf-hound"
title: "Template Management Flow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "template-management"
flow_type: synchronous
trigger: "Editor creates, updates, or deletes an editorial template"
participants:
  - "bffApiLayer"
  - "routeControllers"
  - "domainServiceAdapters"
  - "outboundHttpClient"
  - "continuumWolfhoundApi"
architecture_ref: "components-wolf-hound"
---

# Template Management Flow

## Summary

Editorial administrators manage page templates through the Wolfhound workboard UI. CRUD operations on templates are routed through the BFF's route controllers and domain service adapters, which proxy the requests to `continuumWolfhoundApi` for persistence. Templates define the structural layout used when creating new editorial pages.

## Trigger

- **Type**: user-action
- **Source**: Editor submits a template create, update, or delete action from the workboard (`bffApiLayer`)
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Frontend API Layer | Initiates template CRUD request; receives operation result | `bffApiLayer` |
| Route Controllers | Receives and validates the template operation request | `routeControllers` |
| Domain Service Adapters | Proxies template operation to `continuumWolfhoundApi` | `domainServiceAdapters` |
| Outbound HTTP Client | Executes instrumented HTTP request to `continuumWolfhoundApi` | `outboundHttpClient` |
| Wolfhound API | Persists template create/update/delete and returns result | `continuumWolfhoundApi` |

## Steps

1. **Submit template operation**: Editor submits the template form or delete action; the frontend API layer sends the appropriate HTTP request to the BFF templates endpoint.
   - From: `bffApiLayer`
   - To: `routeControllers`
   - Protocol: REST (GET `/templates`, POST `/templates`, PUT `/templates/:id`, DELETE `/templates/:id`)

2. **Validate and route**: The route controller validates the session and request, then invokes the domain service adapter for the template operation.
   - From: `routeControllers`
   - To: `domainServiceAdapters`
   - Protocol: direct (in-process)

3. **Build upstream request**: The domain service adapter constructs the request payload and routes it to the outbound HTTP client.
   - From: `domainServiceAdapters`
   - To: `outboundHttpClient`
   - Protocol: direct (in-process)

4. **Proxy template operation to Wolfhound API**: The outbound HTTP client sends the template create/update/delete request to `continuumWolfhoundApi`.
   - From: `outboundHttpClient`
   - To: `continuumWolfhoundApi`
   - Protocol: REST (HTTP)

5. **Return result**: `continuumWolfhoundApi` persists the change and returns a success or error response.
   - From: `continuumWolfhoundApi`
   - To: `routeControllers` -> `bffApiLayer`
   - Protocol: REST (HTTP)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Session expired | `routeControllers` rejects before upstream call | BFF returns 401; editor redirected to login |
| Template not found (PUT/DELETE on unknown ID) | `continuumWolfhoundApi` returns 404; propagated through adapters | BFF returns 404; UI displays not-found error |
| `continuumWolfhoundApi` unavailable | `outboundHttpClient` error propagated | BFF returns 500/503; UI displays operation error |
| Validation failure | `routeControllers` rejects request | BFF returns 400; UI displays validation errors |

## Sequence Diagram

```
bffApiLayer           -> routeControllers       : POST/PUT/DELETE /templates[/:id]
routeControllers      -> domainServiceAdapters  : validate and invoke template workflow
domainServiceAdapters -> outboundHttpClient     : build template operation request
outboundHttpClient    -> continuumWolfhoundApi  : HTTP template CRUD request
continuumWolfhoundApi --> outboundHttpClient    : operation result or error
outboundHttpClient    --> domainServiceAdapters : result
domainServiceAdapters --> routeControllers      : result
routeControllers      --> bffApiLayer           : HTTP response
```

## Related

- Architecture dynamic view: `dynamic-editorial-publish-flow`
- Related flows: [Page Create and Save](page-create-save.md), [Schedule Management](schedule-management.md)
