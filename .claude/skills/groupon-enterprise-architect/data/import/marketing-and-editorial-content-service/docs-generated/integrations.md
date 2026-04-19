---
service: "marketing-and-editorial-content-service"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 0
---

# Integrations

## Overview

MECS has one external integration: the Global Image Service (GIMS), which handles binary image storage and CDN delivery. This is an outbound HTTPS call made only during image creation when the caller provides a binary image file. All other integrations are internal database connections to owned PostgreSQL instances. There are no inbound webhooks and no message-bus integrations.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Global Image Service (GIMS) | HTTPS/multipart | Upload binary image files; receive back CDN-accessible image URL and metadata | yes | `gims` |

### Global Image Service (GIMS) Detail

- **Protocol**: HTTPS multipart/form-data POST
- **Base URL**: `https://img.grouponcdn.com` (configured via `globalImageServiceClient.url`)
- **Endpoint**: `POST /v1/upload`
- **Auth**: ClientId (`client_id`) and API key (`api_key`) passed as multipart form fields
- **Purpose**: When a caller submits a binary image file to `POST /mecs/image`, MECS forwards the image bytes to GIMS, which stores the file and returns a CDN-accessible URL. The returned URL and metadata are stored in the `images` table `metadata` (JSONB) field.
- **Failure mode**: If GIMS returns a non-2xx response or the status field is not `"ok"`, MECS throws a `GlobalImageServiceClientException`, which propagates as a 500 response to the caller. No fallback or retry is implemented.
- **Circuit breaker**: No circuit breaker configured. Timeouts are set to 180,000 ms (3 minutes) for read, write, and connect.
- **Metrics**: Upload success and failure counters are emitted as `custom.imageservice.client` measurements with `operation_id=uploadImage` and `status=success|failed` tags.

## Internal Dependencies

> No evidence found of inbound service-to-service dependencies beyond the owned PostgreSQL database connections documented in [Data Stores](data-stores.md).

## Consumed By

> Upstream consumers are tracked in the central architecture model. Known consumers include internal marketing and merchandising tools (e.g., Merch UI), which access the service via CORS-enabled HTTP on port 8080.

## Dependency Health

- **GIMS**: No health check or circuit breaker. Failures surface immediately as 5xx responses. Timeout configuration (`readTimeout`, `writeTimeout`, `connectTimeout` all set to 180,000 ms) is the only resilience mechanism.
- **PostgreSQL (Write/Read)**: Database connectivity health check is intentionally disabled in cloud deployments (see `ContentServiceConfiguration` comment: "a database outage would then cause pods to restart rather than API responding with 5xx errors"). Connection pools are managed by the jtier DaaS Postgres library.
