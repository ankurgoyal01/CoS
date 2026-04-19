---
service: "ugc-api"
title: Overview
generated: "2026-03-03"
type: overview
domain: "User Generated Content"
platform: "Continuum"
team: "UGC"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard (JTier)"
  framework_version: "jtier-service-pom 5.14.0"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# UGC API Overview

## Purpose

The UGC API is Groupon's central service for all User Generated Content — reviews, answers, images, tips, surveys, and videos. It exposes a versioned REST API used by consumer-facing surfaces (web, mobile, apps) and internal admin tooling to create, retrieve, moderate, and manage content submitted by customers and merchants. The service persists UGC data to a PostgreSQL database, caches read-heavy data in Redis, stores media in Amazon S3, and publishes events to a JMS message bus for downstream consumers.

## Scope

### In scope

- Storing and retrieving customer reviews (answers) for merchants, places, and deals
- Computing review summaries, ratings aggregates, and aspect breakdowns per merchant or place
- Managing user-submitted images — upload URL generation (pre-signed S3), action recording, and moderation search
- Managing user-submitted videos — upload URL generation, search, update, and video actions
- Survey lifecycle management — creation, dispatch, eligibility, reply submission, and viewed/completed tracking
- Modal/survey presentation via the `/modal_provider` path
- Admin endpoints for content moderation: review search, image search, video search, content opt-out management, answer rating updates, and bulk user-data deletion
- UGC copy and transfer operations between merchants
- Publishing UGC events to `continuumUgcMessageBus` (JMS/ActiveMQ)
- Rate limiting via Redis (`continuumUgcRedis`)

### Out of scope

- Deal catalog management (handled by `continuumDealCatalogService`)
- Merchant profile management (handled by `continuumMerchantApi`)
- Consumer identity management (handled by `continuumUserService` / `continuumConsumerDataService`)
- Taxonomy classification (handled by `continuumTaxonomyService`)
- Image CDN rendering and resizing (handled by `continuumImageService`)
- Email notification delivery (handled by `continuumEmailService`)
- Order and voucher management (handled by `continuumOrdersService`)

## Domain Context

- **Business domain**: User Generated Content (UGC)
- **Platform**: Continuum
- **Upstream consumers**: Consumer web/mobile frontends, merchant-facing MPP (Merchant Partner Portal), admin tooling, SEO API, deal catalog pipelines
- **Downstream dependencies**: `continuumTaxonomyService`, `continuumConsumerDataService`, `continuumDealCatalogService`, `continuumGoodsInventoryService`, `continuumImageService`, `continuumMerchantApi`, `continuumOrdersService`, `continuumEmailService`, `continuumUserService`, Amazon S3, PostgreSQL, Redis, JMS/ActiveMQ

## Stakeholders

| Role | Description |
|------|-------------|
| Team owner | UGC team (ugc-dev@groupon.com) |
| On-call / SRE | ugc-alerts@groupon.com; PagerDuty service P057HSW |
| Primary contact | cvemuri (team lead) |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `pom.xml` — `project.build.targetJdk=11`, `.java-version` |
| Framework | Dropwizard (via JTier) | JTier service-pom 5.14.0 | `pom.xml` parent `jtier-service-pom:5.14.0` |
| Runtime | JVM (Eclipse Temurin) | Java 11 | `src/main/docker/Dockerfile` — `jtier/prod-java11-jtier:3` |
| Build tool | Maven | mvnvm-managed | `pom.xml`, `.mvn/maven.config` |
| Container base | Docker | JTier prod-java11 image | `src/main/docker/Dockerfile` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-jdbi` | inherited | db-client | JDBI-based data access layer (JTier internal) |
| `jtier-daas-postgres` | inherited | db-client | PostgreSQL DaaS integration via JTier |
| `jtier-migrations` | inherited | db-client | Flyway-based schema migrations via JTier |
| `jedis` | 3.0.1 | db-client | Redis client for rate limiting and cache |
| `dropwizard-redis` | inherited | db-client | Dropwizard Redis bundle |
| `ugc-common` | 1.1.2026.01.21_... | http-framework | Shared UGC models, REST response types, and utilities |
| `RosettaJdbi` | 3.11.2 | orm | HubSpot Rosetta JDBI binding for JSON/POJO mapping |
| `lombok` | 1.18.6 | serialization | Boilerplate reduction via compile-time code generation |
| `gson` | 2.8.2 | serialization | JSON serialization/deserialization |
| `guava` | 31.1-jre | validation | Google core libraries (collections, utilities) |
| `commons-pool2` | 2.9.0 | db-client | Connection pooling for Redis |
| `stringtemplate` | 3.2.1 | templating | SQL/template rendering for dynamic query construction |
| `poi` / `poi-ooxml` | 3.14 | serialization | Apache POI for Excel report generation |
| `wiremock-standalone` | 2.23.2 | testing | HTTP mock server for integration tests |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
