---
service: "ingestion-jtier"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "3PIP Partner Feed Ingestion"
platform: "Continuum"
team: "3PIP Ingestion (3pip-cbe-eng@groupon.com, vaarora)"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard"
  framework_version: "5.15.0"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# ingestion-jtier Overview

## Purpose

ingestion-jtier is the third-party inventory partner (3PIP) feed ingestion service within the Continuum commerce platform. It extracts partner inventory feeds from external providers (Viator, Mindbody, Booker, RewardsNetwork), transforms raw offer data into Groupon deal structures, and drives deal creation and lifecycle management via downstream internal APIs. The service bridges external partner catalogs with Groupon's deal catalog, ensuring offer availability is kept current through both scheduled batch runs and on-demand API triggers.

## Scope

### In scope

- Extracting partner inventory feeds from external providers via REST and SFTP
- Transforming raw partner offer data into Groupon-compatible offer/deal models
- Triggering deal creation and updates through the Deal Management API
- Synchronizing offer availability (start/end times, capacity) for existing deals
- Managing deal state transitions (pause, unpause, deletion)
- Maintaining partner and offer metadata in the ingestion PostgreSQL database
- Caching ingestion state and distributed locks via Redis
- Publishing operational and ingestion lifecycle events to the Message Bus
- Exposing APIs for on-demand ingest triggers and availability queries
- Running scheduled Quartz jobs for periodic feed extraction and availability sync

### Out of scope

- Deal display and rendering (handled by Deal Catalog / MBNXT frontend)
- Consumer-facing checkout and payment flows (handled by Continuum commerce engine)
- Partner onboarding and contract management (handled by Partner Service)
- Taxonomy definition and management (handled by Taxonomy Service)
- Direct consumer traffic — this is a backend ingestion pipeline

## Domain Context

- **Business domain**: 3PIP Partner Feed Ingestion
- **Platform**: Continuum
- **Upstream consumers**: Scheduled triggers (Quartz), on-demand API callers (internal ops tooling, Jenkins pipelines)
- **Downstream dependencies**: Deal Management API, TPIS (Third-Party Inventory Service), Partner Service, Taxonomy Service, Message Bus, external partners (Viator, Mindbody, Booker, RewardsNetwork)

## Stakeholders

| Role | Description |
|------|-------------|
| Team | 3PIP Ingestion engineering team (3pip-cbe-eng@groupon.com) |
| Owner | vaarora |
| Consumers | Internal ops tooling, Jenkins pipelines triggering ingest runs |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | pom.xml (`java.version`) |
| Framework | Dropwizard | 5.15.0 | jtier-service-pom parent POM |
| Runtime | JVM | 11 | pom.xml (`maven.compiler.source/target`) |
| Build tool | Maven | 3.5+ | pom.xml |
| Package manager | Maven | | pom.xml |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| jackson-databind | 2.15.3 | serialization | JSON serialization/deserialization of partner feed payloads |
| httpclient | 4.5.14 | http-framework | HTTP client for external partner REST API calls |
| guice | 5.1.0 | di | Dependency injection wiring |
| jedis | 2.10.2 | db-client | Redis client for caching and distributed locks |
| jtier-quartz-bundle | (jtier-managed) | scheduling | Quartz scheduler integration for periodic ingestion jobs |
| jtier-daas-postgres | (jtier-managed) | db-client | PostgreSQL connection pool and config bundle |
| jtier-jdbi3 | (jtier-managed) | orm | JDBI3 SQL object layer for PostgreSQL access |
| jtier-messagebus-client | (jtier-managed) | message-client | Message Bus publish/consume client |
| jtier-retrofit | (jtier-managed) | http-framework | Retrofit-based HTTP client wrappers for internal services |
| freemarker | 2.3.28 | templating | Template rendering for feed transformation |
| aws-java-sdk-s3 | (aws-managed) | storage | S3 access for feed file storage and retrieval |
| jsurfer-jackson | 1.4.3 | serialization | Streaming JSON path parser for large partner feed files |
| rest-assured | 5.3.2 | testing | Integration/API test assertions |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
