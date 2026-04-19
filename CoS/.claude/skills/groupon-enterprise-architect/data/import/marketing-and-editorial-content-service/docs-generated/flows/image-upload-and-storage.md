---
service: "marketing-and-editorial-content-service"
title: "Image Upload and Storage"
generated: "2026-03-03"
type: flow
flow_name: "image-upload-and-storage"
flow_type: synchronous
trigger: "POST /mecs/image with multipart/form-data body"
participants:
  - "mecs_api"
  - "mecs_business"
  - "mecs_globalImageClient"
  - "gims"
  - "mecs_dataAccess"
  - "continuumMarketingEditorialContentPostgresWrite"
architecture_ref: "components-continuum-marketing-editorial-content-service"
---

# Image Upload and Storage

## Summary

An internal client submits a multipart form request to create a new image content record. If the request includes a binary image file, MECS uploads it to the Global Image Service (GIMS) and records the returned CDN URL. If only a URL reference is provided (for images already in GIMS), no upload is performed. In both cases, MECS persists the image metadata to PostgreSQL and returns the created record with its system-generated UUID.

## Trigger

- **Type**: api-call
- **Source**: Internal client (e.g., Merch UI, editorial tooling) via `POST /mecs/image`
- **Frequency**: On demand, triggered by editorial content authors creating new image assets

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Internal client | Initiates the image creation request | — |
| API Resources | Receives and validates multipart form request | `mecs_api` |
| Content Services | Coordinates image upload and persistence logic | `mecs_business` |
| Global Image Service Client | Forwards binary image to GIMS via HTTPS | `mecs_globalImageClient` |
| Global Image Service (GIMS) | Stores the image file and returns CDN URL | `gims` |
| Data Access Layer | Persists image content record to PostgreSQL | `mecs_dataAccess` |
| MECS Postgres (Write) | Stores image record and triggers audit insertion | `continuumMarketingEditorialContentPostgresWrite` |

## Steps

1. **Receive multipart request**: Client sends `POST /mecs/image` with `Content-Type: multipart/form-data`. The form contains an optional binary `image` part and a required `content` JSON string part.
   - From: Internal client
   - To: `mecs_api` (ImageResource)
   - Protocol: HTTP multipart/form-data

2. **Validate ClientId authentication**: The jtier auth bundle intercepts the request and validates the `clientId` query parameter against the credentials stored in PostgreSQL.
   - From: `mecs_api`
   - To: ClientId auth store (PostgreSQL)
   - Protocol: JDBC

3. **Parse and validate content JSON**: `ImageResource` deserializes the `content` form field into an `ImageContent` object. Validates that either a binary image or a non-empty `originalImageUrl` is present. Assigns a system-generated UUID.
   - From: `mecs_api`
   - To: `mecs_api` (internal)
   - Protocol: direct

4. **Delegate to image service**: `ImageResource` calls `ImageContentService.save(imageContent, imageStream)`.
   - From: `mecs_api`
   - To: `mecs_business`
   - Protocol: direct

5. **Upload image to GIMS** (conditional — only when binary image is provided): `ImageContentService` calls `HttpGlobalImageService.uploadImage(imageStream, baseName)`, which sends a `POST /v1/upload` multipart request to `https://img.grouponcdn.com`.
   - From: `mecs_globalImageClient`
   - To: `gims`
   - Protocol: HTTPS multipart/form-data

6. **Receive GIMS response**: GIMS returns an `UploadImageResponse` with status and CDN URL. `ImageContentService` merges the response fields into the `ImageContent` object.
   - From: `gims`
   - To: `mecs_globalImageClient`
   - Protocol: HTTPS/JSON

7. **Persist image record**: `ImageContentService` calls the data access layer to save the `ImageContent` to PostgreSQL. A database trigger (`images_audit`) automatically inserts an `INSERT` audit row in `images_audit`.
   - From: `mecs_dataAccess`
   - To: `continuumMarketingEditorialContentPostgresWrite`
   - Protocol: JDBC

8. **Return created response**: `ImageResource` builds a `201 Created` response with the persisted `ImageContent` entity and a `Location` header pointing to `GET /mecs/image/{uuid}`.
   - From: `mecs_api`
   - To: Internal client
   - Protocol: HTTP/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing image file and missing originalImageUrl | Validated in ImageResource before any service call | 422 Unprocessable Entity |
| Malformed `content` JSON field | `WebApplicationException` thrown during deserialization | 422 Unprocessable Entity |
| GIMS returns non-2xx or status != "ok" | `GlobalImageServiceClientException` thrown; logged with metrics | 500 Internal Server Error to caller |
| GIMS network timeout | OkHttp throws IOException after 180,000 ms | 500 Internal Server Error to caller |
| PostgreSQL write failure | JDBI exception propagates | 500 Internal Server Error to caller |
| Invalid ClientId | jtier auth bundle rejects request | 401 Unauthorized |

## Sequence Diagram

```
Client -> ImageResource: POST /mecs/image (multipart: image + content JSON)
ImageResource -> AuthBundle: validate clientId
AuthBundle --> ImageResource: authenticated
ImageResource -> ImageResource: parse content JSON, assign UUID
ImageResource -> ImageContentService: save(imageContent, imageStream)
ImageContentService -> HttpGlobalImageService: uploadImage(imageStream, baseName)
HttpGlobalImageService -> GIMS: POST /v1/upload (multipart)
GIMS --> HttpGlobalImageService: UploadImageResponse {status, url}
HttpGlobalImageService --> ImageContentService: UploadImageResponse
ImageContentService -> DataAccessLayer: save(ImageContent with CDN URL)
DataAccessLayer -> PostgresWrite: INSERT INTO images; trigger INSERT INTO images_audit
PostgresWrite --> DataAccessLayer: saved ImageContent
DataAccessLayer --> ImageContentService: saved ImageContent
ImageContentService --> ImageResource: saved ImageContent
ImageResource --> Client: 201 Created, Location: /mecs/image/{uuid}, body: ImageContent
```

## Related

- Architecture component view: `components-continuum-marketing-editorial-content-service`
- Related flows: [Content Search and Retrieval](content-search-and-retrieval.md), [JSON Patch Partial Update](json-patch-update.md)
