---
service: "unit-tracer"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Finance Engineering"
platform: "Continuum"
team: "Finance Engineering"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard"
  framework_version: "JTier jtier-service-pom 5.14.0"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Unit Tracer Overview

## Purpose

Unit Tracer is an internal diagnostic tool owned by Finance Engineering that builds aggregated history reports for individual Groupon inventory units (vouchers). Given a unit UUID or Groupon code (e.g., `LG-`, `TP-`, `VS-`, `GL-` prefixed codes), it fans out to multiple upstream services — inventory services, accounting service, and the message-to-ledger service — and consolidates the results into a single HTML or JSON report. The tool exists to support finance engineers and customer support workflows when investigating the lifecycle and payment state of a voucher unit.

## Scope

### In scope

- Accepting a unit identifier (UUID or Groupon code) via HTTP query parameter
- Validating and normalizing the identifier (UUID format, valid Groupon code prefix)
- Querying Third Party Inventory Service, Voucher Inventory Service, and Groupon Live Inventory Service (with sequential fallback) for unit inventory details
- Querying Accounting Service for unit financial data (`amounts`, `checkNumbers`, `inventoryUnitEvents`, `payableEvents`, `salesforcePaymentTerm`) and vendor payment schedules
- Querying Message to Ledger service for unit lifecycle message history
- Assembling all responses into a `UnitReport` with per-step request/response logging and error capture
- Serving reports as rendered HTML (browser-friendly) via `GET /unit` and as JSON via `GET /api/unit`
- Supporting batch lookups of multiple unit IDs in a single request (comma-separated)

### Out of scope

- Writing or modifying inventory, accounting, or ledger records
- Consuming or publishing asynchronous events or message queues
- Owning any persistent data store
- Authentication or authorization enforcement (no auth mechanism configured at the resource level)
- Customer-facing endpoints

## Domain Context

- **Business domain**: Finance Engineering
- **Platform**: Continuum
- **Upstream consumers**: Finance engineers, customer support tooling (internal; upstream consumers are tracked in the central architecture model)
- **Downstream dependencies**: `continuumThirdPartyInventoryService`, `continuumVoucherInventoryService`, Groupon Live Inventory Service (stub), Accounting Service (`continuumAccountingService`), Message to Ledger service (stub)

## Stakeholders

| Role | Description |
|------|-------------|
| Finance Engineering team | Service owners; receive build failure email alerts on `main` branch failures |
| Finance engineers / CS tools | Primary users who look up unit history for investigation and reconciliation |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `src/main/docker/Dockerfile` — `prod-java11-jtier:3` |
| Framework | Dropwizard (JTier) | jtier-service-pom 5.14.0 | `pom.xml` parent |
| Runtime | JVM | 11 | `src/main/docker/Dockerfile` |
| Build tool | Maven | 3.6.3 | `mvnvm.properties` |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-retrofit` | 4.2.2 | http-framework | Retrofit-based HTTP client wiring for all downstream service calls |
| `dropwizard-views-mustache` | (managed by JTier BOM) | ui-framework | Mustache template rendering for HTML report views |
| `retrofit2` | (transitive via jtier-retrofit) | http-framework | Typed REST client interface definitions for all five downstream clients |
| `jackson-databind` | (managed by JTier BOM) | serialization | JSON serialization/deserialization of API responses |
| `wiremock` | 2.20.0 | testing | HTTP mock server for integration tests |
| `dropwizard-core` | (managed by JTier BOM) | http-framework | JAX-RS resource registration, lifecycle, health checks |
| `codahale metrics` | (managed by JTier BOM) | metrics | Dropwizard health check base class |
| `arpnetworking steno` | (transitive via JTier) | logging | Structured JSON logging (steno format) |
| `guava ImmutableMap` | (transitive) | validation | Immutable query parameter map construction |
| `swagger-annotations` | (managed by JTier BOM) | api-documentation | `@Api` annotation on JAX-RS resources for Swagger spec generation |
| `hibernate-validator` | (managed by JTier BOM) | validation | `@NotEmpty` constraint on query parameters |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
