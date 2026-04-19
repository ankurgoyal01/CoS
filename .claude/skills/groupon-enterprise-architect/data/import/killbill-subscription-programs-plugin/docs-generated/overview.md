---
service: "killbill-subscription-programs-plugin"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Subscriptions / Recurring Commerce"
platform: "Continuum"
team: "Select"
status: active
tech_stack:
  language: "Java"
  language_version: "8"
  framework: "Kill Bill OSGi Plugin"
  framework_version: "killbill-oss-parent 0.143.24 / killbill-base-plugin 4.0.1"
  runtime: "Apache Tomcat"
  runtime_version: "8.5"
  build_tool: "Maven"
  package_manager: "Maven / Nexus"
---

# Kill Bill Subscription Programs Plugin Overview

## Purpose

The Kill Bill Subscription Programs Plugin (`sp-plugin`) is an OSGi plugin that extends Kill Bill's billing platform to implement Groupon's subscription program order lifecycle. It listens to Kill Bill invoice events and Groupon MBus ledger events to create subscription orders via the Lazlo GAPI and to reconcile invoice payment status based on downstream transaction outcomes. The plugin supports programs such as Groupon Select, AutoRebuy, and Merchant Account Fees.

## Scope

### In scope

- Listening to Kill Bill `INVOICE_CREATION` events and triggering order creation via the Lazlo GAPI (`multi_item_orders` endpoint)
- Consuming `jms.topic.Orders.TransactionalLedgerEvents` messages from the Groupon MBus to drive payment reconciliation
- Refreshing invoice state for a given order by calling the Orders read service
- Managing short-lived authorization tokens used when calling the GAPI on behalf of a user
- Storing retry-notification metadata and plugin tokens in a dedicated MySQL schema
- Exposing HTTP endpoints for manual order triggers, invoice refresh, healthchecks, and token operations
- Per-tenant and per-region plugin configuration via Kill Bill's tenant config upload mechanism

### Out of scope

- Kill Bill core subscription lifecycle management (handled by Kill Bill platform itself)
- Payment gateway processing (handled by separate Kill Bill payment plugins)
- Subscription catalog management (managed via Kill Bill catalog XML uploads)
- Consumer-facing subscription APIs (exposed by upstream services; this plugin is an internal platform component)

## Domain Context

- **Business domain**: Subscriptions / Recurring Commerce
- **Platform**: Continuum (Kill Bill)
- **Upstream consumers**: Kill Bill platform delivers `INVOICE_CREATION` events in-process; Groupon MBus delivers `TransactionalLedgerEvents` from the Orders system
- **Downstream dependencies**: Lazlo GAPI (`continuumApiLazloService`) for order creation; Orders service (`continuumOrdersService`) for order/payment status reads; MySQL (`continuumSubscriptionProgramsPluginDb`) for plugin persistence; Groupon MBus (`messageBus`) for ledger event consumption

## Stakeholders

| Role | Description |
|------|-------------|
| Select Engineering Team | Owns and develops the plugin; on-call via `select-dev@groupon.pagerduty.com` |
| Subscription Program Business Owners | Rely on the plugin to process recurring charges for Select, AutoRebuy, and related programs |
| Kill Bill Platform Team | Provides the underlying billing and entitlement platform the plugin extends |
| Orders / GAPI Team | Downstream services called by the plugin for order creation and status |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 8 | `pom.xml` `<java.version>8</java.version>` |
| Framework | Kill Bill OSGi Plugin | killbill-oss-parent 0.143.24 | `pom.xml` parent declaration |
| Base plugin | killbill-base-plugin | 4.0.1 | `pom.xml` `<killbill-base-plugin.version>4.0.1</killbill-base-plugin.version>` |
| HTTP framework | Jooby | inherited from killbill-oss-parent | `pom.xml`, `SPActivator.java` |
| Build tool | Maven | Maven 3.x | `pom.xml`, `Jenkinsfile` |
| Runtime | Apache Tomcat | 8.5.16 | `OwnersManual.md` startup command |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `killbill-plugin-api-entitlement` | inherited | plugin-api | Entitlement plugin API hook for subscription lifecycle interception |
| `killbill-plugin-api-notification` | inherited | plugin-api | Notification/event listener API for in-process Kill Bill events |
| `mbus-client` | 1.2.16 | message-client | Groupon internal message bus client for consuming JMS/STOMP ledger events |
| `jooq` | 3.10.3 | orm | Type-safe SQL DSL for plugin DB access (token and retry tables) |
| `retrofit2` | 2.3.0 | http-client | HTTP client for Orders service integration |
| `com.ning:async-http-client` | inherited | http-client | Async HTTP client for GAPI (Lazlo) calls |
| `jackson-core` / `jackson-databind` | inherited | serialization | JSON serialization for GAPI payloads and MBus messages |
| `guice` | inherited | di | Dependency injection for plugin component wiring |
| `snakeyaml` | 1.18 | config | YAML parsing for per-tenant plugin configuration |
| `killbill-jdbi` | inherited | db-client | JDBI SQL object mapping for plugin persistence |
| `killbill-notificationq` | inherited | scheduling | Notification queue service for retry scheduling |
| `logback-classic` | 1.2.9 | logging | SLF4J-backed structured logging |
| `logback-steno` | 1.18.5 | logging | Structured steno log format for Splunk ingestion |
| `testng` | inherited | testing | Test framework for unit and integration tests |
