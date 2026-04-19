---
service: "deal-performance-api-v2"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Marketing / Deal Analytics"
platform: "Continuum"
team: "Marketing Services"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard"
  framework_version: "JTier jtier-service-pom 5.14.1"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Deal Performance API V2 Overview

## Purpose

Deal Performance API V2 aggregates and serves pre-computed deal performance metrics — including purchases, views, CLO claims, impressions, and deal attribute data — over configurable date/time ranges and grouping dimensions. It is a shared data service used by Marketing (for campaign analysis and deal identification) and by Search and Recommendation Ranking teams (as input into scoring and ranking pipelines). The service reads exclusively from a GDS-managed PostgreSQL database that is populated by upstream data pipelines.

## Scope

### In scope

- Serving deal-level performance metrics (purchases, views, CLO claims, impressions) via `POST /getDealPerformanceMetrics`
- Serving deal option-level performance metrics (purchases and activations per option) via `POST /getDealOptionPerformanceMetrics`
- Serving deal attribute metrics (NOB, NOR, GR, GB, refunds, unique visitors, redemption rate, promo codes, impressions) via `GET /getDealAttributeMetrics`
- Supporting time granularity of HOURLY and DAILY across all metric types
- Supporting multi-dimensional grouping (platform, gender, brand, timestamp, option ID, division ID, activation)
- Supporting primary vs. replica database routing per request

### Out of scope

- Writing or ingesting performance data (handled by upstream data pipelines in `deal-performance-data-pipelines`)
- User-level or session-level analytics
- Real-time streaming metrics
- Deal metadata management

## Domain Context

- **Business domain**: Marketing / Deal Analytics
- **Platform**: Continuum
- **Upstream consumers**: Marketing Services tools, Search and Recommendation Ranking pipeline, internal analytics consumers
- **Downstream dependencies**: GDS PostgreSQL (`deal_perf_v2_prod` / `deal_perf_v2_stg` databases)

## Stakeholders

| Role | Description |
|------|-------------|
| Service Owner | Marketing Services team (`asdwivedi`) |
| Engineering Team | Marketing Services (`mis-engineering@groupon.com`) |
| SRE Contact | `mds-alerts@groupondev.opsgenie.net` |
| Consumers | Marketing analytics, Search/Ranking ranking pipeline |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `pom.xml` — `project.build.targetJdk=11` |
| Framework | Dropwizard (JTier) | jtier-service-pom 5.14.1 | `pom.xml` parent |
| Runtime | JVM | 11 | `.ci/Dockerfile` — `prod-java11-jtier:3` |
| Build tool | Maven | 3.x | `pom.xml`, `.mvn/` directory |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-daas-postgres` | via BOM | db-client | JTier Postgres connection pool management |
| `jtier-jdbi3` | via BOM | orm | JTier JDBI3 integration for SQL execution |
| `jdbi3-stringtemplate4` | via BOM | orm | StringTemplate4 SQL templating for dynamic query generation |
| `jtier-api-utils` | via BOM | http-framework | JTier API utilities and generated model support |
| `caffeine` | 3.0.3 | state-management | In-process caching (Caffeine) |
| `arpnetworking-steno` | via BOM | logging | Structured JSON logging (Steno) |
| `junit-jupiter-api` | via BOM | testing | JUnit 5 unit testing |
| `jtier-daas-testing` | via BOM | testing | JTier integration test support with real DB |
| `jtier-testing` | via BOM | testing | JTier service integration test helpers |
| `swagger-codegen-maven-plugin` | 3.0.25 | http-framework | Code generation from `swagger.yaml` for API interfaces and models |
| `jtier-api-codegen2` | 5.9.0 | http-framework | Groupon JTier custom Swagger codegen language |
| `jacoco-maven-plugin` | via BOM | testing | Code coverage reporting |
