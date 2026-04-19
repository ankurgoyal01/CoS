---
service: "ugc-api"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumUgcApiService"
    - "continuumUgcPostgresPrimary"
    - "continuumUgcPostgresReadReplica"
    - "continuumUgcRedis"
    - "continuumUgcRedisCache"
    - "continuumUgcS3"
    - "continuumUgcMessageBus"
---

# Architecture Context

## System Context

The UGC API (`continuumUgcApiService`) is a backend service within the **Continuum Platform** (`continuumSystem`), Groupon's core commerce engine. It sits as the sole authoritative store for user-generated content across all Groupon surfaces. Consumer-facing web and mobile clients call it to display and submit reviews, images, and surveys. Internal admin tools call it for moderation. The service depends on multiple Continuum microservices for contextual data (merchant info, deal catalog, orders, taxonomy) and delegates media storage to Amazon S3 and email delivery to a dedicated email service.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| UGC API Service | `continuumUgcApiService` | Service | Java/Dropwizard | Core REST API; processes all UGC reads and writes |
| UGC Postgres (Primary) | `continuumUgcPostgresPrimary` | Database | PostgreSQL | Primary transactional database for all UGC data |
| UGC Postgres (Read Replica) | `continuumUgcPostgresReadReplica` | Database | PostgreSQL | Read-only replica for high-volume read queries |
| UGC Redis | `continuumUgcRedis` | Cache | Redis | Rate limiting and transient cache keys |
| UGC Redis Cache | `continuumUgcRedisCache` | Cache | Redis | Read-heavy lookup cache |
| UGC Media Buckets | `continuumUgcS3` | Storage | Amazon S3 | Object storage for UGC images and videos |
| UGC Message Bus (JMS) | `continuumUgcMessageBus` | Messaging | ActiveMQ/JMS | Event bus for UGC lifecycle events |

## Components by Container

### UGC API Service (`continuumUgcApiService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `ugcApiResources` | HTTP resources (JAX-RS controllers) — routes for reviews, answers, images, videos, surveys, modals, admin, and UGC copy/transfer | Dropwizard/JAX-RS |
| `ugcApiServices` | Domain business logic — review submission, survey eligibility, content moderation, image and video action processing | Java |
| `ugcApiDataAccess` | JDBI DAOs and JDBI-based data access helpers for all entities | JDBI / RosettaJdbi / PostgreSQL |
| `ugcApiIntegrations` | HTTP clients and JMS producers for external services (taxonomy, consumer data, merchant API, image service, orders, email, user service) | Jersey / JMS |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumUgcApiService` | `continuumUgcPostgresPrimary` | Reads and writes all UGC data | JDBC/PostgreSQL |
| `continuumUgcApiService` | `continuumUgcPostgresReadReplica` | Reads UGC data for high-volume queries | JDBC/PostgreSQL |
| `continuumUgcApiService` | `continuumUgcRedis` | Rate limiting and transient cache | Redis protocol |
| `continuumUgcApiService` | `continuumUgcRedisCache` | Caches read-heavy data | Redis protocol |
| `continuumUgcApiService` | `continuumUgcS3` | Generates pre-signed upload URLs; stores and retrieves media | HTTPS/S3 API |
| `continuumUgcApiService` | `continuumUgcMessageBus` | Publishes UGC lifecycle events | JMS/ActiveMQ |
| `continuumUgcApiService` | `continuumTaxonomyService` | Fetches taxonomy and category data | REST/HTTP |
| `continuumUgcApiService` | `continuumConsumerDataService` | Fetches consumer profile data | REST/HTTP |
| `continuumUgcApiService` | `continuumDealCatalogService` | Fetches deal catalog data | REST/HTTP |
| `continuumUgcApiService` | `continuumGoodsInventoryService` | Reads goods inventory data | REST/HTTP |
| `continuumUgcApiService` | `continuumImageService` | Manages image operations (resize, CDN) | REST/HTTP |
| `continuumUgcApiService` | `continuumMerchantApi` | Fetches merchant profile data | REST/HTTP |
| `continuumUgcApiService` | `continuumOrdersService` | Fetches order data to validate survey eligibility | REST/HTTP |
| `continuumUgcApiService` | `continuumEmailService` | Sends email notifications | REST/HTTP |
| `continuumUgcApiService` | `continuumUserService` | Fetches user identity data | REST/HTTP |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-continuumUgcApiService`
