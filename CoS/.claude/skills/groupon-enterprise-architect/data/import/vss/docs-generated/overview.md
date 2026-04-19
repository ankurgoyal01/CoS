---
service: "vss"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Voucher / Merchant Tools"
platform: "Continuum"
team: "geo-team"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard"
  framework_version: "via JTier jtier-service-pom 5.14.0"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Voucher Smart Search (VSS) Overview

## Purpose

VSS (Voucher Smart Search) enables Merchant Centre to search redeemable vouchers by aggregating voucher inventory data and user account data into a unified MySQL store. It is a revamp of the legacy Voucher Redemption Service, purpose-built for new search requirements and GDPR compliance. The service maintains a near-real-time local copy of relevant voucher and user data by consuming message bus events, and exposes a REST search API consumed directly by Merchant Centre.

## Scope

### In scope

- Voucher search by first name, last name, Groupon code, security/redemption code, gifted email, and user email
- Aggregating voucher unit data from VIS (v1) and VIS 2.0 (v2) inventory sources
- Maintaining a local MySQL read/write store of voucher-user associations
- Consuming JMS events for inventory unit updates, user updates, user email changes, and GDPR user erasures
- Scheduled Quartz backfill jobs to re-index voucher units from inventory sources
- API-key-protected user obfuscation endpoint for GDPR compliance (erases/obfuscates PII)
- Admin endpoint to trigger manual backfills by date range or unit UUID list
- Health and status endpoint at `/grpn/status`

### Out of scope

- Voucher creation, issuance, or redemption processing (owned by Voucher Inventory Service)
- User account management (owned by Users Service)
- Merchant authentication and authorization (owned upstream by Merchant Centre)
- Reporting or analytics on voucher data

## Domain Context

- **Business domain**: Voucher / Merchant Tools
- **Platform**: Continuum
- **Upstream consumers**: `merchantCenter` — Merchant Centre calls VSS REST API for voucher search
- **Downstream dependencies**: `continuumUsersService` (user lookup via HTTP), `continuumVoucherInventoryService` / VIS 2.0 (inventory fetch via HTTP), `mbus` (JMS message bus for event consumption), `continuumVssMySql` (owned MySQL data store)

## Stakeholders

| Role | Description |
|------|-------------|
| Service Owner | khsingh (team: geo-team) |
| Team | geo-team — cdbangalore@groupon.com, geo-team@groupon.com |
| Primary Consumer | Merchant Centre (voucher search UI) |
| On-call / PagerDuty | vss@groupon.pagerduty.com — https://groupon.pagerduty.com/services/PK3CGBU |
| Slack | #geo-services (CF9BSHL1M) |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `pom.xml` — `project.build.targetJdk=11`; Dockerfile `prod-java11-jtier:3` |
| Framework | Dropwizard (JTier) | jtier-service-pom 5.14.0 | `pom.xml` parent |
| Runtime | JVM | 11 | `src/main/docker/Dockerfile` |
| Build tool | Maven | mvnvm-managed | `mvnvm.properties`, `.mvn/maven.config` |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-service-pom` | 5.14.0 | http-framework | JTier parent POM — Dropwizard service scaffold |
| `jtier-jdbi` | managed | orm | JDBI-based SQL access layer |
| `jtier-daas-mysql` | managed | db-client | DaaS MySQL connection pooling and configuration |
| `jtier-migrations` | managed | db-client | MySQL schema migration runner |
| `jtier-messagebus-client` | managed | message-client | JMS message bus consumer/producer integration |
| `jtier-quartz-bundle` | managed | scheduling | Dropwizard-integrated Quartz scheduler |
| `quartz` | managed | scheduling | Quartz job scheduler for backfill tasks |
| `jtier-quartz-mysql-migrations` | managed | scheduling | MySQL-backed Quartz job store migrations |
| `jtier-retrofit` | managed | http-framework | Retrofit2 HTTP client for outbound calls |
| `lombok` | 1.18.0 | validation | Boilerplate reduction (builders, getters) |
| `jackson-datatype-guava` | managed | serialization | Jackson serialization for Guava types |
| `steno` / `steno-bundle` | managed | logging | Structured JSON logging (Steno format) |
| `dropwizard-redis` | managed | db-client | Redis integration (present as dependency) |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
