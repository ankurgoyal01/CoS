---
service: "salesforce-cache"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Salesforce Integration"
platform: "Continuum"
team: "Salesforce Integration"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard"
  framework_version: "JTier 5.14.0"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Salesforce Cache Overview

## Purpose

Salesforce Cache is the replacement for the legacy Reading Rainbow service. It is a read-only cache of select Salesforce CRM objects (such as Account, Opportunity, Task, and RecordType), periodically replicated from Salesforce into a PostgreSQL database and served to internal consumers via a REST API. The service decouples Groupon internal systems from direct Salesforce API calls, reducing latency and Salesforce API quota consumption.

## Scope

### In scope

- Serving read-only cached Salesforce object records via a versioned REST API (`/v0/...`)
- Periodically replicating Salesforce data into the internal PostgreSQL cache using Quartz-scheduled jobs
- Authenticating API clients via Basic Auth with per-client field-level access control
- Filtering, paginating, and field-projecting Salesforce records in API responses
- Managing cache schema changes (adding/removing objects and fields via CLI migration tooling)
- Removing stale cached records via an unstaler job
- Notifying downstream systems (Quantum Lead) of lead-related Salesforce updates

### Out of scope

- Writing data back to Salesforce (the service is read-only with respect to Salesforce)
- Real-time or webhook-based Salesforce data synchronization (replication is poll-based)
- Salesforce authentication and session management for external clients (clients use the cache's own Basic Auth)
- Full Salesforce object coverage (only configured objects are cached)

## Domain Context

- **Business domain**: Salesforce Integration
- **Platform**: Continuum
- **Upstream consumers**: Internal Groupon services that need Salesforce CRM data (e.g., services querying Account, Opportunity, Task, RecordType records)
- **Downstream dependencies**: Salesforce CRM API (via SalesforceHttpClient), PostgreSQL (reading-rainbow database), Redis, Quantum Lead system

## Stakeholders

| Role | Description |
|------|-------------|
| Salesforce Integration Team | Service owner and on-call team (sfint-dev@groupon.com) |
| Internal API Clients | Groupon internal services that consume Salesforce data via the cache API (must be provisioned with a client ID) |
| Salesforce Integration On Call | PagerDuty escalation target for production alerts (salesforce-cache-alerts@groupon.pagerduty.com) |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `.java-version`, `pom.xml` compiler source/target |
| Framework | Dropwizard (JTier) | jtier-service-pom 5.14.0 | `pom.xml` parent |
| Runtime | JVM | 11 | `.ci/Dockerfile` (`dev-java11-maven`) |
| Build tool | Maven | 3.x | `pom.xml`, `.mvn/maven.config` |
| Package manager | Maven | | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `spring-boot-starter-web` | 2.3.2.RELEASE | http-framework | Embedded HTTP server support |
| `jtier-jdbi3` | (managed) | orm | JDBI3-based database access layer |
| `jtier-daas-postgres` | (managed) | db-client | Groupon managed PostgreSQL client |
| `flyway-core` | 4.2.0 | db-client | Database schema migrations |
| `dropwizard-redis` | (managed) | db-client | Redis client integration for Dropwizard |
| `jtier-quartz-bundle` | (managed) | scheduling | Quartz scheduler for replication jobs |
| `SalesforceHttpClient` | 1.13 | http-framework | Groupon internal Salesforce API HTTP client |
| `mbus-client` | 1.4.0 | message-client | Groupon Messagebus event publishing |
| `jtier-auth-bundle` | 0.2.2 | auth | Basic Auth authentication and authorization |
| `antlr4-runtime` | 4.7.2 | validation | ANTLR grammar-based filter expression parser |
| `jackson-databind` | (managed) | serialization | JSON serialization/deserialization |
| `jtier-retrofit` | (managed) | http-framework | Retrofit-based HTTP client for outbound calls |
| `bcrypt` | 0.9.0 | auth | Password hashing for client credentials |
| `caffeine` | 3.0.3 | state-management | In-process caching (dependency management) |
