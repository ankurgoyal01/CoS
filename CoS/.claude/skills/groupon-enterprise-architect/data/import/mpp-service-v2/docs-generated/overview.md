---
service: "mpp-service-v2"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Merchant Pages"
platform: "Continuum"
team: "merchant-pages"
status: active
tech_stack:
  language: "Java"
  language_version: "17"
  framework: "Dropwizard"
  framework_version: "via JTier jtier-service-pom 5.14.1"
  runtime: "JVM"
  runtime_version: "17 (Eclipse Temurin)"
  build_tool: "Maven"
  package_manager: "Maven"
---

# MPP Service V2 Overview

## Purpose

MPP Service V2 (Merchant Pages Platform Service V2) is the backend service that powers Groupon's merchant page experience. It owns the canonical slug (permalink) lifecycle for merchant places, assembles place data responses by aggregating information from M3, LP API, and taxonomy sources, and maintains index synchronization with the Relevance API to ensure that placed merchants appear correctly in search results. The service replaces an earlier Redis-based architecture with a PostgreSQL-backed persistence model.

## Scope

### In scope

- Slug generation, storage, and redirect management for merchant place pages
- Place data assembly (`PlaceData`, `MapPlaceData`, `ShortPlaceData`) by aggregating M3, LP API, taxonomy, and related-place data
- Bidirectional index synchronization with the Relevance API (RAPI) — marking slugs as indexed or unindexed
- Sitemap generation and serving for merchant pages by domain
- Cross-link generation and periodic refresh via scheduled Quartz jobs
- Message-bus consumption of place-update, inventory-product-update, and deal-distribution events
- Taxonomy snapshot persistence and cache-backed read path for place attributes
- Admin APIs for controlling and inspecting the index-sync job

### Out of scope

- Merchant deal creation and management (handled by deal/commerce services)
- User-facing storefront rendering (handled by MBNXT and frontend layers)
- Inventory management (owned by Voucher Inventory API)
- Taxonomy authoring (owned by the Taxonomy Service)
- Merchant onboarding and CRM (owned by Salesforce and M3)

## Domain Context

- **Business domain**: Merchant Pages
- **Platform**: Continuum
- **Upstream consumers**: MBNXT frontend, SEO crawlers, internal deal and search pages that call `/mpp/v1/place/*` and `/mpp/v1/places` endpoints
- **Downstream dependencies**: M3 Merchant Service, M3 Places Service, LP API (Lazlo), Taxonomy Service, Bhuvan Service, Voucher Inventory API, Relevance API (RAPI), Salesforce (OAuth + Merchant URL API), message bus (JMS)

## Stakeholders

| Role | Description |
|------|-------------|
| Team owner | merchant-pages — goods-cxx-dev@groupon.com |
| Service owner | vpande |
| On-call (PagerDuty) | mpp-service-v2@groupon.pagerduty.com (POQLFLJ) |
| Announcement list | goods-cxx-dev@groupon.com |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 17 | `pom.xml` `project.build.targetJdk`, `.envrc` `sdk use java 17.0.5-tem` |
| Framework | Dropwizard (JTier) | jtier-service-pom 5.14.1 | `pom.xml` parent |
| Runtime | JVM (Eclipse Temurin) | 17 | `src/main/docker/Dockerfile` base image `prod-java17-jtier` |
| Build tool | Maven | mvnvm.properties | `pom.xml`, `mvnvm.properties` |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-jdbi3` | (BOM-managed) | orm | JDBI3 ORM for PostgreSQL DAO layer |
| `jtier-daas-postgres` | (BOM-managed) | db-client | JTier PostgreSQL DataSource abstraction (read/write split) |
| `jtier-messagebus-client` | (BOM-managed) | message-client | JMS/MBus consumer and producer client |
| `jtier-quartz-bundle` | (BOM-managed) | scheduling | Quartz job scheduling integration (sitemap, cross-link, index-sync, place-update jobs) |
| `jtier-quartz-postgres-migrations` | (BOM-managed) | scheduling | Quartz Postgres schema migration support |
| `jtier-migrations` | (BOM-managed) | db-client | Database schema migration framework |
| `jtier-retrofit` | (BOM-managed) | http-framework | Retrofit-based HTTP client for all downstream REST integrations |
| `com.groupon.m3:models` | 5.1.6 | serialization | M3 merchant/place domain model shared library |
| `com.groupon.mpp:mpp-models` | 1.10 | serialization | MPP shared domain model library |
| `com.github.ben-manes.caffeine:caffeine` | 3.2.0 | state-management | In-process LRU cache for place attribute taxonomy data |
| `com.github.slugify:slugify` | 3.0.2 | validation | URL-safe slug generation from merchant/place names |
| `org.json:json` | 20220924 | serialization | JSON parsing utilities |
| `com.github.tomakehurst:wiremock-standalone` | (test) | testing | HTTP mock server for integration tests |
| `mockito-junit-jupiter` | (test) | testing | Unit test mocking |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
