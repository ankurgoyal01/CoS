---
service: "marketing-and-editorial-content-service"
title: "Content Search and Retrieval"
generated: "2026-03-03"
type: flow
flow_name: "content-search-and-retrieval"
flow_type: synchronous
trigger: "GET /mecs/image or GET /mecs/text with optional query parameters"
participants:
  - "mecs_api"
  - "mecs_business"
  - "mecs_dataAccess"
  - "continuumMarketingEditorialContentPostgresRead"
architecture_ref: "components-continuum-marketing-editorial-content-service"
---

# Content Search and Retrieval

## Summary

Internal clients query MECS to retrieve lists of image or text content records matching specified filters, or fetch a single record by UUID. All read operations are routed to the PostgreSQL read replica to reduce load on the primary database. Results can be field-filtered using the `show` query parameter, which limits the JSON fields returned in the response.

## Trigger

- **Type**: api-call
- **Source**: Internal clients (editorial tools, Merch UI, downstream services) via `GET /mecs/image`, `GET /mecs/image/{uuid}`, `GET /mecs/text`, or `GET /mecs/text/{uuid}`
- **Frequency**: On demand, high frequency — called whenever editors browse or search content, and whenever other services need to retrieve stored editorial assets

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Internal client | Initiates the search or get request | — |
| API Resources | Receives request, binds search/pagination parameters, delegates to business layer | `mecs_api` |
| Content Services | Calls data access layer with search parameters | `mecs_business` |
| Data Access Layer | Executes SQL query against read replica via JDBI router | `mecs_dataAccess` |
| MECS Postgres (Read) | Serves the read query; returns matching rows | `continuumMarketingEditorialContentPostgresRead` |

## Steps

1. **Receive GET request**: Client issues `GET /mecs/image` (or `/mecs/text`) with optional query parameters for filtering (e.g., by UUID, tag, project, locale, component type) and pagination (`limit`, `offset`). Or client issues `GET /mecs/image/{uuid}` for a direct UUID lookup.
   - From: Internal client
   - To: `mecs_api` (ImageResource or TextResource)
   - Protocol: HTTP/JSON

2. **Validate ClientId authentication**: The jtier auth bundle validates the `clientId` query parameter.
   - From: `mecs_api`
   - To: ClientId auth store (PostgreSQL)
   - Protocol: JDBC

3. **Bind search parameters**: Jersey binds query parameters into `ImageSearchParam` (or `TextSearchParam`) and `PaginationParam` bean objects using `@BeanParam`. Bean Validation annotations enforce parameter constraints.
   - From: `mecs_api`
   - To: `mecs_api` (internal)
   - Protocol: direct

4. **Delegate to content service**: `ImageResource.search()` calls `ImageService.search(searchParam, pagination)`. For a by-UUID fetch, `ImageResource.get(uuid)` calls `ImageService.get(uuid)`.
   - From: `mecs_api`
   - To: `mecs_business`
   - Protocol: direct

5. **Route to JDBI read instance**: The data access layer's `ImageContentJdbiRouter` (or `TextContentJdbiRouter`) selects the read JDBI instance. The DAO builds the SQL query with `WHERE` clauses derived from the non-null filter parameters and appends `LIMIT`/`OFFSET` from the pagination object.
   - From: `mecs_dataAccess`
   - To: `continuumMarketingEditorialContentPostgresRead`
   - Protocol: JDBC

6. **Execute query and map results**: PostgreSQL executes the query and returns rows. JDBI maps each row to an `ImageContent` (or `TextContent`) object using the configured row mapper.
   - From: `continuumMarketingEditorialContentPostgresRead`
   - To: `mecs_dataAccess`
   - Protocol: JDBC

7. **Apply field filter (optional)**: If the `show` query parameter is present, `JacksonResponseFilter` is applied as a response filter to remove fields not in the `show` set before serialization.
   - From: `mecs_api`
   - To: Internal client
   - Protocol: HTTP/JSON

8. **Return results**: For search, `200 OK` with a JSON array of content records. For by-UUID get, `200 OK` with the single record, or `404 Not Found` if the UUID does not exist.
   - From: `mecs_api`
   - To: Internal client
   - Protocol: HTTP/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| UUID not found in database | `ResourceNotFoundException` thrown; mapped by `ResourceNotFoundExceptionMapper` | 404 Not Found |
| Invalid search parameter format | Bean Validation failure; mapped by `JerseyViolationExceptionMapper` | 422 Unprocessable Entity |
| PostgreSQL read replica unavailable | JDBI exception propagates | 500 Internal Server Error |
| Read replica lag (record not yet visible) | No retry logic; the query returns whatever is visible on the replica | 404 Not Found (transient) or stale data |

## Sequence Diagram

```
Client -> ImageResource: GET /mecs/image?limit=20&offset=0&project=GROUPON
ImageResource -> AuthBundle: validate clientId
AuthBundle --> ImageResource: authenticated
ImageResource -> ImageResource: bind ImageSearchParam, PaginationParam
ImageResource -> ImageContentService: search(searchParam, pagination)
ImageContentService -> ImageContentJdbiRouter: search(searchParam, pagination)
ImageContentJdbiRouter -> PostgresRead: SELECT * FROM images WHERE ... LIMIT 20 OFFSET 0
PostgresRead --> ImageContentJdbiRouter: rows
ImageContentJdbiRouter --> ImageContentService: List<ImageContent>
ImageContentService --> ImageResource: List<ImageContent>
ImageResource -> JacksonResponseFilter: apply show field filter (if present)
ImageResource --> Client: 200 OK, JSON array
```

## Related

- Architecture component view: `components-continuum-marketing-editorial-content-service`
- Related flows: [Image Upload and Storage](image-upload-and-storage.md), [JSON Patch Partial Update](json-patch-update.md)
