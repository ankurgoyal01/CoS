---
service: "killbill-adyen-plugin"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Payments / International Checkout"
platform: "Continuum"
team: "Intl-Checkout"
status: active
tech_stack:
  language: "Java"
  language_version: "8"
  framework: "Kill Bill OSGi plugin framework"
  framework_version: "0.18.z compatible"
  runtime: "JVM"
  runtime_version: "Java 8"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Kill Bill Adyen Plugin Overview

## Purpose

The Kill Bill Adyen Plugin is an OSGi bundle that integrates Kill Bill's subscription billing platform with Adyen as a payment service provider. It handles all outbound payment operations (authorize, capture, refund, void, recurring) via Adyen's SOAP and REST/Checkout APIs, and processes inbound asynchronous payment notifications from Adyen to reconcile transaction states within Kill Bill. The plugin supports multi-country, multi-merchant-account configurations and multiple payment methods including credit cards, SEPA direct debit, ELV, HPP, Klarna, and 3D Secure v1/v2 flows.

## Scope

### In scope
- Submitting authorize, capture, refund, and void transactions to Adyen SOAP Payment API
- Submitting payments via Adyen Checkout REST API
- Generating Hosted Payment Page (HPP) form descriptors and redirect URLs
- Processing and reconciling Adyen SOAP webhook notifications (AUTHORISATION, CAPTURE, REFUND, CANCELLATION, CHARGEBACK, etc.)
- Managing recurring payment contracts (ONECLICK and RECURRING types)
- Supporting 3D Secure v1 (PaRes/MD) and 3D Secure v2 challenge/identify-shopper flows
- Persisting payment methods, Adyen responses, notifications, and HPP requests in the plugin database
- Scheduling delayed follow-up actions for 3DSv2 using a notification queue
- Exposing a healthcheck endpoint that validates Adyen endpoint reachability
- Per-tenant and per-region configuration via Kill Bill's tenant configuration API

### Out of scope
- Kill Bill core subscription and invoicing logic (managed by Kill Bill platform)
- Fraud scoring and risk decisioning (delegated to Adyen)
- Shopper-facing checkout UI (handled by upstream callers)
- Currency conversion (delegated to Adyen's DCC feature)
- Reporting and dispute management beyond raw data persistence

## Domain Context

- **Business domain**: Payments / International Checkout
- **Platform**: Continuum
- **Upstream consumers**: Kill Bill platform (invokes payment plugin APIs and servlet endpoints)
- **Downstream dependencies**: Adyen payment gateway (SOAP Payment, SOAP Recurring, Adyen Checkout REST API, HPP)

## Stakeholders

| Role | Description |
|------|-------------|
| Intl-Checkout team | Owns and maintains the plugin; handles Groupon-specific Adyen integration |
| Kill Bill platform | Orchestrates payment lifecycle and invokes plugin APIs |
| Adyen | External payment gateway providing authorisation, settlement, and notifications |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 8 | `pom.xml` maven-compiler-plugin source/target 1.8 |
| Framework | Kill Bill OSGi plugin framework | 0.18.z | `pom.xml` parent `killbill-oss-parent:0.140.55` |
| Build tool | Maven | 3.x | `pom.xml`, `.ci/Dockerfile` maven:3.5.4-jdk-8-alpine |
| Packaging | OSGi Bundle | - | `maven-bundle-plugin`, `AdyenActivator` |
| Runtime | JVM | Java 8 | `.ci/Dockerfile` jdk-8-alpine |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `adyen-java-api-library` | 12.0.1 | http-framework | Adyen Checkout REST API client |
| `killbill-plugin-api-payment` | (platform) | http-framework | Kill Bill payment plugin API contract |
| `killbill-plugin-api-notification` | (platform) | message-client | Kill Bill notification plugin API |
| `killbill-base-plugin` | (platform) | http-framework | Base plugin utilities and OSGi support |
| `killbill-queue` | (platform) | scheduling | Notification queue for delayed 3DSv2 actions |
| `killbill-jdbi` | (platform) | db-client | JDBI database access layer |
| `cxf-core` / `cxf-rt-frontend-jaxws` | 3.3.6 | http-framework | Apache CXF for Adyen SOAP (Payment, Recurring, HPP, Notification) WSDLs |
| `jackson-databind` | 2.9.2 | serialization | JSON serialization for Checkout API and plugin properties |
| `jooq` | (platform) | orm | Type-safe SQL query builder for plugin DB access |
| `guava` | 21.0 | validation | Collections utilities, preconditions |
| `async-http-client` | (platform) | http-framework | Async HTTP for directory and HPP calls |
| `snakeyaml` | (platform) | serialization | YAML configuration parsing |
| `joda-time` / `joda-money` | (platform) | validation | Date/time and monetary amount handling |
| `killbill-clock` | (platform) | scheduling | Pluggable clock for time-sensitive operations |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for the full dependency list.
