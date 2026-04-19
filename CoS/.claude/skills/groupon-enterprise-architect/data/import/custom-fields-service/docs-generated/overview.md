---
service: "custom-fields-service"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Checkout / Engage"
platform: "Continuum"
team: "3PIP CFS"
status: active
tech_stack:
  language: "Java"
  language_version: "17"
  framework: "Dropwizard"
  framework_version: "via jtier-service-pom 5.14.1"
  runtime: "JVM"
  runtime_version: "17"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Custom Fields Service Overview

## Purpose

Custom Fields Service (CFS) is a backend service that stores, prefills, and validates dynamic field templates used during Groupon checkout and inventory-service flows. It allows third-party inventory services (TPIS, GLive, VIS, Getaways, Goods) to attach merchant-defined data-collection requirements to their products. At checkout time, consumers retrieve the localized field definitions, optionally pre-populated with user profile data, and submit responses for server-side validation.

## Scope

### In scope

- Storing custom field template definitions (field types, validation rules, localized labels)
- Retrieving individual field sets by UUID with locale-aware label translation
- Merging multiple field sets into a single combined view (merged fields)
- Prefilling field values from the Users Service (firstName, lastName, email, phone)
- Validating filled-in field values against template rules (required, pattern, min/max length, min/max value, boolean acceptance)
- Administrative creation and deletion of field templates (API-key protected)
- Listing all field templates with pagination and template-type filtering (COMMON / PRIVATE)

### Out of scope

- Storing filled-in field response values submitted by purchasers at checkout (caller responsibility)
- User account management (owned by Users Service)
- Inventory or deal data (owned by inventory services)
- Frontend rendering of field UIs

## Domain Context

- **Business domain**: Checkout / Engage — third-party inventory booking flows
- **Platform**: Continuum
- **Upstream consumers**: TPIS (Third-Party Inventory Service), GLive (Groupon Live Inventory Service), VIS (Voucher Inventory Service), Getaways Inventory Service, Goods
- **Downstream dependencies**: Users Service (user data prefill), PostgreSQL via DaaS (template persistence)

## Stakeholders

| Role | Description |
|------|-------------|
| Team | 3PIP CFS — owns and operates the service (3pip-cfs@groupon.com) |
| Owner | sudasari |
| On-call | 3PIP Booking team via PagerDuty (P97C4VA / PBR91RA) |
| Consumers | TPIS, GLive, VIS, Getaways, Goods engineering teams |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 17 | `pom.xml` — `project.build.targetJdk=17` |
| Framework | Dropwizard (JTier) | jtier-service-pom 5.14.1 | `pom.xml` parent POM |
| Runtime | JVM (Eclipse Temurin) | 17 | `src/main/docker/Dockerfile` — `prod-java17-jtier:3` |
| Build tool | Maven | mvnvm.properties | `mvnvm.properties`, `.mvn/maven.config` |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-daas-postgres` | managed | db-client | PostgreSQL connection via DaaS pool |
| `jtier-migrations` | managed | db-client | Database schema migrations (Flyway-style) |
| `jtier-jdbi3` | managed | orm | JDBI3 SQL object DAO layer |
| `jtier-retrofit` | managed | http-framework | Retrofit2 HTTP client for outbound calls |
| `jtier-swagger-annotations` | managed | api | Swagger/OpenAPI annotation support |
| `com.google.guava` | managed | state-management | In-memory caching (user service client cache) |
| `commons-validator` | 1.7 | validation | Email and general field validation |
| `com.googlecode.libphonenumber` | 9.0.4 | validation | Phone number validation by country code |
| `io.dropwizard:dropwizard-testing` | managed | testing | Integration test support |
| `org.mockito:mockito-core` | managed | testing | Unit test mocking |
| `com.squareup.okhttp:mockwebserver` | 2.7.5 | testing | HTTP mock server for client tests |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
