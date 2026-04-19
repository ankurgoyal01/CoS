---
service: "coupons-revproc"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Coupons / Revenue Processing"
platform: "Continuum"
team: "Coupons"
status: active
tech_stack:
  language: "Java"
  language_version: "21"
  framework: "Dropwizard"
  framework_version: "4.x (via JTier jtier-service-pom 5.15.0)"
  runtime: "JVM"
  runtime_version: "21"
  build_tool: "Maven"
  package_manager: "Maven (mvnvm)"
---

# Coupons Revproc Overview

## Purpose

coupons-revproc (Revenue Processing) is a multi-phase JTier/Dropwizard service that ingests affiliate transaction data from AffJet across multiple countries, validates and enriches each transaction with click and merchant data, then publishes the processed results downstream to the Groupon message bus (Mbus) and Salesforce. The service acts as the central clearing house for coupon-affiliate revenue attribution, ensuring every qualifying redemption produces both a `click` and a `redemption` message that downstream attribution and finance systems can consume.

## Scope

### In scope

- Scheduled and on-demand ingestion of affiliate transactions from AffJet (19 country/network variants: US, GB, AU, DE, ES, FR, IT, NL, PL, IE, VC_GB, VC_AU, VC_BR, VC_DE, VC_FR, VC_IE, VC_NL, WL_GB, WL_IE)
- Validation and deduplication of inbound transactions
- Click enrichment via VoucherCloud API (fetches click, merchant, and offer details)
- Merchant slug standardization and mapping
- Persisting unprocessed and processed transaction state to MySQL
- Publishing click and redemption messages to the Groupon message bus
- Sending bonus payment and reconciliation updates to Salesforce
- Generating coupon feed exports and uploading to Dotidot SFTP
- Sanitizing and prefilling redirect URL caches in Redis
- Exposing internal REST endpoints for manual ingestion triggers and processed transaction queries

### Out of scope

- Coupon creation or redemption validation (handled upstream by coupon inventory services)
- Consumer-facing coupon display or search (handled by MBNXT / frontend)
- Affiliate network management or merchant onboarding
- Direct billing or payment processing (handled by Salesforce downstream)

## Domain Context

- **Business domain**: Coupons / Revenue Processing
- **Platform**: Continuum
- **Upstream consumers**: Internal Groupon services querying processed transactions via `GET /transactions`; Quartz cron scheduler triggering AffJet ingestion jobs
- **Downstream dependencies**: AffJet API (transaction source), VoucherCloud API (click enrichment), Groupon message bus (Mbus, JMS), Salesforce (bonus payments), Dotidot SFTP (feed uploads), MySQL (state), Redis (cache/buffer)

## Stakeholders

| Role | Description |
|------|-------------|
| Service owner | c_marustamyan (Coupons team) |
| Engineering team | Coupons (coupons-eng@groupon.com) |
| Operations / SRE | Notified via OpsGenie service 9a5a27d1-5977-411b-a040-262d2cd46ca4 |
| Downstream consumers | Attribution, finance, and reporting services consuming Mbus click/redemption events |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 21 | `pom.xml` — `project.build.targetJdk` = 21 |
| Framework | Dropwizard (via JTier) | 4.x | `pom.xml` — `jtier-service-pom` 5.15.0; `dropwizard-guicey` 5.7.1 |
| Runtime | JVM | 21 | `.java-version`, `pom.xml` |
| Build tool | Maven | managed via mvnvm | `mvnvm.properties`, `.mvn/maven.config` |
| Package manager | Maven | | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `dropwizard-guicey` | 5.7.1 | http-framework | Guice dependency injection for Dropwizard |
| `jtier-service-pom` | 5.15.0 | http-framework | Groupon JTier base POM — bundles Dropwizard, auth, migrations, Quartz |
| `jtier-messagebus-client` | managed | message-client | Publishes click and redemption messages to Mbus (JMS) |
| `jtier-jedis-bundle` | managed | db-client | Redis access via Jedis for redirect cache and message buffer |
| `jtier-jdbi3` / `jtier-daas-mysql` | managed | orm | JDBI3 DAOs for MySQL persistence of transactions |
| `jtier-quartz-bundle` | managed | scheduling | Quartz cron scheduler for per-country AffJet ingestion jobs |
| `jtier-migrations` | managed | db-client | Flyway database schema migration support |
| `jtier-retrofit` / `jtier-okhttp` | managed | http-framework | Retrofit2 + OkHttp HTTP clients for AffJet and VoucherCloud APIs |
| `SalesforceHttpClient` | 1.16 | http-framework | Groupon internal HTTP client for Salesforce REST API |
| `jsch` | 0.2.17 | http-framework | JSch SFTP client for Dotidot feed uploads |
| `jtier-auth-bundle` / `jtier-auth-mysql-jdbi3` | managed | auth | Client-ID-based authentication for API endpoints |
| `commons-text` | managed | validation | String manipulation utilities |
| `wiremock-standalone` | managed | testing | HTTP mock server for integration tests |
| `mockito-junit-jupiter` | 4.6.1 | testing | Unit test mocking |
