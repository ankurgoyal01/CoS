---
service: "wolf-hound"
title: "Page Create and Save Flow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "page-create-save"
flow_type: synchronous
trigger: "Editor submits a new or updated editorial page from the workboard UI"
participants:
  - "bffApiLayer"
  - "routeControllers"
  - "domainServiceAdapters"
  - "outboundHttpClient"
  - "continuumWolfhoundApi"
  - "continuumWhUsersApi"
architecture_ref: "components-wolf-hound"
---

# Page Create and Save Flow

## Summary

A content editor composes or edits an editorial page in the Vue.js workboard and submits it for saving. The BFF route controllers validate the session and request payload, then the domain service adapters write the page data to `continuumWolfhoundApi`. If the operation requires permission checking, the Users API (`continuumWhUsersApi`) is consulted before the write is accepted.

## Trigger

- **Type**: user-action
- **Source**: Editor clicks Save or submits a new page form in the Vue.js workboard (`bffApiLayer`)
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Frontend API Layer | Submits page create/update request; receives save confirmation | `bffApiLayer` |
| Route Controllers | Receives, validates, and routes the create/save request | `routeControllers` |
| Domain Service Adapters | Calls Users API for permission check (if required) and Wolfhound API to persist the page | `domainServiceAdapters` |
| Outbound HTTP Client | Executes instrumented HTTP requests to upstream services | `outboundHttpClient` |
| Wolfhound API | Persists the new or updated editorial page | `continuumWolfhoundApi` |
| Users API | Validates the editor's session and group permissions | `continuumWhUsersApi` |

## Steps

1. **Submit page save request**: Editor submits the page form; the frontend API layer sends a POST or PUT to the BFF pages endpoint.
   - From: `bffApiLayer`
   - To: `routeControllers`
   - Protocol: REST (HTTP POST `/pages` or PUT `/pages/:id`)

2. **Validate session and permissions**: The route controller checks the session. If group-level permissions are required, it invokes the domain service adapter to query `continuumWhUsersApi`.
   - From: `routeControllers`
   - To: `domainServiceAdapters`
   - Protocol: direct (in-process)

3. **Check user group permissions**: The domain service adapter calls `continuumWhUsersApi` via the outbound HTTP client to confirm the editor has write access.
   - From: `outboundHttpClient`
   - To: `continuumWhUsersApi`
   - Protocol: REST (HTTP)

4. **Write page to Wolfhound API**: With permissions confirmed, the domain service adapter sends the page payload to `continuumWolfhoundApi` via the outbound HTTP client.
   - From: `outboundHttpClient`
   - To: `continuumWolfhoundApi`
   - Protocol: REST (HTTP POST or PUT)

5. **Return save result**: `continuumWolfhoundApi` persists the page and returns the saved page record or an error.
   - From: `continuumWolfhoundApi`
   - To: `domainServiceAdapters` -> `routeControllers` -> `bffApiLayer`
   - Protocol: REST (HTTP)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Session expired | `routeControllers` rejects request | BFF returns 401; editor redirected to login |
| Insufficient permissions | `continuumWhUsersApi` returns denial; adapter propagates | BFF returns 403; UI displays access denied |
| `continuumWolfhoundApi` unavailable | `outboundHttpClient` error propagated | BFF returns 500/503; UI displays save error |
| Validation failure (missing required fields) | `routeControllers` rejects before upstream call | BFF returns 400; UI highlights validation errors |

## Sequence Diagram

```
bffApiLayer          -> routeControllers        : POST /pages or PUT /pages/:id
routeControllers     -> domainServiceAdapters   : validate and invoke save workflow
domainServiceAdapters -> outboundHttpClient     : build permissions check request
outboundHttpClient   -> continuumWhUsersApi     : GET user/group permissions
continuumWhUsersApi  --> outboundHttpClient     : permissions result
outboundHttpClient   --> domainServiceAdapters  : permissions result
domainServiceAdapters -> outboundHttpClient     : build page write request
outboundHttpClient   -> continuumWolfhoundApi   : POST/PUT page payload
continuumWolfhoundApi --> outboundHttpClient    : saved page record or error
outboundHttpClient   --> domainServiceAdapters  : result
domainServiceAdapters --> routeControllers      : result
routeControllers     --> bffApiLayer            : HTTP response (saved page or error)
```

## Related

- Architecture dynamic view: `dynamic-editorial-publish-flow`
- Related flows: [Editorial Publish](editorial-publish.md), [Editor Page Load](editor-page-load.md)
