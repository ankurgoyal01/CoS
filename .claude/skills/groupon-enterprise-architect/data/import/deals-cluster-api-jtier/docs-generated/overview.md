---
service: "deals-cluster-api-jtier"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Marketing Services"
platform: "Continuum"
team: "Marketing Services (MARS)"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard (JTier)"
  framework_version: "jtier-service-pom 5.14.1"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Deals Cluster API Overview

## Purpose

Deals Cluster API is a RESTful JTier service that groups Groupon deals into named clusters using configurable rules. It provides cluster and rule management endpoints consumed by the Deals Cluster Spark Job for data generation and by downstream marketing systems for deal navigation and tagging. It also exposes top-cluster ranking endpoints and a marketing tagging workflow that tags or untags deals via the Marketing Deal Service.

## Scope

### In scope

- Managing cluster rule definitions (CRUD) that determine how deals are grouped
- Exposing pre-computed deal clusters with filtering by country, channel, category, division, and deal UUID
- Exposing top-performing cluster rankings (by conversion rate, navigation category) for use in site navigation
- Managing top-cluster rule definitions (CRUD)
- Executing marketing tagging use cases: publishing tag/untag requests to JMS message bus
- Persisting and exposing a tagging audit trail
- In-memory caching of top-cluster data at API startup

### Out of scope

- Actual deal cluster computation (handled by the companion Deals Cluster Spark Job on Cerebro/GDOOP)
- Deal catalog data ownership (sourced from `continuumDealCatalogService`)
- Deal management and tag application (executed by `continuumMarketingDealService`)
- External caching services (no Redis or Memcached; only Guava in-memory cache)

## Domain Context

- **Business domain**: Marketing Services — deal grouping and marketing automation
- **Platform**: Continuum
- **Upstream consumers**: Deals Cluster Spark Job (fetches rules), internal marketing tooling (tagging use cases), site navigation surfaces (top clusters)
- **Downstream dependencies**: `continuumDealsClusterDatabase` (PostgreSQL via DaaS), `continuumMarketingDealService` (tagging/untagging), `continuumDealCatalogService` (deal catalog data), JMS message bus (tagging queue, untagging queue)

## Stakeholders

| Role | Description |
|------|-------------|
| Engineering team | Marketing Services (MARS) — mis-engineering@groupon.com |
| Service owner | asdwivedi |
| Alert contact | feed-service-alerts@groupon.com |
| On-call / SOC | deals-cluster-alerts@groupon.com |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `.java-version`, `.ci/Dockerfile` (dev-java11-maven) |
| Framework | Dropwizard (JTier) | jtier-service-pom 5.14.1 | `pom.xml` |
| Runtime | JVM | 11 | `.java-version` |
| Build tool | Maven | — | `pom.xml`, `.mvn/maven.config` |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-service-pom` | 5.14.1 | http-framework | JTier parent POM; provides Dropwizard service structure |
| `jtier-daas-postgres` | (managed) | db-client | DaaS-managed PostgreSQL connection and pooling (PgBouncer) |
| `jtier-jdbi` | (managed) | orm | JDBI-based data access layer for all DAO components |
| `jtier-messagebus-client` | 0.4.1 | message-client | JMS message bus client for publishing tagging/untagging messages |
| `jtier-messagebus-dropwizard` | 0.4.1 | message-client | Dropwizard integration for JMS message bus workers |
| `jtier-retrofit` | (managed) | http-framework | Retrofit HTTP client for outbound calls to deal catalog and DM API |
| `jtier-quartz-bundle` | (managed) | scheduling | Quartz-based scheduling for tagging use case execution |
| `jtier-quartz-postgres-migrations` | (managed) | scheduling | Quartz scheduler DB migration support |
| `jtier-auth-bundle` | (managed) | auth | Authentication bundle for JTier services |
| `jtier-migrations` | (managed) | db-client | Database schema migration tooling |
| `jackson-datatype-jsr310` | (managed) | serialization | Java 8 date/time type support for JSON serialization |
| `json-patch` | 1.9 | serialization | JSON Patch (RFC 6902) support |
| `stringtemplate` | 3.2.1 | validation | ANTLR StringTemplate for dynamic query/rule templating |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
