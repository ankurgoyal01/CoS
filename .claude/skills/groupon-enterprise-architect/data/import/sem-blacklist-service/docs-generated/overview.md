---
service: "sem-blacklist-service"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Search Engine Marketing"
platform: "Continuum"
team: "SEM"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard / JTier"
  framework_version: "5.14.1"
  runtime: "JVM"
  runtime_version: "11.0.9"
  build_tool: "Maven"
  package_manager: "Maven"
---

# SEM Blacklist Service Overview

## Purpose

The SEM Blacklist Service (also referred to as the SEM Denylist Service) manages denylist and blacklist entries used by Groupon's Search Engine Marketing programs. It provides a REST API for creating, querying, and deleting denylist entries scoped by client, country, search engine, program, and channel. The service also automates denylist management by polling Asana task boards and synchronizing Google Sheets-based blacklists on scheduled intervals.

## Scope

### In scope

- REST API for CRUD operations on denylist/blacklist entries (`/denylist` and `/blacklist` endpoint families)
- Paginated and batch-country queries of denylist entries filtered by client, country, search engine, program, and channel
- Date-range queries for active denylist entries
- Automated processing of Asana tasks to add or delete denylist terms (scheduled Quartz job and manual API trigger)
- Scheduled Google Sheets synchronization to refresh PLA (Product Listing Ads) blacklists from remote spreadsheets
- Persistence of all denylist entries in a PostgreSQL database managed via DaaS (Database-as-a-Service)

### Out of scope

- Applying or enforcing blacklists in ad serving pipelines (that responsibility lies in SEM bidding and ad-platform services)
- Management of Asana projects or Google Sheets structure (those are configured externally)
- User authentication and authorization beyond the `X-GRPN-Username` header convention
- Reporting or analytics on denylist usage

## Domain Context

- **Business domain**: Search Engine Marketing (SEM) — controls which deal permalinks, keywords, and merchant entities are suppressed from SEM campaigns
- **Platform**: Continuum
- **Upstream consumers**: SEM bidding systems, SEM keyword management tooling, and internal SEM operations tools that read the denylist via the REST API
- **Downstream dependencies**: PostgreSQL (DaaS), Asana REST API (`https://app.asana.com/api/1.0`), Google Sheets API (via `google-api-services-sheets`)

## Stakeholders

| Role | Description |
|------|-------------|
| SEM Team | Owns and operates the service; manages denylist entries via Asana and Google Sheets |
| SEM Operations | Uses the Asana board workflow to request add/delete of denylist terms |
| SRE / On-call | Responds to alerts via OpsGenie (`sem-analytics-service@groupondev.opsgenie.net`) |
| Consuming SEM services | Read denylist data via REST API to filter ad targets |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11.0.9 | `.java-version`, `pom.xml` compiler source/target |
| Framework | Dropwizard / JTier | 5.14.1 (jtier-service-pom) | `pom.xml` parent POM |
| Runtime | JVM | 11 | `src/main/docker/Dockerfile` (prod-java11-jtier base image) |
| Build tool | Maven | (mvnvm.properties) | `.mvn/maven.config`, `mvnvm.properties` |
| Package manager | Maven | | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-daas-postgres` | (managed by parent POM) | db-client | PostgreSQL connection via DaaS |
| `jtier-jdbi` | (managed by parent POM) | orm | JDBI SQL object DAO layer for blacklist persistence |
| `jtier-migrations` | (managed by parent POM) | db-client | Database schema migrations |
| `jtier-quartz-bundle` | (managed by parent POM) | scheduling | Quartz scheduler integration for periodic jobs |
| `jtier-quartz-postgres-migrations` | (managed by parent POM) | scheduling | Quartz job store schema migrations |
| `google-api-services-sheets` | v4-rev502-1.18.0-rc | http-framework | Google Sheets API client for reading blacklist spreadsheets |
| `google-oauth-client-jetty` | 1.18.0-rc | auth | OAuth2 client for Google API authentication |
| `google-http-client-jackson2` | 1.23.0 | serialization | HTTP client with Jackson JSON support for Google APIs |
| `jackson-core` | 2.12.1 | serialization | JSON serialization/deserialization |
| `lombok` | 1.18.24 | validation | Boilerplate reduction (data classes, builders) |
| `commons-lang3` | 3.12.0 | validation | String utilities for validation logic |
| `stringtemplate` | 3.2 | orm | StringTemplate3 SQL statement locator for JDBI |
| `httpclient` | 4.5.13 | http-framework | Apache HTTP client (used transitively) |
| `mockito-core` | 3.11.2 | testing | Unit test mocking framework |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
