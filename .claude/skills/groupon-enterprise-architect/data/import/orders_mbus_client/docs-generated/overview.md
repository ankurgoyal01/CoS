---
service: "orders_mbus_client"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Orders / Payments"
platform: "Continuum"
team: "Orders"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard"
  framework_version: "inherited from jtier-service-pom 5.14.0"
  runtime: "JVM"
  runtime_version: "AdoptOpenJDK 11 UBI"
  build_tool: "Maven"
  package_manager: "Maven (pom.xml)"
---

# Orders Mbus Client (JOMC) Overview

## Purpose

Orders Mbus Client (JOMC) is the message bus bridge for the Groupon Orders platform. It subscribes to multiple MBus topics — covering payment updates, account erasure, bucks-mirror synchronisation, VFM promotional adjustments, and PayPal billing records — then translates each inbound event into a targeted HTTP call against the Orders service. It also publishes outbound gift-order messages to MBus using a durable, DB-backed queue with exponential-backoff retry logic.

## Scope

### In scope

- Subscribing to MBus topics: `PaymentUpdateTopic`, `AccountEraseTopic`, `BucksMirrorTopic`, `VFMPromotionalAdjustmentsEnabledTopic`, `PaypalBillingAgreementTopic`, `BeModTopic`.
- Translating inbound MBus payloads and forwarding them as HTTP requests to the Orders service.
- Persisting outbound messages to MySQL and publishing them to `jms.topic.Order.Gift` via a scheduled Quartz job.
- Exponential-backoff retry logic for failed publishes (up to `maxRetryCount`; then status becomes `abandoned`).
- Distributed message locking via a `lock_key` / `release_at` column pair to prevent duplicate processing across replicas.
- Scheduled monitoring of message-queue depths and thread-pool utilisation.
- Heartbeat-based health checks via `heartbeat.txt`.

### Out of scope

- Order creation and core order management (handled by the `orders` service).
- Payment gateway integration (handled upstream by payments providers and the payments MBus topic).
- GDPR erasure orchestration beyond forwarding the account-erase event to Orders.
- Consumer-side persistence; all persistence for consumed events is delegated to the Orders service.

## Domain Context

- **Business domain**: Orders / Payments
- **Platform**: Continuum
- **Upstream consumers**: No direct HTTP consumers; the service is a pure worker — it is driven by MBus events and Quartz schedules.
- **Downstream dependencies**: Orders service (HTTP/JSON), MBus (JMS/STOMP), MySQL message store.

## Stakeholders

| Role | Description |
|------|-------------|
| Engineering owner | Orders team (`orders-eng@groupon.com`) |
| On-call / SRE | `orders-alert@groupon.com`, PagerDuty service `PTFWI82` |
| Slack channel | `#orders-and-payments` |
| Service owner | adisharma / lead: dram |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `pom.xml` `<project.build.targetJdk>11</project.build.targetJdk>`, `.java-version` |
| Framework | Dropwizard (via jtier-service-pom) | 5.14.0 parent | `pom.xml` `<parent>` |
| Runtime | AdoptOpenJDK 11 UBI | 11 | `Dockerfile` `FROM adoptopenjdk/openjdk11:ubi` |
| Build tool | Maven | via mvnvm | `mvnvm.properties`, `.mvn/maven.config` |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-messagebus-dropwizard` | parent-managed | message-client | MBus consumer and producer integration |
| `jtier-daas-mysql` | parent-managed | db-client | DaaS-managed MySQL datasource configuration |
| `jtier-jdbi` | parent-managed | orm | JDBI SQL object DAO layer for the message store |
| `jtier-quartz-bundle` | parent-managed | scheduling | Quartz scheduler integration for publish and monitoring jobs |
| `jtier-migrations` | parent-managed | db-client | Flyway-based MySQL schema migrations on startup |
| `jtier-ctx` | parent-managed | http-framework | JTier request context propagation |
| `dropwizard-core` | parent-managed | http-framework | HTTP server, lifecycle, health checks, configuration |
| `okhttp3` | parent-managed | http-framework | HTTP client for outbound calls to the Orders service |
| `jtier-okhttp` | 1.1.6 | http-framework | JTier OkHttp wrapper with tracing/context support |
| `jackson-annotations` | parent-managed | serialization | JSON message binding |
| `org.json:json` | 20180813 | serialization | JSON request body construction in OrdersClient |
| `stringtemplate` | 3.2.1 | orm | JDBI StringTemplate3 statement locator |
| `commons-codec` / `commons-io` | parent-managed | logging | Apache Commons utilities |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
