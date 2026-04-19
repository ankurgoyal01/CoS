---
service: "gpn-data-api"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Affiliate Marketing / Analytics"
platform: "Continuum"
team: "AFL"
status: active
tech_stack:
  language: "Java"
  language_version: "21"
  framework: "Dropwizard"
  framework_version: "JTier 5.15.0"
  runtime: "JVM"
  runtime_version: "21"
  build_tool: "Maven"
  package_manager: "Maven"
---

# GPN Data API Overview

## Purpose

GPN Data API is a backend REST service that provides marketing attribution data for Groupon orders. It enables affiliate and marketing analytics teams to determine which marketing channels (UTM sources, affiliate IDs, promo codes) drove specific purchases. The service queries Google BigQuery for attribution details and enforces per-day query limits tracked in MySQL.

## Scope

### In scope

- Serving order attribution details by legacy order ID, support ID, or promo code
- Returning attribution results as JSON (full list or paginated) or as CSV export
- Enforcing a configurable daily query count limit per environment
- Batching large order ID lists into 1,000-item chunks for BigQuery query safety

### Out of scope

- User authentication and access control (handled by upstream gateway / sem-ui)
- Attribution data ingestion and pipeline management (owned by data engineering)
- Frontend presentation of attribution data (owned by `sem-ui`)
- Order management or financial transaction processing

## Domain Context

- **Business domain**: Affiliate Marketing / Analytics
- **Platform**: Continuum (Groupon Conveyor Cloud, GCP us-central1)
- **Upstream consumers**: `sem-ui` (Attribution Lens UI); affiliate analytics tooling
- **Downstream dependencies**: Google BigQuery (`prj-grp-dataview-prod-1ff9`), MySQL (query count limits)

## Stakeholders

| Role | Description |
|------|-------------|
| AFL Team (owner) | Develops and operates the service; contact gpn-dev@groupon.com |
| Affiliate Managers | Internal users of Attribution Lens who look up order attribution via sem-ui |
| SRE / On-call | Responds to PagerDuty alerts via gpn-alerts@groupon.com |
| Data Engineering | Owns the BigQuery datasets queried by this service |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 21 | `pom.xml` — `project.build.targetJdk` = 21; `.java-version` |
| Framework | Dropwizard (JTier) | JTier 5.15.0 | `pom.xml` — parent `jtier-service-pom:5.15.0` |
| Runtime | JVM (Eclipse Temurin) | 21 | `src/main/docker/Dockerfile` — `prod-java21-jtier:3` |
| Build tool | Maven | 3.x (mvnvm) | `mvnvm.properties`, `.mvn/maven.config` |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `com.groupon.jtier:jtier-service-pom` | 5.15.0 | http-framework | Dropwizard-based service chassis with JTier conventions |
| `com.google.cloud:google-cloud-bigquery` | 2.40.2 | db-client | Google BigQuery Java SDK for querying attribution datasets |
| `com.teradata.jdbc:terajdbc4` | 17.20.00.12 | db-client | Teradata JDBC driver (legacy path; DAOs present but current flow uses BigQuery) |
| `org.jdbi:jdbi3-sqlobject` | (JTier managed) | orm | SQL object DAO layer for MySQL query-count table |
| `org.jdbi:jdbi3-jodatime2` | (JTier managed) | orm | Joda-Time type support for JDBI |
| `com.groupon.jtier:jtier-daas-mysql` | (JTier managed) | db-client | JTier MySQL data-access support |
| `com.fasterxml.jackson.dataformat:jackson-dataformat-csv` | (JTier managed) | serialization | CSV serialization for the `/attribution/orders/csv` endpoint |
| `com.groupon.jtier:jtier-migrations` | 5.8.0 | db-client | Database migration support for MySQL schema management |
| `io.swagger:swagger-annotations` | (JTier managed) | validation | Swagger/OpenAPI annotation processing |
| `com.arpnetworking.steno:steno` | (JTier managed) | logging | Structured JSON logging |
| `org.assertj:assertj-core` | (JTier managed) | testing | Fluent assertion library for unit tests |
| `org.mockito:mockito-inline` | 3.4.6 | testing | Mocking framework for unit tests |
| `com.google.code.gson:gson` | 2.10.1 | serialization | Required transitive dependency for google-cloud-bigquery |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
