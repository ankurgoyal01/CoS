---
service: "merchant-prep-service"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Merchant Experience"
platform: "Continuum"
team: "Merchant Experience"
status: active
tech_stack:
  language: "Java"
  language_version: "21"
  framework: "Dropwizard / JTier"
  framework_version: "5.14.0"
  runtime: "JVM"
  runtime_version: "Java 21 (Eclipse Temurin)"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Merchant Preparation Service Overview

## Purpose

The Merchant Preparation Service (MPRES) supports the deal self-prep workflow inside Groupon's Merchant Center. It sits behind UMAPI and provides merchants with a structured set of steps to complete before their deals go live, including updating tax information, payment banking details, billing address, and company classification. The service persists workflow progress in PostgreSQL and synchronizes account and opportunity data with Salesforce.

## Scope

### In scope

- Serving and accepting updates to merchant tax information (TIN, company type, DEI info)
- Serving and accepting updates to payment banking information (routing number, IBAN, account number, payment hold status)
- Managing merchant billing address retrieval and updates
- Tracking self-prep step completion state per opportunity and per account
- Managing merchant onboarding checklists and campaign onboarding status
- Verification code generation and validation for identity verification flows
- Document upload coordination (Adobe Sign agreement initiation)
- Scheduled sync of merchant last-login data back to Salesforce (`SFLastLoginUpdateJob`)
- Scheduled monthly survey notification dispatch to eligible merchants (`MonthlySurveyJob`)
- Publishing merchant feature-flag update events to the message bus (`MerchantMessageQueue`)
- Retrieving opportunity tasks and creating Salesforce tasks
- Audit trail logging for all merchant data changes

### Out of scope

- Merchant Center UI rendering (handled by the front-end application)
- Authentication and token issuance (handled by UMAPI)
- Contract storage and generation (delegated to `continuumContractService`)
- Accounting/payment hold final adjudication (delegated to `continuumAccountingService`)
- Merchant profile master data management (delegated to `continuumM3MerchantService`)

## Domain Context

- **Business domain**: Merchant Experience — deal preparation and onboarding
- **Platform**: Continuum
- **Upstream consumers**: Merchant Center front-end (via UMAPI proxy); internal SOX-scoped consumers via `mx-merchant-preparation::app_sox_c2` subservice
- **Downstream dependencies**: Salesforce (REST), M3 Merchant Service (REST), NOTS notification service (REST), Accounting Service (REST), Contract Service (REST), Message Bus (JMS), MLS RIN Service (REST), Adobe Sign API (REST), Fonoa TIN/VAT validation (REST), Reading Rainbow cache (REST)

## Stakeholders

| Role | Description |
|------|-------------|
| Merchant Experience team | Primary owners (MerchantCenter-BLR@groupon.com); contact owner: rrathore |
| SRE / Alerts | bmx-alert@groupon.com; PagerDuty: PV2ZOZL |
| SOX compliance consumers | Services accessing the `app_sox_c2` subservice for write operations |
| Groupon merchants | End users completing deal prep steps through Merchant Center |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 21 | `pom.xml` — `project.build.targetJdk=21`, `Dockerfile` base image `prod-java21-jtier:4` |
| Framework | Dropwizard / JTier | 5.14.0 | `pom.xml` — parent `jtier-service-pom:5.14.0` |
| Runtime | JVM (Eclipse Temurin) | Java 21 | `Dockerfile` — `FROM docker.groupondev.com/jtier/prod-java21-jtier:4` |
| Build tool | Maven | managed via mvnvm | `mvnvm.properties`, `.mvn/maven.config` |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-service-core` | 5.14.0 (BOM) | http-framework | Core Dropwizard JTier service wiring and lifecycle |
| `jtier-daas-postgres` | 5.14.0 (BOM) | db-client | DaaS-managed PostgreSQL connection pool |
| `jtier-jdbi` | 5.14.0 (BOM) | orm | JDBI 3 DAO layer for SQL access |
| `jtier-migrations` / `jtier-quartz-postgres-migrations` | 5.14.0 (BOM) | db-client | Flyway-based database schema migrations |
| `jtier-messagebus-client` | 5.14.0 (BOM) | message-client | JTier message bus (MBUS) producer for async events |
| `jtier-retrofit` | 5.14.0 (BOM) | http-framework | Retrofit 2 HTTP client factory for downstream calls |
| `jtier-rxjava3` / `jtier-rxjava3-retrofit` | 5.14.0 (BOM) | http-framework | RxJava 3 async wrappers for Retrofit calls |
| `jtier-auth-bundle` | 5.14.0 (BOM) | auth | Authentication bundle for UMAPI-backed request auth |
| `jtier-quartz-bundle` | 5.14.0 (BOM) | scheduling | Quartz scheduler integration for periodic jobs |
| `hk2-di-core` / `hk2-di-retrofit` / `hk2-di-jdbi3` | 5.14.1.0 (BOM) | http-framework | HK2 dependency injection for all components |
| `immutables` `value` | BOM-managed | serialization | Immutable value-object generation for models |
| `jackson-dataformat-xml` | 2.8.2 | serialization | XML serialization support (SOAP TIN check interop) |
| `swagger-codegen-maven-plugin` | 3.0.25 | http-framework | Code generation from OpenAPI specs for server stubs and client stubs |
| `opentelemetry-javaagent` | bundled in image | metrics | OpenTelemetry tracing via Java agent (`-javaagent`) |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
