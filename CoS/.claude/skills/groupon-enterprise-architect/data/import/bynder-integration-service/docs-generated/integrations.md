---
service: "bynder-integration-service"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 1
internal_count: 5
---

# Integrations

## Overview

The bynder-integration-service integrates with six systems. One is external (Bynder DAM, accessed via the official Bynder Java SDK and REST API). Five are internal Continuum platform services covering image storage, deal catalog, taxonomy, messaging, and keyword recommendations. All integrations use REST, the Bynder Java SDK, or the JTier message bus client.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Bynder DAM | rest / sdk | Pull image assets and metadata; upload new images | yes | `bynder` |

### Bynder DAM Detail

- **Protocol**: REST via `bynder-java-sdk`
- **Base URL / SDK**: Bynder Java SDK (configured with Bynder portal URL and OAuth credentials)
- **Auth**: OAuth 2.0 via Bynder SDK (client credentials)
- **Purpose**: Primary source of all editorial image assets. The service polls Bynder on a schedule to pull new and updated images and their metadata (variants, tags, metaproperties). Also used for image uploads via the upload flow.
- **Failure mode**: Scheduled and manual sync operations fail; no new images ingested. Existing local data remains available.
- **Circuit breaker**: No evidence found in codebase.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Image Service | rest | Push synchronized images; retrieve image URLs for variants | `continuumImageService` |
| Deal Catalog Service | rest | Propagate image metadata updates affecting deal content | `continuumDealCatalogService` |
| Taxonomy Service | rest | Fetch taxonomy hierarchy for local sync and metaproperty updates | `continuumTaxonomyService` |
| Message Bus | message-bus | Publish image/taxonomy updated events; consume Bynder, IAM, and Taxonomy messages | `messageBus` |
| Keywords Model API | rest | Fetch keyword recommendations for stock image search | `continuumKeywordsModelApi` |

### Image Service Detail

- **Protocol**: REST
- **Base URL / SDK**: Configured via environment variable; accessed via retrofit2
- **Auth**: Service-to-service credentials
- **Purpose**: Receives image records after successful Bynder/IAM sync so images are available to Groupon's image delivery infrastructure. Also queried to retrieve canonical image URLs for variant records.
- **Failure mode**: Images synchronized to local DB but not propagated to Image Service; downstream consumers cannot retrieve images
- **Circuit breaker**: No evidence found in codebase.

### Deal Catalog Service Detail

- **Protocol**: REST
- **Base URL / SDK**: Configured via environment variable; accessed via retrofit2
- **Auth**: Service-to-service credentials
- **Purpose**: Notified of image metadata updates that affect deal content images, ensuring deal catalog display reflects the latest editorial image changes
- **Failure mode**: Deal catalog images become stale until next sync
- **Circuit breaker**: No evidence found in codebase.

### Taxonomy Service Detail

- **Protocol**: REST
- **Base URL / SDK**: Configured via environment variable; accessed via retrofit2
- **Auth**: Service-to-service credentials
- **Purpose**: Source of truth for the taxonomy hierarchy; fetched on `/taxonomy/update` trigger or scheduled job to update local metaproperties and tags tables
- **Failure mode**: Local taxonomy data becomes stale; taxonomy sync fails
- **Circuit breaker**: No evidence found in codebase.

### Keywords Model API Detail

- **Protocol**: REST
- **Base URL / SDK**: Configured via environment variable; accessed via retrofit2
- **Auth**: Service-to-service credentials
- **Purpose**: Provides keyword suggestions for stock image recommendations exposed via `GET /api/v1/stock/recommendations`
- **Failure mode**: Stock recommendations endpoint returns empty or error
- **Circuit breaker**: No evidence found in codebase.

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Editorial Client App | REST | Primary UI for Editorial team to browse, search, update, and upload images |

> Additional upstream consumers are tracked in the central architecture model.

## Dependency Health

> No evidence found in codebase. Health checks for downstream dependencies are expected to follow standard JTier/Dropwizard health check patterns registered in `bisApplicationOrchestrator`.
