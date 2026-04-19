---
service: "global_subscription_service"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Subscriptions"
platform: "Continuum"
team: "Global Subscription Service"
status: active
tech_stack:
  language: "Java"
  language_version: "17"
  framework: "Dropwizard / JTier"
  framework_version: "jtier-service-pom 5.14.1"
  runtime: "JVM"
  runtime_version: "17"
  build_tool: "Maven 3"
  package_manager: "Maven"
---

# Global Subscription Service Overview

## Purpose

The Global Subscription Service (GSS) is Groupon's central platform for managing subscriber communication preferences across all channels and geographies. It stores and enforces SMS consent records (including double opt-in and GDPR compliance), manages email notification subscriptions by country and locale, and handles push notification device token registration and lifecycle. The service acts as the authoritative source of truth for whether a given consumer or phone number may be contacted by a given channel.

## Scope

### In scope
- SMS consent creation, update, and removal (by consumer UUID or phone number)
- SMS consent type (taxonomy) management per country/locale/client
- Email notification subscription management by list type and country
- Push notification device token registration, update, and deactivation
- Push subscription management by device or consumer
- Subscription event publishing to MBus and Kafka for downstream consumers
- GDPR unsubscribe flows (bulk and per-consent-type)
- Risk scoring for double opt-in flows (via `double-optin-riskscoring-lib`)
- Batch processing for email subscription calculations

### Out of scope
- Sending SMS messages (delegated to Rocketman SMS Service)
- Sending email messages (delegated to EDS / Email Delivery Service)
- Raw user account management (delegated to User Service)
- Regulatory consent logging (delegated to regulatory-consent-log / Consent Service)
- Geographic division resolution (delegated to Geo Services)

## Domain Context

- **Business domain**: Subscriptions
- **Platform**: Continuum
- **Upstream consumers**: Mobile apps, web frontend, internal marketing systems, Rocketman, EDS
- **Downstream dependencies**: `continuumUserService`, `continuumConsentService`, Rocketman SMS Service, EDS (Email Delivery Service), Geo Services, MBus, Kafka

## Stakeholders

| Role | Description |
|------|-------------|
| Team owner | balsingh — subscriptions-engineering@groupon.com |
| Engineering team | dgupta, bteja, rajdubey, uyadav |
| On-call | PagerDuty service P1NQCYT — global-subscription-service-alert@groupon.pagerduty.com |
| Slack channel | #subscription-engineering (C017W7A3NKT) |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 17 | `.java-version` |
| Framework | Dropwizard / JTier | jtier-service-pom 5.14.1 | `pom.xml` parent |
| Runtime | JVM | 17 | `.java-version` |
| Build tool | Maven | 3 | `pom.xml`, `.mvn/maven.config` |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-okhttp` | 1.1.6 | http-framework | Outbound HTTP client via OkHttp |
| `retrofit` + `converter-jackson` | 2.x | http-framework | Type-safe HTTP clients for downstream services |
| `jtier-retrofit` | — | http-framework | JTier-aware Retrofit wrapper |
| `jtier-messagebus-client` | 5.7.3 | message-client | MBus publish/consume integration |
| `jtier-daas-postgres` | — | db-client | JTier-managed PostgreSQL data access |
| `jtier-jdbi3` | — | orm | JDBI3 SQL object mapping |
| `jtier-migrations` | — | db-client | PostgreSQL schema migration runner |
| `postgresql` | 42.7.3 | db-client | PostgreSQL JDBC driver |
| `common-api` / `core-service` / `api-cassandra-impl` | 3.25 | db-client | Shared subscription domain model + Cassandra access layer |
| `libphonenumber` | 7.4.4 | validation | Phone number parsing and normalization |
| `lombok` | 1.18.20 | serialization | Boilerplate reduction for model classes |
| `double-optin-riskscoring-lib` | 1.9 | validation | Risk scoring for SMS double opt-in flows |
| `akka-actor_2.11` | 2.3.4 | scheduling | Actor-based async task execution |
| `metrics3-tools` | 4.1.0 | metrics | Dropwizard Metrics integration |
| `stringtemplate` | 3.2.1 | serialization | SMS message template rendering |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
