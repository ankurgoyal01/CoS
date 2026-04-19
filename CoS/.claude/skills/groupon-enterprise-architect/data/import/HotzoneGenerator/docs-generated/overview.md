---
service: "HotzoneGenerator"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Proximity / Emerging Channels"
platform: "Continuum"
team: "Emerging Channels"
status: active
tech_stack:
  language: "Java"
  language_version: "1.8"
  framework: "None (standalone batch jar)"
  framework_version: ""
  runtime: "JVM"
  runtime_version: "1.8"
  build_tool: "Maven 3.x"
  package_manager: "Maven"
---

# HotzoneGenerator Overview

## Purpose

HotzoneGenerator is a scheduled Java batch job that produces geo-targeted "hotzone" deal records for Groupon's proximity notification system. It queries the Marketing Deal Service (MDS) for qualifying deals based on per-category configurations, enriches them with taxonomy metadata, open-hours data, and deal-catalog inventory product IDs, then submits the resulting hotzone set to the Proximity Notifications API. On Tuesdays it also auto-generates hotzone campaign configurations from trending deal-cluster categories.

## Scope

### In scope
- Fetching active hotzone campaign configurations from the Proximity Notifications API (`hotzone/campaign` endpoint).
- Querying MDS for deals matching each campaign's category, price threshold, conversion rate, and purchase count filters.
- Enriching deals with open-hours data from the internal API proxy (GAPI) and inventory product IDs from Deal Catalog.
- Generating per-redemption-location HotZone records with geo-coordinates, time windows, and radius values adjusted by population-density coefficients.
- Inserting generated hotzones via the Proximity Notifications API (`POST hotzone`).
- Auto-generating campaign configurations from trending deal-cluster categories (weekly, Tuesdays).
- Deleting expired hotzones and auto-generated campaigns, and purging old send logs before each run.
- Sending weekly proximity emails for active consumers (`weekly_email` run mode).
- Operating across NA (US, CA) and EMEA (GB, FR, DE, IT, ES, AU, IE, BE, NL, PL) regions.

### Out of scope
- Serving consumer-facing proximity queries (handled by Proximity Notifications service).
- Managing push notification delivery (handled downstream by Proximity Notifications service).
- Deal creation, editing, or lifecycle management (handled by deal creation services).
- Taxonomy hierarchy management (read-only consumer of `continuumTaxonomyService`).

## Domain Context

- **Business domain**: Proximity / Emerging Channels
- **Platform**: Continuum
- **Upstream consumers**: None — this is a batch initiator, not a serving endpoint.
- **Downstream dependencies**: Marketing Deal Service (MDS), Taxonomy Service v2, Deal Catalog Service, Internal API Proxy (GAPI / deal-clusters), Proximity Notifications API, Proximity PostgreSQL database (weekly email mode).

## Stakeholders

| Role | Description |
|------|-------------|
| Emerging Channels team | Service owner; runs as headless user `svc_emerging_channel` |
| Proximity / Notifications team | Consumer of generated hotzones via Proximity Notifications API |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 1.8 | `pom.xml` `project.build.targetJdk=1.8`, `.java-version` |
| Build tool | Maven | 3.x | `pom.xml` `modelVersion 4.0.0` |
| Packaging | maven-assembly-plugin (jar-with-dependencies) | 2.x | `pom.xml` |
| Runtime | JVM | 1.8 | `pom.xml` `maven.compiler.source=1.8` |
| CI | Jenkins | — | `Jenkinsfile` using `java-pipeline-dsl@latest-2` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `com.google.code.gson:gson` | 2.6.2 | serialization | JSON serialization and deserialization of all API payloads |
| `com.google.guava:guava` | 19.0 | utility | `Optional`, `ImmutableList`, `ImmutableMap` used throughout the pipeline |
| `org.apache.commons:commons-lang3` | 3.4 | utility | String utilities (`StringUtils`) in deal enrichment |
| `org.apache.logging.log4j:log4j-api` | 2.17.0 | logging | Log4j2 API for structured event logging |
| `org.apache.logging.log4j:log4j-core` | 2.17.0 | logging | Log4j2 implementation |
| `org.apache.logging.log4j:log4j-slf4j-impl` | 2.17.0 | logging | SLF4J bridge for Steno logger |
| `com.groupon.prodtools:steno` | 0.2.0 | logging | Groupon structured logger (`StenoLogger`) for machine-readable log events |
| `com.groupon.common:app-config` | 1.8.0 | config | Environment-aware properties loader (`AppConfig`); reads `/props/project.<env>.properties` |
| `org.postgresql:postgresql` | 42.0.0 | db-client | JDBC driver for reading weekly consumer IDs from Proximity PostgreSQL |
| `org.projectlombok:lombok` | 1.18.12 | utility | Compile-time boilerplate reduction (provided scope) |
| `junit:junit` | 4.11 | testing | Unit test framework |
