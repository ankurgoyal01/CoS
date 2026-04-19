---
service: "bhuvan"
title: "Taxonomy Place Management"
generated: "2026-03-03"
type: flow
flow_name: "taxonomy-place-management"
flow_type: synchronous
trigger: "HTTP GET/POST/PUT/DELETE to /places, /sources, /placeTypes, /indexes, or /relationshipTypes"
participants:
  - "continuumBhuvanService_httpApiTaxonomy"
  - "continuumBhuvanService_roDataStore"
  - "continuumBhuvanService_rwDataStore"
  - "continuumBhuvanPostgres"
architecture_ref: "dynamic-continuum-bhuvan-taxonomy"
---

# Taxonomy Place Management

## Summary

This flow covers CRUD operations on the geo taxonomy — the master data model that describes places, their types, the sources they come from, the indexes used to find them, and the relationship types that connect them. Read operations use the read-only Postgres connection; write operations (create, update, delete) use the read-write Postgres connection. This flow is used by data ingestion pipelines and administrative tools that manage Bhuvan's geo entity master data.

## Trigger

- **Type**: api-call
- **Source**: Internal data management tools, geo data ingestion pipelines, or administrative scripts
- **Frequency**: On-demand (data loading and updates — lower frequency than entity search)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Taxonomy HTTP API | Receives and validates CRUD requests; routes to appropriate DAO layer | `continuumBhuvanService_httpApiTaxonomy` |
| Read-Only Data Store | Executes SELECT queries for list/get operations via JDBI3 | `continuumBhuvanService_roDataStore` |
| Read-Write Data Store | Executes INSERT/UPDATE/DELETE for create/update/delete operations via JDBI3 | `continuumBhuvanService_rwDataStore` |
| Bhuvan Postgres DB | Primary taxonomy data store | `continuumBhuvanPostgres` |

## Steps

### Read (LIST / GET)

1. **Receives read request**: Taxonomy HTTP API receives a `GET /places` (with optional filters), `GET /places/{id}`, `GET /sources`, `GET /indexes`, etc.
   - From: caller
   - To: `continuumBhuvanService_httpApiTaxonomy`
   - Protocol: REST/HTTP

2. **Queries read-only Postgres**: Routes to the Read-Only Data Store to execute a parameterized SELECT query with pagination (cursor-style `start`/`rows` or offset/limit).
   - From: `continuumBhuvanService_roDataStore`
   - To: `continuumBhuvanPostgres`
   - Protocol: Postgres (JDBI3)

3. **Returns results**: Returns the entity or paginated list to the caller.
   - From: `continuumBhuvanService_httpApiTaxonomy`
   - To: caller
   - Protocol: REST/HTTP JSON

### Write (CREATE / UPDATE / DELETE)

1. **Receives write request**: Taxonomy HTTP API receives `POST /places`, `PUT /places/{id}`, `DELETE /places/{id}`, or equivalent for sources, place types, indexes, relationship types.
   - From: caller
   - To: `continuumBhuvanService_httpApiTaxonomy`
   - Protocol: REST/HTTP

2. **Validates request body**: API validates the JSON body against the schema (required fields, format constraints).

3. **Executes write on read-write Postgres**: Routes to the Read-Write Data Store for INSERT, UPDATE, or DELETE via JDBI3 DAO.
   - From: `continuumBhuvanService_rwDataStore`
   - To: `continuumBhuvanPostgres`
   - Protocol: Postgres (JDBI3)

4. **Returns result**: Returns the created/updated entity (or 200 OK for delete) to the caller.
   - From: `continuumBhuvanService_httpApiTaxonomy`
   - To: caller
   - Protocol: REST/HTTP JSON

### Special: Reverse Geocode (`/places/locate`)

1. **Receives locate request**: `GET /places/locate?lat=X&lng=Y&index=<index-name>` — finds place(s) whose geometry contains the coordinate.
   - From: caller
   - To: `continuumBhuvanService_httpApiTaxonomy`
   - Protocol: REST/HTTP

2. **Queries Postgres with spatial filter**: Read-Only Data Store executes a PostGIS spatial query (geometry contains point) against the `place_geoms` table using the GiST index.
   - From: `continuumBhuvanService_roDataStore`
   - To: `continuumBhuvanPostgres`
   - Protocol: Postgres (JDBI3 + PostGIS)

3. **Returns matching places**: Returns place objects to the caller.
   - From: `continuumBhuvanService_httpApiTaxonomy`
   - To: caller
   - Protocol: REST/HTTP JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid JSON body | Returns `400 Bad Request` with error detail | Write rejected |
| UUID not found (GET/PUT/DELETE) | Returns `404 Not Found` | Caller notified |
| Constraint violation (duplicate name, FK violation) | Postgres error translated to `400 Bad Request` | Write rejected |
| Postgres read-write connection unavailable | Returns `503 Service Unavailable` | Write fails |

## Sequence Diagram

```
Caller -> TaxonomyAPI: POST /places {place_json}
TaxonomyAPI -> TaxonomyAPI: validate body
TaxonomyAPI -> RWDataStore: insertPlace(place)
RWDataStore -> Postgres: INSERT INTO places ...
Postgres --> RWDataStore: {uuid: "abc-123", ...}
RWDataStore --> TaxonomyAPI: place entity
TaxonomyAPI --> Caller: 200 {uuid: "abc-123", ...}
```

## Related

- Architecture dynamic view: `dynamic-continuum-bhuvan-taxonomy`
- Related flows: [Geo Spatial Index Rebuild](geo-spatial-index-rebuild.md), [Relationship Build](relationship-build.md)
