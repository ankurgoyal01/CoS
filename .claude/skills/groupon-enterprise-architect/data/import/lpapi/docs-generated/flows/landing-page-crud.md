---
service: "lpapi"
title: "Landing Page CRUD"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "landing-page-crud"
flow_type: synchronous
trigger: "HTTP request to /lpapi/pages, /lpapi/routes, /lpapi/crosslinks, /lpapi/attribute-types, /lpapi/locations, or /lpapi/divisions"
participants:
  - "continuumLpapiApp"
  - "appApiResources"
  - "appDataAccess"
  - "continuumLpapiPrimaryPostgres"
  - "continuumLpapiReadOnlyPostgres"
architecture_ref: "lpapiAppComponents"
---

# Landing Page CRUD

## Summary

This flow covers the creation, retrieval, update, and deletion of landing page records and their associated entities (routes, crosslinks, attribute types, locations, divisions). It is the primary data management flow for the LPAPI service and is triggered by internal consumers — CMS operators, SEO tooling, or automated pipelines — via REST calls to `continuumLpapiApp`.

## Trigger

- **Type**: api-call
- **Source**: Internal consumer (CMS operator, SEO tooling, or automated pipeline)
- **Frequency**: On-demand per operator or automation action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API consumer | Initiates the REST request | External to LPAPI |
| LPAPI App | Receives and processes the request | `continuumLpapiApp` |
| API Resources | Handles REST routing and request binding | `appApiResources` |
| Data Access Layer | Executes SQL reads and writes | `appDataAccess` |
| LPAPI Primary Postgres | Receives all write operations | `continuumLpapiPrimaryPostgres` |
| LPAPI Read-Only Postgres | Serves read (GET) requests | `continuumLpapiReadOnlyPostgres` |

## Steps

### Create (POST)

1. **Receives create request**: Consumer sends `POST /lpapi/pages` (or equivalent endpoint) with a JSON body
   - From: API consumer
   - To: `appApiResources` in `continuumLpapiApp`
   - Protocol: REST / HTTP

2. **Validates and binds request**: `appApiResources` validates the request payload and binds it to the internal domain model
   - From: `appApiResources`
   - To: `appDataAccess`
   - Protocol: direct (in-process)

3. **Writes record to database**: `appDataAccess` inserts the new entity into `continuumLpapiPrimaryPostgres`
   - From: `appDataAccess`
   - To: `continuumLpapiPrimaryPostgres`
   - Protocol: JDBC

4. **Returns created record**: `appApiResources` returns the created entity with HTTP 201
   - From: `continuumLpapiApp`
   - To: API consumer
   - Protocol: REST / HTTP

### Read (GET)

1. **Receives read request**: Consumer sends `GET /lpapi/pages/{id}` or a list query
   - From: API consumer
   - To: `appApiResources` in `continuumLpapiApp`
   - Protocol: REST / HTTP

2. **Queries read replica**: `appDataAccess` reads the entity from `continuumLpapiReadOnlyPostgres`
   - From: `appDataAccess`
   - To: `continuumLpapiReadOnlyPostgres`
   - Protocol: JDBC

3. **Returns entity**: `appApiResources` serializes the result and returns HTTP 200
   - From: `continuumLpapiApp`
   - To: API consumer
   - Protocol: REST / HTTP

### Update (PUT)

1. **Receives update request**: Consumer sends `PUT /lpapi/pages/{id}` with the updated payload
   - From: API consumer
   - To: `appApiResources`
   - Protocol: REST / HTTP

2. **Validates and applies update**: `appDataAccess` updates the record in `continuumLpapiPrimaryPostgres`
   - From: `appDataAccess`
   - To: `continuumLpapiPrimaryPostgres`
   - Protocol: JDBC

3. **Returns updated record**: HTTP 200 with updated entity
   - From: `continuumLpapiApp`
   - To: API consumer
   - Protocol: REST / HTTP

### Delete (DELETE)

1. **Receives delete request**: Consumer sends `DELETE /lpapi/pages/{id}`
   - From: API consumer
   - To: `appApiResources`
   - Protocol: REST / HTTP

2. **Deletes record**: `appDataAccess` removes the entity from `continuumLpapiPrimaryPostgres`
   - From: `appDataAccess`
   - To: `continuumLpapiPrimaryPostgres`
   - Protocol: JDBC

3. **Returns confirmation**: HTTP 204 No Content
   - From: `continuumLpapiApp`
   - To: API consumer
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid request payload | Validation error in `appApiResources` | HTTP 422 with field-level error list |
| Entity not found (GET/PUT/DELETE) | Not-found check in `appDataAccess` | HTTP 404 |
| PostgreSQL write failure | Exception propagates to `appApiResources` | HTTP 500 |
| Duplicate/conflict on create | Database constraint violation | HTTP 409 or HTTP 422 |

## Sequence Diagram

```
Consumer -> appApiResources: POST/GET/PUT/DELETE /lpapi/pages/{id}
appApiResources -> appDataAccess: bind and delegate operation
appDataAccess -> continuumLpapiPrimaryPostgres: INSERT/UPDATE/DELETE (writes)
appDataAccess -> continuumLpapiReadOnlyPostgres: SELECT (reads)
continuumLpapiPrimaryPostgres --> appDataAccess: write confirmation
continuumLpapiReadOnlyPostgres --> appDataAccess: result rows
appDataAccess --> appApiResources: domain entity
appApiResources --> Consumer: HTTP 200/201/204/4xx/5xx
```

## Related

- Architecture component view: `lpapiAppComponents`
- Related flows: [Route Resolution and URL Mapping](route-resolution-and-url-mapping.md), [Taxonomy Sync and Category Management](taxonomy-sync-and-category-management.md)
