---
service: "mls-yang"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Merchant Lifecycle"
platform: "Continuum"
team: "Merchant Experience"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard"
  framework_version: "inherited from jtier-service-pom 5.14.0"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Merchant Lifecycle Service Yang (mls-yang) Overview

## Purpose

mls-yang is the read-model projection component of the Merchant Lifecycle Service (MLS). It consumes MLS command messages from Kafka and projects merchant lifecycle state — including voucher counts, CLO transactions, merchant facts, deal snapshots, and history events — into a set of PostgreSQL read databases. In parallel, a batch subsystem runs scheduled Quartz jobs that import deal engagement metrics from Hive/Janus, manage inventory products, and execute data retention policies.

## Scope

### In scope

- Consuming MLS Kafka command topics (`mls.VoucherSold`, `mls.VoucherRedeemed`, `mls.BulletCreated`, `mls.MerchantFactChanged`, `mls.MerchantAccountChanged`, `mls.CloTransaction`, `mls.HistoryEvent`, `mls.Generic`) and projecting them into read-model databases
- Serving read-model data via an internal REST API (voucher counts, CLO transactions, merchant accounts, merchant facts)
- Scheduled batch imports of deal engagement metrics (shares, email clicks/impressions, web/mobile clicks/impressions, merchant website referrals) from Janus/Hive
- Scheduled inventory product imports and daily deal backfills via Hive
- Scheduled merchant risk/refund rate imports via Cerebro Hive
- CLO transaction data retention (periodic purge of old CLO records)
- Persistence partition management for the Yang database
- Publishing batch feedback commands to the MLS message bus upon job completion

### Out of scope

- Producing new MLS command events (owned by mls-yin or other Yin-side services)
- Consumer-facing APIs — Yang's REST endpoints are internal operational/debugging interfaces
- Deal catalog data ownership (consumed from `deal-catalog` service)
- Authentication/authorisation infrastructure

## Domain Context

- **Business domain**: Merchant Lifecycle — tracking merchant account state, deal performance, voucher activity, and CLO transactions across the Groupon platform
- **Platform**: Continuum
- **Upstream consumers**: Other MLS platform services and analytics systems reading from the Yang databases; internal teams querying the REST API
- **Downstream dependencies**: Kafka (MLS command topics), PostgreSQL databases (yangDb, rinDb, historyDb, dealIndexDb), Hive/Janus (deal metrics), Cerebro Hive (risk data), Deal Catalog service (permalink-to-UUID resolution)

## Stakeholders

| Role | Description |
|------|-------------|
| Merchant Experience Team | Owns and operates the service; primary on-call (MerchantCenter-BLR@groupon.com) |
| SRE / Alerting | bmx-alert@groupon.com; PagerDuty service PV2ZOZL |
| Merchant Analytics | Consumes projected metrics data from Yang databases |
| MLS Platform | Upstream command producers; sibling services in the MLS ecosystem |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `pom.xml` `<project.build.targetJdk>11</project.build.targetJdk>` |
| Framework | Dropwizard | jtier-service-pom 5.14.0 | `pom.xml` parent POM |
| Runtime | JVM | 11 | `.java-version`, `.ci/Dockerfile` base image `dev-java11-maven` |
| Build tool | Maven | 3.x (jtier managed) | `pom.xml`, `.mvn/maven.config` |
| Scheduler | Quartz | jtier-quartz-bundle | `pom.xml` `jtier-quartz-bundle` dependency |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `kafka-clients` | 0.10.2.1 | message-client | Kafka consumer for MLS command topics |
| `dropwizard-jdbi` / `jtier-jdbi` | jtier managed | orm | DAO layer for all PostgreSQL interactions |
| `jtier-daas-postgres` | jtier managed | db-client | DaaS-backed PostgreSQL connection pooling |
| `jtier-quartz-bundle` | jtier managed | scheduling | Clustered Quartz scheduler for batch jobs |
| `hk2-di-core` | jtier-ext managed | validation | HK2 dependency injection framework |
| `jtier-hive` | 0.1.5 | db-client | Hive JDBC driver wrapper for Janus/Cerebro queries |
| `jtier-rxjava3-retrofit` / `jtier-rxjava3-extras` | jtier-ext managed | http-framework | Reactive HTTP client for Deal Catalog calls |
| `mx-jtier-commons` | 2.0.0 | http-framework | Groupon MX shared utilities including DealCatalogClient |
| `mls-commons` | mls-shared 2.1.0 | message-client | Shared MLS command/payload types and Kafka utilities |
| `jtier-jsonholder-bundle` | jtier-ext managed | serialization | JsonHolder for JSON field extraction and binding |
| `org.immutables:value` | jtier managed | validation | Compile-time immutable value objects |
| `arpnetworking steno` | jtier managed | logging | Structured steno logging |
| `groupon messagebus` | jtier managed | message-client | Message bus producer for batch feedback commands |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
