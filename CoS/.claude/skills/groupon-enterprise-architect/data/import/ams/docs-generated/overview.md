---
service: "ams"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Audience Management / CRM"
platform: "Continuum"
team: "Audience Service / CRM"
status: active
tech_stack:
  language: "Java"
  language_version: "17"
  framework: "Dropwizard/JTier"
  framework_version: ""
  runtime: "JVM"
  runtime_version: "17"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Audience Management Service (AMS) Overview

## Purpose

The Audience Management Service (AMS) is the authoritative system for defining, computing, storing, and exporting audience segments within Groupon's Continuum platform. It manages the full lifecycle of audience objects — from criteria definition through Spark-based calculation to multi-store persistence and downstream distribution. AMS serves ads targeting and reporting workloads by providing reliable, scheduled, and on-demand audience data.

## Scope

### In scope

- Audience definition and criteria management (creation, update, resolution)
- Sourced audience calculation via Spark jobs orchestrated through Livy Gateway
- Published audience lifecycle management and Kafka event publishing
- Audience export orchestration to Bigtable, Cassandra, and MySQL
- Execution scheduling and batch queue management for audience compute jobs
- Custom query execution against audience data
- Audit log recording for audience lifecycle events
- Application bootstrap and health monitoring

### Out of scope

- Spark job execution (delegated to Livy Gateway and YARN)
- Raw event ingestion (AMS does not consume Kafka events; it only publishes)
- Downstream ad serving or targeting decisions
- Consumer-facing UI or merchant-facing interfaces
- Reporting query execution (AMS provides data; reporting systems query it)

## Domain Context

- **Business domain**: Audience Management / CRM
- **Platform**: Continuum
- **Upstream consumers**: Ads platforms, reporting workloads, CRM pipelines
- **Downstream dependencies**: Livy Gateway (Spark job submission), YARN (job monitoring), Kafka (event publishing), Bigtable (attribute reads), Cassandra (published audience records), MySQL (audience metadata)

## Stakeholders

| Role | Description |
|------|-------------|
| Audience Service / CRM Team | Owns development and operations |
| Ads Platform Team | Consumes audience segments for targeting |
| Reporting Team | Consumes audience data for analytics and reporting |
| Platform Engineering | Manages Continuum infrastructure dependencies |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 17 | Inventory summary |
| Framework | Dropwizard/JTier | — | Inventory summary |
| Runtime | JVM | 17 | Inventory summary |
| Build tool | Maven | — | Inventory summary |
| Package manager | Maven | — | Inventory summary |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Dropwizard-Hibernate | — | orm | JPA/Hibernate integration with Dropwizard lifecycle |
| JDBI3 | — | db-client | Fluent SQL access for audience and audit queries |
| Flyway | 3.2.1 | db-client | MySQL schema migrations |
| Google Cloud Bigtable | 2.19.2 | db-client | Reads realtime audience attributes from Bigtable |
| Kafka Client | 0.11.0.2 | message-client | Publishes `audience_ams_pa_create` events |
| Cassandra Driver | 3.7.2 | db-client | Reads published audience and metadata records |
| Lettuce | 4.4.4 | db-client | Redis client for caching layer |
| AWS SigV4 | — | auth | AWS request signing for cloud service calls |
| Jackson | — | serialization | JSON serialization/deserialization for REST APIs |
| HttpComponents | — | http-framework | HTTP client for outbound REST calls (e.g., Livy Gateway) |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
