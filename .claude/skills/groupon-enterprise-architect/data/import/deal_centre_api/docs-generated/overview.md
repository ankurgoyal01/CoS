---
service: "deal_centre_api"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Deal Centre / Product Catalog"
platform: "Continuum"
team: "Deal Centre"
status: active
tech_stack:
  language: "Java"
  language_version: "8"
  framework: "Spring Boot"
  framework_version: ""
  runtime: "JVM"
  runtime_version: ""
  build_tool: "Maven"
  package_manager: "Maven"
---

# Deal Centre API Overview

## Purpose

Deal Centre API is the central Spring Boot service for Groupon's Deal Centre and Product Catalog domains within the Continuum Platform. It exposes REST endpoints consumed by merchant-facing, buyer-facing, and admin-facing workflows, coordinating deal creation, inventory tracking, catalog lookups, and order processing. The service bridges internal Groupon commerce systems — including Deal Management API, Deal Catalog Service, and the Message Bus — with the PostgreSQL datastore that owns all deal centre and catalog state.

## Scope

### In scope

- Merchant deal creation and management workflows (CRUD for deals, options, and products via Deal Management API)
- Buyer workflows for browsing and purchasing deals
- Admin workflows for product catalog management
- Inventory event publishing and consumption via Message Bus
- Deal catalog event publishing and consumption via Message Bus
- Transactional email dispatch via Email Service
- Persistence of deal centre and catalog data in PostgreSQL

### Out of scope

- Deal Centre UI rendering (handled by `dealCentreUi`, which calls this API over HTTPS)
- Raw tax calculation (handled by a dedicated tax service — not in the active federated model)
- User/merchant report generation (handled by a dedicated user report service — not in the active federated model)
- Deal asset file storage (handled by an S3 bucket — not in the active federated model)
- Authentication and identity management (handled upstream)

## Domain Context

- **Business domain**: Deal Centre / Product Catalog
- **Platform**: Continuum
- **Upstream consumers**: Deal Centre UI (HTTPS/JSON), internal Groupon admin tooling
- **Downstream dependencies**: Deal Management API (HTTP), Deal Catalog Service (HTTP), Message Bus (MBus), Email Service (HTTP), PostgreSQL (JPA/JDBC)

## Stakeholders

| Role | Description |
|------|-------------|
| Merchant | Creates, updates, and monitors deals and product catalog entries |
| Buyer | Browses the deal catalog and initiates purchase workflows |
| Admin | Manages the product catalog and deal configuration |
| Deal Centre Team | Owns and operates this service |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 8 | `architecture/models/components/continuum-deal-centre-api-components.dsl` |
| Framework | Spring Boot | — | `architecture/models/components/continuum-deal-centre-api-components.dsl` |
| Runtime | JVM | — | Java 8 runtime |
| Build tool | Maven | — | Standard Spring Boot Java 8 project convention |
| Package manager | Maven | | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Spring MVC | — | http-framework | REST controller layer (`dca_apiControllers`) |
| Spring Data JPA / Hibernate | — | orm | Persistence layer (`dca_persistenceLayer`) |
| MBus client | — | message-client | Message Bus integration (`dca_messageBusIntegration`) |
| Spring Actuator | — | metrics | Health checks and application diagnostics (`dca_healthAndMetrics`) |
| HTTP client | — | http-framework | External service clients for DMAPI, Deal Catalog, Mailman (`dca_externalClients`) |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
