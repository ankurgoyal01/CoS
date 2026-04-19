---
service: "client-id"
title: Overview
generated: "2026-03-03"
type: overview
domain: "API Identity & Access"
platform: "Continuum"
team: "groupon-api"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard"
  framework_version: "1.3.29"
  runtime: "JVM"
  runtime_version: "Eclipse Temurin prod-java11-jtier:3"
  build_tool: "Maven"
  package_manager: "Maven (Nexus)"
---

# Client ID Service Overview

## Purpose

Client ID Service is an internal API service that manages the full lifecycle of API client identities at Groupon. A client ID identifies an API consumer — it defines that consumer's access rights, rate limits, ownership, and app-version metadata. The service is the authoritative source of client and token data consumed by API Proxy (for request authentication and rate enforcement) and API Lazlo (for client lookup).

## Scope

### In scope

- Creating, reading, updating, and suspending API client records and their associated access tokens
- Managing service-to-token mappings that define which services a token can call and at what rate limits
- Managing mobile client records (platform, version thresholds, download URLs)
- Scheduling temporary rate-limit changes (bumps) with automatic start and revert
- Storing and serving reCAPTCHA configuration and threshold data per client and region
- Providing an internal HTML management UI as well as a machine-readable JSON API
- Self-service token creation flow with Jira ticket creation for support tracking

### Out of scope

- Runtime request authentication and enforcement (handled by API Proxy)
- Client usage metrics and analytics (handled downstream)
- OAuth flow / token issuance (client-id manages identities, not OAuth grants)
- User identity management beyond the internal admin user concept

## Domain Context

- **Business domain**: API Identity & Access
- **Platform**: Continuum
- **Upstream consumers**: API Proxy (periodic sync via `/v3/services/{serviceName}`), API Lazlo (client lookup)
- **Downstream dependencies**: MySQL primary database (writes), MySQL read replica (reads), Jira REST API (self-service ticket creation)

## Stakeholders

| Role | Description |
|------|-------------|
| API Platform team (groupon-api) | Service owners; manage deployments and schema |
| API Proxy operators | Primary consumers of token sync endpoints |
| API Lazlo operators | Consumers of client search endpoints |
| Internal developers | Use self-service flow to register new API clients |
| GDS (Database Services) | Manage MySQL provisioning and cross-env replication |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `.java-version`, `Dockerfile FROM prod-java11-jtier:3` |
| Framework | Dropwizard | 1.3.29 | `pom.xml` `io.dropwizard.version` property |
| Runtime | JVM (Eclipse Temurin) | prod-java11-jtier:3 | `src/main/docker/Dockerfile` |
| Build tool | Maven | jtier-service-pom 5.14.0 | `pom.xml` parent |
| Package manager | Maven / Nexus | — | `pom.xml`, `README.md` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `dropwizard-jdbi` | 1.3.29 | orm / db-client | JDBI SQL object layer for MySQL DAOs |
| `jtier-daas-mysql` | (jtier BOM) | db-client | Groupon internal MySQL connection pool wrapper |
| `jtier-retrofit` | (jtier BOM) | http-framework | HTTP client base for outbound calls |
| `okhttp3` (via `jtier-retrofit`) | (jtier BOM) | http-framework | HTTP client for Jira REST integration |
| `dropwizard-views-freemarker` | 1.3.29 | ui-framework | Server-side FreeMarker HTML templating for management UI |
| `joda-time` | 2.12.0 | scheduling | Date/time handling for schedule start/end window evaluation |
| `gson` | (jtier BOM) | serialization | JSON serialization support |
| `javax.json-api` + glassfish impl | 1.1.4 | serialization | JSON object construction for Jira payloads |
| `metrics-sma` + `metrics-sma-influxdb` | (jtier BOM) | metrics | Telegraf/InfluxDB metrics emission |
| `jtier-immutables-style` | (jtier BOM) | validation | Immutable value object generation |
| `wiremock` | 2.27.2 | testing | HTTP stub server for integration tests |
| `mockito-core` | (jtier BOM) | testing | Unit test mocking |
| `jaxb-api` | 2.3.1 | serialization | JAXB compatibility for Java 11 |
