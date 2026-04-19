---
service: "deletion_service"
title: Overview
generated: "2026-03-03"
type: overview
domain: "GDPR / Privacy / Data Compliance"
platform: "Continuum"
team: "Display Advertising"
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

# Deletion Service Overview

## Purpose

The Deletion Service implements the GDPR "Right to Be Forgotten" for Groupon's Goods and Display platforms. When a user requests to be forgotten, the service receives an erasure event from the message bus, records pending erasure tasks for each relevant downstream service, and then executes those tasks — replacing personal data (email, name, phone, address) with the anonymisation string "bast". A confirmation event is published to the message bus when erasure is complete.

## Scope

### In scope

- Consuming GDPR erase events from the `jms.topic.gdpr.account.v1.erased` message bus topic
- Persisting per-service erasure requests and their status in the Deletion Service PostgreSQL database
- Executing erasure against the Orders MySQL database (anonymising fulfillment line items)
- Triggering SMS consent deletion via the Rocketman transactional email API (Attentive integration)
- Publishing per-service and per-request completion events to the `jms.queue.gdpr.account.v1.erased.complete` queue
- Providing an admin-only REST API to query erasure status and manually submit erasure requests
- Scheduled retry of failed or pending erasure requests every 30 minutes via Quartz

### Out of scope

- User account deletion or deactivation (handled upstream by account management)
- Commerce Interface, Goods Inventory Service, and Smart Routing erasure (integrations present but currently disabled)
- DCOR, Online Return Centre, and Goods Label API erasure (decommissioned services)
- Non-Goods platforms (e.g. Encore, MBNXT)

## Domain Context

- **Business domain**: GDPR / Privacy / Data Compliance
- **Platform**: Continuum (Goods & Display)
- **Upstream consumers**: MBUS GDPR account erase topic producers (account management pipeline); admin operators via REST API
- **Downstream dependencies**: Orders MySQL DB, Rocketman transactional email API, Deletion Service PostgreSQL DB, MBUS erase-complete queue

## Stakeholders

| Role | Description |
|------|-------------|
| Display Advertising Engineering | Service owner; responsible for development and operations |
| GDPR / Legal | Business sponsor; defines right-to-be-forgotten requirements |
| Service Reliability | On-call response via Wavefront alerts |
| Admin Operators | Use the REST API to query status or manually trigger erasures |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `pom.xml` maven-compiler-plugin `<source>11</source>` |
| Framework | Dropwizard (JTier) | jtier-service-pom 5.14.0 | `pom.xml` parent |
| Runtime | JVM | 11 | `.java-version`, `src/main/docker/Dockerfile` base image `prod-java11-jtier:3` |
| Build tool | Maven | (project-managed) | `pom.xml`, `.mvn/maven.config` |
| Package manager | Maven | (project-managed) | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-messagebus-client` | (JTier-managed) | message-client | Consumes GDPR erase events and publishes completion events via MBUS |
| `jtier-daas-postgres` | (JTier-managed) | db-client | Manages connections to the Deletion Service PostgreSQL database |
| `jtier-daas-mysql` | (JTier-managed) | db-client | Manages connections to the Orders MySQL database |
| `jtier-jdbi` | (JTier-managed) | orm | JDBI-based SQL query layer over PostgreSQL and MySQL |
| `jtier-quartz-bundle` | (JTier-managed) | scheduling | Quartz scheduler integration for the 30-minute erase retry job |
| `jtier-auth-bundle` | (JTier-managed) | auth | Client-ID-based authentication for the admin REST API |
| `jtier-retrofit` | (JTier-managed) | http-framework | Retrofit HTTP client for outbound calls to Rocketman |
| `cassandra-driver-core` | 2.0.12.3 | db-client | Cassandra driver (present as dependency; no active integration evidenced) |
| `aws-java-sdk-s3` | 1.12.255 | db-client | AWS S3 SDK (configuration class present; not used in active integrations) |
| `lombok` | 1.18.24 | validation | Reduces boilerplate via `@Data`, `@Builder`, `@CustomLog` annotations |
| `jackson-databind` | 2.12.6.1 | serialization | JSON serialization/deserialization for message payloads and REST contracts |
| `commons-io` | 2.8.0 | validation | I/O utility library |
| `testcontainers` | (JTier-managed) | testing | Containerized database integration testing |
| `mockito-inline` | 3.7.7 | testing | Mocking framework for unit tests |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
