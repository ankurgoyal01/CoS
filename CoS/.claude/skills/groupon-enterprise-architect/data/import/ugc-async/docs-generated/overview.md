---
service: "ugc-async"
title: Overview
generated: "2026-03-03"
type: overview
domain: "User Generated Content"
platform: "Continuum"
team: "UGC"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard"
  framework_version: "via jtier-service-pom 5.14.0"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# UGC Async Service Overview

## Purpose

ugc-async is the asynchronous background-processing service for Groupon's User Generated Content platform. It consumes events from the internal message bus (MBus), runs scheduled Quartz jobs, and performs long-running tasks such as survey creation, survey notification dispatch, media migration from S3, GDPR erasure processing, and ratings aggregation. The service acts as the processing backbone for UGC so that real-time consumer-facing services remain responsive.

## Scope

### In scope
- Consuming MBus events for deal updates, rating events, GDPR erasure requests, cache expiry, and survey triggers
- Creating surveys for Local, Third-Party, and Goods deal types from order data and Teradata
- Sending survey notifications via email, push, and inbox channels
- Dispatching email reminder notifications for unanswered surveys
- Moving customer-uploaded images and videos from S3 staging buckets to the Image Service
- Aggregating ratings and updating place/merchant aspect summaries from Essence NLP output
- Scheduled cleanup of duplicate surveys
- Goods data migration jobs (cloned deal review transfer, goods migration)
- GDPR user-data erasure processing

### Out of scope
- Real-time survey submission and answer ingestion (handled by ugc-api / ugc-all)
- Serving review/rating read APIs
- Direct consumer-facing HTTP interactions (this is a worker, not an API server)
- Email / push template rendering (delegated to Rocketman / CRM messaging services)

## Domain Context

- **Business domain**: User Generated Content
- **Platform**: Continuum
- **Upstream consumers**: MBus platform publishes events that trigger this service; Quartz timer triggers scheduled jobs internally
- **Downstream dependencies**: UGC Postgres DB, Redis cache, Taxonomy Service, Deal Catalog Service, Voucher Inventory Service, Goods Inventory Service, Users Service, Consumer Data Service, M3 Merchant Service, API Gateway, Booking Service, Rocketman (email/push), CRM inbox service, S3, Image Service, Teradata warehouse, Essence Aspect Tagging Service

## Stakeholders

| Role | Description |
|------|-------------|
| Owner | yrathore (UGC team) |
| Team members | sudasari, yrathore, jshashoo, skhanduri, piyc |
| Team email | ugc-dev@groupon.com |
| SRE alerts | ugc-alerts@groupon.com |
| On-call | PagerDuty service P057HSW |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `pom.xml` `project.build.targetJdk=11`; Dockerfile `prod-java11-jtier:3` |
| Framework | Dropwizard | via jtier-service-pom | `pom.xml` parent `jtier-service-pom:5.14.0` |
| Runtime | JVM 11 (Eclipse Temurin) | image tag :3 | `src/main/docker/Dockerfile` `FROM docker.groupondev.com/jtier/prod-java11-jtier:3` |
| Build tool | Maven | - | `pom.xml` |
| Scheduler | Quartz | via jtier-quartz-bundle | `pom.xml` `jtier-quartz-bundle` dependency |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| jtier-service-pom | 5.14.0 | http-framework | Parent POM providing Dropwizard, health check, and JTIER platform conventions |
| jtier-messagebus-client | managed | message-client | Consuming and interacting with internal MBus topics |
| jtier-quartz-bundle | managed | scheduling | Quartz job scheduling integrated with Dropwizard lifecycle |
| jtier-daas-postgres | managed | db-client | PostgreSQL data-access layer (JDBI-based) |
| jtier-daas-mysql | managed | db-client | MySQL data-access layer (used for legacy stores) |
| jtier-jdbi | managed | orm | JDBI DAO wiring and configuration |
| jtier-migrations | managed | db-client | Database schema migration management |
| jedis / dropwizard-redis | 3.0.1 | db-client | Redis client for cache coordination |
| redisson | managed | db-client | Distributed lock and Redis advanced client |
| jtier-retrofit | managed | http-framework | HTTP client wiring for downstream service calls |
| ugc-common | 1.1.2025.11.13_21.07_09c51be8 | db-client | Shared UGC JDBI DAOs, models, and service utilities |
| gson | managed | serialization | JSON serialization for Redis payloads |
| opencsv | 4.0 | serialization | CSV parsing for Teradata import data |
| async-http-client (ning) | 1.9.40 | http-framework | Async HTTP calls to downstream services |
| commons-pool2 | 2.9.0 | db-client | Connection pooling for external clients |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
