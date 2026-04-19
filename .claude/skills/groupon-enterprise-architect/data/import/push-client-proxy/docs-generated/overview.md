---
service: "push-client-proxy"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Email Delivery / Audience Management"
platform: "Continuum"
team: "Subscription Engineering"
status: active
tech_stack:
  language: "Java"
  language_version: "17"
  framework: "Spring Boot"
  framework_version: "3.5.4"
  runtime: "eclipse-temurin"
  runtime_version: "17-jre-jammy"
  build_tool: "Maven"
  package_manager: "Maven"
---

# push-client-proxy Overview

## Purpose

push-client-proxy is a Spring Boot service that acts as a gateway between Bloomreach (an external email platform) and Groupon's internal email and audience infrastructure. It validates, rate-limits, and routes outbound email sends via SMTP, and maintains audience membership records across Redis and PostgreSQL. It also consumes delivery-status events from Kafka to fire callback notifications back to upstream systems.

## Scope

### In scope

- Receiving `POST /email/send-email` requests from Bloomreach and routing them to the correct SMTP relay after validating rate limits, user account existence, and exclusion denylist.
- Verifying email-send credential tokens via `GET /email/verify`.
- Accepting `PATCH /audiences/{audienceId}` requests from the Audience Management Service and persisting audience membership changes to Redis and PostgreSQL.
- Returning audience counts via `GET /audiences/{audienceId}`.
- Consuming `msys_delivery` Kafka topic messages (CSV format), correlating them with cached Redis email metadata, and dispatching delivery-status callbacks to downstream HTTP endpoints.
- Consuming `email-send-topic` Kafka messages to process asynchronous batch email sends and persist outcomes to the email-send PostgreSQL table.
- Publishing retry messages back to `email-send-topic` for transient send failures.
- Emitting operational metrics (counters and timers) to InfluxDB via the `custom.cdp.*` namespace.

### Out of scope

- Template rendering and email content assembly — owned by upstream callers (Bloomreach / Audience Management).
- Subscription management data writes — the Subscription Service reads data authored elsewhere.
- Long-term email delivery analytics — written to InfluxDB and consumed downstream.
- Infrastructure for the Kafka broker — owned by the central Kafka platform team.

## Domain Context

- **Business domain**: Email delivery / Audience management
- **Platform**: Continuum
- **Upstream consumers**: Bloomreach (email send API), `continuumAudienceManagementService` (audience patch/get API)
- **Downstream dependencies**: SMTP relay, `continuumKafkaBroker` (topics `msys_delivery`, `email-send-topic`), PostgreSQL (main + exclusions DBs), MySQL (users lookup), Redis (primary + incentive clusters), InfluxDB (metrics)

## Stakeholders

| Role | Description |
|------|-------------|
| Subscription Engineering | Service owner; responsible for delivery, reliability, and on-call |
| Email Platform | Consumers of delivery-status callback events |
| Audience Management | Primary caller of the audience patch and get APIs |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 17 | `pom.xml` `<java.version>17</java.version>` |
| Framework | Spring Boot | 3.5.4 | `pom.xml` parent `spring-boot-starter-parent` |
| Runtime | eclipse-temurin | 17-jre-jammy | `src/main/docker/Dockerfile` |
| Build tool | Maven | 3.9.6 (CI) | `Jenkinsfile`, `mvnw` |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| spring-kafka | (Spring Boot BOM) | message-client | Kafka consumer and producer integration |
| spring-boot-starter-data-redis | (Spring Boot BOM) | db-client | Redis cluster access via Lettuce |
| spring-boot-starter-data-jpa | (Spring Boot BOM) | orm | JPA/Hibernate for PostgreSQL and MySQL |
| spring-boot-starter-mail | (Spring Boot BOM) | http-framework | SMTP email sending (JavaMail) |
| spring-boot-starter-web | (Spring Boot BOM) | http-framework | REST API layer (embedded Tomcat) |
| spring-boot-starter-validation | (Spring Boot BOM) | validation | Bean validation on request models |
| postgresql | 42.7.2 | db-client | PostgreSQL JDBC driver |
| mysql-connector-java | 8.0.33 | db-client | MySQL JDBC driver (users lookup) |
| bucket4j_jdk17-core | 8.15.0 | — | Token-bucket rate limiting |
| bucket4j_jdk17-lettuce | 8.15.0 | — | Redis-backed distributed rate limiting via Lettuce |
| guava | 32.1.3-jre | — | Utility collections and helpers |
| metrics-sma / metrics-sma-influxdb | 5.14.0 | metrics | Groupon internal SMA metrics library for InfluxDB |
| commons-pool2 | (Spring Boot BOM) | db-client | Connection pooling for Lettuce |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
