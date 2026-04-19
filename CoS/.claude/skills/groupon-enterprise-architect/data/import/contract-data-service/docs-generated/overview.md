---
service: "contract-data-service"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Contract / Finance Engineering"
platform: "Continuum"
team: "FED (fed@groupon.com)"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard"
  framework_version: "via JTier jtier-service-pom 5.14.0"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Contract Data Service (CoDS) Overview

## Purpose

Contract Data Service (CoDS) is the new canonical source of merchant contract information at Groupon. It stores and serves payment terms, contract parties, and payment invoicing configurations for merchant agreements. The service replaces legacy contract storage in Deal Management API (DMAPI) and provides a single authoritative record under SOX compliance controls.

## Scope

### In scope

- Storing and retrieving merchant contract terms (pricing, payment terms, adjustments, tax configuration)
- Storing and retrieving contract parties (merchant identifiers, payment schedules)
- Storing and retrieving payment invoicing configurations (installments, initial payments, external keys)
- Creating aggregate contract records that associate party, terms, and invoicing configuration
- Backfilling historical contract data from DMAPI and Deal Catalog into CoDS format

### Out of scope

- Deal inventory management (owned by Deal Management API / `continuumDealManagementApi`)
- Deal catalog lookups beyond backfill support (owned by Deal Catalog Service / `continuumDealCatalogService`)
- Merchant onboarding workflows
- Payment processing and settlement execution

## Domain Context

- **Business domain**: Contract / Finance Engineering
- **Platform**: Continuum
- **Upstream consumers**: Internal services that need authoritative merchant contract data (tracked in central architecture model)
- **Downstream dependencies**: Deal Management API (DMAPI) for backfill data retrieval; Deal Catalog Service for secondary deal resolution during backfill

## Stakeholders

| Role | Description |
|------|-------------|
| Service owner | FED team (fed@groupon.com) |
| SOX compliance | Repo lives in `sox-inscope` GitHub org; access requires `contract-service-ro` team approval |
| On-call | CoDS Opsgenie (https://groupondev.app.opsgenie.com/service/222b7dcf-5f55-46c4-9869-b53199ddae31) |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `.java-version`, `pom.xml` `<source>11</source>` |
| Framework | Dropwizard (JTier) | via `jtier-service-pom` 5.14.0 | `pom.xml` `<parent>` |
| Runtime | JVM | 11 | `src/main/docker/Dockerfile` — `prod-java11-jtier:3` |
| Build tool | Maven | managed by JTier | `pom.xml`, `mvnvm.properties` |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-daas-postgres` | via JTier BOM | db-client | JTier-managed PostgreSQL connection pool via JDBI |
| `jdbi` | via JTier BOM | db-client | SQL object mapping and DAO layer |
| `jtier-jdbi` | via JTier BOM | db-client | JTier JDBI integration helpers |
| `jtier-migrations` | via JTier BOM | db-client | Flyway-based schema migration runner |
| `flyway-maven-plugin` | 5.2.4 | db-client | Database schema versioning and migration |
| `jtier-okhttp` | via JTier BOM | http-framework | OkHttp-based HTTP client for outbound calls |
| `jtier-retrofit` | 4.2.2 | http-framework | Retrofit HTTP client for DMAPI and Deal Catalog |
| `jtier-messagebus-client` | via JTier BOM | message-client | Message bus client (declared; no active topic publication found) |
| `dropwizard-redis` | via JTier BOM | db-client | Redis integration (declared in pom.xml) |
| `jtier-daas-testing` | via JTier BOM | testing | Integration test helpers for Postgres |
| `okhttp3-mockwebserver` | via JTier BOM | testing | HTTP mock server for client tests |
| `jackson-databind` | via Dropwizard | serialization | JSON serialization/deserialization for API payloads |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
