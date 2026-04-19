---
service: "billing-record-options-service"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Payments"
platform: "Continuum"
team: "Global Payments"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard"
  framework_version: "jtier-service-pom 5.14.0"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Billing Record Options Service Overview

## Purpose

The Billing Record and Options Service (BROS) is a read-oriented configuration service that answers the question "which payment methods are available here?" for any Groupon checkout flow. It maps country codes, client types (derived from user-agent strings or role headers), inventory context, and brand filters to an ordered list of payment providers with their associated billing record types, variants, flow types, currencies, and capabilities. Downstream checkout and payment processing services consume this data to render the correct payment UI and route transactions to the appropriate payment provider.

## Scope

### In scope

- Serving available payment methods filtered by country code (ISO 3166-1 alpha-2)
- Serving payment methods filtered by payment provider ID, amount, and user-agent
- Resolving client type from user-agent strings and role headers
- Applying include/exclude filter logic based on inventory product IDs, inventory service types, and Primary Deal Service (PDS) category IDs
- Ranking payment providers by client-type-specific importance scores
- Exposing the `bros` schema — applications, client types, countries, payment types, payment providers, and provider importance — via PostgreSQL
- Caching data for low-latency reads via Redis (RAAS)
- Emitting custom counter metrics per country, client type, brand, exchange flag, and inventory service type

### Out of scope

- Executing payment transactions or authorizations
- Storing customer billing records or saved payment instruments
- Managing payment provider credentials or secrets (handled in a separate secrets submodule)
- Administering payment provider configuration data (administered via a separate tool or DB migration)

## Domain Context

- **Business domain**: Payments / Global Payments
- **Platform**: Continuum
- **Upstream consumers**: Checkout frontends (FRONTEND, MOBILE, CHECKOUT applications), internal payment orchestration services
- **Downstream dependencies**: DaaS PostgreSQL (`daasPostgresPrimary`), RAAS Redis (`raasRedis`)

## Stakeholders

| Role | Description |
|------|-------------|
| Team Owner | Global Payments team (owner: khsingh, lead: pnamdeo) — cap-payments@groupon.com |
| On-call | PagerDuty service P6H79CS — bros@groupon.pagerduty.com |
| Consumers | Checkout and payment UI teams that render payment method selectors |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `src/main/docker/Dockerfile` (prod-java11-jtier image) |
| Framework | Dropwizard (JTier) | jtier-service-pom 5.14.0 | `pom.xml` |
| Runtime | JVM | 11 | `src/main/docker/Dockerfile` |
| Build tool | Maven | — | `pom.xml`, `mvnvm.properties` |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-daas-postgres` | BOM-managed | db-client | DaaS-backed PostgreSQL connection management |
| `jtier-jdbi` | BOM-managed | orm | JDBI DAO layer for SQL query execution |
| `jtier-migrations` | BOM-managed | db-client | Flyway database migration runner |
| `payment-cache` (payments SDK) | 1.0.4 | db-client | Redis cache abstraction for payment data |
| `payment-methods-server-sdk` (payments SDK) | 1.0.4 | http-framework | Server-side API interface and model definitions |
| `com.fasterxml.jackson` | BOM-managed | serialization | JSON serialization and deserialization |
| `org.slf4j` | BOM-managed | logging | Structured logging via SLF4J / Steno |
| `jtier-metrics-sma` | BOM-managed | metrics | Custom counter metric emission via Telegraf |
| `org.apache.commons-lang3` | BOM-managed | validation | String utilities used in filter logic |
| `junit-jupiter` | BOM-managed | testing | Unit and integration test framework |
| `jtier-daas-testing` | BOM-managed | testing | DaaS integration test support |
| `jtier-redis-testing` | BOM-managed | testing | Redis integration test support |
| `rest-assured` | 2.9.0 | testing | HTTP integration testing against live service |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for the full list.
