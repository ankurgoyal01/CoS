---
service: "tronicon-cms"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Merchandising Experience & Intelligence"
platform: "Continuum"
team: "Merchandising Experience & Intelligence"
status: active
tech_stack:
  language: "Java"
  language_version: "17"
  framework: "JTier (Dropwizard)"
  framework_version: "5.14.0"
  runtime: "JVM"
  runtime_version: "17"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Tronicon CMS Overview

## Purpose

Tronicon CMS is a REST API service that manages static and legal page content for Groupon properties. It provides versioned, brand-aware, and locale-aware content storage and a full editorial lifecycle — draft authoring, publish, and archival — for HTML and JSON page content. The service powers legal pages such as terms and conditions, privacy policies, and promotional content pages (e.g., `https://www.groupon.com/legal/paintball-usa-tickets-16`) across Groupon and LivingSocial brands.

## Scope

### In scope

- CRUD operations for CMS content items (HTML and JSON content types)
- Content lifecycle state machine: DRAFT → VALIDATED (published) → ARCHIVED
- Multi-brand support: `groupon`, `livingsocial`, `test`
- Multi-locale content storage and retrieval
- Content versioning with auto-increment and version cloning from existing content
- Full audit log tracking of content changes (path, brand, locale, version, key)
- Usability statistics per content item: script count and warning count
- Path-based, key-based, path-list, and team-based content lookup

### Out of scope

- Frontend rendering of legal pages (handled by downstream consumer services)
- User authentication and authorization management
- CDN or edge caching configuration
- Rich media or binary asset storage

## Domain Context

- **Business domain**: Merchandising Experience & Intelligence — legal and static content management
- **Platform**: Continuum
- **Upstream consumers**: Downstream services and frontends that render legal pages (consumers not enumerated in this repo; tracked in the central architecture model)
- **Downstream dependencies**: MySQL database (DaaS) via `jtier-daas-mysql` and JDBI3

## Stakeholders

| Role | Description |
|------|-------------|
| Team Owner | Merchandising Experience & Intelligence |
| Email | wolfhound-dev@groupon.com |
| Primary Contact | nmallesh |
| Team Members | jblood, mdsouza, lcarranzaarias, aperbellini, nmallesh, gbitra, ahaluska |
| SRE / PagerDuty | wolfhound-apps@groupon.pagerduty.com — PD service P13VDUS |
| Slack Support | #wolfhound-support |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 17 | `pom.xml` (`project.build.targetJdk`) |
| Framework | JTier (Dropwizard) | parent POM 5.14.0 | `pom.xml` (`jtier-service-pom`) |
| Runtime | JVM | 17 (Eclipse Temurin) | `src/main/docker/Dockerfile` base image `prod-java17-alpine-jtier` |
| Build tool | Maven | managed via `mvnvm.properties` | `.mvn/maven.config` |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-service-pom` | 5.14.0 | http-framework | JTier parent POM — provides Dropwizard HTTP service scaffold, lifecycle, metrics |
| `jtier-daas-mysql` | managed | db-client | JTier MySQL DaaS integration — managed database connection pool |
| `jtier-jdbi3` | managed | orm | JDBI3 SQL object API — type-safe DAO-based database access |
| `jtier-migrations` | managed | db-client | Flyway-based schema migration — runs automatically on startup |
| `commons-codec` | 1.15 | serialization | MD5 checksum computation for the `md5Checksum` content integrity field |
| `mockito-junit-jupiter` | managed | testing | Unit test mocking framework |
| `assertj-core` | managed | testing | Fluent assertion library for unit tests |
| `jacoco-maven-plugin` | managed | testing | Code coverage enforcement (80% method, 70% branch minimums) |
| `jtier-daas-testing` | managed | testing | DaaS integration test support |
| `jtier-testing` | managed | testing | JTier-specific test utilities |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for the full list.
