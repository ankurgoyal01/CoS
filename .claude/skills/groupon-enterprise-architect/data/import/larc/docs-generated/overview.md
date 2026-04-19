---
service: "larc"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Travel — Hotel Rate Management"
platform: "Continuum / Getaways"
team: "Getaways Engineering"
status: active
tech_stack:
  language: "Java"
  language_version: "11.0.2"
  framework: "Dropwizard"
  framework_version: "via jtier-service-pom 5.14.0"
  runtime: "JVM"
  runtime_version: "Java 11"
  build_tool: "Maven"
  build_tool_version: "3.3.9"
  package_manager: "Maven"
---

# Travel Lowest Available Rate Calculator (LARC) Overview

## Purpose

LARC automates a manual process that previously occurred at deal setup and throughout the lifetime of a Getaways booking deal. The service periodically ingests hotel market pricing data from QL2 (a third-party pricing data provider) via SFTP/FTP, calculates the Lowest Available Rate (LAR) for all nights across all travel windows and rate plan options of each deal, and pushes those computed rates to the Travel Inventory Service so that Groupon Getaways deals reflect accurate market pricing.

## Scope

### In scope
- Polling QL2 FTP/SFTP servers and downloading partner CSV pricing feed files
- Parsing and loading QL2 CSV data into the LARC MySQL database (nightly LAR records)
- Mapping QL2 rate descriptions to Groupon room types and rate plans
- Computing the lowest available rate for each night within each deal's travel window
- Publishing QL2 price updates and GRPN rate updates to the Travel Inventory Service
- Managing hotel records and their QL2 identifiers
- Maintaining approved rate discount percentages per rate plan
- Archiving old or unused nightly LAR records
- Sending transactional email notifications for unmapped rate descriptions (via Rocketman service)

### Out of scope
- Groupon deal creation and deal catalog management (owned by `continuumDealCatalogService`)
- Inventory availability and booking logic (owned by `continuumTravelInventoryService`)
- Customer-facing hotel search or rate display (owned by downstream consumer services)
- QL2 data production or feed generation (managed by QL2 as third-party)

## Domain Context

- **Business domain**: Travel — Getaways hotel pricing and rate management
- **Platform**: Continuum (Groupon legacy/modern commerce engine)
- **Upstream consumers**: eTorch (deal management extranet), Getaways extranet app — both call the LARC API to manage hotel mappings and trigger rate updates
- **Downstream dependencies**: Travel Inventory Service (receives computed rate updates), Deal Catalog / Content Service (provides product set and rate-plan metadata), QL2 FTP server (provides hotel pricing feeds)

## Stakeholders

| Role | Description |
|------|-------------|
| Getaways Engineering | Owning team — develops, deploys, and maintains LARC (getaways-eng@groupon.com) |
| Service Owner | nranjanray |
| SRE / On-call | Alerts via getaways-larc-alerts@groupon.com; PagerDuty service PNJO670 |
| Getaways Operations | Uses the extranet UI (powered by LARC API) to manage hotel-to-QL2 mappings and rate descriptions |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11.0.2 | `.java-version` |
| Framework | Dropwizard (via jtier-service-pom) | 5.14.0 parent POM | `pom.xml` |
| Runtime | JVM | Java 11 | `pom.xml` `project.build.targetJdk` |
| Build tool | Maven | 3.3.9 | `mvnvm.properties` |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-service-pom` | 5.14.0 | http-framework | Groupon JTier base service platform (Dropwizard wrapper) |
| `jtier-daas-mysql` | managed | db-client | Groupon DaaS MySQL datasource provisioning |
| `jtier-jdbi` | managed | orm | JDBI-based SQL access layer |
| `jtier-migrations` | managed | db-client | MySQL schema migration runner |
| `jtier-okhttp` | managed | http-framework | OkHttp HTTP client base |
| `jtier-retrofit` | managed | http-framework | Retrofit HTTP client for downstream REST calls |
| `travel-rate-calc` | 1.0.6 | scheduling | Groupon Travel rate calculation library |
| `lombok` | 1.18.22 | validation | Boilerplate reduction (getters, setters, builders) |
| `log4j-core` | 2.20.0 | logging | Application logging |
| `commons-net` | 3.4 | http-framework | Apache Commons Net FTP client for QL2 feed downloads |
| `jsch` | 0.1.55 | http-framework | JSch SFTP client for QL2 SFTP feed downloads |
| `gson` | managed | serialization | JSON serialization/deserialization |
| `jackson-types` | 1.0.1 | serialization | Groupon Jackson type utilities (UuidString, etc.) |
| `commons-lang3` | managed | validation | Apache Commons string and object utilities |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
