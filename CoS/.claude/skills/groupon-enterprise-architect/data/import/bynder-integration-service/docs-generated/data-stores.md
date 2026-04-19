---
service: "bynder-integration-service"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumBynderIntegrationMySql"
    type: "mysql"
    purpose: "Local image metadata store: images, variants, keywords, tags, sources, translations, asset types, metaproperties"
---

# Data Stores

## Overview

The bynder-integration-service owns a single MySQL database that serves as the local materialized view of all image assets synchronized from Bynder and IAM. It stores the full metadata model: images, image variants, keywords, tags, sources, translations, asset types, and taxonomy metaproperties. The `bisPersistence` component (JDBI-based) is the sole accessor of this database. There are no caches — all reads are served directly from MySQL.

## Stores

### Bynder Integration MySQL (`continuumBynderIntegrationMySql`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumBynderIntegrationMySql` |
| Purpose | Authoritative local store for all image assets, metadata, and taxonomy data synchronized from Bynder DAM and IAM |
| Ownership | owned |
| Migrations path | > No evidence found in codebase. |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `images` | Core image asset records synchronized from Bynder/IAM | image_id, bynder_asset_id, iam_asset_id, title, rating, source_id, created_at, updated_at |
| `image_variants` | Individual renditions/variants of an image (sizes, formats) | variant_id, image_id, url, width, height, format, is_primary |
| `keywords` | Keyword/tag vocabulary for image classification | keyword_id, name, created_at |
| `image_keywords` | Many-to-many association between images and keywords | image_id, keyword_id |
| `tags` | Bynder taxonomy tags applied to images | tag_id, name, bynder_tag_id |
| `image_tags` | Many-to-many association between images and tags | image_id, tag_id |
| `sources` | Image source definitions (Bynder, IAM, stock, etc.) | source_id, name, type |
| `translations` | Localized metadata for images | translation_id, image_id, locale, title, description |
| `asset_types` | Bynder asset type classifications | asset_type_id, name, bynder_type_id |
| `metaproperties` | Bynder taxonomy metaproperties used for asset classification | metaproperty_id, name, bynder_metaproperty_id, options |
| `uploads` | Upload history records for images pushed to Bynder | upload_id, image_id, status, uploaded_at |

#### Access Patterns

- **Read**: Lookup images by image_id or bynder_asset_id; list variants by image_id; list keywords; filter images by keyword, tag, or source; retrieve upload history by image_id
- **Write**: Insert or upsert on scheduled/event-driven sync; update image metadata on PUT `/api/v1/images/{id}`; insert on image upload; insert/update taxonomy tables on taxonomy sync
- **Indexes**: No evidence found in codebase. Expected indexes on `bynder_asset_id`, `iam_asset_id`, `source_id`, and foreign keys.

## Caches

> Not applicable. No caching layer is configured for this service.

## Data Flows

Image data flows into the MySQL database from two directions:

1. **Scheduled pull**: `bisScheduledJobs` (Quartz) calls Bynder/IAM APIs via `bisExternalClients`, writes image records to MySQL via `bisPersistence`, then pushes to Image Service.
2. **Event-driven**: `bisMessageProcessors` receives change events from the message bus and upserts the affected image/taxonomy records in MySQL.

Taxonomy data flows in via a separate path: the `/taxonomy/update` trigger or scheduled job fetches the hierarchy from the Taxonomy Service and updates the `metaproperties`, `tags`, and related tables.

There is no CDC or replication from MySQL to other systems — downstream services receive updates via the message bus events published after each sync operation.
