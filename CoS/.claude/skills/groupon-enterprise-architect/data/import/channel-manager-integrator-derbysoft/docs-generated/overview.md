---
service: "channel-manager-integrator-derbysoft"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Getaways / Travel"
platform: "Continuum"
team: "Getaways Engineering"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard"
  framework_version: "via jtier-service-pom 5.14.1"
  runtime: "JVM"
  runtime_version: "Java 11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Channel Manager Integrator Derbysoft Overview

## Purpose

The Channel Manager Integrator Derbysoft service acts as the integration bridge between Groupon Getaways and the Derbysoft channel manager. It receives Availability, Rates, and Inventory (ARI) data pushed by Derbysoft partners, validates and persists the payload, then forwards it to internal Groupon systems via Kafka. It also processes outbound reservation and cancellation requests from the internal system (received via MBus) and submits them to the Derbysoft API over HTTPS, returning confirmation or failure responses through MBus.

## Scope

### In scope
- Receiving and validating Daily ARI push payloads from Derbysoft (`POST /ari/daily/push`)
- Publishing validated ARI payloads to an internal Kafka topic
- Consuming `RESERVE` and `CANCEL` booking request messages from MBus
- Submitting pre-book, book, and cancellation calls to the Derbysoft reservation API
- Persisting reservation, cancellation, ARI request/response records, and hotel/room-type/rate-plan mapping data to PostgreSQL
- Exposing resource mapping endpoints for hotel hierarchy and connectivity extranet mapping management
- Exposing a hotel sync status API for checking Derbysoft supplier hotel and product states

### Out of scope
- Inventory pricing logic (owned by `getaways-inventory`)
- Customer-facing booking UX
- Payment processing
- Channel manager routing decisions (which channel manager handles a given hotel is determined upstream)

## Domain Context

- **Business domain**: Getaways / Travel
- **Platform**: Continuum
- **Upstream consumers**: Groupon Inventory Service Worker (ISW) sends booking/cancel messages via MBus; Derbysoft partner systems push ARI data via HTTP
- **Downstream dependencies**: Derbysoft Channel Manager API (HTTPS/JSON); Getaways Inventory Service (HTTP/JSON for hierarchy lookups); MBus broker (STOMP/JMS); Kafka broker

## Stakeholders

| Role | Description |
|------|-------------|
| Getaways Engineering | Owns and maintains this service (getaways-eng@groupon.com) |
| Service Owner | nranjanray |
| On-call team members | mann, pracharya, sdash |
| SRE / Monitoring | getaways-monitoring+inventory-production@groupon.com |
| PagerDuty | PNID06D |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `pom.xml` — `<project.build.targetJdk>11</project.build.targetJdk>`, `src/main/docker/Dockerfile` |
| Framework | Dropwizard (JTier) | jtier-service-pom 5.14.1 | `pom.xml` `<parent>` block |
| Runtime | JVM | Java 11 | `src/main/docker/Dockerfile` — `FROM docker.groupondev.com/jtier/prod-java11-jtier:3` |
| Build tool | Maven | mvnvm.properties | `mvnvm.properties`, `.mvn/maven.config` |
| Package manager | Maven | | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-service-pom` | 5.14.1 | http-framework | Parent POM providing Dropwizard, JTier platform conventions |
| `kafka-clients` | 0.10.2.1 | message-client | Kafka producer for publishing ARI payloads |
| `jtier-messagebus-client` | (BOM-managed) | message-client | MBus STOMP/JMS client for consuming ISW booking messages and producing booking responses |
| `jtier-daas-postgres` | (BOM-managed) | db-client | Managed PostgreSQL data source and connection pooling |
| `jtier-jdbi3` | (BOM-managed) | orm | JDBI3 DAO layer for SQL access |
| `jtier-migrations` | (BOM-managed) | db-client | PostgreSQL schema migration via Flyway/Liquibase bundle |
| `jtier-retrofit` | (BOM-managed) | http-framework | Retrofit2-based HTTP client for Derbysoft and Inventory API calls |
| `jtier-swagger-annotations` | (BOM-managed) | validation | Swagger/OpenAPI annotations for endpoint documentation |
| `channel-manager-async-schema` | 0.0.22 | serialization | Shared schema for `RequestMessageContainer`, `ResponseMessageContainer`, `ARIMessage`, and related message types |
| `joda-money` | 0.12 | serialization | Monetary value representation used in rate/pricing data |
| `lombok` | 1.18.2 | validation | Boilerplate reduction for immutable data objects |
| `commons-collections` | 3.2.2 | validation | Apache Commons Collections utility (version-pinned for conflict resolution) |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
