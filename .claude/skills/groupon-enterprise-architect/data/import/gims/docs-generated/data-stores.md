---
service: "gims"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "gims-image-storage"
    type: "object-storage (inferred)"
    purpose: "Persistent image blob storage"
  - id: "gims-metadata-db"
    type: "relational database (inferred)"
    purpose: "Image metadata, references, and transformation records"
---

# Data Stores

## Overview

GIMS is an image management service, so it necessarily owns persistent storage for image blobs and associated metadata. The exact storage technology is not documented in the federated architecture model, but based on the service's purpose (image storage and delivery with CDN integration) and the patterns observed in related services (e.g., media-service uses GCS object storage), the following stores are inferred.

## Stores

### Image Blob Storage (`gims-image-storage`)

| Property | Value |
|----------|-------|
| Type | Object storage (inferred — S3, GCS, or equivalent) |
| Architecture ref | `gims` |
| Purpose | Persistent storage for original and transformed image files |
| Ownership | owned |
| Migrations path | (not available) |

#### Key Entities

> No evidence found in codebase. Expected entities include original images, transformed/resized variants, and upload metadata.

#### Access Patterns

- **Read**: Image retrieval by ID or path; transformed image variants served via CDN
- **Write**: Image uploads from internal services (Metro Draft, MyGroupons, Messaging, MECS, etc.)
- **Indexes**: (not available)

### Image Metadata Database (`gims-metadata-db`)

| Property | Value |
|----------|-------|
| Type | Relational database (inferred — MySQL or PostgreSQL) |
| Architecture ref | `gims` |
| Purpose | Image metadata, transformation records, signed URL state, and reference tracking |
| Ownership | owned |
| Migrations path | (not available) |

#### Key Entities

> No evidence found in codebase. Expected entities include image records, transformation parameters, asset references, and access audit records.

#### Access Patterns

- **Read**: Metadata lookups by image ID; signed URL validation
- **Write**: Metadata creation on upload; transformation record tracking
- **Indexes**: (not available)

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Akamai CDN edge cache | CDN | Caches transformed and original images at edge locations for fast global delivery | Configured per content type (inferred) |

## Data Flows

- **Upload flow**: Internal services upload images via GIMS REST API. GIMS stores the original blob in object storage, creates metadata records, and may trigger transformation processing.
- **Delivery flow**: Consumer-facing image requests are routed through Akamai CDN. On cache miss, Akamai fetches the image from GIMS origin, caches it at the edge, and serves subsequent requests from cache.
- **Cache priming**: The Image Service Primer (`continuumImageServicePrimer`) proactively requests transformed and original images from GIMS to warm the CDN cache, reducing cold-start latency for consumers.
