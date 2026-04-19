---
service: "wolf-hound"
title: "Editorial Publish Flow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "editorial-publish"
flow_type: synchronous
trigger: "Editor clicks the Publish action in the workboard UI"
participants:
  - "bffApiLayer"
  - "routeControllers"
  - "domainServiceAdapters"
  - "outboundHttpClient"
  - "continuumWolfhoundApi"
  - "viewRenderingLayer"
architecture_ref: "dynamic-editorial-publish-flow"
---

# Editorial Publish Flow

## Summary

An editorial author initiates a publish action from the Vue.js workboard UI. The request travels through the BFF's frontend API layer to the route controllers, which validate the request and delegate to the domain service adapters. The adapters build an outbound HTTP call via the shared outbound HTTP client and deliver the publish instruction to `continuumWolfhoundApi`. Upon completion, the UI receives updated content views rendered by the view rendering layer.

## Trigger

- **Type**: user-action
- **Source**: Editor clicks Publish in the Vue.js workboard (`bffApiLayer`)
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Frontend API Layer | Initiates publish action from the browser; receives updated view after completion | `bffApiLayer` |
| Route Controllers | Receives and validates the publish request; selects the appropriate service workflow | `routeControllers` |
| Domain Service Adapters | Orchestrates the downstream call to Wolfhound API | `domainServiceAdapters` |
| Outbound HTTP Client | Executes the instrumented HTTP request to `continuumWolfhoundApi` | `outboundHttpClient` |
| Wolfhound API | Accepts the publish instruction and persists the state change | `continuumWolfhoundApi` |
| View Rendering Layer | Renders and returns updated content views to the frontend | `viewRenderingLayer` |

## Steps

1. **Submit publish action**: Editor clicks Publish; the frontend API layer sends a POST request to the BFF publish endpoint.
   - From: `bffApiLayer`
   - To: `routeControllers`
   - Protocol: REST (HTTP POST to `/pages/:id/publish`)

2. **Validate request and select workflow**: The route controller validates the incoming request (auth session, required fields) and invokes the domain service adapter for the publish workflow.
   - From: `routeControllers`
   - To: `domainServiceAdapters`
   - Protocol: direct (in-process)

3. **Build outbound API request**: The domain service adapter constructs the HTTP request payload and passes it to the outbound HTTP client.
   - From: `domainServiceAdapters`
   - To: `outboundHttpClient`
   - Protocol: direct (in-process)

4. **Deliver publish instruction to Wolfhound API**: The outbound HTTP client sends the authenticated HTTP request to `continuumWolfhoundApi`.
   - From: `outboundHttpClient`
   - To: `continuumWolfhoundApi`
   - Protocol: REST (HTTP)

5. **Return publish result**: `continuumWolfhoundApi` processes the publish and returns a success or error response to the BFF.
   - From: `continuumWolfhoundApi`
   - To: `outboundHttpClient` -> `domainServiceAdapters` -> `routeControllers`
   - Protocol: REST (HTTP)

6. **Render updated content view**: After workflow execution, the frontend API layer requests updated content views from the view rendering layer to reflect the published state.
   - From: `bffApiLayer`
   - To: `viewRenderingLayer`
   - Protocol: direct (in-process / HTTP)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `continuumWolfhoundApi` unreachable | `outboundHttpClient` returns error; `domainServiceAdapters` propagates upstream | BFF returns 500/503 to frontend; UI displays error message |
| Invalid publish request (missing fields) | `routeControllers` rejects with validation error | BFF returns 400 to frontend; UI displays validation error |
| Auth session invalid | `routeControllers` rejects before reaching adapters | BFF returns 401/403; editor redirected to login |
| `continuumWolfhoundApi` returns business error | Propagated from adapter to route controller | BFF returns appropriate HTTP error; UI surfaces the message |

## Sequence Diagram

```
bffApiLayer        -> routeControllers    : POST /pages/:id/publish (submit publish action)
routeControllers   -> domainServiceAdapters : validate and invoke publish workflow
domainServiceAdapters -> outboundHttpClient : build outbound publish request
outboundHttpClient -> continuumWolfhoundApi : HTTP POST publish instruction
continuumWolfhoundApi --> outboundHttpClient : publish result (success/error)
outboundHttpClient --> domainServiceAdapters : result
domainServiceAdapters --> routeControllers   : result
routeControllers   --> bffApiLayer           : HTTP response
bffApiLayer        -> viewRenderingLayer    : render updated content views
viewRenderingLayer --> bffApiLayer           : updated view response
```

## Related

- Architecture dynamic view: `dynamic-editorial-publish-flow`
- Related flows: [Page Create and Save](page-create-save.md), [Schedule Management](schedule-management.md)
