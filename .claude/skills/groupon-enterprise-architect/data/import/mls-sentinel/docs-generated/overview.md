---
service: "mls-sentinel"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Merchant Lifecycle System"
platform: "Continuum"
team: "Merchant Experience"
status: active
tech_stack:
  language: "Java"
  language_version: "17"
  framework: "Dropwizard (JTier)"
  framework_version: "5.14.0"
  runtime: "JVM"
  runtime_version: "17"
  build_tool: "Maven"
  package_manager: "Maven"
---

# MLS Sentinel Overview

## Purpose

MLS Sentinel is the validation and routing gateway of the Merchant Lifecycle System (MLS). It consumes domain events from the internal MessageBus (voucher sales, voucher redemptions, CLO transactions, Salesforce account changes), validates the data against authoritative upstream services, and emits fully-validated Kafka Command messages for downstream consumers — primarily MLS Yang. It also serves as the write API for the Merchant History Service.

## Scope

### In scope

- Consuming domain events from MessageBus queues (`jms.queue.mls.*`, `jms.topic.clo.*`)
- Validating entity freshness against owner services (VIS, M3, Deal Catalog, Reading Rainbow) before emitting commands
- Publishing validated Kafka Command messages to MLS topics (`mls.VoucherSold`, `mls.VoucherRedeemed`, `mls.MerchantFactChanged`, `mls.MerchantAccountChanged`, `mls.CloTransaction`, `mls.BulletCreated`, `mls.HistoryEvent`)
- Maintaining three internal PostgreSQL databases: deal index, inventory unit index, and merchant history
- Exposing operational trigger endpoints for backfill, DLQ retry, manual update, and CLO transaction injection
- Writing history events to the Merchant History DB and/or forwarding them to Yang via Kafka

### Out of scope

- Consuming or projecting the Kafka Command messages (responsibility of MLS Yang)
- Read-model queries over merchant history (responsibility of MLS Yang)
- Commerce transaction processing (handled by the voucher and CLO origin systems)
- Merchant account management (handled by M3 Merchant Service and Salesforce integration layer)

## Domain Context

- **Business domain**: Merchant Lifecycle System (MLS)
- **Platform**: Continuum
- **Upstream consumers**: MLS Yang (primary Kafka consumer), any service subscribed to `mls.*` Kafka topics
- **Downstream dependencies**: MessageBus (MBus), Voucher Inventory Service (VIS), Reading Rainbow, M3 Merchant Service, Deal Catalog Service, Inventory Service, three owned PostgreSQL databases

## Stakeholders

| Role | Description |
|------|-------------|
| Merchant Experience Team | Service owner; on-call responder via bmx-alert@groupon.com and PagerDuty |
| MLS Yang Team | Primary consumer of Kafka Command messages produced by Sentinel |
| SRE / Platform | Infrastructure provisioning and cloud migration support |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 17 | `pom.xml` — `<project.build.targetJdk>17</project.build.targetJdk>` |
| Framework | Dropwizard (JTier) | 5.14.0 | `pom.xml` — parent `jtier-service-pom:5.14.0` |
| Runtime | JVM (Eclipse Temurin) | 17 | `src/main/docker/Dockerfile` — `prod-java17-jtier:2024-12-11-v2` |
| Build tool | Maven | 3.x (mvnvm) | `mvnvm.properties`, `.mvn/maven.config` |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-service-pom` | 5.14.0 | http-framework | JTier parent POM; provides Dropwizard lifecycle, DI, auth bundles |
| `mls-commons` / `mls-shared-bom` | 2.1.1 | message-client | Shared MLS command types, Kafka router, serialization utilities |
| `jtier-jdbi` / `hk2-di-jdbi3` | — | db-client | JDBI3 DAO layer with HK2 DI integration for PostgreSQL access |
| `jtier-daas-postgres` | — | db-client | JTier DaaS-managed PostgreSQL connection pooling |
| `jtier-messagebus` (MBus) | — | message-client | MessageBus consumer/producer for JMS-style queue/topic consumption |
| `kafka_2.11` | 0.9.0.1 | message-client | Apache Kafka producer for emitting MLS Command messages |
| `hk2-di-retrofit` / `jtier-rxjava3-retrofit` | — | http-framework | Retrofit2 + RxJava3 HTTP client framework for upstream service calls |
| `fis-client-rxjava-jsonholder` | 0.6.6 | http-framework | FIS (Federated Inventory Service) Rx HTTP client |
| `org.immutables:value` | — | serialization | Immutable value objects for configuration and message payloads |
| `jtier-auth-bundle` | — | auth | Client-ID based authentication for inbound trigger API requests |
| `jtier-opslog` | — | logging | Structured operations logging (Steno logger) |
| `metricslib` | 1.0.6 | metrics | Groupon metrics library; feeds Wavefront dashboards |
| `flyway-core` | 6.0.0 | db-client | Database schema migrations (test scope; migrations in `mls-db-schemas`) |
| `opentelemetry-javaagent` | bundled | metrics | OpenTelemetry Java agent for distributed tracing via OTLP |
