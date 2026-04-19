---
service: "product-bundling-service"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Deal Platform"
platform: "Continuum"
team: "Deal Platform"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard"
  framework_version: "via jtier-service-pom 5.14.1"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Product Bundling Service Overview

## Purpose

Product Bundling Service (PBS) is responsible for creating, storing, and managing bundles that associate multiple deal products together. It feeds bundle information to the Deal Catalog (DAG) so that `bundles` data is available in the DC (Deal Catalog) response consumed by downstream commerce surfaces. The service also runs scheduled jobs to refresh warranty bundles and ML-driven recommendation bundles sourced from HDFS and scored by Flux.

## Scope

### In scope

- Bundle CRUD operations: create, read, and delete bundles per deal UUID and bundle type
- Bundle type validation against a configured allowlist (`warranty`, `item-authority`, `acquisition`, `retention`, `battery`, `combo`, `fbt`)
- Deal Catalog node synchronization: upsert and delete bundle nodes in Deal Catalog after every bundle write or delete
- Scheduled warranty bundle refresh: queries voucher and goods inventory services, derives eligible warranty options, and posts bundles via internal API
- Scheduled recommendation bundle refresh: reads HDFS input files from Cerebro, triggers Flux scoring runs, reads Flux output from HDFS, and publishes recommendation payloads to Kafka (Watson KV)
- Bundle configuration storage and retrieval (picker type, position, bundle type metadata)
- Creative content storage: locale-specific title, subtitle, and pitch markup per bundled product

### Out of scope

- Serving deal catalog content directly to consumers (owned by `continuumDealCatalogService`)
- Inventory management (owned by `continuumVoucherInventoryService` and `continuumGoodsInventoryService`)
- ML model training and scoring (handled by Flux platform)
- Recommendation input data preparation (handled by Cerebro/HDFS pipeline)
- Consumer-facing storefront rendering of bundles (downstream responsibility)

## Domain Context

- **Business domain**: Deal Platform — deal product bundling and recommendations
- **Platform**: Continuum
- **Upstream consumers**: Deal Catalog (DAG) reads bundle data via the PBS REST API; internal tools and operators trigger manual refresh via the refresh endpoint
- **Downstream dependencies**: Deal Catalog Service (read deal metadata, write/delete bundle nodes), Voucher Inventory Service (warranty eligibility data), Goods Inventory Service (warranty eligibility data), Flux API (ML recommendation scoring), HDFS/Cerebro (recommendation input files), HDFS/Gdoop (Flux output files), Watson KV Kafka (recommendation event publishing), PostgreSQL (bundle persistence)

## Stakeholders

| Role | Description |
|------|-------------|
| Service Owner | sudasari (Deal Platform team) |
| Engineering Team | Deal Platform — deal-catalog-dev@groupon.com |
| SRE Escalation | deal-platform-urgent@groupon.com |
| Slack Channel | CFPDDNHNW |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `pom.xml` (`project.build.targetJdk=11`), `.java-version` |
| Framework | Dropwizard (JTier) | jtier-service-pom 5.14.1 | `pom.xml` parent |
| Runtime | JVM | 11 | `src/main/docker/Dockerfile` (`prod-java11-jtier:3`) |
| Build tool | Maven | mvnvm managed | `mvnvm.properties`, `.mvn/maven.config` |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-daas-postgres` | jtier-managed | db-client | PostgreSQL connection pool and DaaS integration |
| `jtier-jdbi` | jtier-managed | orm | JDBI DAO layer for SQL access |
| `jdbi` | jtier-managed | orm | SQL object mapping and query execution |
| `jtier-okhttp` | jtier-managed | http-framework | OkHttp-based HTTP client for service calls |
| `jtier-retrofit` | jtier-managed | http-framework | Retrofit HTTP client configuration for downstream services |
| `jtier-quartz-bundle` | jtier-managed | scheduling | Quartz scheduler integration for cron jobs |
| `jtier-auth-bundle` | jtier-managed | auth | Client ID authentication bundle |
| `jtier-auth-postgres` | jtier-managed | auth | PostgreSQL-backed client ID storage |
| `jtier-migrations` | jtier-managed | db-client | Database schema migration runner |
| `apache kafka-clients` | 0.11.0.1 | message-client | Kafka producer for Watson KV recommendation events |
| `holmes kv-producer` | 6.62.1 | message-client | Groupon Watson KV Kafka publisher |
| `hadoop-client` | 2.8.1 | db-client | HDFS read/write for recommendation input and output files |
| `snakeyaml` | jtier-managed | serialization | YAML configuration parsing |
| `commons-lang3` | jtier-managed | validation | Apache Commons string/object utilities |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
