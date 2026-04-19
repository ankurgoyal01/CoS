---
service: "mx-merchant-access"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Merchant Experience"
platform: "Continuum"
team: "Merchant Experience"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Spring MVC"
  framework_version: "4.2.0.RELEASE"
  runtime: "Apache Tomcat"
  runtime_version: "8.5.73"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Merchant Access Service Overview

## Purpose

The Merchant Access Service (MAS, service ID `mx-merchant-access`) is the single authorization service that controls which user accounts may access which merchants on the Groupon platform. It manages merchant contacts, assigns application-scoped roles and access rights, tracks primary contacts per merchant, and maintains an audit trail of all changes. It also reacts to lifecycle events from the user-accounts system (account merged, deactivated, or erased) to keep access data consistent.

## Scope

### In scope
- Creating and deleting merchant contact relationships (user-to-merchant bindings)
- Assigning and updating per-application roles for a merchant contact
- Maintaining the primary contact designation for each merchant
- Storing and managing future contacts (invited users not yet registered)
- Managing notification group preferences per merchant contact
- Consuming MBus account lifecycle events to clean up access data on account deletion, deactivation, or merge
- Full audit trail of all write operations
- Exposing roles and access rights catalog via REST

### Out of scope
- User authentication (delegated to identity provider / users-service)
- Merchant data management (handled by `mx-merchant-api`)
- Direct customer-facing (B2C) access control
- Deal or order-level authorization

## Domain Context

- **Business domain**: Merchant Experience (MX)
- **Platform**: Continuum (legacy/modern commerce engine)
- **Upstream consumers**: Internal MX platform services requiring merchant-user authorization (e.g., merchant portal front-end, merchant-api); SOX-scoped and non-SOX consumers use separate VIP endpoints
- **Downstream dependencies**: PostgreSQL (primary data store via DaaS), MBus (message bus for lifecycle events), `mx-merchant-api` (referenced as dependency)

## Stakeholders

| Role | Description |
|------|-------------|
| Service owner | rrathore (Merchant Experience team) |
| Engineering team | MerchantCenter-BLR@groupon.com |
| Alerting contact | bmx-alert@groupon.com |
| API announcements | mx-api-announce@groupon.com |
| On-call | PagerDuty service PV2ZOZL |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `pom.xml` (`java.version=11`) |
| Framework | Spring MVC | 4.2.0.RELEASE | `access-webapp/pom.xml` |
| Runtime | Apache Tomcat | 8.5.73 | `access-webapp/src/main/docker/Dockerfile` |
| Base image | JRE Temurin (prod-java11) | 2021-10-14 | `Dockerfile` |
| Build tool | Maven | 3.x | `pom.xml` (multi-module) |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `spring-webmvc` | 4.2.0.RELEASE | http-framework | REST controller layer, dispatcher servlet |
| `spring-orm` / `spring-tx` | 4.2.0.RELEASE | orm | JPA integration and transaction management |
| `hibernate-core` | 4.3.6.Final | orm | JPA/ORM provider for entity persistence |
| `hibernate-entitymanager` | 4.3.6.Final | orm | EntityManager factory |
| `postgresql` | 42.7.3 | db-client | JDBC driver for PostgreSQL |
| `commons-dbcp` | 1.4 | db-client | Database connection pool |
| `commons-mbus` (mx-commons) | 1.54.21 | message-client | MBus consumer integration for account lifecycle events |
| `mx-clients` | 1.141.21 | http-client | Internal Groupon service client library |
| `ehcache` | 2.8.1 | cache | In-process caching (optional, toggled by `mas.ehcache_enabled`) |
| `liquibase-core` | 3.2.2 | db-migration | Database schema migration management |
| `httpclient` (Apache) | 4.3.6 | http-client | Outbound HTTP requests to downstream services |
| `slf4j-api` + `slf4j-log4j12` | 1.7.5 | logging | Structured logging facade and log4j binding |
| `metrics-sma` / `metrics-sma-influxdb` | 5.5.0 | metrics | SMA metric emission (Wavefront-compatible) |
| `opentelemetry-javaagent` | bundled | observability | Distributed tracing via OpenTelemetry Java agent |
| `guava` | 18.0 | utility | Immutable collections, string splitting utilities |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
