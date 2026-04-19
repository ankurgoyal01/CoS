---
service: "optimus-prime-api"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Data Integration and ETL (DnD Tools)"
platform: "continuum"
team: "DnD Tools"
status: active
tech_stack:
  language: "Java"
  language_version: "17"
  framework: "Dropwizard"
  framework_version: "JTier v5.14.0"
  runtime: "Java 17 / JTier"
  runtime_version: "17"
  build_tool: "Maven"
  package_manager: "Maven 3.x"
---

# Optimus Prime API Overview

## Purpose

Optimus Prime API is the central control plane for Groupon's internal ETL pipeline platform. It enables data engineers and analysts to define ETL job configurations, schedule and trigger runs, monitor execution status, and manage connections to external data sources. The service orchestrates job execution via Apache NiFi and maintains the full lifecycle of job definitions, run history, and user/group access control in PostgreSQL.

## Scope

### In scope

- CRUD management of ETL job definitions (via `/v2/users/{username}/jobs` endpoints)
- Scheduling job runs using Quartz Scheduler triggers
- Orchestrating NiFi process group lifecycle for job execution
- Tracking job run status and persisting run history to PostgreSQL
- Archiving old run records via scheduled Quartz jobs
- User and group management with LDAP/Active Directory authentication
- Connection management for external data sources (encrypted credentials stored in PostgreSQL)
- File transfer integrations (GCS bucket ingress/egress, S3, SFTP)
- Analytics metadata retrieval via Google Sheets API
- Email notifications and alerts via SMTP relay
- Automated cleanup of jobs owned by disabled LDAP users

### Out of scope

- NiFi process group design and template authoring (managed by NiFi / data engineering teams)
- Direct data transformation logic (executed inside NiFi flows, not in this service)
- Hive and BigQuery schema management (owned by data warehouse teams)
- End-user data exploration or BI tooling

## Domain Context

- **Business domain**: Data Integration and ETL (DnD Tools)
- **Platform**: continuum
- **Upstream consumers**: Data engineers and analysts using the Optimus Prime UI or direct API clients; internal tools calling job management endpoints
- **Downstream dependencies**: NiFi (`continuumOptimusPrimeNifi`), Active Directory / LDAP, SMTP Relay, Google Sheets API, GCS (`continuumOptimusPrimeGcsBucket`), S3 (`continuumOptimusPrimeS3Storage`), SFTP (`cloudPlatform`), Hive Warehouse, BigQuery Warehouse, PostgreSQL (`continuumOptimusPrimeApiDb`)

## Stakeholders

| Role | Description |
|------|-------------|
| DnD Tools Team | Service owners responsible for development and operations |
| Data Engineers / Analysts | Primary API consumers who create, schedule, and monitor ETL jobs |
| Platform / Infra Team | Manages NiFi clusters and underlying compute resources |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 17 | `architecture/models/components/continuumOptimusPrimeApi.dsl` |
| Framework | Dropwizard (JTier) | 5.14.0 | Inventory — framework |
| Runtime | Java 17 / JTier | 17 | Inventory — runtime |
| Build tool | Maven | 3.x | Inventory — build_tool |
| Package manager | Maven | 3.x | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| JTier | 5.14.0 | http-framework | Groupon's internal Dropwizard platform wrapper |
| PostgreSQL JDBC (jtier-daas-postgres) | — | db-client | PostgreSQL connectivity |
| JDBI 3 | — | orm | SQL object mapping and DAO layer |
| Flyway (jtier-migrations) | — | db-client | Database schema migrations |
| NiFi Client | 1.16.3 | http-client | REST client for NiFi process group management |
| Quartz Scheduler | — | scheduling | Cron-based job triggering and scheduled background tasks |
| AWS SDK | 2.17.174 | storage | S3 bucket file operations |
| Google Cloud Storage | 2.26.1 | storage | GCS bucket file operations |
| Simple Java Mail | 6.0.5 | notification | SMTP email delivery |
| SSHJ | 0.31.0 | storage | SFTP file transfer |
| Resilience4j | 1.7.1 | http-framework | Circuit breaker and retry for outbound calls |
| Cron-Utils | 9.1.6 | scheduling | Cron expression parsing and validation |
| FreeMarker | 2.3.30 | serialization | Email and notification template rendering |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
