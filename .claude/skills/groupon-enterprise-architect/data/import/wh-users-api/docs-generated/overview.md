---
service: "wh-users-api"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Merchandising Experience & Intelligence"
platform: "Continuum / Wolfhound CMS"
team: "Merchandising Experience & Intelligence"
status: active
tech_stack:
  language: "Java"
  language_version: "17"
  framework: "Dropwizard"
  framework_version: "via jtier-service-pom 5.14.0"
  runtime: "JVM"
  runtime_version: "17"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Wolfhound Users API Overview

## Purpose

Wolfhound Users API (wh-users-api) provides a REST API for user-related operations within the Wolfhound CMS platform. It manages the lifecycle of three core entity types — users, groups, and resources — persisting them in a DaaS-managed PostgreSQL database. The service is a backend component of the Continuum platform, consumed by Wolfhound CMS tools and internal services that require user and permission management.

## Scope

### In scope

- CRUD operations for Wolfhound **users** (create, read by UUID or username/platform, update, delete, filtered list)
- CRUD operations for Wolfhound **groups** (create, read by UUID, update, delete, list)
- CRUD operations for Wolfhound **resources** (create, read by UUID, update, delete, list)
- Denormalized **platform user** lookups that join user, group, and resource data
- Database schema management via Flyway migrations on startup
- Routing reads to a read-only PostgreSQL replica and writes to the primary

### Out of scope

- Authentication and authorization enforcement (not implemented in this service)
- Wolfhound CMS content management (handled by other Wolfhound services)
- Event publishing or consumption (this is a synchronous REST-only service)
- User session management

## Domain Context

- **Business domain**: Merchandising Experience & Intelligence — Wolfhound CMS user management
- **Platform**: Continuum (legacy/modern commerce engine); sub-domain Wolfhound CMS
- **Upstream consumers**: Wolfhound CMS tools and internal services that call the `/wh/v2/` REST API
- **Downstream dependencies**: DaaS-managed PostgreSQL (read-write primary + read-only replica)

## Stakeholders

| Role | Description |
|------|-------------|
| Team owner | Merchandising Experience & Intelligence — wolfhound-dev@groupon.com |
| Service owner | nmallesh |
| Team members | jblood, aperbellini, nmallesh, mdsouza, lcarranzaarias, ahaluska |
| SRE alerts | wolfhound-alerts@groupon.com |
| PagerDuty | https://groupon.pagerduty.com/services/P13VDUS |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 17 | `pom.xml` `project.build.targetJdk`, `setup_development_environment.md` |
| Framework | Dropwizard (JTier) | jtier-service-pom 5.14.0 | `pom.xml` parent |
| Runtime | JVM | 17 | `src/main/docker/Dockerfile` base image `prod-java17-alpine-jtier:3` |
| Build tool | Maven | (mvnvm-managed) | `pom.xml`, `mvnvm.properties` |
| Package manager | Maven | | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| jtier-service-pom | 5.14.0 | http-framework | JTier parent POM — Dropwizard service scaffold and lifecycle |
| jtier-jdbi3 | (managed by parent) | db-client | JDBI3 integration for SQL query mapping |
| jtier-daas-postgres | (managed by parent) | db-client | DaaS-managed PostgreSQL connection pool configuration |
| jtier-migrations | (managed by parent) | db-client | Flyway database migration runner on service startup |
| Dropwizard Jersey | (managed by parent) | http-framework | JAX-RS REST resource hosting and request routing |
| Codahale Metrics | (managed by parent) | metrics | JVM and application metrics registry |
| Arpnetworking Steno | (managed by parent) | logging | Structured JSON logging via `LoggerFactory` |
| Jackson | (managed by parent) | serialization | JSON request/response serialization via `@JsonProperty` |
| Guava Preconditions | (managed by parent) | validation | Configuration null-checks at startup |
| assertj-core | (managed by parent) | testing | Fluent assertions in tests |
| mockito-junit-jupiter | (managed by parent) | testing | Mock-based unit test support |
| jtier-daas-testing | (managed by parent) | testing | DaaS integration test helpers |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
