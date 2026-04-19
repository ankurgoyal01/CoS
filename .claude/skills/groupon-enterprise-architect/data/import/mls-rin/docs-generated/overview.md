---
service: "mls-rin"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Merchant Lifecycle / Merchant Experience"
platform: "Continuum"
team: "Merchant Experience"
status: active
tech_stack:
  language: "Java"
  language_version: "17"
  framework: "Dropwizard (JTier)"
  framework_version: "jtier-service-pom 5.14.0"
  runtime: "JVM"
  runtime_version: "17"
  build_tool: "Maven"
  package_manager: "Maven"
---

# MLS RIN (Merchant Lifecycle System Read Interface) Overview

## Purpose

MLS RIN (Merchant Lifecycle System Read Interface) is the HTTP read-only layer for the Merchant Lifecycle System (MLS). It exposes MLS-managed data — deals, units, metrics, history events, CLO transactions, insights, and merchant risk — through a versioned REST API consumed primarily by Merchant Center and internal tooling. The service acts as a facade that aggregates data from multiple read-optimized local PostgreSQL databases and a range of downstream Continuum platform services, presenting a unified view of merchant and deal lifecycle state.

## Scope

### In scope
- Serving deal index queries (list, detail, counts) backed by local PostgreSQL read models
- Unit search and batch unit fetch across federated inventory services (VIS, GLive, Getaways, TPIS, CLO, Goods, etc.)
- Exposing merchant metrics (email, web, mobile impressions/clicks) aggregated from the metrics database
- Providing deal history event retrieval from the history database
- Serving CLO transaction data (itemized list, visits, new customers) from the CLO read model
- Surfacing merchant insights analytics and CX health data
- Returning merchant risk status and thresholds
- Providing performance timeline endpoints for best-of-deal computations

### Out of scope
- Writing or mutating MLS data (write operations are owned by MLS Yang and related write-side services)
- Consumer-facing (shopper) API — this service is internal / Merchant Center facing
- Authentication and authorization policy definition (delegated to JTier auth bundle and client-id role map)
- Inventory data ownership (inventory data is owned by VIS, GLive, Getaways, and other inventory services)

## Domain Context

- **Business domain**: Merchant Lifecycle / Merchant Experience
- **Platform**: Continuum
- **Upstream consumers**: Merchant Center (internal UI/portal), mx-merchant-analytics, and other internal Merchant Experience services
- **Downstream dependencies**: mls-yang (data writer), deal-catalog, voucher-inventory-service, grouponlive-inventory-service, m3_merchant_service, orders, geoplaces, ugc-places, tsd_aggregator, mls-sentinel, reading-rainbow, mx-merchant-analytics, third-party-inventory, clo-inventory-service, discussionservice, pricing service, merchant advisor service

## Stakeholders

| Role | Description |
|------|-------------|
| Service Owner | Merchant Experience team (MerchantCenter-BLR@groupon.com) |
| SRE / On-call | bmx-alert@groupon.com; PagerDuty service PV2ZOZL |
| Engineering Lead | rrathore (owner), pravm, kbhandari, akkedia, admishra (members) |
| Consumers | Merchant Center portal, internal analytics tools |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 17 | `pom.xml` (`project.build.targetJdk`, `maven.compiler.source/target`) |
| Framework | Dropwizard via JTier | jtier-service-pom 5.14.0 | `pom.xml` parent |
| Runtime | JVM | 17 | `Dockerfile` (`prod-java17-jtier:2024-04-23-77dca2a`) |
| Build tool | Maven | (JTier managed) | `pom.xml`, `.mvn/maven.config` |
| Package manager | Maven | | `pom.xml` |
| API spec | Swagger / OpenAPI 2.0 | swagger-codegen-maven-plugin 3.0.25 | `pom.xml` |
| Observability | OpenTelemetry Java Agent | bundled in Docker image | `Dockerfile` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-service-pom` | 5.14.0 | http-framework | JTier Dropwizard service base |
| `mx-jtier-commons` | 2.0.48 | http-framework | Shared Groupon HTTP utilities and models |
| `commons-api` | 1.54.32 | http-framework | Groupon commons API layer |
| `hk2-di-core` / `hk2-di-retrofit` | (jtier-ext BOM) | http-framework | HK2 dependency injection with Retrofit HTTP clients |
| `hk2-di-jdbi3` | (jtier-ext BOM) | orm | JDBI3 integration for PostgreSQL data access |
| `jtier-rxjava3` / `jtier-rxjava3-retrofit` | (jtier-ext BOM) | scheduling | RxJava3 reactive composition for async calls |
| `fis-client-rxjava-jsonholder` | 0.6.7 | http-framework | FIS (Federated Inventory Service) client |
| `jtier-auth-bundle` | (jtier BOM) | auth | Client-ID role-based authentication |
| `jtier-daas-postgres` | (jtier BOM) | db-client | DaaS PostgreSQL connection management |
| `hk2-di-caching` | (jtier-ext BOM) | state-management | In-process caching support |
| `jtier-opslog` | (jtier-ext BOM) | logging | Operational structured logging (Steno) |
| `rxjava3-extensions` | 3.0.1 | scheduling | RxJava3 operator extensions |
| `price-formatter` | 1.3.0 | serialization | Groupon price formatting |
| `commons-validator` | 1.6 | validation | Apache Commons input validation |
| `flyway-core` | 6.0.0 | db-client | Database schema migration (test scope) |
