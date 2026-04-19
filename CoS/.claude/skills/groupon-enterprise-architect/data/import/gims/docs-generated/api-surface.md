---
service: "gims"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal-service-auth (inferred)]
---

# API Surface

## Overview

GIMS exposes HTTP/REST APIs for image upload, retrieval, transformation, metadata management, and signed URL generation. It is consumed by numerous internal Continuum services for deal image uploads, campaign asset management, map image signing, theme asset storage, and cache priming. The API surface is inferred from cross-service relationship descriptions in the architecture model, as the GIMS source repository is not federated.

## Endpoints

### Image Upload

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | (inferred) | Upload images via file or URL | Internal service auth |
| POST | (inferred) | Upload images and videos with signed URLs | Internal service auth |

### Image Retrieval

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | (inferred) | Retrieve original or transformed images by ID | Internal service auth |
| GET | (inferred) | Retrieve image metadata | Internal service auth |

### Image Signing

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST/GET | (inferred) | Generate signed URLs for secure image access | Internal service auth |
| POST/GET | (inferred) | Sign map image requests for location-based content | Internal service auth |

> No evidence found in codebase for exact endpoint paths. The GIMS source repository is not federated into the architecture repo. Endpoint details should be obtained from the service's API documentation, OpenAPI spec, or source code.

## Request/Response Patterns

### Common headers

> No evidence found in codebase. Standard Continuum service headers are expected (authentication tokens, request tracing headers).

### Error format

> No evidence found in codebase. Expected to follow Continuum platform error response conventions.

### Pagination

> No evidence found in codebase. Image listing endpoints may support pagination for bulk retrieval operations.

## Rate Limits

> No evidence found in codebase. Rate limiting may be applied at the Akamai CDN layer for public-facing image URLs.

## Versioning

> No evidence found in codebase. API versioning strategy should be documented by the service owner.

## OpenAPI / Schema References

> No evidence found in codebase. The GIMS source repository is not federated. OpenAPI spec or schema files should be available in the service's source repository.
