---
service: "scs-jtier"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Shopping Cart / User Generated Content"
platform: "Continuum"
team: "UGC-Dev"
status: active
tech_stack:
  language: "Java"
  language_version: "1.8"
  framework: "Dropwizard"
  framework_version: "via jtier-service-pom 5.14.0"
  runtime: "JVM"
  runtime_version: "Java 11 (container image: prod-java11-jtier:3)"
  build_tool: "Maven"
  package_manager: "Maven (mvnvm 3.5.4)"
---

# Shopping Cart Service JTier Overview

## Purpose

Shopping Cart Service JTier (scs-jtier) is the backend service responsible for all CRUD operations on a user's shopping cart. It is a rewrite of the existing legacy Shopping Cart Service, built on Groupon's internal JTier/Dropwizard framework. The service stores and retrieves cart data from a MySQL database, validates item purchasability against deal and inventory services, and publishes cart lifecycle events to an internal message bus.

## Scope

### In scope
- Retrieving the full cart contents for a user identified by bCookie or consumer ID
- Retrieving the cart item count (size)
- Adding items to the cart (upsert semantics: insert if absent, update quantity if present)
- Updating item quantities in the cart
- Removing items from the cart
- Marking a cart as checked out or deactivated
- Validating cart items against deal data and inventory availability
- Publishing `updated_cart` events to the message bus on each cart mutation
- Running scheduled jobs to detect abandoned carts and publish `abandoned_cart` events
- Running scheduled jobs to mark and move inactive carts

### Out of scope
- User authentication — delegated to upstream gateway (Lazlo/GAPI)
- Payment processing — handled by downstream checkout services
- Deal catalog management — owned by `continuumDealService`
- Inventory management — owned by `continuumGoodsInventoryService` and `continuumVoucherInventoryService`

## Domain Context

- **Business domain**: Shopping Cart / User Generated Content
- **Platform**: Continuum
- **Upstream consumers**: GAPI / Lazlo API gateway (calls this service on behalf of web, touch, and mobile app users)
- **Downstream dependencies**: Deal Catalog Service (`continuumDealService`), Goods Inventory Service (`continuumGoodsInventoryService`), Voucher Inventory Service (`continuumVoucherInventoryService`), MySQL read/write database pair, Groupon internal message bus (Mbus)

## Stakeholders

| Role | Description |
|------|-------------|
| Team | UGC-Dev — primary development and on-call team (ugc-dev@groupon.com) |
| Owner | sudasari — service owner listed in .service.yml |
| SRE alert | cart-jtier-alerts@groupon.pagerduty.com — PagerDuty notification alias |
| Data store ops | GDS team (gds@groupon.com) — manages MySQL DaaS database |
| Mailing list | ugc-dev@groupon.com — announcement mailing list |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 1.8 | `.java-version` |
| Framework | Dropwizard (via JTier) | jtier-service-pom 5.14.0 | `pom.xml` parent |
| Runtime container | prod-java11-jtier | 3 | `src/main/docker/Dockerfile` |
| Build tool | Maven | 3.5.4 | `mvnvm.properties` |
| Package manager | Maven | 3.5.4 | `mvnvm.properties` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-service-pom` | 5.14.0 | http-framework | Parent POM providing Dropwizard-based service scaffold |
| `jtier-daas-mysql` | managed by parent | db-client | MySQL DaaS connection pooling and configuration |
| `jtier-jdbi` | managed by parent | orm | JDBI SQL object DAO pattern for MySQL access |
| `jtier-retrofit` | managed by parent | http-client | Retrofit-based HTTP client for downstream service calls |
| `jtier-messagebus-client` | managed by parent | message-client | Groupon Mbus (message bus) publisher client |
| `jtier-quartz-bundle` | managed by parent | scheduling | Quartz job scheduler integration for background jobs |
| `jtier-migrations` | managed by parent | db-client | Database schema migration support |
| `jtier-quartz-mysql-migrations` | managed by parent | scheduling | Quartz job store backed by MySQL |
| `com.groupon.api:common-utils` | 1.2.0 | validation | Common Groupon API utilities |
| `immutables` | managed by parent | serialization | Compile-time immutable value object generation |
| `jackson` | managed by parent | serialization | JSON serialization/deserialization |
| `junit` | managed by parent | testing | Unit test framework |
| `assertj-core` | managed by parent | testing | Fluent assertion library |
| `dropwizard-testing` | managed by parent | testing | Integration test support for Dropwizard resources |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
