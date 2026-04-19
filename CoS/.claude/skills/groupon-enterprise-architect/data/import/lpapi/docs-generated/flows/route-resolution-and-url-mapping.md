---
service: "lpapi"
title: "Route Resolution and URL Mapping"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "route-resolution-and-url-mapping"
flow_type: synchronous
trigger: "HTTP GET to /lpapi/routes or a route-lookup API call with a URL path"
participants:
  - "continuumLpapiApp"
  - "appApiResources"
  - "appRoutingState"
  - "appDataAccess"
  - "continuumLpapiReadOnlyPostgres"
architecture_ref: "lpapiAppComponents"
---

# Route Resolution and URL Mapping

## Summary

Route resolution is the core read-path flow for LPAPI, used to map an incoming URL path (e.g., `/local/chicago/restaurants`) to a structured route model that identifies the corresponding landing page, locale, site, and taxonomy context. The `appRoutingState` component in `continuumLpapiApp` parses the URL using the LPURL library, resolves the route from the read replica, and returns the enriched route model to the caller.

## Trigger

- **Type**: api-call
- **Source**: Internal consumer (SEO tooling, downstream rendering service, or automated pipeline)
- **Frequency**: Per-request (on-demand, high-frequency read path)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API consumer | Sends the route resolution request | External to LPAPI |
| LPAPI App | Receives and processes the request | `continuumLpapiApp` |
| API Resources | Handles REST routing and dispatches to routing state | `appApiResources` |
| Routing State | Parses the URL and resolves the route model | `appRoutingState` |
| Data Access Layer | Reads route records from the read replica | `appDataAccess` |
| LPAPI Read-Only Postgres | Serves the route lookup query | `continuumLpapiReadOnlyPostgres` |

## Steps

1. **Receives route lookup request**: Consumer sends `GET /lpapi/routes` with a URL path parameter (or equivalent route resolution call)
   - From: API consumer
   - To: `appApiResources`
   - Protocol: REST / HTTP

2. **Dispatches to routing state**: `appApiResources` delegates the request to `appRoutingState` for URL parsing and route resolution
   - From: `appApiResources`
   - To: `appRoutingState`
   - Protocol: direct (in-process)

3. **Parses URL path**: `appRoutingState` uses the LPURL library to parse the incoming URL and extract route components (locale, division, category segments, location)
   - From: `appRoutingState`
   - To: LPURL (in-process library)
   - Protocol: direct

4. **Queries route store**: `appDataAccess` looks up the matching route record from `continuumLpapiReadOnlyPostgres` using the parsed URL components
   - From: `appDataAccess`
   - To: `continuumLpapiReadOnlyPostgres`
   - Protocol: JDBC

5. **Returns route model**: `appRoutingState` assembles the enriched route model (page ID, locale, site context, taxonomy category) and returns it via `appApiResources`
   - From: `appRoutingState`
   - To: `appApiResources`
   - Protocol: direct (in-process)

6. **Returns HTTP response**: `appApiResources` serializes the route model and returns HTTP 200
   - From: `continuumLpapiApp`
   - To: API consumer
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| URL path does not match any route | No record found in DB | HTTP 404 Not Found |
| Malformed URL path | LPURL parse failure in `appRoutingState` | HTTP 400 Bad Request |
| Read replica unavailable | JDBC connection failure | HTTP 503 or 500 |
| Ambiguous route match | Route store returns multiple candidates | `appRoutingState` applies site/locale precedence rules to select best match |

## Sequence Diagram

```
Consumer -> appApiResources: GET /lpapi/routes?path=/local/chicago/restaurants
appApiResources -> appRoutingState: resolve route for URL path
appRoutingState -> LPURL: parse URL segments (locale, division, category, location)
LPURL --> appRoutingState: parsed route components
appRoutingState -> appDataAccess: lookup route by parsed components
appDataAccess -> continuumLpapiReadOnlyPostgres: SELECT route WHERE path matches
continuumLpapiReadOnlyPostgres --> appDataAccess: route record
appDataAccess --> appRoutingState: route domain model
appRoutingState --> appApiResources: enriched route model (page ID, locale, site, taxonomy)
appApiResources --> Consumer: HTTP 200 route model JSON
```

## Related

- Architecture component view: `lpapiAppComponents`
- Related flows: [Landing Page CRUD](landing-page-crud.md), [Auto-Index Analysis Job](auto-index-analysis-job.md)
