---
service: "afl-rta"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Affiliates / Marketing Attribution"
platform: "Continuum"
team: "AFL"
status: active
tech_stack:
  language: "Java"
  language_version: "21"
  framework: "Dropwizard"
  framework_version: "JTier jtier-service-pom 5.15.0"
  runtime: "JVM"
  runtime_version: "21"
  build_tool: "Maven"
  package_manager: "Maven"
---

# AFL RTA (Affiliate Real-Time Attribution) Overview

## Purpose

AFL RTA (Affiliate Real-Time Attribution) is a Kafka-driven Java service that performs real-time attribution for marketing channels. It processes two event types — external referrer clicks and deal purchase orders — arriving via the Janus Tier 2 Kafka topic, determines which marketing channel and affiliate should receive credit for each event within a 7-day attribution window, and publishes attributed orders downstream via MBus for partner channel integration (notably Commission Junction).

## Scope

### In scope

- Consuming Janus-processed `externalReferrer` (click) events from Kafka and registering attributed clicks in MySQL
- Consuming Janus-processed `dealPurchase` (order) events from Kafka and correlating them against stored click history
- Performing channel-specific attribution strategies (AFL, CJ, GPN, etc.) within a 7-day referral window
- Enriching attributed orders with order details (Orders API) and deal taxonomy (MDS)
- Publishing attributed orders to MBus for downstream partner processing (Commission Junction integration)
- Deduplication and audit storage of attributed orders in MySQL
- Providing attribution data for the Wavefront RTA dashboard

### Out of scope

- Upstream Janus event processing (owned by the data-engineering team)
- Commission Junction API integration (handled by `afl-3pgw`)
- Deal listing, pricing, or inventory management
- Direct customer-facing API endpoints (this service has no public REST API)

## Domain Context

- **Business domain**: Affiliates / Marketing Attribution
- **Platform**: Continuum
- **Upstream consumers**: Janus Tier 2 Kafka topic (`continuumJanusTier2Topic`) feeds all inbound data; no HTTP callers are known from this repo
- **Downstream dependencies**: `continuumOrdersService` (HTTPS/JSON), `continuumMarketingDealService` / MDS (HTTPS/JSON), `messageBus` MBus/JMS, `continuumAflRtaMySql` (JDBC)

## Stakeholders

| Role | Description |
|------|-------------|
| Affiliates Engineering Team | Primary owners; misc questions during office hours (gpn-dev@groupon.com) |
| Affiliates Alerts On-call | Emergency support and outages; triggers PagerDuty 24/7 (gpn-alerts@groupon.com) |
| #affiliates Google Chat | General questions during Dublin office hours |
| data-engineering (Janus team) | Owns and maintains the upstream janus-tier2 Kafka topic |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 21 | `pom.xml` `maven.compiler.source=21` |
| Framework | Dropwizard (JTier) | jtier-service-pom 5.15.0 | `pom.xml` parent POM |
| Runtime | JVM | 21 | `pom.xml`, `.java-version` |
| Build tool | Maven | 3.x (JTier managed) | `pom.xml`, `.mvn/maven.config` |
| Package manager | Maven | | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| kafka-clients | 2.7.0 | message-client | Polls Janus events from the Kafka janus-tier2 topic |
| janus-thin-mapper | 1.7-Aff | serialization | Deserializes Janus Avro/JSON event payloads into typed POJOs |
| jtier-messagebus-client | JTier managed | message-client | Publishes attributed orders to MBus/JMS |
| jtier-daas-mysql | JTier managed | db-client | Managed MySQL (DaaS) connection pool and configuration |
| jtier-jdbi3 | JTier managed | orm | JDBI3-based SQL access layer for click and order persistence |
| jtier-migrations | JTier managed | db-client | Database schema migration management |
| jtier-retrofit | JTier managed | http-framework | HTTP client for Orders API and MDS outbound calls |
| failsafe | 2.4.4 | resilience | Retry and circuit-breaker policies for outbound HTTP calls |
| cache2k | 2.6.1.Final | db-client | In-process cache for deal taxonomy and attribution tier lookups |
| guava | 31.1-jre | validation | General-purpose utilities |
| URL-parsing | 0.0.43 | validation | Parses and validates click URLs from referrer events |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for the full dependency manifest.
