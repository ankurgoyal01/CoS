---
service: "marketing-and-editorial-content-service"
title: "JSON Patch Partial Update"
generated: "2026-03-03"
type: flow
flow_name: "json-patch-update"
flow_type: synchronous
trigger: "PATCH /mecs/image/{uuid} or PATCH /mecs/text/{uuid} with RFC 6902 JSON Patch body"
participants:
  - "mecs_api"
  - "mecs_business"
  - "mecs_dataAccess"
  - "continuumMarketingEditorialContentPostgresRead"
  - "continuumMarketingEditorialContentPostgresWrite"
architecture_ref: "components-continuum-marketing-editorial-content-service"
---

# JSON Patch Partial Update

## Summary

A client applies one or more RFC 6902 JSON Patch operations to an existing image or text content record. MECS fetches the current record from the read replica, applies the patch operations in-memory using the `json-patch` library, and (unless `dryRun=true`) persists the patched record to the primary PostgreSQL instance. Bulk patch is also supported: clients can supply a list of UUIDs and a single patch to apply uniformly to multiple records. Dry-run mode allows clients to preview the patch result without committing changes.

## Trigger

- **Type**: api-call
- **Source**: Internal clients (editorial tooling, batch update scripts) via `PATCH /mecs/image/{uuid}` or `PATCH /mecs/text/{uuid}`
- **Frequency**: On demand; also used for bulk operations via `PATCH /mecs/image` (collection)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Internal client | Initiates the patch request | — |
| API Resources | Receives PATCH request, delegates to business layer | `mecs_api` |
| Content Services | Fetches record, applies patch, conditionally persists | `mecs_business` |
| Data Access Layer | Reads current record from read replica; writes patched record to primary | `mecs_dataAccess` |
| MECS Postgres (Read) | Serves the current record for patch base | `continuumMarketingEditorialContentPostgresRead` |
| MECS Postgres (Write) | Stores the patched record | `continuumMarketingEditorialContentPostgresWrite` |

## Steps

1. **Receive PATCH request**: Client sends `PATCH /mecs/image/{uuid}` with `Content-Type: application/json`. Body is a JSON array of RFC 6902 patch operations (e.g., `[{"op":"replace","path":"/metadata/name","value":"new-name"}]`). Optional `dryRun=true` query parameter suppresses persistence.
   - From: Internal client
   - To: `mecs_api` (ImageResource or TextResource)
   - Protocol: HTTP/JSON

2. **Validate ClientId authentication**: The jtier auth bundle validates the `clientId` query parameter.
   - From: `mecs_api`
   - To: ClientId auth store (PostgreSQL)
   - Protocol: JDBC

3. **Delegate to content service**: `ImageResource.patch(uuid, dryRun, patch)` calls `ImageContentService.patch(uuid, patch, dryRun)`.
   - From: `mecs_api`
   - To: `mecs_business`
   - Protocol: direct

4. **Fetch current record**: `ImageContentService` calls `imageContentDao.get(uuid)` via the data access layer, which queries the read replica.
   - From: `mecs_dataAccess`
   - To: `continuumMarketingEditorialContentPostgresRead`
   - Protocol: JDBC

5. **Validate record exists**: If the record is not found, `ResourceNotFoundException` is thrown immediately.
   - From: `mecs_business`
   - To: Internal client
   - Protocol: HTTP/JSON (404 Not Found)

6. **Apply patch in memory**: `ImageContentService` serializes the `ImageContent` to a `JsonNode` using Jackson, then calls `JsonPatch.apply(jsonNode)` from the `com.github.fge:json-patch` library. The result is deserialized back to an `ImageContent` object.
   - From: `mecs_business`
   - To: `mecs_business` (internal)
   - Protocol: direct

7. **Persist patched record** (if not dry-run): If `dryRun=false`, the patched record is saved via the data access layer to the primary PostgreSQL. A database trigger writes an `UPDATE` row to `images_audit` (or `text_audit`).
   - From: `mecs_dataAccess`
   - To: `continuumMarketingEditorialContentPostgresWrite`
   - Protocol: JDBC

8. **Return patched record**: `200 OK` with the patched `ImageContent` (or `TextContent`) JSON body — regardless of whether dry-run was used.
   - From: `mecs_api`
   - To: Internal client
   - Protocol: HTTP/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| UUID not found | `ResourceNotFoundException` thrown before patch is applied | 404 Not Found |
| Invalid patch JSON (malformed) | `JsonProcessingExceptionMapper` handles Jackson deserialization error | 400 Bad Request |
| Patch operation fails (e.g., path not found) | `JsonPatchException` caught; wrapped in `WebApplicationException` | 500 Internal Server Error |
| Result cannot be deserialized after patch | `JsonProcessingException` caught; wrapped in `WebApplicationException` | 500 Internal Server Error |
| PostgreSQL write failure | JDBI exception propagates | 500 Internal Server Error |
| `dryRun=true` | Patch is applied in memory; no database write occurs | 200 OK with preview result |

## Sequence Diagram

```
Client -> ImageResource: PATCH /mecs/image/{uuid}?dryRun=false (JSON Patch ops)
ImageResource -> AuthBundle: validate clientId
AuthBundle --> ImageResource: authenticated
ImageResource -> ImageContentService: patch(uuid, patch, dryRun=false)
ImageContentService -> DataAccessLayer: get(uuid) [read replica]
DataAccessLayer -> PostgresRead: SELECT * FROM images WHERE uuid = ?
PostgresRead --> DataAccessLayer: ImageContent row
DataAccessLayer --> ImageContentService: ImageContent
ImageContentService -> ImageContentService: serialize to JsonNode, apply patch, deserialize
ImageContentService -> DataAccessLayer: save(patchedImageContent) [primary]
DataAccessLayer -> PostgresWrite: UPDATE images SET ... WHERE uuid = ?; trigger UPDATE images_audit
PostgresWrite --> DataAccessLayer: patchedImageContent
DataAccessLayer --> ImageContentService: patchedImageContent
ImageContentService --> ImageResource: patchedImageContent
ImageResource --> Client: 200 OK, JSON patchedImageContent
```

## Related

- Architecture component view: `components-continuum-marketing-editorial-content-service`
- Related flows: [Image Upload and Storage](image-upload-and-storage.md), [Content Delete with Audit](content-delete.md)
