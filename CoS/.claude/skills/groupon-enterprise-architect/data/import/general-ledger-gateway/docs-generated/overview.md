---
service: "general-ledger-gateway"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Financial Operations / General Ledger"
platform: "Continuum"
team: "FED (fed@groupon.com)"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard"
  framework_version: "JTier jtier-service-pom 5.14.0"
  runtime: "JVM"
  runtime_version: "oracle64-11.0.9"
  build_tool: "Maven"
  package_manager: "Maven"
---

# General Ledger Gateway Overview

## Purpose

General Ledger Gateway (GLG) acts as an abstraction layer between Groupon's internal financial platform and NetSuite ERP systems. It receives invoice requests from Accounting Service, translates them into NetSuite RESTlet calls, and synchronises applied invoice data back from NetSuite into Accounting Service. The service was created as a Geekon 2020 project to decouple Accounting Service from direct NetSuite dependencies and to own the scheduled reconciliation jobs previously embedded in Accounting Service.

> **Note**: As of August 2022, the service is temporarily on hold with Kubernetes pods scaled to zero. The `ImportAppliedInvoicesJob` is production-ready and the infrastructure remains intact for rapid re-activation.

## Scope

### In scope

- Routing ledger invoice create/update requests to the correct NetSuite instance (`GOODS_NETSUITE`, `NETSUITE`, `NORTH_AMERICA_LOCAL_NETSUITE`)
- Exposing REST endpoints for invoice lookup and ledger entry status queries
- Running scheduled/on-demand jobs that download applied invoices from NetSuite saved searches and apply them in Accounting Service
- Caching NetSuite currency lookups in Redis
- Persisting invoice records and ledger entry mappings in PostgreSQL
- Managing Quartz scheduler state (job store) in PostgreSQL

### Out of scope

- Direct merchant payment processing (handled by Accounting Service)
- NetSuite administration or account configuration
- Payment synchronisation job (`ImportPaymentsJob`) — planned but not yet implemented
- Kafka/message-bus enqueueing strategies — under investigation (see FED-10260)

## Domain Context

- **Business domain**: Financial Operations / General Ledger
- **Platform**: Continuum
- **Upstream consumers**: Accounting Service (invoice create/show/apply via HTTPS)
- **Downstream dependencies**: NetSuite ERP (three instances via OAuth 1.0 RESTlets over HTTPS), Accounting Service (apply-invoice callbacks via HTTPS), PostgreSQL (read/write + read-only), Redis (cache)

## Stakeholders

| Role | Description |
|------|-------------|
| Service Owner | Eric Evangelista (erevangelista@groupon.com) |
| Engineering Team | FED (Finance Engineering Division) |
| Primary Consumer | Accounting Service (sox-inscope) |
| Compliance Boundary | SOX-inscope — restricted push-to-main access |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `pom.xml` `project.build.targetJdk`, `.java-version` |
| Framework | Dropwizard (JTier) | jtier-service-pom 5.14.0 | `pom.xml` parent |
| Runtime | JVM | oracle64-11.0.9 | `.java-version` |
| Build tool | Maven | 3.6+ | `.mvn/maven.config`, `README.md` |
| Container base | prod-java11-jtier | 2023-12-19-609aedb | `src/main/docker/Dockerfile` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Dagger 2 | 2.40.1 | dependency-injection | Compile-time dependency injection |
| Quartz (jtier-quartz-bundle) | JTier managed | scheduling | Cron and ad-hoc job management |
| Flyway | 8.0.4 | db-client | Database schema migrations |
| jtier-daas-postgres | 5.2.0 | db-client | PostgreSQL connection pool management |
| jtier-jdbi3 | JTier managed | orm | JDBI 3 DAO layer over PostgreSQL |
| dropwizard-redis | 1.5.1 | db-client | Redis integration via Lettuce for NetSuite cache |
| ScribeJava APIs | 8.1.0 | auth | OAuth 1.0 signing for NetSuite RESTlet calls |
| Resilience4j Retry | 1.7.1 | http-framework | Retry policies on NetSuite and Accounting Service HTTP calls |
| WireMock | 2.27.2 | testing | HTTP stub server for integration tests |
| Mockito JUnit Jupiter | JTier managed | testing | Unit test mocking |
| Hamcrest | 2.2 | testing | Assertion matchers |
