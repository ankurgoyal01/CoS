---
service: "mds-feed-api"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [api-key]
---

# API Surface

## Overview

The Marketing Feed Service exposes a REST API over HTTP on port 8080. Consumers use it to manage the full lifecycle of deal feed configurations: from creation and grouping through scheduled generation, batch monitoring, file dispatch, and upload to external destinations. An admin API is also available on the admin port (8081) at `/feed-api-admin/`. The OpenAPI specification is available at `doc/swagger/swagger.yaml` and at runtime via `/swagger`.

## Endpoints

### Feed Service

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/feed` | Get all feed configurations (optionally filtered by `clientId`) | None |
| POST | `/feed` | Create a new feed configuration | Client ID |
| GET | `/feed/{uuid}` | Get a specific feed configuration by UUID | None |
| PUT | `/feed/{uuid}` | Update a specific feed configuration | Client ID |
| DELETE | `/feed/{uuid}` | Delete a specific feed configuration | Client ID |
| PATCH | `/feed/{uuid}` | Partially update a feed configuration using JSON Patch (RFC 6902) | Client ID |
| PUT | `/feed/description/{uuid}` | Update the description of a feed configuration | Client ID |
| POST | `/feed/promote/{uuid}` | Promote a feed configuration (copy config to another feed) | Client ID |

### Feed Groups Service

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/feedGroup` | Get all feed groups | None |
| POST | `/feedGroup` | Create a new feed group | Client ID |
| GET | `/feedGroup/{uuid}` | Get a feed group by UUID | None |
| PUT | `/feedGroup/{uuid}` | Update a specific feed group | Client ID |
| DELETE | `/feedGroup/{uuid}` | Delete a specific feed group | Client ID |

### Feed Groups Schedule Service

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/feedSchedule` | Get all feed group schedules | None |
| POST | `/feedSchedule` | Create a new feed group schedule (cron expression) | Client ID |
| GET | `/feedSchedule/{uuid}` | Get a schedule by UUID | None |
| PUT | `/feedSchedule/{uuid}` | Update a specific schedule | Client ID |
| DELETE | `/feedSchedule/{uuid}` | Delete a specific schedule | Client ID |
| GET | `/feedSchedule/{uuid}/activate/{active}` | Activate or deactivate a schedule | Client ID |
| GET | `/feedSchedule/{uuid}/trigger` | Manually trigger a schedule immediately | None |

### Livy Service (Spark Job Submission)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/sparkjob/{feedUuid}` | Submit a Spark job to generate a feed | None |
| POST | `/sparkjob/with-config/{feedUuid}` | Submit a Spark job with an overridden config or artifact URL | None |
| POST | `/sparkjob/staging/{feedUuid}` | Submit a Spark job in an isolated staging environment | None |
| POST | `/sparkjob/merge/{batchUuid}` | Submit a Spark merge job for multi-feed merging | None |
| DELETE | `/sparkjob/{jobId}` | Stop and delete a running Spark job | None |

### Batches Service

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/batches` | Get all Spark batch records | None |
| GET | `/batches/{uuid}` | Get a specific batch by UUID | None |
| PUT | `/batches/{uuid}` | Update a batch record | Client ID |
| GET | `/batches/feed/{feedUuid}` | Get all batches for a given feed UUID | None |
| GET | `/batches/state/{state}` | Get all batches with a given state | None |
| GET | `/batches/creationDate/{creationDate}/state/{state}` | Get batches by date and state | None |
| GET | `/batches/livyId/{livyId}` | Get batches by Livy batch ID | None |
| GET | `/batches/applicationId/{applicationId}` | Get batch by YARN application ID | None |
| GET | `/batches/cost/{feedUuid}` | Get compute cost data by date for a feed UUID | None |

### Dispatch Service

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/dispatcher/feed/{feedUuid}` | Get download URL for the most recent generated feed file | None |
| GET | `/dispatcher/batch/{batchUuid}` | Get download URL for a specific batch's generated feed file | None |

### Feed Upload Service

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/upload/feed/{feedUuid}` | Initiate upload of the most recent successful batch for a feed | None |
| GET | `/upload/batch/{batchUuid}` | Initiate upload of a specific feed batch | None |
| POST | `/upload/merge` | Merge multiple feed batches and upload the result | Client ID |

### Feed Upload Batches Service

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/upload-batches/{uuid}` | Get an upload batch by UUID | None |
| GET | `/upload-batches/feed/{feedUuid}` | Get all upload batches for a feed UUID | None |
| GET | `/upload-batches/feed-batch/{feedBatchUuid}` | Get all upload batches for a feed batch UUID | None |
| GET | `/upload-batches/creationDate/{creationDate}/state/{state}` | Get upload batches by date and state | None |

### Feed Upload Profile Service

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/upload/profile` | Get all upload profiles | None |
| POST | `/upload/profile` | Create an upload profile | Client ID |
| GET | `/upload/profile/{uuid}` | Get an upload profile by UUID | None |
| PUT | `/upload/profile/{uuid}` | Update an upload profile | Client ID |
| GET | `/upload/profile/name/{profileName}` | Get an upload profile by name | None |

### SSH Key Pair Service

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/keypair` | Get all SSH key pairs | None |
| POST | `/keypair` | Create an SSH key pair (multipart upload) | Client ID |
| GET | `/keypair/{uuid}` | Get an SSH key pair by UUID | None |
| PUT | `/keypair/{uuid}` | Update an SSH key pair | Client ID |
| DELETE | `/keypair/{uuid}` | Delete an SSH key pair | Client ID |
| GET | `/keypair/name/{name}` | Get an SSH key pair by name | None |

### Metrics Service

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/metrics` | Add a metric record (called by the Spark job after generation) | Client ID |
| DELETE | `/metrics` | Delete all metrics for a given feed UUID | Client ID |

### Statistics Service

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/statistics/{uuid}` | Get aggregated metric statistics for a feed | None |

### Enum Resource

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/enum/{type}` | Get valid values for `FEEDSTATUS` or `LIVYBATCHSTATE` enums | None |

### Audit

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/audit` | Query audit log by entity type and UUID (admin port 8081) | None |

### Health / Status

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/grpn/status` | JTier standard health/status endpoint | None |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` for JSON body requests
- `Content-Type: multipart/form-data` for SSH key pair file upload endpoints

### Error format

Standard Dropwizard error response shape:
```json
{
  "code": 404,
  "message": "No Feed found with provided uuid"
}
```
Error type: `io.dropwizard.jersey.errors.ErrorMessage`

### Pagination

> No evidence found in codebase. No pagination parameters are defined in the Swagger specification; endpoints return full result sets.

## Rate Limits

> No rate limiting configured.

## Versioning

No URL path versioning. The API is unversioned; the service version is embedded in the Swagger `info.version` field (`1.0.${patch}`).

## OpenAPI / Schema References

- OpenAPI 2.0 specification: `doc/swagger/swagger.yaml` and `doc/swagger/swagger.json`
- Runtime Swagger UI:
  - Staging: `http://mds-feed-staging.snc1/swagger`
  - Production: `http://mds-feed-vip.snc1/swagger`
