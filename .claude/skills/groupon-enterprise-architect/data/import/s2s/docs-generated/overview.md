---
service: "s2s"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Display Advertising"
platform: "Continuum"
team: "SEM/Display Engineering"
status: active
tech_stack:
  language: "Java"
  language_version: "17"
  framework: "Dropwizard / JTier"
  framework_version: "5.14.1"
  runtime: "JVM"
  runtime_version: "17"
  build_tool: "Maven"
  package_manager: "Maven"
---

# S2S Overview

## Purpose

S2S (Server-to-Server) is Groupon's display advertising event forwarding service. It consumes raw Janus Tier2/Tier3 purchase and engagement events from Kafka, applies customer consent filtering, enriches payloads with customer PII (hashed), order data, and IV/GP values, then dispatches conversion events to ad partners including Facebook CAPI, Google Ads, TikTok Ads, and Reddit Ads. It also manages booster campaign lifecycle via DataBreaker integration and MBus deal update ingestion.

## Scope

### In scope

- Consuming Janus Tier2/Tier3 Kafka events and filtering based on customer consent
- Enriching events with hashed customer PII (email, phone), order data, and incremental value (IV/GP)
- Forwarding conversion events to Facebook CAPI, Google Ads/Enhanced Conversions, TikTok Ads, and Reddit Ads
- Managing partner click ID attribution cache (Postgres-backed)
- Processing MBus booster deal update topics for DataBreaker ingestion
- Running scheduled Quartz jobs for Teradata EDW customer info backfill, AES retry processing, and financial data pipelines
- Generating Google Ads automation proposals and ROI reports via BigQuery and Google Sheets
- Sending SMTP notifications for booster and automation workflows
- Publishing consent-filtered events to outbound Kafka topics (`da_s2s_events` and partner-specific topics)

### Out of scope

- Generating or originating Janus events (owned by Janus/tracking infrastructure)
- Managing customer consent decisions (owned by Consent Service)
- Deal pricing and catalog management (owned by Pricing API, MDS, Deal Catalog)
- Order creation and fulfillment (owned by Orders Service)
- End-to-end booster campaign configuration (owned by DataBreaker and Trask)

## Domain Context

- **Business domain**: Display Advertising — partner conversion tracking and booster campaign management
- **Platform**: Continuum
- **Upstream consumers**: Janus Kafka (Tier2/Tier3 topics), MBus booster deal topics, HTTP callers invoking manual update endpoints
- **Downstream dependencies**: Facebook CAPI, Google Ads API, TikTok Ads API, Reddit Ads API, DataBreaker, Consent Service, Orders Service, MDS, Pricing API, Deal Catalog, User Service, Trask Service, Teradata EDW, PostgreSQL, Cerebro DB, BigQuery

## Stakeholders

| Role | Description |
|------|-------------|
| SEM/Display Engineering | Owns and operates the S2S service |
| Display Advertising team | Business owner of partner event forwarding and booster campaigns |
| Ad Partners (Facebook, Google, TikTok, Reddit) | Consumers of forwarded conversion event data |
| Data/Analytics | Consumers of BigQuery financial tables written by S2S jobs |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 17 | Summary |
| Framework | Dropwizard / JTier | 5.14.1 | Summary |
| Runtime | JVM | 17 | Summary |
| Build tool | Maven | — | Summary |
| Package manager | Maven | — | — |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Kafka Client | 2.8.1 | message-client | Consuming Janus Tier events and publishing consent-filtered topics |
| Retrofit | — | http-framework | HTTP clients for Consent Service, MDS, Orders, Pricing, DataBreaker, and partner APIs |
| PostgreSQL JDBC | — | db-client | Operational data: consent cache, click IDs, debug events, retries |
| Quartz | — | scheduling | Scheduled jobs for EDW sync, AES retry, and financial data pipelines |
| Teradata JDBC | 17.20 | db-client | Querying customer info and AES retry data from EDW |
| BigQuery | 26.58.0 | db-client | Reading financial tables for ROI metrics and booster enrichment |
| Facebook Java SDK | 23.0.0 | http-framework | Facebook CAPI event submission |
| Google Ads API | 38.0.0 | http-framework | Google Ads / Enhanced Conversions event submission |
| Google Sheets API | — | http-framework | ROI report export to Google Sheets |
| Cache2k | 2.1.1 | db-client | In-memory caching of consent decisions and partner click IDs |
| Failsafe | 3.3.2 | http-framework | Retry and circuit breaker policies for partner API calls |
| Vavr | 0.10.4 | validation | Functional data structures and validation pipelines |
| MBus Client | — | message-client | Consuming regional booster deal update topics |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
