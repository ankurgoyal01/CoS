---
service: "itier-3pip-docs"
title: "API Documentation Rendering"
generated: "2026-03-03"
type: flow
flow_name: "api-documentation-rendering"
flow_type: synchronous
trigger: "Partner navigates to the 3PIP API documentation page"
participants:
  - "frontendBundle"
  - "redocPageController"
architecture_ref: "dynamic-continuumThreePipDocsWeb"
---

# API Documentation Rendering

## Summary

When a partner navigates to `/3pip/docs` or the Redoc-rendered documentation page, `itier-3pip-docs` authenticates the merchant user, merges the three versioned 3PIP OpenAPI specification packages (ingestion, transactional, and booking), dereferences all `$ref` pointers, and renders the Redoc documentation UI. Partners can also retrieve the merged OpenAPI spec as a downloadable `swagger.json` file via `GET /groupon-simulator/get-open-api-spec` with optional `operationId` filtering.

## Trigger

- **Type**: user-action
- **Source**: Partner browser navigates to `/3pip/docs` or the Groupon Developer Portal documentation URL; or the frontend SPA calls `GET /groupon-simulator/get-open-api-spec`
- **Frequency**: On-demand (per page load)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Partner Browser | Requests the documentation page or OpenAPI spec | External actor |
| `redocPageController` | Renders the `/3pip/docs` page with Redoc component | `continuumThreePipDocsWeb` |
| `frontendBundle` | Requests docs shell from the controller (SSR) | `continuumThreePipDocsWeb` |
| `simulatorApiActions` | Handles `getOpenApiSpec` action for spec download endpoint | `continuumThreePipDocsWeb` |

## Steps

### Path A: `/3pip/docs` Page Render

1. **Receives page request**: Partner browser sends `GET /3pip/docs`.
   - From: Partner browser
   - To: `redocPageController`
   - Protocol: HTTP GET

2. **Checks merchant authentication**: The `requireMerchantLogin` middleware checks `bypassMerchantAuth` feature flag. If `false`, validates merchant user session via `continuumUsersService`. If `true` (production), proceeds directly.
   - From: `redocPageController` (middleware)
   - To: `continuumUsersService` (when auth required)
   - Protocol: Cookie / OAuth token

3. **Renders docs page**: `redocPageController` calls the `redoc/index` controller action, which renders the Redoc page shell using the `itier-server` page renderer.
   - From: `redocPageController`
   - To: Partner browser
   - Protocol: HTTP 200 HTML

4. **Requests docs shell**: The rendered page loads the `frontendBundle` SPA, which calls back to `redocPageController` for the docs shell content.
   - From: `frontendBundle` (browser)
   - To: `redocPageController`
   - Protocol: HTTP (in-process via Preact/React rendering)

### Path B: OpenAPI Spec Download

1. **Requests OpenAPI spec**: Partner browser or SPA sends `GET /groupon-simulator/get-open-api-spec?operationId={optional}`.
   - From: `frontendBundle` (browser)
   - To: `simulatorApiActions`
   - Protocol: HTTP GET

2. **Merges OpenAPI specs**: `simulatorApiActions` calls `mergeOpenApiSpec()`, which combines the three 3PIP spec packages (`@grpn/grpn-3pip-ingestion-docs`, `@grpn/grpn-3pip-transactional-docs`, `@grpn/grpn-3pip-booking-docs`).
   - From: `simulatorApiActions` (in-process)

3. **Dereferences spec**: Calls `refParser.dereference()` via `json-schema-ref-parser` to resolve all `$ref` pointers, with circular reference handling set to `ignore`.
   - From: `simulatorApiActions` (in-process)

4. **Filters by operationId (optional)**: If `operationId` query param is provided, filters `swaggerFile.paths` to only include the matching operation and removes tags, servers, and info fields.
   - From: `simulatorApiActions` (in-process)

5. **Returns swagger.json**: Returns the merged (and optionally filtered) spec as a downloadable `swagger.json` file.
   - From: `simulatorApiActions`
   - To: `frontendBundle` (browser)
   - Protocol: HTTP 200 (file download, `Content-Disposition: attachment; filename=swagger.json`)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Merchant auth failure on `/3pip/docs` | Middleware catches auth failure | Redirect to `/merchant/center/login?redirect_uri=...` |
| `refParser.dereference` fails | Error caught; `json(err, 500)` returned | HTTP 500 returned to frontend |
| Top-level exception in `getOpenApiSpec` | Outer try/catch returns `json(error, 500)` | HTTP 500 returned |

## Sequence Diagram

```
Partner Browser -> redocPageController: GET /3pip/docs
redocPageController -> continuumUsersService: getMerchantUser() [if bypassMerchantAuth=false]
continuumUsersService --> redocPageController: merchant user or auth failure
redocPageController --> Partner Browser: HTTP 200 HTML (Redoc page)
frontendBundle -> simulatorApiActions: GET /groupon-simulator/get-open-api-spec
simulatorApiActions -> simulatorApiActions: mergeOpenApiSpec() [inline: ingestion + transactional + booking specs]
simulatorApiActions -> simulatorApiActions: refParser.dereference(mergedSpec)
simulatorApiActions --> frontendBundle: HTTP 200 swagger.json (file download)
```

## Related

- Architecture dynamic view: `dynamic-continuumThreePipDocsWeb`
- OpenAPI spec source: `doc/openapi.yml`
- Spec packages: `@grpn/grpn-3pip-ingestion-docs` v2.21.1, `@grpn/grpn-3pip-transactional-docs` v2.19.8, `@grpn/grpn-3pip-booking-docs` v1.2.1
- Related flows: [Partner Authentication](partner-authentication.md)
