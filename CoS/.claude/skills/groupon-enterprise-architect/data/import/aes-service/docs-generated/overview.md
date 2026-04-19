---
service: "aes-service"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Search Engine Marketing / Display Audiences"
platform: "Continuum"
team: "Search Engine Marketing"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard"
  framework_version: "JTier jtier-service-pom 5.14.1"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Audience Export Service Overview

## Purpose

The Audience Export Service (AES) creates and manages user audience segments for third-party ad platforms — Facebook, Google, Microsoft (Bing Ads), and TikTok. It receives audience definitions from CIA (the internal audience management service), materialises the relevant customer data from Cerebro/Hive warehouse tables, computes deltas between audience runs, and uploads the resulting sets of hashed email addresses and device IDs to each configured ad-network partner on a scheduled (typically daily) basis.

## Scope

### In scope
- Creating, updating, pausing, resuming, and deleting scheduled and published audience records.
- Running daily Quartz cron jobs to export audience deltas to Facebook, Google, Microsoft, and TikTok.
- Computing incremental and moving-window audience deltas from source data.
- Mapping Groupon customer IDs to hashed emails and device IDs (IDFA) before export.
- Maintaining a local PostgreSQL store for audience metadata, job status, partner audience registrations, and filtered-user lists.
- Consuming MBus erasure and consent events to enforce GDPR deletion across all partner audiences and local tables.
- Exposing REST endpoints for audience lifecycle management and admin utilities.
- Maintaining an in-memory AMS cache of extended audience info.

### Out of scope
- Audience data creation and segment definition (owned by CIA).
- Raw customer data storage (owned by Cerebro/Hive warehouse).
- Ad-campaign activation and bid management (owned by ad platforms directly).
- Frontend audience management UI (served by Display Wizard, which calls AES APIs).

## Domain Context

- **Business domain**: Search Engine Marketing / Display Audiences
- **Platform**: Continuum
- **Upstream consumers**: Display Wizard UI (via REST); CIA (triggers audience creation); GDPR deletion pipeline (via REST and MBus)
- **Downstream dependencies**: CIA (audience schedules), Cerebro/Hive (source customer data), Facebook Ads API, Google Ads API (gRPC), Microsoft Bing Ads Bulk API, TikTok Ads API, GCP Cloud Storage, AES Postgres (primary), AES Postgres S2S (customer mapping)

## Stakeholders

| Role | Description |
|------|-------------|
| Engineering Owner | Search Engine Marketing team (da-communications@groupon.com) |
| On-call | da-alerts@groupon.com / PagerDuty PW2Z1UF |
| Ad Operations | Marketing team using Display Wizard to manage audience segments |
| Privacy/Legal | Relies on AES GDPR erasure API to remove customers from ad platforms |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `pom.xml` maven-compiler-plugin source/target |
| Framework | Dropwizard (JTier) | jtier-service-pom 5.14.1 | `pom.xml` parent |
| Runtime | JVM | 11 | `.java-version`, `pom.xml` |
| Build tool | Maven | — | `pom.xml`, `.mvn/` |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `google-ads` | 38.0.0 | http-client | Google Ads API gRPC/REST client for audience management |
| `microsoft.bingads` | 13.0.16 | http-client | Microsoft Bing Ads Bulk API SDK for customer list upload |
| `hadoop-client` | 3.3.0 | db-client | HDFS and Hive JDBC connectivity for Cerebro warehouse reads |
| `hive-jdbc` | 2.0.0 | db-client | JDBC driver for querying Hive/Cerebro audience source tables |
| `google-cloud-storage` | 2.52.0 | http-client | GCP Cloud Storage SDK for temporary export file handling |
| `jtier-daas-postgres` | (managed) | db-client | JTier PostgreSQL DaaS integration for primary and S2S datastores |
| `jtier-jdbi` | (managed) | orm | JDBI-based DAO layer for database access |
| `jtier-quartz-bundle` | (managed) | scheduling | Quartz scheduler integration for daily audience export cron jobs |
| `mbus-client` / `jtier-messagebus-client` | (managed) | message-client | Groupon MBus consumer for erasure and consent topics |
| `jtier-okhttp` / `jtier-retrofit` | (managed) | http-client | HTTP client framework for CIA and Facebook REST API calls |
| `lombok` | 1.18.24 | validation | Boilerplate reduction (builders, getters, setters) |
| `jsch` | 0.1.55 | http-client | SSH/SFTP support for legacy file transfer patterns |
| `jackson-core` / `jackson-annotations` | 2.12.x | serialization | JSON serialization for REST API payloads |
