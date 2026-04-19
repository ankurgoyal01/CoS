---
service: "ugc-api"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 9
---

# Integrations

## Overview

The UGC API integrates with 9 internal Continuum services (REST/HTTP) and 3 infrastructure systems (PostgreSQL, Redis, JMS/ActiveMQ, and S3). All internal service calls are made via HTTP clients (Jersey) managed within the `ugcApiIntegrations` component. The service lists 16 dependencies in `.service.yml`, of which 9 are active federated services and 7 are stubs (inventory services, localization, place service, visibility service, inbox service, gconfig, and rocketman) not fully modeled in the current C4 architecture.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Amazon S3 | HTTPS/S3 API | Pre-signed upload URL generation; media storage and retrieval for images and videos | yes | `continuumUgcS3` |
| ActiveMQ / JMS | JMS | Publishing UGC lifecycle events to downstream consumers | yes | `continuumUgcMessageBus` |
| PostgreSQL | JDBC | Primary transactional storage and read-replica queries for all UGC entities | yes | `continuumUgcPostgresPrimary` / `continuumUgcPostgresReadReplica` |

### Amazon S3 Detail

- **Protocol**: HTTPS via AWS SDK (pre-signed URL generation)
- **Base URL / SDK**: AWS S3 — configured via JTier secrets; bucket names are environment-specific
- **Auth**: IAM role / AWS credentials via JTier secret-service-v2
- **Purpose**: Stores user-submitted images and videos; generates time-limited pre-signed PUT URLs for browser-direct uploads
- **Failure mode**: Pre-signed URL generation fails; upload endpoints return 500; files cannot be submitted
- **Circuit breaker**: No evidence found

### ActiveMQ / JMS Detail

- **Protocol**: JMS via ActiveMQ
- **Base URL / SDK**: mbus (Groupon internal message bus service) — configured via JTier environment config
- **Auth**: Internal broker credentials via JTier config
- **Purpose**: Publishes UGC lifecycle events (answer submitted/deleted, image action, video action, survey completed) to downstream consumers including analytics and SEO pipelines
- **Failure mode**: Event publication fails silently or with a logged error; content is still persisted to PostgreSQL
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Taxonomy Service | REST/HTTP | Fetches category taxonomy data for review aspect classification | `continuumTaxonomyService` |
| Consumer Data Service | REST/HTTP | Fetches consumer profile data for review enrichment and eligibility checks | `continuumConsumerDataService` |
| Deal Catalog Service | REST/HTTP | Fetches deal metadata (title, permalink, status) for review context | `continuumDealCatalogService` |
| Goods Inventory Service | REST/HTTP | Reads goods inventory data for survey eligibility and deal context | `continuumGoodsInventoryService` |
| Image Service | REST/HTTP | Manages image operations — CDN URL generation, resize, and validation after upload | `continuumImageService` |
| Merchant API | REST/HTTP | Fetches merchant profile data for review enrichment and copy/transfer operations | `continuumMerchantApi` |
| Orders Service | REST/HTTP | Fetches order data to validate post-purchase survey eligibility | `continuumOrdersService` |
| Email Service | REST/HTTP | Sends email notifications (e.g., review reply notifications to merchants) | `continuumEmailService` |
| User Service | REST/HTTP | Fetches user identity data for reviewer name, avatar, and permission checks | `continuumUserService` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. Based on `.service.yml` documentation links and API tags, known callers include:

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Consumer web/mobile frontend | REST/HTTP | Displays and submits reviews, images, surveys on deal/merchant pages |
| MPP (Merchant Partner Portal) | REST/HTTP | Displays merchant-facing UGC and moderation data via `mpp-service` path variants |
| SEO API (`seoapi`) | REST/HTTP | Reads review counts and ratings for SEO-enriched pages |
| Admin moderation tooling | REST/HTTP | Performs content moderation via admin endpoints |
| Surveys Service (`surveys-service`) | REST/HTTP | Coordinates survey dispatch and uses UGC API to create post-redemption surveys |

## Dependency Health

> No circuit breaker configuration was found in the repository source. JTier provides HTTP client retry and timeout configuration inherited from `jtier-service-pom`. Timeout and retry values are set in JTier YAML runtime configuration. If the Taxonomy, Consumer Data, or Deal Catalog services are unavailable, review enrichment will degrade — the core review read/write path against PostgreSQL will continue to function.
