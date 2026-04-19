---
service: "partner-attributes-mapping-service"
title: Overview
generated: "2026-03-03"
type: overview
domain: "CLO / Partner Distribution"
platform: "Continuum"
team: "CLO"
status: active
tech_stack:
  language: "Java"
  language_version: "17"
  framework: "Dropwizard"
  framework_version: "JTier jtier-service-pom 5.14.0"
  runtime: "JVM"
  runtime_version: "17"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Partner Attributes Mapping Service Overview

## Purpose

The Partner Attributes Mapping Service (PAMS) is a Dropwizard microservice that acts as a translational layer for communication between Groupon and third-party distribution partners. It manages bidirectional mappings between Groupon internal entity IDs (UUIDs) and partner-specific entity IDs, scoped per partner namespace and entity type. The service also embeds the Partner Signature Service (PSST), which generates and validates HMAC signatures for payloads exchanged with external partners.

## Scope

### In scope
- Storing, retrieving, updating, and deleting Groupon-to-partner ID mappings per partner namespace and entity type
- Bidirectional lookup: resolving partner IDs from Groupon IDs and vice versa
- Generating and updating cryptographic secrets (HMAC keys) for registered partners
- Creating HMAC-SHA1 signatures for outbound payloads destined for partner endpoints
- Validating inbound signatures sent by partners
- Enforcing per-partner authorization rules for update and delete operations (via `partnerConfig`)

### Out of scope
- Actual CLO offer/deal lifecycle management (handled by other CLO services)
- Partner authentication/token issuance (partners supply a `client-id` header; identity management is external)
- Serving end-user or merchant-facing traffic directly

## Domain Context

- **Business domain**: CLO (Card-Linked Offers) / Groupon Anywhere partner distribution
- **Platform**: Continuum
- **Upstream consumers**: Internal Groupon services that distribute CLO inventory to third-party partners (e.g., banking partners, Gemini)
- **Downstream dependencies**: PostgreSQL (`continuumPartnerAttributesMappingPostgres`) — the sole data store for mappings and partner secrets

## Stakeholders

| Role | Description |
|------|-------------|
| CLO Engineering (clo-dev@groupon.com) | Service owners; development, deployment, and on-call |
| CLO Alerts (clo-alerts@groupon.com) | Operational alert recipients |
| Distribution Partner Engineers | Consumers of the mapping and signature APIs to integrate with Groupon |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 17 | `pom.xml` — `project.build.targetJdk`, `maven.compiler.source` |
| Framework | Dropwizard (via JTier) | JTier 5.14.0 | `pom.xml` — `jtier-service-pom` parent |
| Runtime | JVM | 17 | `src/main/docker/Dockerfile` — `prod-java17-jtier:3` |
| Build tool | Maven | (managed by JTier) | `pom.xml`, `.mvn/maven.config` |
| Package manager | Maven | | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-daas-postgres` | (managed by parent) | db-client | PostgreSQL connection pool via DaaS |
| `jtier-jdbi3` | (managed by parent) | orm | JDBI3 SQL object API for DAOs |
| `jtier-migrations` | (managed by parent) | db-client | Flyway-based PostgreSQL schema migrations at startup |
| `jtier-swagger-annotations` | (managed by parent) | http-framework | Swagger/OpenAPI annotation support |
| `org.antlr:stringtemplate` | 3.2.1 | serialization | String templating for query construction |
| `org.apache.httpcomponents:httpclient` | (managed by parent) | http-framework | HTTP client used in signature construction (NameValuePair utilities) |
| `net.oauth` (vendored) | (local) | auth | OAuth percent-encoding utilities for HMAC signature generation |
| `org.immutables` | (managed by parent) | serialization | Immutable value object generation for config and API param classes |
| `com.arpnetworking.steno` | (managed by parent) | logging | Structured JSON logging |
| `javax.crypto.Mac` / JDK | JDK 17 | auth | HMAC-SHA1 signature computation |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
