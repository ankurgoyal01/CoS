---
service: "alligator"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Relevance / Card Aggregation"
platform: "Continuum"
team: "Relevance"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Spring Boot"
  framework_version: "2.5.14"
  runtime: "JVM"
  runtime_version: "JTier prod-java11-jtier:2023-12-19"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Alligator Overview

## Purpose

Alligator is a Spring Boot card aggregation service that assembles and decorates card payloads for clients of the Continuum platform. It acts as a fan-out orchestrator: given a deck UUID or card permalink, it fetches card definitions, template configurations, deal data, geo constraints, user attributes, and experiment assignments from multiple upstream services, then merges and decorates them into a unified response. The service is designed to run only in realtime staging and production environments in direct support of the RAPI (Relevance API) real-time service.

## Scope

### In scope

- Serving assembled card sets for a given deck UUID or card permalink (`GET /cardatron/cards`, `GET /v5/cardatron/cards/deckconfig`)
- Real-time decoration of a single card against its template (`GET /v2/cardatron/cards/decorate`, `GET /v5/cardatron/cards/decorate`)
- Resolving deck client identifiers from platform names using cached client data
- Geo polygon lookup and division resolution from latitude/longitude coordinates
- Eligibility filtering using audience attributes from the Audience Management Service
- Weather-aware card selection via the OpenWeather integration
- Caching of deck, card, template, client, geo polygon, and permalink data in Redis (`continuumAlligatorRedis`)
- Scheduled cache refresh via the `cacheReloadWorker` background worker
- Debug endpoints for inspecting card and cache state (`/debug/card/{uuid}`, `/cache/cachevalues`)

### Out of scope

- Authoring or storing card, deck, and template definitions (owned by the Cardatron Campaign Service)
- Deal search indexing (owned by GAPI / Relevance API)
- User authentication and session management (handled upstream by calling clients)
- Recommendation model training (handled by the Deal Recommendation Service)
- Taxonomy management (owned by the Taxonomy Service)

## Domain Context

- **Business domain**: Relevance / Card Aggregation
- **Platform**: Continuum
- **Upstream consumers**: RAPI (Relevance API) and other Continuum platform clients that need assembled card payloads
- **Downstream dependencies**: Cardatron Campaign Service, GAPI (API Proxy), Relevance API, Janus (personalized recently-viewed), Deal Decoration Service, Deal Recommendation Service, Finch (experiment/config), Taxonomy Service, Users Service, Audience Management Service, OpenWeather

## Stakeholders

| Role | Description |
|------|-------------|
| Relevance Team | Service owner; primary contact: relevance-infra@groupon.com |
| PagerDuty On-Call | Incident escalation: darwin-alerts@groupon.pagerduty.com / https://groupon.pagerduty.com/services/PIHP2Y2 |
| Tronicon / Cardatron Team | Card data schema and upstream Cardatron Campaign Service (tronicon-dev@groupon.com) |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `pom.xml` `<java.version>11</java.version>` |
| Framework | Spring Boot | 2.5.14 | `pom.xml` `spring-boot-dependencies` |
| Runtime | JTier JVM | prod-java11-jtier:2023-12-19 | `src/main/docker/Dockerfile` |
| Build tool | Maven | 3.5.2+ | `pom.xml` `jtier.maven.version` |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| spring-boot-starter-web | 2.5.14 | http-framework | Spring MVC REST controllers |
| spring-boot-starter-data-redis | 2.5.14 | db-client | Redis cache access via Lettuce/Jedis |
| spring-boot-starter-actuator | 2.5.14 | metrics | Health and metrics endpoints |
| spring-boot-starter-cache | 2.5.14 | db-client | Spring abstraction for cache operations |
| netflix-hystrix-core | 1.5.8 | http-framework | Circuit breaker for all outbound HTTP calls |
| finch | 3.6.1 | scheduling | Groupon experiment/config assignment client |
| micrometer-registry-influx | 2.5.14 | metrics | Metrics export to InfluxDB/Telegraf |
| micrometer-registry-jmx | 2.5.14 | metrics | JMX metrics exposure |
| lettuce-core | 6.1.6.RELEASE | db-client | Async Redis client (Lettuce) |
| jedis | (spring-managed) | db-client | Synchronous Redis client |
| logback-steno | 1.18.3 | logging | Structured JSON logging (steno format) |
| jts-core | 1.14.0 | validation | Geo polygon operations (JTS Topology Suite) |
| springfox-boot-starter | 3.0.0 | serialization | OpenAPI/Swagger documentation generation |
| httpclient | 4.5.2 | http-framework | Apache HTTP client for outbound calls |
| guava | 31.0.1-jre | serialization | Google Guava utilities |
| jackson | (spring-managed) | serialization | JSON serialization/deserialization |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for the full dependency list.
