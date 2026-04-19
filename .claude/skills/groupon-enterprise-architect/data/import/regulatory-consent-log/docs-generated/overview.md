---
service: "regulatory-consent-log"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Regulatory / Privacy (GDPR)"
platform: "Continuum"
team: "Groupon API"
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

# Regulatory Consent Log Overview

## Purpose

The Regulatory Consent Log (RCL) service is the authoritative store for GDPR-mandated user consent records across Groupon and LivingSocial. It persists, retrieves, and revokes user consents captured at registration, checkout, subscription, cookie acceptance, and other consumer-facing touchpoints. It also manages the erasure lifecycle for b-cookies belonging to deleted users, satisfying Groupon's right-to-be-forgotten obligations.

## Scope

### In scope

- Storing and retrieving user consent log records (identifiers: `user_id`, `b_cookie`, `device_id`)
- Supporting multiple consent workflow types: `registration`, `checkout`, `email_subscription`, `billing_record`, `cookies`, `user_delete`, `order_update`, `start_tradein`, `groupon_redeem`, `order_return`, `dnsmi`, `vas`, `social_submodal`
- Managing consent event types: `accept`, `revoke`, `forget`
- Tracking erased b-cookie mappings for users who exercised right-to-erasure
- Initiating and tracking user account erasure requests
- Receiving and processing Transcend webhook events (access requests and erasure requests) for GDPR compliance
- Publishing consent log messages to the message bus via Cronus
- Consuming user-erasure events from the message bus and managing the async erasure pipeline

### Out of scope

- Performing the actual user account deletion (handled by the Users Service)
- Serving b-cookie issuance (handled by API-Torii / Janus)
- Access request data aggregation beyond consent records (handled by Lazlo / Transcend)
- Consent UI rendering (handled by front-end services and consumer-facing flows)

## Domain Context

- **Business domain**: Regulatory / Privacy (GDPR)
- **Platform**: Continuum
- **Upstream consumers**: Registration service, Checkout service, Subscription Modal service, API-Lazlo, API-Torii, Transcend Privacy Platform (webhook)
- **Downstream dependencies**: PostgreSQL (DaaS), Redis (RaaS), Message Bus (ActiveMQ Artemis), Janus Aggregator Service, Transcend Privacy Platform, Lazlo API, LivingSocial Transcend API, LivingSocial Lazlo API

## Stakeholders

| Role | Description |
|------|-------------|
| Groupon API Team | Service owners and maintainers (apidevs@groupon.com) |
| Privacy / Legal | Requires accurate consent audit trail for GDPR compliance |
| Registration, Checkout, Subscription teams | Primary API consumers for consent recording |
| API-Lazlo / API-Torii | Consumers of the cookie validation endpoint |
| Platform Integration / SRE | Monitor SLAs and on-call response |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `.java-version`, `pom.xml` `project.build.targetJdk` |
| Framework | Dropwizard (JTier) | jtier-service-pom 5.14.0 | `pom.xml` parent |
| Runtime | JVM | 11 | `src/main/docker/Dockerfile` (`prod-java11-jtier:3`) |
| Build tool | Maven | 3.x | `.mvn/maven.config`, `pom.xml` |
| Package manager | Maven | | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-daas-postgres` | (BOM managed) | db-client | PostgreSQL DataSource via Groupon DaaS |
| `jtier-messagebus-client` | (BOM managed) | message-client | Publish and consume MBus/ActiveMQ Artemis topics |
| `jtier-jdbi3` + `jdbi3-stringtemplate4` | (BOM managed) | orm | SQL mapping and query templating via JDBI 3 |
| `cronus-bundle` | (BOM managed) | scheduling | Transactional outbox pattern for MBus publishing |
| `jtier-quartz-bundle` | (BOM managed) | scheduling | Quartz scheduler integration for periodic jobs |
| `dropwizard-redis` (dropwizard-jedis) | (BOM managed) | db-client | Redis pub/sub and queue operations |
| `regconsentlog-server` | 1.4 | http-framework | Generated JAX-RS server stubs from OpenAPI 2.0 spec |
| `retrofit` + `okhttp` | (BOM managed) | http-framework | HTTP client for Janus, Transcend, and Lazlo integrations |
| `java-jwt` (auth0) | 3.8.2 | auth | JWT verification for Transcend webhook signatures |
| `steno` | (BOM managed) | logging | Structured JSON logging |
| `metrics-sma-influxdb` + `metrics-sma` | (BOM managed) | metrics | SMA/InfluxDB metrics reporting |
| `testcontainers` | 1.15.1 | testing | Integration testing with real Postgres and Redis containers |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
