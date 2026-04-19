---
service: "img-service-primer"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumImageServicePrimerDb"
    type: "mysql"
    purpose: "Video metadata and transformation state"
  - id: "unknownImageServiceS3Bucket"
    type: "s3"
    purpose: "Transformed video asset storage"
  - id: "unknownGcsMediaBucket"
    type: "gcs"
    purpose: "Source media download"
  - id: "unknownGcsTransformedMediaBucket"
    type: "gcs"
    purpose: "Transformed media references"
---

# Data Stores

## Overview

Image Service Primer owns one primary relational store (MySQL) for video transformation state tracking. It also interacts with external object storage systems — AWS S3 for uploading transformed video payloads and Google Cloud Storage (GCS) for downloading source media objects and reading transformed media references. The image pre-fetching pipeline itself is stateless; no deal or image metadata is persisted beyond the video transformation workflow.

## Stores

### Image Service Primer DB (`continuumImageServicePrimerDb`)

| Property | Value |
|----------|-------|
| Type | MySQL |
| Architecture ref | `continuumImageServicePrimerDb` |
| Purpose | Stores video metadata and tracks video transformation state across pipeline runs |
| Ownership | owned |
| Migrations path | Managed via `jtier-quartz-mysql-migrations` (version 0.1.4) and JDBI3 |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Video records | Track video assets and their transformation status | Video ID, transformation state, timestamps |
| Quartz job tables | Quartz scheduler state (in-database job store via jtier-quartz-mysql-migrations) | Job name, trigger state, next fire time |

#### Access Patterns

- **Read**: `VideoDao` reads transformation records to determine current state before processing; Quartz reads scheduler state tables.
- **Write**: `VideoDao` writes and updates transformation records after each pipeline step; Quartz writes job execution state.
- **Indexes**: No evidence found in codebase of specific index definitions in source files.

### AWS S3 — Transformed Video Storage (`unknownImageServiceS3Bucket`)

| Property | Value |
|----------|-------|
| Type | S3 |
| Architecture ref | Referenced as stub in architecture DSL |
| Purpose | Upload destination for ffmpeg-transformed video payloads |
| Ownership | external (shared with GIMS) |
| Client | `software.amazon.awssdk:s3` version 2.26.25 |

#### Access Patterns

- **Write**: `S3VideoUploader` uploads completed video transformation artifacts.
- **Delete**: Image delete flow (`POST /v1/images`) removes image assets from S3.

### GCS — Source Media (`unknownGcsMediaBucket`)

| Property | Value |
|----------|-------|
| Type | Google Cloud Storage |
| Architecture ref | Referenced as stub in architecture DSL |
| Purpose | `VideoTransformer` downloads source video media prior to ffmpeg processing |
| Ownership | external |
| Client | `google-cloud-storage` via GCP BOM 26.44.0 |

#### Access Patterns

- **Read**: `VideoTransformer` downloads source media objects from this bucket for transformation.

### GCS — Transformed Media References (`unknownGcsTransformedMediaBucket`)

| Property | Value |
|----------|-------|
| Type | Google Cloud Storage |
| Architecture ref | Referenced as stub in architecture DSL |
| Purpose | Stores references to transformed media output |
| Ownership | external |
| Client | `google-cloud-storage` via GCP BOM 26.44.0 |

#### Access Patterns

- **Read**: `VideoTransformer` reads transformed media references from this bucket.

## Caches

The image pre-fetching pipeline warms external caches as its primary goal, but does not own or manage any cache directly:

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| GIMS front cache | External (GIMS-owned) | Warmed by issuing HTTP requests to GIMS via `ImageServiceClient` | GIMS-controlled |
| GIMS back cache | External (GIMS-owned) | Warmed as a side effect of GIMS serving the pre-fetch requests | GIMS-controlled |
| Akamai edge cache | External (CDN) | Warmed by issuing HTTPS requests to Akamai via `AkamaiClient` | Akamai-controlled |

## Data Flows

- Deal metadata flows from `continuumDealCatalogService` into memory only — no persistence.
- Video transformation state flows: message bus event -> MySQL read (current state) -> ffmpeg processing -> MySQL write (updated state) -> S3 upload.
- Image delete flow: operator request -> S3 delete + GIMS cache purge + Akamai cache purge.
