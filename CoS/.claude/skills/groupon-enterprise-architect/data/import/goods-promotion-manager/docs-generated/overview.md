---
service: "goods-promotion-manager"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Goods / Inventory Lifecycle Staging"
platform: "Continuum"
team: "Goods Engineering Seattle"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard (JTier)"
  framework_version: "jtier-service-pom 5.14.0"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Goods Promotion Manager Overview

## Purpose

Goods Promotion Manager (GPM) is an internal tool that allows Groupon merchandise and pricing teams to create and manage goods promotions. It replaces a manual, time-consuming, and error-prone spreadsheet process by providing an API-backed system for promotion lifecycle management, deal eligibility evaluation, and ILS (Inventory Lifecycle Staging) pricing export. The service is part of the Continuum platform within the Goods/Inventory domain.

## Scope

### In scope

- Creating, updating, locking, submitting, and querying promotions and their lifecycle status (`CREATED`, `LOCKED`, `SUBMITTED`, `DONE`)
- Associating deals with promotions (`promotion_deals`) and evaluating deal promotion eligibility
- Tracking and reporting promotion ineligibilities
- Managing promotion inventory products and their ILS pricing data
- Exporting promotion pricing data as downloadable CSV files for pricing teams
- Scheduling and executing background Quartz jobs for product import and established price updates
- Providing country and metric reference data for promotion configuration

### Out of scope

- Deal creation and deal metadata management (owned by `continuumDealManagementApi`)
- Core pricing calculation (owned by `corePricingServiceSystem`)
- Frontend / buyer-facing promotion display
- Non-goods (local deals) promotions

## Domain Context

- **Business domain**: Goods / Inventory Lifecycle Staging (ILS)
- **Platform**: Continuum
- **Upstream consumers**: Internal Groupon tools (merchandise and pricing teams via client-authenticated REST calls); Optimus job `ILS_marketing_grid_update_ILS_new_disc`
- **Downstream dependencies**: Deal Management API (`continuumDealManagementApi`) for deal/inventory-product data; Core Pricing Service (`corePricingServiceSystem`) for established price lookups

## Stakeholders

| Role | Description |
|------|-------------|
| Goods Engineering Seattle | Service owner; responsible for development, deployment, and operations |
| Merchandise / Pricing Teams | Primary internal users; create and submit promotions via the API |
| SRE / On-call | Respond to infrastructure alerts via PagerDuty service PX8IU6S |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `pom.xml` (`maven.compiler.source=11`), `.java-version` |
| Framework | Dropwizard (JTier) | jtier-service-pom 5.14.0 | `pom.xml` `<parent>` |
| Runtime | JVM (Eclipse Temurin) | Java 11 | `src/main/docker/Dockerfile` base image `jtier/prod-java11-jtier` |
| Build tool | Maven | (jtier-managed) | `pom.xml`, `.mvn/maven.config` |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| jtier-daas-postgres | (jtier-managed) | db-client | PostgreSQL connectivity via JTier DaaS abstraction |
| jtier-jdbi | (jtier-managed) | orm | JDBI-based DAO layer for SQL access |
| jtier-migrations | (jtier-managed) | db-client | Flyway database migration management |
| jtier-quartz-bundle | (jtier-managed) | scheduling | Quartz job scheduler integration |
| jtier-quartz-postgres-migrations | (jtier-managed) | scheduling | Quartz Postgres-backed job store schema migrations |
| jtier-retrofit | (jtier-managed) | http-framework | Retrofit2 HTTP client for outbound REST calls |
| jtier-okhttp | (jtier-managed) | http-framework | OkHttp underlying HTTP transport |
| jtier-auth-bundle | (jtier-managed) | auth | Client-ID authentication and role-based authorization |
| jtier-swagger-annotations | (jtier-managed) | validation | Swagger/OpenAPI annotation support |
| Lombok | 1.18.6 | validation | Boilerplate reduction (getters, setters, constructors) |
| commons-lang3 | (jtier-managed) | validation | Apache Commons utility methods |
| org.json | 20180813 | serialization | JSON parsing utilities |
| stringtemplate | 3.2.1 | serialization | String template rendering for dynamic SQL/output |
| mockito-inline | (jtier-managed) | testing | Inline mocking for unit tests |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
