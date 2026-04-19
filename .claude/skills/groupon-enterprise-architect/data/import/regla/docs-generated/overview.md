---
service: "regla"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Emerging Channels / Inbox Management"
platform: "continuum"
team: "Emerging Channels"
status: active
tech_stack:
  language: "Java / Scala"
  language_version: "Java 1.8 / Scala 2.11.8"
  framework: "Play Framework"
  framework_version: "2.5"
  runtime: "JVM"
  runtime_version: "JDK 1.8"
  build_tool: "SBT"
  package_manager: "SBT / Ivy"
---

# regla Overview

## Purpose

regla is a rules engine and deal purchase decision platform within the Continuum Emerging Channels domain. It manages the full lifecycle of rule definitions — creation, approval, activation, and deactivation — and evaluates those rules against consumer purchase history and browse events to drive inbox management actions such as push notifications and email campaigns. A companion Kafka stream job processes high-volume event streams for batch rule evaluation.

## Scope

### In scope

- CRUD operations on rule definitions with an approval/rejection workflow
- Registration and management of rule instances tied to events
- Synchronous rule evaluation queries (has user purchased a deal since X, has user ever purchased)
- Category and taxonomy tree resolution for rule conditions
- Stream processing of deal-purchase and browse events via Kafka Streams / Spark
- Rule-triggered action execution (push notifications via Rocketman, emails via Email Campaign, incentives via Incentive Service)
- Redis caching of purchase history, rule state, and taxonomy data for low-latency evaluation
- Integration with Taxonomy Service v2 for category hierarchy resolution

### Out of scope

- Consumer profile management (handled by consumer-data service)
- Deal catalogue management (handled by Deal Catalog service)
- Push notification delivery infrastructure (handled by Rocketman v2)
- Email delivery infrastructure (handled by Email Campaign service)
- Identity and authentication (handled by upstream platform services)

## Domain Context

- **Business domain**: Emerging Channels / Inbox Management
- **Platform**: continuum
- **Upstream consumers**: Inbox management orchestration, campaign management tools, internal admin interfaces
- **Downstream dependencies**: Taxonomy Service v2, Deal Catalog, Email Campaign, Event Delivery Service, Kafka, Watson-KV, Incentive Service, Rocketman v2, MessageBus, TSD Aggregator, STAAS

## Stakeholders

| Role | Description |
|------|-------------|
| Emerging Channels Team | Service owner; responsible for maintenance and on-call |
| Inbox Management Product | Uses rule evaluation to drive personalised notifications |
| Data Engineering | Consumes Kafka stream job output for downstream analytics |
| Campaign Operations | Creates and manages rule definitions via admin workflows |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 1.8 | Inventory / build.sbt |
| Language | Scala | 2.11.8 | Inventory / build.sbt |
| Framework | Play Framework | 2.5 | Inventory / build.sbt |
| Runtime | JVM / JDK | 1.8 | Inventory |
| Build tool | SBT | — | build.sbt |
| Package manager | SBT / Ivy | — | build.sbt |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| postgresql | 42.6.0 | db-client | JDBC driver for PostgreSQL |
| kafka-streams | 2.8.2 | message-client | Stream processing of deal-purchase and browse events |
| kafka-0.8-thin-client | 2.0.16 | message-client | Legacy Kafka 0.8 producer/consumer for topic publishing |
| mbus-client | 1.1.0 | message-client | MessageBus integration for Continuum event fabric |
| jedis | 2.8.0 | db-client | Redis client for purchase history cache and rule state |
| guava | 18 | validation | Collections, caching, and utility functions |
| commons-httpclient | 3.1 | http-framework | Outbound HTTP calls to integrated services |
| jackson-datatype-joda | 2.2.2 | serialization | JSON serialisation with Joda-Time support |
| logback | 1.2.9 | logging | Structured application logging |
| metrics-sma-influxdb | 5.12.0 | metrics | Application metrics emission to InfluxDB / TSD Aggregator |
| freemarker | 2.3.21 | ui-framework | Template rendering for rule action content |
| joda-money | 0.7 | validation | Monetary value handling in rule conditions |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
