---
service: "merchant-service"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Merchant Data"
platform: "Continuum"
team: "Merchant Data"
status: active
tech_stack:
  language: "Java"
  language_version: "21"
  framework: "Spring MVC"
  framework_version: "6.2.0"
  runtime: "Apache Tomcat"
  runtime_version: "11.0 (JRE 21 Temurin)"
  build_tool: "Maven 3"
  package_manager: "Maven (Artifactory)"
---

# M3 Merchant Service Overview

## Purpose

The M3 Merchant Service (also known as Merchant CRUD or `mcrud`) is the primary system of record for all Groupon merchant data. It provides REST endpoints for creating, reading, and updating merchants, account contacts, features, and configurations. The service also synchronizes merchant and place records with the Universal Merchant API (UMAPI) via the MMUD (Merchant Master Update/Delete) flow, and notifies downstream consumers of merchant state changes through the Voltron message bus.

## Scope

### In scope

- Storing and serving the canonical merchant aggregate record (name, status, locale, Salesforce ID, images, writeups, account contacts)
- CRUD operations for merchant features (boolean flags) and configurations (key/value pairs)
- MMUD-driven merchant and place synchronization with the Universal Merchant API
- Redis-backed read caching for high-throughput GET endpoints
- Publishing merchant create and update notifications to the Voltron message bus
- Serving account contact data linked to merchants

### Out of scope

- Consumer-facing merchant display and discovery (handled by downstream services)
- Deal or order processing (handled by Continuum commerce services)
- Identity and access management (authentication delegated to `client_id` allowlist)
- Place data ownership (places owned by `continuumM3PlacesService`)
- Merchant financial or payment data (handled by separate financial services)

## Domain Context

- **Business domain**: Merchant Data
- **Platform**: Continuum
- **Upstream consumers**: Universal Merchant API (`continuumUniversalMerchantApi`), internal tools, merchant-facing portals (via MMUD), and any service requiring merchant aggregates by M3 merchant identifier
- **Downstream dependencies**: `continuumMerchantServiceMySql` (primary data store), `continuumMerchantServiceRedis` (read cache), `continuumUniversalMerchantApi` (MMUD sync target), `continuumM3PlacesService` (place fetch/create during MMUD), Voltron message bus (notifications), `metricsStack`, `loggingStack`

## Stakeholders

| Role | Description |
|------|-------------|
| Team | Merchant Data team (merchantdata@groupon.com) — owns and operates the service |
| Owner | mamsingh (team lead) |
| Consumers | Internal platform services that need merchant aggregates |
| SRE / On-Call | merchant-data-alerts@groupon.pagerduty.com |
| Mailing list | merchant-data-announce@groupon.com |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 21 | `pom.xml` — `maven-compiler-plugin` release=21 |
| Framework | Spring MVC | 6.2.0 | `pom.xml` — `org.springframework.version` |
| Runtime | Apache Tomcat | 11.0 (JRE 21 Temurin) | `docker/Dockerfile` — base image `tomcat:11.0-jre21-temurin` |
| Build tool | Maven | 3 | `pom.xml` |
| Package manager | Maven (Artifactory) | | `pom.xml` — `https://artifactory.groupondev.com/artifactory/public` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| spring-webmvc | 6.2.0 | http-framework | REST controller layer, request dispatch |
| hibernate-core-jakarta | 5.6.15.Final | orm | Object-relational mapping for merchant domain entities |
| flyway-core | 11.1.0 | db-client | Database schema migrations |
| mysql-connector-j | 8.4.0 | db-client | MySQL JDBC driver for primary data store |
| c3p0 | 0.10.1 | db-client | JDBC connection pooling |
| lettuce-core | 6.5.1.RELEASE | db-client | Redis client for read-through cache |
| jackson-databind | 2.18.2 | serialization | JSON serialization/deserialization for REST payloads |
| voltron/mbus-producer | 2.26 | message-client | Voltron MessageBusNotifier for merchant create/update events |
| kryo | 5.6.2 | serialization | Binary serialization for cache payloads |
| merchantdata-config | 3.1.5 | configuration | Groupon merchant config provider |
| metrics-sma-influxdb | 5.14.1 | metrics | SMA metrics emission to InfluxDB/Wavefront |
| logback-steno | 2.1.2 | logging | Structured JSON logging |
| lombok | 1.18.36 | serialization | Boilerplate reduction (builders, getters) |
| commons-validator | 1.9.0 | validation | Input validation utilities |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
