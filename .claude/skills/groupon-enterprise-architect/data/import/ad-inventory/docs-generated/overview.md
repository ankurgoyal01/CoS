---
service: "ad-inventory"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Advertising / Demand-side Ad Management"
platform: "Continuum"
team: "ads-eng@groupon.com"
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

# Ad Inventory Overview

## Purpose

Ad Inventory (also known as Ads on Groupon, Sponsored Listings, Sponsored Ads, or Merchandising Ads) is a Dropwizard/JTier backend service responsible for managing ad audience targeting, serving ad placements to Groupon pages, ingesting sponsored listing click events, and orchestrating multi-source ad performance reporting pipelines. It acts as the central coordination layer between Groupon's ad serving surface and external ad networks (Google Ad Manager / DFP, LiveIntent, Rokt, CitrusAd). The service is classified as Criticality Tier 2 (T2) and is SOX in-scope.

## Scope

### In scope

- Audience lifecycle management: create, fetch, delete audience definitions backed by bloom filters stored in GCS
- Audience eligibility resolution for ad placements using in-memory and Redis caches
- Ad placement serving via the `/ai/api/v1/placement` endpoint with audience, page, platform, and locale targeting
- Sponsored listing click tracking (`/ai/api/v1/slc/{id}`) and forwarding to CitrusAd
- Scheduled and on-demand ad report generation from Google Ad Manager (DFP), LiveIntent, and Rokt
- Report ingestion pipeline: download CSV reports, validate schema, stage to GCS, load into Hive tables
- SMA metrics emission for placement counts and click counts
- Email notification for report lifecycle events
- Admin operations: cache refresh and configuration reset

### Out of scope

- Ad creative management and delivery of ad creative assets (handled upstream by ad networks)
- Audience data collection and segmentation (audiences are defined externally and registered via AMS)
- Billing and invoicing for ad campaigns
- Real-time bidding (RTB) infrastructure

## Domain Context

- **Business domain**: Advertising / Demand-side Ad Management
- **Platform**: Continuum
- **Upstream consumers**: Groupon frontend pages and apps calling `/ai/api/v1/placement` for ad slots; internal reporting consumers querying Hive
- **Downstream dependencies**: Google Ad Manager (DFP), LiveIntent, Rokt (via AWS S3), CitrusAd, Audience Management Service (AMS), MySQL, Redis, GCS, Hive, SMA Metrics, Email (SMTP)

## Stakeholders

| Role | Description |
|------|-------------|
| Engineering Owner | ushankarprasad — primary service owner |
| Team | ads-eng@groupon.com (members: amrsingh, dchauhan, jmanuelm, schatterjee, ssanghvi, ushankarprasad) |
| On-call | ad-inventory@groupon.pagerduty.com; Slack: ai-engineering (#CF8G3HBBP) |
| Reporting Escalation | ai-reporting@groupon.com |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 17 | `pom.xml` — `maven.compiler.source`, `project.build.targetJdk` |
| Framework | Dropwizard / JTier | 5.14.1 (jtier-service-pom parent) | `pom.xml` parent artifact |
| Runtime | JVM | 17 | `.java-version`, `pom.xml` |
| Build tool | Maven | — | `pom.xml`, `mvnvm.properties` |
| Scheduler | Quartz | via jtier-quartz-bundle | `pom.xml`, `AdInventoryConfiguration.java` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| jtier-quartz-bundle | via parent | scheduling | Quartz-based job scheduler integration for report pipeline cron jobs |
| jtier-daas-mysql | via parent | db-client | DaaS-managed MySQL connectivity |
| jtier-jdbi3 | via parent | orm | JDBI3 DAO layer for audience, report, and click persistence |
| jtier-migrations | via parent | db-client | Liquibase-based database schema migrations |
| jtier-okhttp | via parent | http-framework | OkHttp client for outbound HTTP calls (AMS, CitrusAd, LiveIntent) |
| redisson | 3.16.0 | db-client | Redis client (Redisson) for audience and ad content caches |
| google-cloud-storage | 1.25.0 | integration | GCS SDK for bloom filter and report CSV staging |
| aws-java-sdk-s3 | 1.12.255 | integration | AWS S3 client for downloading Rokt report CSVs |
| ads-lib / dfp-axis | 4.19.0 | integration | Google Ad Manager (DFP) API client for report scheduling and download |
| opencsv | 4.6 | serialization | CSV parsing and validation for downloaded ad reports |
| jackson-dataformat-csv | 2.8.8 | serialization | Jackson CSV mapper for report transformations |
| jtier-hive | 1.4.6 | db-client | Hive JDBC integration for loading analytical report tables |
| commons-email / javax.mail | 1.3.1 / 1.6.2 | integration | SMTP email notifications for report lifecycle events |
| apache-velocity | 1.7 | templating | Email template rendering |
