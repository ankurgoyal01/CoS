---
service: "pricing-control-center-jtier"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Dynamic Pricing"
platform: "Continuum"
team: "Dynamic Pricing"
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

# Pricing Control Center JTier Overview

## Purpose

Pricing Control Center JTier is the backend service powering Groupon's internal revenue management Control Center UI. It allows sales representatives, inventory managers, and team leads to create, validate, schedule, and unschedule Item Level Sales (ILS) programs across multiple pricing channels. The service orchestrates the full lifecycle of a sale — from file upload and validation through asynchronous scheduling into the Pricing Service and downstream analytics upload.

## Scope

### In scope

- Accepting CSV file uploads and JSON payloads to create sale and product records for multiple pricing channels (LOCAL_ILS, LOCAL_ILS_MANUAL, GOODS, GOODS_EMEA, LOCAL_EMEA_MANUAL, SELLOUT, RPO)
- Managing the complete sale status lifecycle: `NEW` → `SCHEDULING_PENDING` → `SCHEDULING_STARTED` → `SALE_SETUP_COMPLETE` → `UNSCHEDULING_PENDING` → `UNSCHEDULING_ENDED`
- Running Quartz-based scheduled jobs to poll for pending sales and orchestrate scheduling/unscheduling via the Pricing Service
- Automatic sale creation for Sellout and Retail Price Optimization (RPO) channels by processing model output files from Gdoop and GCS
- Custom ILS support: synchronizing flux model schedules from Hive, fetching deal options from ML model outputs, and sending go-live email notifications
- Superset pre-fetch: periodically pulling deal eligibility data from Hive into PostgreSQL for fast scheduling lookups
- Analytics upload: inserting scheduled product data into internal and external (Teradata) log raw tables
- User identity, role management, and SOX-compliant access control (IM, IMTL, SUPER, SEARCH roles)
- Quartz scheduler management API for operational visibility and trigger state control

### Out of scope

- Rendering the Control Center frontend UI (handled by a separate web application)
- Executing the actual pricing logic or maintaining deal pricing rules (handled by `continuumPricingService`)
- Voucher inventory management (handled by `continuumVoucherInventoryService`)
- User authentication token issuance (handled by `continuumUsersService` / Doorman)
- ML model training and flux output generation (handled by Data Science pipelines)

## Domain Context

- **Business domain**: Dynamic Pricing / Revenue Management
- **Platform**: Continuum
- **Upstream consumers**: Control Center UI (browser-based), Data Science team clients (`supportedClientIds` configured), internal tooling via `user-email` header auth
- **Downstream dependencies**: `continuumPricingService` (program creation/deletion), `continuumVoucherInventoryService` (min-per-pledge data), `continuumUsersService` (user/role resolution), Hive Warehouse (flux model and superset datasets), GCS Dynamic Pricing Bucket (RPO extracts), Gdoop/HDFS (Sellout flux files), SMTP relay (email notifications), PostgreSQL (transactional state)

## Stakeholders

| Role | Description |
|------|-------------|
| IM (Inventory Manager) | Creates and modifies sales; cannot unilaterally approve; not SOX-scoped |
| IMTL (Inventory Manager Team Lead) | Creates, approves, and schedules sales; SOX-scoped |
| SUPER | All IMTL abilities plus user management and unschedule override past cutoff |
| SEARCH | Read-only access to sale and product data |
| Dynamic Pricing Engineering | Service owners (`dp-engg@groupon.com`) |
| Data Science | Produces flux model outputs consumed by Sellout, RPO, and Custom ILS jobs |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `pom.xml` `project.build.targetJdk` = 11 |
| Framework | Dropwizard (JTier) | jtier-service-pom 5.14.1 | `pom.xml` parent |
| Runtime | JVM | 11 (Eclipse Temurin) | `src/main/docker/Dockerfile` base image `prod-java11-jtier:2023-12-19` |
| Build tool | Maven | mvnvm-managed | `mvnvm.properties`, `.mvn/maven.config` |
| Package manager | Maven | | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-daas-postgres` | (BOM-managed) | db-client | JTier PostgreSQL DaaS integration with session/transaction pool |
| `jtier-quartz-bundle` | (BOM-managed) | scheduling | Dropwizard Quartz bundle for clustered scheduled job execution |
| `jtier-jdbi` | (BOM-managed) | orm | JDBI-based DAO framework for PostgreSQL access |
| `jtier-migrations` | (BOM-managed) | db-client | Flyway-based database schema migration runner |
| `jtier-retrofit` | (BOM-managed) | http-framework | Retrofit HTTP client integration for downstream service calls |
| `jtier-hive` | 0.1.5 | db-client | Hive JDBC connectivity for querying flux model and superset data |
| `aws-java-sdk` | 1.12.205 | db-client | AWS SDK for S3 file path references |
| `google-cloud-storage` | 1.25.0 | db-client | GCP SDK for downloading RPO extract files from GCS |
| `opencsv` | 4.2 | serialization | CSV file parsing for ILS upload and RPO file processing |
| `gson` | (BOM-managed) | serialization | JSON serialization for API payloads |
| `simple-java-mail` | 5.1.4 | messaging | SMTP email notification for job failures and Custom ILS go-live alerts |
| `resilience4j-retry` | 1.3.0 | validation | Retry logic for external service calls and Hive queries |
| `lombok` | 1.18.32 | validation | Boilerplate reduction for DTO and entity classes |
| `org.immutables:value` | (BOM-managed) | validation | Immutable value objects for configuration and domain models |
| `apache-curator` | 4.2.0 | state-management | ZooKeeper client (curator-client/recipes/framework) for distributed coordination |
