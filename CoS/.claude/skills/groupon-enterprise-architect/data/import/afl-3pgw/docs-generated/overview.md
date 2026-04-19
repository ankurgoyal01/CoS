---
service: "afl-3pgw"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Affiliates"
platform: "Continuum"
team: "AFL"
status: active
tech_stack:
  language: "Java"
  language_version: "21"
  framework: "JTier (Dropwizard)"
  framework_version: "5.15.0"
  runtime: "JVM"
  runtime_version: "21"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Affiliates 3rd Party Gateway (afl-3pgw) Overview

## Purpose

AFL-3PGW (Affiliates Third Party Gateway) is a Groupon Continuum platform service that receives real-time order attribution events from the affiliate real-time attribution pipeline and forwards qualifying transactions to external affiliate networks. It also runs scheduled reconciliation jobs that correct missed, cancelled, refunded, or charged-back orders at Commission Junction (CJ) and Awin. The service operates across both NA and EMEA regions.

## Scope

### In scope

- Consuming order attribution events from the MBUS topic `jms.topic.afl_rta.attribution.orders`
- Submitting real-time sale registrations to Commission Junction via S2S HTTP calls
- Submitting real-time transaction events to Awin via REST API
- Running scheduled reconciliation jobs for new sales, corrections (refunds, cancellations, chargebacks)
- Fetching CJ performance reports and commission data via GraphQL/CSV
- Processing Awin transaction approvals and network reports
- Distributing Spotify offer emails via Mailman service
- Persisting submission and audit records in the service-owned MySQL database

### Out of scope

- Attributing orders to affiliate networks (handled by `afl-rta`)
- Managing affiliate partner network contracts or accounts
- End-customer-facing API endpoints
- Groupon coupon or voucher management

## Domain Context

- **Business domain**: Affiliates
- **Platform**: Continuum
- **Upstream consumers**: `messageBus` (MBUS) — `afl-rta` service publishes attributed order events onto `jms.topic.afl_rta.attribution.orders`
- **Downstream dependencies**: Commission Junction (CJ) external API, Awin external API, `continuumOrdersService`, `continuumMarketingDealService`, `continuumIncentiveService`, Mailman service

## Stakeholders

| Role | Description |
|------|-------------|
| Affiliates Team | Service owners; responsible for development and operations (gpn-dev@groupon.com) |
| Affiliates Alerts | On-call rotation for alerts and outages (gpn-alerts@groupon.com, PagerDuty) |
| Commission Junction | External affiliate network receiving order submissions |
| Awin | External affiliate network receiving order submissions |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 21 | `pom.xml` (`maven.compiler.source=21`) |
| Framework | JTier (Dropwizard) | 5.15.0 | `pom.xml` (`jtier-service-pom:5.15.0`) |
| Runtime | JVM | 21 | `.java-version`, `pom.xml` |
| Build tool | Maven | 3.x | `pom.xml`, `.mvn/maven.config` |
| Package manager | Maven | | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| jtier-messagebus-client | (managed by JTier BOM) | message-client | Consumes MBUS JMS topic events |
| jtier-jdbi3 | (managed by JTier BOM) | db-client | JDBI-based MySQL DAO layer |
| jtier-migrations | (managed by JTier BOM) | db-client | Flyway schema migrations |
| jtier-quartz-bundle | (managed by JTier BOM) | scheduling | Quartz job scheduler with MySQL clustering |
| jtier-retrofit | (managed by JTier BOM) | http-framework | Retrofit HTTP clients for all external APIs |
| jtier-daas-mysql | (managed by JTier BOM) | db-client | DaaS MySQL connection management |
| net.jodah:failsafe | (managed by JTier BOM) | http-framework | Retry and circuit-breaker policies |
| jackson-dataformat-csv | (managed by JTier BOM) | serialization | Parsing CJ CSV report downloads |
| lombok | 1.18.38 | validation | Boilerplate reduction for config/DTO classes |
| io.vavr:vavr | 0.10.5 | validation | Functional error handling |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
