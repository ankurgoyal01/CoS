---
service: "billing-record-service"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Payments / Checkout"
platform: "Continuum"
team: "cap-payments@groupon.com"
status: active
tech_stack:
  language: "Java"
  language_version: "1.8"
  framework: "Spring MVC"
  framework_version: "4.3.7.RELEASE"
  runtime: "Apache Tomcat"
  runtime_version: "7"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Billing Record Service Overview

## Purpose

Billing Record Service (BRS) stores purchaser payment instrument data — including credit card Primary Account Numbers (PANs) and SEPA International Bank Account Numbers (IBANs) — together with associated billing addresses for later reuse at checkout. It acts as the authoritative record of what payment methods a Groupon purchaser has on file, managing the full lifecycle from creation through authorization, deactivation, and GDPR erasure. The service is a Tier 1 component with a target SLA of 99.9% and a maximum overhead of 100ms per request.

## Scope

### In scope

- Storing and retrieving purchaser billing records (credit card and SEPA/ELV payment instruments)
- Managing billing record lifecycle states: INITIATED, AUTHORIZED, USER_DEACTIVATED, REFUSED, EXPIRED, ONE_TIME_RECORD, IRR_FORGOTTEN
- Managing billing addresses associated with payment instruments
- Redis caching of billing record query results with selective invalidation
- GDPR Individual Rights Request (IRR) handling: erasing PII, marking records as IRR_FORGOTTEN, triggering PCI token deletion via PCI-API
- Publishing IRR completion events back to the Groupon Message Bus
- Consuming token-deletion messages from the Message Bus and orchestrating PCI-API calls
- Orders-to-BRS data migration for legacy billing record backfill
- Braintree one-time token generation for Grubhub integration

### Out of scope

- Raw payment processing and authorization (handled by payment gateways)
- PCI-scoped card storage (delegated to PCI-API)
- Order management (handled by `continuumOrdersService`)
- Checkout orchestration (handled by `continuumCheckoutReloadedService`)

## Domain Context

- **Business domain**: Payments / Checkout
- **Platform**: Continuum
- **Upstream consumers**: `continuumCheckoutReloadedService` (creates, updates, retrieves billing records); `continuumOrdersService` (billing record lookups by legacy order references)
- **Downstream dependencies**: PostgreSQL (primary data store), Redis (cache), PCI-API (token lifecycle), Braintree (one-time tokens), Groupon Message Bus (mbus), Orders MySQL (legacy migration reads)

## Stakeholders

| Role | Description |
|------|-------------|
| Service Owner | khsingh |
| Team Lead | pnamdeo |
| Engineering Team | pranade, khsingh, abhgupta, pnamdeo, ssaharawat, dawasthi, skaul |
| Mailing List | cap-payments@groupon.com |
| PagerDuty | https://groupon.pagerduty.com/services/PL181L3 |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 1.8 | `pom.xml` `<target.jdk>1.8</target.jdk>` |
| Framework | Spring MVC | 4.3.7.RELEASE | `pom.xml` `<spring.version>4.3.7.RELEASE</spring.version>` |
| Runtime | Apache Tomcat | 7 (tomcat7-maven-plugin) | `pom.xml` plugin config |
| ORM | Hibernate | 3.6.10.Final | `pom.xml` `<hibernate.version>` |
| Build tool | Maven | 3.9.6 | `Dockerfile` base image `maven:3.9.6-ibmjava-8` |
| Packaging | WAR | — | `pom.xml` `<packaging>war</packaging>` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| spring-data-jpa | Ingalls-SR16 | orm | JPA repository abstraction over Hibernate |
| spring-data-redis | Ingalls-SR16 | db-client | Redis cache integration |
| jedis | 2.9.0 | db-client | Redis client |
| hibernate-core | 3.6.10.Final | orm | JPA persistence provider |
| postgresql | 42.7.3 | db-client | PostgreSQL JDBC driver |
| liquibase-maven-plugin | 3.5.3 | db-client | Database schema migrations |
| braintree-java | 2.73.0 | payment | Braintree payment gateway integration |
| mbus-client | 1.3.1 | message-client | Groupon Message Bus producer and consumer |
| hystrix-core | 1.5.10 | resilience | Circuit breaker for external dependencies |
| archaius-core | 0.7.5 | config | Netflix Archaius dynamic configuration |
| jackson-databind | 2.8.7 | serialization | JSON serialization / deserialization |
| logback-steno | 1.16.2 | logging | Structured JSON logging (Steno format) |
| metrics-core | 3.2.2 | metrics | JVM and application metrics |
| springfox-swagger2 | 2.8.0 | api-docs | Swagger 2.0 API documentation generation |
| spring-hateoas | 0.23.0.RELEASE | http-framework | HAL+JSON hypermedia responses |
| immutables | 2.5.5 | serialization | Value-object code generation |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
