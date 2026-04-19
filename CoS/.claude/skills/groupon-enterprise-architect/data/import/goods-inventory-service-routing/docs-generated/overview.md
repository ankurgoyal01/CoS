---
service: "goods-inventory-service-routing"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Goods / Inventory / Logistics"
platform: "Continuum"
team: "RAPT"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard"
  framework_version: "JTier jtier-service-pom 5.7.3"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Goods Inventory Service Routing Overview

## Purpose

Goods Inventory Service Routing (GISR) is an HTTP routing proxy that sits in front of the multi-regional Goods Inventory Service (GIS). It receives inventory product read, upsert, and update requests, determines which regional GIS instance owns the requested products based on their shipping regions, and forwards the request to the correct regional endpoint. A local PostgreSQL store caches the shipping-region-to-product mapping so that routing decisions can be made without roundtripping to GIS on every call.

## Scope

### In scope

- Routing `GET /inventory/v1/products` calls to the correct regional GIS instance by shipping region
- Routing `POST /inventory/v1/products` (upsert) calls to the correct regional GIS instance
- Routing `PUT /inventory/v1/products/{uuid}` (update) calls to the correct regional GIS instance
- Persisting and updating the inventory-product-to-shipping-region mapping in a local PostgreSQL store after every successful upsert or update
- Validating that all products in a single request belong to the same geographic region (rejecting mixed-region batches)
- Injecting the `X-HB-Region` hybrid-boundary header when forwarding requests to GIS

### Out of scope

- Actual inventory product storage and business logic (owned by `continuumGoodsInventoryService`)
- Order processing, deal management, and payment flows
- Consumer-facing product catalogue or search

## Domain Context

- **Business domain**: Goods / Inventory / Logistics
- **Platform**: Continuum
- **Upstream consumers**: Internal Groupon services that create or query inventory products without knowing which regional GIS owns them
- **Downstream dependencies**: `continuumGoodsInventoryService` (NA and EMEA regional endpoints), `continuumGoodsInventoryServiceRoutingDb` (PostgreSQL)

## Stakeholders

| Role | Description |
|------|-------------|
| Team owner | RAPT team (`inventory@groupon.com`) |
| On-call / SRE | Pagerduty service P7VSOA6; Slack `#goods-eng-seattle` |
| Service owner (named) | dbreen (owner), creisor, brettk (members) |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `pom.xml` `project.build.targetJdk = 11`; Dockerfile `prod-java11-jtier` |
| Framework | Dropwizard (JTier) | jtier-service-pom 5.7.3 | `pom.xml` parent |
| Runtime | JVM | 11 | `.java-version`, Dockerfile base image |
| Build tool | Maven | mvnvm-managed | `mvnvm.properties`, `.mvn/maven.config` |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-daas-postgres` | (JTier managed) | db-client | Managed PostgreSQL connection pool and DaaS integration |
| `jtier-jdbi3` | (JTier managed) | orm | JDBI 3 SQL object mapping for DAO layer |
| `jtier-okhttp` | (JTier managed) | http-framework | OkHttp-based HTTP client for outbound GIS calls |
| `io.dropwizard:dropwizard-testing` | (JTier managed) | testing | Integration test harness for Dropwizard resources |
| `org.immutables:value` | (JTier managed) | serialization | Compile-time immutable value objects for request/response types |
| `io.atlassian.fugue:fugue` | 3.0.0 | validation | `Either` type for functional error-handling in routing and client layers |
| `com.fasterxml.jackson` | (JTier managed) | serialization | JSON serialization/deserialization for API contracts |
| `org.jdbi.v3` | (JTier managed) | db-client | SQL queries and transactions against PostgreSQL |
| `codahale.metrics` | (JTier managed) | metrics | Health check and metrics reporting |
| `com.arpnetworking.steno` | (JTier managed) | logging | Structured JSON (steno) logging |
| `org.junit.jupiter` | (JTier managed) | testing | JUnit 5 unit and integration tests |
| `org.assertj:assertj-core` | (JTier managed) | testing | Fluent assertion library for tests |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
