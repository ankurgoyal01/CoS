---
service: "place-service"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Merchant Data / Place"
platform: "Continuum"
team: "Merchant Data"
status: active
tech_stack:
  language: "Java"
  language_version: "1.8"
  framework: "Spring MVC"
  framework_version: "5.2.0.RELEASE"
  runtime: "Tomcat"
  runtime_version: "8.5.78 (JRE 11 Temurin)"
  build_tool: "Maven 3"
  package_manager: "Maven"
---

# M3 Place Service Overview

## Purpose

The M3 Place Service (artifact ID `placereadservice`, service ID `m3_placeread`) is the system of record for all Groupon merchant place data. It provides REST APIs for querying, searching, creating, and updating places that represent physical merchant locations. The service is consumed across deal redemption, merchant onboarding, and consumer-facing experiences spanning both North America and EMEA regions.

## Scope

### In scope

- Authoritative read APIs for place-by-ID, place search, place count, and place autocomplete
- Place write, create, merge, and history APIs for internal mutation flows
- Redis-backed response caching with 15–30 minute TTL
- OpenSearch/Elasticsearch indexed place search and count queries
- Postgres-backed ICF place record persistence
- Google Maps candidate lookup for place enrichment
- Salesforce-to-M3 place synchronization (sf-m3-synchronizer-worker sidecar)
- Reverse negotiator processing (m3-reverser-negotiator-worker sidecar)
- Source metadata management via Source Controller
- Defrank (place data normalization) endpoint

### Out of scope

- Merchant identity and business profile management (handled by `continuumM3MerchantService`)
- Deal creation and deal lifecycle (handled by other Continuum services)
- Consumer-facing deal search and discovery (handled by relevance/search services)
- Voltron workflow orchestration (invoked by this service but owned by Voltron platform)

## Domain Context

- **Business domain**: Merchant Data / Place
- **Platform**: Continuum
- **Upstream consumers**: Internal Groupon services requiring place data (deal services, merchant tools, consumer APIs), identified by `client_id` parameter
- **Downstream dependencies**: Place Postgres (ICF store), Place OpenSearch (search index), Place Redis Cache, M3 Merchant Service, Google Maps Places API

## Stakeholders

| Role | Description |
|------|-------------|
| Service Owner | Merchant Data team (merchantdata@groupon.com) |
| On-call | PagerDuty service PTIR99Q, merchant-data-alerts@groupon.pagerduty.com |
| Consumers | Internal Groupon services calling place read/write APIs with a registered `client_id` |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 1.8 | `pom.xml` `<java.version>1.8</java.version>` |
| Framework | Spring MVC | 5.2.0.RELEASE | `pom.xml` `<org.springframework.version>` |
| Runtime | Tomcat | 8.5.78 (JRE 11 Temurin) | `docker/Dockerfile` base image |
| Build tool | Maven | 3 | `pom.xml` |
| Package manager | Maven | | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `spring-webmvc` | 5.2.0.RELEASE | http-framework | HTTP request routing and controller layer |
| `elasticsearch-rest-high-level-client` | 7.17.22 | db-client | Queries and indexes place documents in OpenSearch/Elasticsearch |
| `jedis` | 2.9.0 | db-client | Redis cache access for place response caching |
| `jackson-databind` | 2.10.1 | serialization | JSON serialization/deserialization for API payloads |
| `google-maps-services` | 2.0.0 | http-framework | Google Maps Places API calls for geo-enrichment |
| `mbus-client` | 1.5.2 | message-client | Groupon internal message bus integration |
| `place-transformer` | 3.13 | serialization | ICF-to-M3 place model transformation |
| `place-translator` | 2.0.8 | serialization | M3 place model translation |
| `voltron-tasks` | 7.0.53 | scheduling | Voltron workflow and history task invocation |
| `merchantdata-interchange` | 8.2.6 | serialization | Merchant data interchange model |
| `metrics-sma` | 5.5.0 | metrics | SMA metrics emission (Wavefront/InfluxDB) |
| `logback-steno` | 1.18.3 | logging | Structured JSON logging |
| `orika-core` | 1.5.4 | serialization | Bean mapping between internal and external models |
| `springfox-swagger2` | 2.9.2 | validation | Swagger/OpenAPI documentation generation |
| `spatial4j` + `jts-core` | 0.7 / 1.15.0 | validation | Geospatial shape and coordinate operations |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
