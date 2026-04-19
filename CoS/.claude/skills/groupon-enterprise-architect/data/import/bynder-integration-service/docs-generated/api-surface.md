---
service: "bynder-integration-service"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [jtier-auth-bundle]
---

# API Surface

## Overview

The bynder-integration-service exposes a REST API across two path namespaces: a trigger namespace (`/bynder/`, `/iam/`, `/taxonomy/`) for initiating synchronization jobs, and a data API namespace (`/api/v1/`) for querying and managing image metadata, variants, keywords, sources, uploads, and stock recommendations. The trigger endpoints are primarily used for manual or administrative invocation of sync operations. The `/api/v1/` endpoints are consumed by the Editorial Client App and internal services.

## Endpoints

### Sync Trigger Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/bynder/pull` | Trigger a full Bynder DAM image pull and sync | Internal / Admin |
| GET | `/iam/pull` | Trigger a full IAM image pull and sync | Internal / Admin |
| GET | `/bynder/images/{id}/pull` | Trigger a pull and sync for a single Bynder image by ID | Internal / Admin |
| GET | `/iam/images/{id}/pull` | Trigger a pull and sync for a single IAM image by ID | Internal / Admin |
| GET | `/taxonomy/update` | Trigger a taxonomy metadata sync from the Taxonomy Service | Internal / Admin |

### Image API Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/v1/images/{id}` | Retrieve image metadata including variants and keywords | jtier-auth |
| PUT | `/api/v1/images/{id}` | Update image metadata (rating, primary variant, etc.) | jtier-auth |
| GET | `/api/v1/images/{id}/image_variants` | List all image variants for a given image | jtier-auth |
| GET | `/api/v1/images/{id}/uploads` | Retrieve upload history for an image | jtier-auth |
| POST | `/api/v1/images/upload` | Upload a new image to Bynder and create a local record | jtier-auth |

### Image Variant Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/v1/image_variants/{id}` | Retrieve a specific image variant by ID | jtier-auth |

### Keyword Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/v1/keywords` | List available image keywords | jtier-auth |
| POST | `/api/v1/keywords` | Create a new keyword | jtier-auth |

### Source Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/v1/sources` | List available image sources | jtier-auth |
| POST | `/api/v1/sources` | Create a new image source | jtier-auth |

### Stock Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/v1/stock/recommendations` | Get keyword-based stock image recommendations | jtier-auth |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required for POST/PUT requests
- `Accept: application/json` — expected on all data API endpoints
- JTier auth headers as required by `jtier-auth-bundle 0.2.3`

### Error format

> No evidence found in codebase. Standard Dropwizard/Jersey JSON error responses are expected.

### Pagination

> No evidence found in codebase.

## Rate Limits

> No rate limiting configured.

## Versioning

The data API uses URL path versioning under `/api/v1/`. Sync trigger endpoints use descriptive paths without a version prefix. No multi-version routing evidence found.

## OpenAPI / Schema References

> No evidence found in codebase.
