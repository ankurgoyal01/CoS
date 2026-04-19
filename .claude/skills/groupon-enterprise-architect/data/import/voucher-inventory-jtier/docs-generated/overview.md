---
service: "voucher-inventory-jtier"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Voucher Inventory"
platform: "Continuum"
team: "Voucher Inventory 3.0"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard / JTier"
  framework_version: "5.14.0 (jtier-service-pom)"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Voucher Inventory JTier Overview

## Purpose

Voucher Inventory Service V3 (VIS 3.0, also known as "VIS" or "voucher-inventory-jtier") is Groupon's next-generation inventory microservice, built on the JTier platform using Java and Dropwizard. It provides real-time inventory product details — including pricing, availability, and unit sold counts — for all consumer-facing and internal product experiences. VIS 3.0 was designed to replace the legacy Ruby-on-Rails VIS 1.0/2.0 with improved latency through a cache-behind strategy using Redis (RaaS), eliminating the dependency on Varnish-based front caches.

## Scope

### In scope

- Serving inventory product data for voucher products via `GET /inventory/v1/products`
- Enriching inventory responses with dynamic pricing from Pricing Service
- Enriching inventory responses with availability segments from Calendar Service
- Managing acquisition methods via `POST /inventory/v1/acquisition_method`
- Consuming inventory update and order sold-out events from MessageBus
- Maintaining a Redis cache of inventory products and unit sold counts
- Running scheduled replenishment jobs (Ouroboros) to sync inventory schedules from legacy VIS
- Running scheduled unit redeem jobs that pull and process SFTP files from Groupon Transfer
- Publishing inventory product update events to MessageBus

### Out of scope

- Order placement and redemption logic (handled by Orders Service)
- Pricing calculation (handled by Pricing Service)
- Calendar/availability calculation (handled by Calendar Service)
- Legacy Varnish-based caching (VIS 1.0/2.0 responsibility)
- Deal creation or merchandising data

## Domain Context

- **Business domain**: Voucher Inventory
- **Platform**: Continuum
- **Upstream consumers**: Deal Estate, Deal Wizard, and all clients listed in the client ID document; services querying inventory product data at ~800K RPM
- **Downstream dependencies**: Pricing Service (HTTP), Calendar Service (HTTP), MySQL Product DB, MySQL Units DB, MySQL RW DB, Redis (RaaS), MessageBus (JMS/STOMP), Legacy VIS (HTTP, for replenishment), Groupon Transfer SFTP (for unit redeem)

## Stakeholders

| Role | Description |
|------|-------------|
| Team Owner | Voucher Inventory 3.0 team (glinganaidu, smankala, vnithish, apatil, abhsinha, chegupta) |
| On-call / SRE | voucher-inventory-urgent@groupon.com; PagerDuty: P815MP6 |
| Mailing List | voucher-inventory-dev@groupon.com |
| Slack | #voucher-inventory |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `pom.xml`: `project.build.targetJdk = 11`; `.java-version` |
| Framework | Dropwizard / JTier | jtier-service-pom 5.14.0 | `pom.xml` parent artifact |
| Runtime | JVM | 11 | `.ci/Dockerfile`: `dev-java11-maven:2023-02-27` |
| Build tool | Maven | N/A | `pom.xml`, `.ci/test_and_deploy_to_nexus.sh` |
| Package manager | Maven | N/A | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-service-core` | 5.14.0 (via parent) | http-framework | Core JTier/Dropwizard HTTP server |
| `jtier-daas-mysql` | 5.14.0 (via parent) | db-client | DaaS MySQL integration (HikariCP pool) |
| `jtier-jdbi` | 5.14.0 (via parent) | orm | JDBI DAO layer for MySQL access |
| `jtier-messagebus-client` | 5.14.0 (via parent) | message-client | JMS/STOMP MessageBus publishing and consumption |
| `jtier-okhttp` | 5.14.0 (via parent) | http-framework | OkHttp-based HTTP client for external services |
| `retrofit2:converter-jackson` | via parent | serialization | Jackson-based Retrofit HTTP client |
| `dropwizard-redis` | 1.2.0-0 | db-client | Redis (RaaS/Jedis) integration for Dropwizard |
| `jtier-quartz-bundle` | 1.2.1 | scheduling | Quartz scheduler bundle for JTier (replenishment, unit redeem jobs) |
| `quartz` | 2.3.0 | scheduling | Quartz job scheduling framework |
| `commons-csv` | 1.4 | serialization | CSV parsing for unit redeem SFTP files |
| `jsch` | 0.1.55 | db-client | JSch SFTP client for Groupon Transfer file download |
| `joda-money` | 0.12 | validation | Monetary value handling |
| `java-uuid-generator` | 4.0.1 | serialization | UUID generation for acquisition methods |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
