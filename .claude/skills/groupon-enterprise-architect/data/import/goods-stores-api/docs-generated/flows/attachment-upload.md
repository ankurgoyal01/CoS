---
service: "goods-stores-api"
title: "Attachment Upload"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "attachment-upload"
flow_type: synchronous
trigger: "API request — POST /v2/attachments"
participants:
  - "continuumGoodsStoresApi"
  - "continuumGoodsStoresApi_v2Api"
  - "continuumGoodsStoresApi_auth"
  - "continuumGoodsStoresApi_attachmentService"
  - "continuumGoodsStoresS3"
  - "continuumGoodsStoresDb"
architecture_ref: "dynamic-goods-stores-attachment-upload"
---

# Attachment Upload

## Summary

This flow handles the upload of product images and file attachments via the v2 API. The `continuumGoodsStoresApi_attachmentService` component processes the multipart upload request, streams the binary content to S3 via CarrierWave/Attachinary, and persists attachment metadata to MySQL. The resulting attachment URL is returned to the caller and linked to the product record.

## Trigger

- **Type**: api-call
- **Source**: Merchant tooling or GPAPI client — `POST /v2/attachments`
- **Frequency**: On-demand per attachment upload action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| V2 Goods Stores API | Receives multipart upload request; delegates to Attachment Service | `continuumGoodsStoresApi_v2Api` |
| Authorization & Token Helper | Validates token and role before upload is accepted | `continuumGoodsStoresApi_auth` |
| Attachment & Media Service | Processes file; uploads to S3 via CarrierWave/Attachinary | `continuumGoodsStoresApi_attachmentService` |
| Goods Stores S3 Bucket | Stores uploaded binary content | `continuumGoodsStoresS3` |
| Goods Stores MySQL | Stores attachment metadata (URL, content type, product association) | `continuumGoodsStoresDb` |

## Steps

1. **Receive Upload Request**: Client sends `POST /v2/attachments` with multipart form data containing the file binary and product association metadata.
   - From: `GPAPI client / merchant tooling`
   - To: `continuumGoodsStoresApi_v2Api`
   - Protocol: REST/HTTP (multipart/form-data)

2. **Validate Authorization**: Token and role checked to confirm caller is permitted to upload attachments.
   - From: `continuumGoodsStoresApi_v2Api`
   - To: `continuumGoodsStoresApi_auth`
   - Protocol: direct (in-process)

3. **Validate Upload Parameters**: V2 API validates file type, size, and product association before handing off to the Attachment Service.
   - From: `continuumGoodsStoresApi_v2Api`
   - To: `continuumGoodsStoresApi_attachmentService`
   - Protocol: direct (in-process)

4. **Upload to S3**: Attachment Service streams the binary content to `continuumGoodsStoresS3` via CarrierWave/Attachinary; S3 returns the object URL.
   - From: `continuumGoodsStoresApi_attachmentService`
   - To: `continuumGoodsStoresS3`
   - Protocol: AWS S3 API (CarrierWave/Attachinary)

5. **Persist Attachment Metadata**: Attachment Service writes the attachment record to MySQL with the S3 URL, content type, and product association.
   - From: `continuumGoodsStoresApi_attachmentService`
   - To: `continuumGoodsStoresDb`
   - Protocol: ActiveRecord/MySQL

6. **Return Attachment Response**: API returns the created attachment record including the S3 URL to the caller.
   - From: `continuumGoodsStoresApi_v2Api`
   - To: `GPAPI client`
   - Protocol: REST/HTTP (JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Authorization failure | Request rejected | HTTP 401/403; no upload performed |
| Invalid file type or size | Grape validation rejects request | HTTP 422 with validation errors; no upload |
| S3 upload failure | CarrierWave raises exception; request fails | HTTP 500; no metadata persisted |
| MySQL write failure after S3 upload | Exception raised; orphaned S3 object possible | HTTP 500; attachment metadata not saved; S3 object may need manual cleanup |
| S3 credentials invalid | Upload fails at S3 API level | HTTP 500; check `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` env vars |

## Sequence Diagram

```
GPAPI Client -> continuumGoodsStoresApi_v2Api: POST /v2/attachments (multipart)
continuumGoodsStoresApi_v2Api -> continuumGoodsStoresApi_auth: Validate token and role
continuumGoodsStoresApi_auth --> continuumGoodsStoresApi_v2Api: Authorized
continuumGoodsStoresApi_v2Api -> continuumGoodsStoresApi_attachmentService: Process upload
continuumGoodsStoresApi_attachmentService -> continuumGoodsStoresS3: Stream binary via CarrierWave (S3 API)
continuumGoodsStoresS3 --> continuumGoodsStoresApi_attachmentService: S3 object URL
continuumGoodsStoresApi_attachmentService -> continuumGoodsStoresDb: Persist attachment metadata (ActiveRecord)
continuumGoodsStoresDb --> continuumGoodsStoresApi_attachmentService: Attachment saved
continuumGoodsStoresApi_v2Api --> GPAPI Client: 201 attachment response with URL
```

## Related

- Architecture dynamic view: `dynamic-goods-stores-attachment-upload`
- Related flows: [Product Create/Update & Sync](product-create-update-sync.md), [Authorization Token Validation](authorization-token-validation.md)
