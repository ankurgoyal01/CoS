---
service: "jtier-oxygen"
title: Overview
generated: "2026-03-03"
type: overview
domain: "JTier Platform / Developer Tooling"
platform: "Continuum"
team: "JTier"
status: active
tech_stack:
  language: "Java"
  language_version: "21"
  framework: "Dropwizard"
  framework_version: "via jtier-service-pom 5.15.0"
  runtime: "JVM"
  runtime_version: "21"
  build_tool: "Maven"
  package_manager: "Maven"
---

# JTier Oxygen Overview

## Purpose

JTier Oxygen is a smoke-test and prototyping service for the JTier platform framework. It exercises all major JTier building blocks — HTTP, DaaS (Postgres), RaaS (Redis), MessageBus, and Quartz scheduling — in a real deployed service without carrying production business logic. Changes to JTier framework libraries are validated against Oxygen before being promoted to production services.

## Scope

### In scope

- HTTP REST API demonstrating JTier's Dropwizard-based request handling
- Broadcast management: creating, starting, stopping, and monitoring message-bus fanout scenarios
- Greeting CRUD operations backed by Postgres (exercising JDBI3 + DaaS integration)
- Redis key-value read/write operations (exercising RaaS / Jedis bundle)
- MessageBus publish, consume, mass-publish, mass-consume, and roundtrip performance testing
- GitHub repository star lookup via external HTTP client (OkHttp)
- Quartz-based scheduled jobs (`EverywhereJob` and `ExclusiveJob`) running on a cron schedule
- Proxy endpoint to forward HTTP GET requests to arbitrary URLs

### Out of scope

- Business-critical commerce workflows (orders, payments, deals)
- Customer-facing features
- Data owned by other platform services

## Domain Context

- **Business domain**: JTier Platform / Developer Tooling
- **Platform**: Continuum
- **Upstream consumers**: JTier team engineers and CI pipeline — no external consumer services depend on Oxygen
- **Downstream dependencies**: Postgres (`continuumOxygenPostgres`), Redis (`continuumOxygenRedisCache`), MessageBus, GitHub Enterprise API

## Stakeholders

| Role | Description |
|------|-------------|
| Owner | alasdair (JTier team lead) |
| Team | JTier — daobrien, mmakowski |
| Alerts | jtier-alerts@groupon.com / PagerDuty POVGKE5 |
| Mailing list | jtier-team@groupon.com |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 21 | `pom.xml` `<project.build.targetJdk>21</project.build.targetJdk>` |
| Framework | Dropwizard (JTier) | jtier-service-pom 5.15.0 | `pom.xml` parent POM |
| Runtime | JVM | 21 | `.java-version` (11.0 pin, target 21 in pom) |
| Build tool | Maven | - | `pom.xml`, `.mvn/maven.config` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-daas-postgres` | inherited | db-client | DaaS-managed PostgreSQL connection pooling |
| `jtier-jdbi3` | inherited | orm | JDBI3 DAO layer for SQL access |
| `jtier-messagebus-client` | inherited | message-client | JTier MessageBus (ActiveMQ/Artemis) publish and consume |
| `jtier-jedis-bundle` | inherited | db-client | Redis (RaaS) client integration via Jedis |
| `jtier-quartz-bundle` | inherited | scheduling | Quartz scheduler integration for cron jobs |
| `jtier-quartz-postgres-migrations` | inherited | scheduling | Quartz persistence schema migrations on Postgres |
| `jtier-okhttp` | inherited | http-framework | OkHttp-based HTTP client for outbound calls |
| `jtier-retrofit` | inherited | http-framework | Retrofit HTTP client wrapper for typed external API calls |
| `jtier-migrations` | inherited | db-client | Database schema migration management |
| `junit-jupiter-migrationsupport` | inherited | testing | JUnit 5 test support |
| `mockwebserver` | inherited | testing | OkHttp mock server for HTTP client integration tests |
| `jtier-testing` | inherited | testing | JTier-specific test harness utilities |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for the full list.
