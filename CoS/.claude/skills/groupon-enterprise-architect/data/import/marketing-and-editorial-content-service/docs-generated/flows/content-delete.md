---
service: "marketing-and-editorial-content-service"
title: "Content Delete with Audit"
generated: "2026-03-03"
type: flow
flow_name: "content-delete"
flow_type: synchronous
trigger: "DELETE /mecs/image/{uuid} or DELETE /mecs/text/{uuid} with username query parameter"
participants:
  - "mecs_api"
  - "mecs_business"
  - "mecs_dataAccess"
  - "continuumMarketingEditorialContentPostgresWrite"
architecture_ref: "components-continuum-marketing-editorial-content-service"
---

# Content Delete with Audit

## Summary

An internal client requests deletion of an image or text content record by UUID. The caller must supply a `username` query parameter, which is used to record who performed the deletion in the audit trail. MECS removes the content row from the primary PostgreSQL database and returns a successful response. Unlike INSERT and UPDATE operations (which are audited by PostgreSQL triggers), DELETE audit records are written at the application layer before the row is removed.

## Trigger

- **Type**: api-call
- **Source**: Internal client (editorial tooling, administrative scripts) via `DELETE /mecs/image/{uuid}` or `DELETE /mecs/text/{uuid}`
- **Frequency**: On demand, relatively infrequent — called only when content needs to be permanently removed

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Internal client | Initiates the delete request | — |
| API Resources | Receives and validates the delete request including audit username | `mecs_api` |
| Content Services | Delegates deletion to data access layer | `mecs_business` |
| Data Access Layer | Executes DELETE SQL against primary PostgreSQL | `mecs_dataAccess` |
| MECS Postgres (Write) | Removes the content row from `images` or `text` table | `continuumMarketingEditorialContentPostgresWrite` |

## Steps

1. **Receive DELETE request**: Client sends `DELETE /mecs/image/{uuid}?username=<editor_name>`. The `username` parameter is bound via `AuditUserParam` bean and is validated as required (422 if absent).
   - From: Internal client
   - To: `mecs_api` (ImageResource or TextResource)
   - Protocol: HTTP

2. **Validate ClientId authentication**: The jtier auth bundle validates the `clientId` query parameter.
   - From: `mecs_api`
   - To: ClientId auth store (PostgreSQL)
   - Protocol: JDBC

3. **Validate username present**: `AuditUserParam` Bean Validation (`@Valid`) enforces that `username` is non-empty. If missing, a 422 response is returned immediately.
   - From: `mecs_api`
   - To: `mecs_api` (internal)
   - Protocol: direct

4. **Delegate delete to content service**: `ImageResource.delete(uuid, auditUserParam.getUsername())` calls `ImageContentService.delete(uuid, username)`.
   - From: `mecs_api`
   - To: `mecs_business`
   - Protocol: direct

5. **Execute delete**: The data access layer executes `DELETE FROM images WHERE uuid = ?` against the primary PostgreSQL instance. Returns the number of rows affected.
   - From: `mecs_dataAccess`
   - To: `continuumMarketingEditorialContentPostgresWrite`
   - Protocol: JDBC

6. **Check deletion count**: If the delete affected 0 rows (UUID not found), `ImageResource` throws `ResourceNotFoundException`, returning 404.
   - From: `mecs_api`
   - To: Internal client
   - Protocol: HTTP (404 Not Found)

7. **Return success**: If 1 row was deleted, `ImageResource` returns `204 No Content` (Dropwizard default for void return type on DELETE).
   - From: `mecs_api`
   - To: Internal client
   - Protocol: HTTP (204 No Content)

> Note: The `ImageContentService.delete` method accepts `username` as a parameter for audit purposes. The PostgreSQL `images_audit` trigger fires only on INSERT and UPDATE, not DELETE. Application-level audit writing for DELETE events may be implemented via `AuditService`, but at the time of this documentation the `delete` implementation writes the row count directly without an explicit application-layer audit insert.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing or empty `username` query parameter | `AuditUserParam` Bean Validation fails; mapped by `JerseyViolationExceptionMapper` | 422 Unprocessable Entity |
| UUID does not exist in database | Delete returns 0 rows; `ResourceNotFoundException` thrown | 404 Not Found |
| PostgreSQL write failure | JDBI exception propagates | 500 Internal Server Error |
| Invalid ClientId | jtier auth bundle rejects request | 401 Unauthorized |

## Sequence Diagram

```
Client -> ImageResource: DELETE /mecs/image/{uuid}?username=editor1&clientId=xxx
ImageResource -> AuthBundle: validate clientId
AuthBundle --> ImageResource: authenticated
ImageResource -> ImageResource: validate AuditUserParam (username required)
ImageResource -> ImageContentService: delete(uuid, "editor1")
ImageContentService -> DataAccessLayer: delete(uuid)
DataAccessLayer -> PostgresWrite: DELETE FROM images WHERE uuid = ?
PostgresWrite --> DataAccessLayer: rowsAffected = 1
DataAccessLayer --> ImageContentService: 1
ImageContentService --> ImageResource: 1
ImageResource -> ImageResource: rowCount > 0, no exception
ImageResource --> Client: 204 No Content
```

## Related

- Architecture component view: `components-continuum-marketing-editorial-content-service`
- Related flows: [Text Content Create with Profanity Check](text-content-create.md), [JSON Patch Partial Update](json-patch-update.md)
