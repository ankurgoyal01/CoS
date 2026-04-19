---
service: "push-infrastructure"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Push / Messaging Infrastructure"
platform: "Continuum"
team: "Rocketman / Push Platform Engineering"
status: active
tech_stack:
  language: "Scala"
  language_version: "2.10.3"
  framework: "Play Framework"
  framework_version: "2.2.1"
  runtime: "JVM"
  runtime_version: "Java 8"
  build_tool: "SBT"
  build_tool_version: "0.13.18"
  package_manager: "SBT (Ivy)"
---

# Push Infrastructure (Rocketman v2) Overview

## Purpose

Push Infrastructure (Rocketman v2) is Groupon's centralized multi-channel message delivery service responsible for ingesting, rendering, scheduling, and dispatching push notifications, email, and SMS messages. It serves as the single authoritative delivery plane for all outbound marketing and transactional communications across the Continuum platform. The service decouples message authoring and campaign assembly from actual delivery, enabling high-throughput async processing and reliable retry semantics.

## Scope

### In scope

- Receiving and enqueuing user message requests via REST API
- Template rendering using FreeMarker templates (fetched from Redis cache)
- Scheduling campaigns and time-delayed messages via Quartz
- Processing delivery queues — push (FCM/APNs), email (SMTP), SMS (gateway)
- Consuming Kafka topics to ingest event-triggered messages
- Publishing delivery status events to RabbitMQ `status-exchange`
- Rate-limiting outbound delivery per user/channel using Redis
- Aggregating campaign delivery statistics
- Error tracking with retry and clear operations
- Cache invalidation for rendered templates
- Exposing a dashboard API for operational visibility

### Out of scope

- Campaign creation and audience segmentation (handled by upstream campaign services)
- User preference and opt-out management (handled by user profile / preference services)
- Email template authoring (content managed externally; templates fetched at render time)
- Inbound message handling (no reply/bounce processing in this service)
- Mobile SDK push registration (handled by device registration services)

## Domain Context

- **Business domain**: Push / Messaging Infrastructure
- **Platform**: Continuum
- **Upstream consumers**: Campaign orchestration services, transactional event producers, Kafka topic publishers (rm_daf, rm_preflight, rm_coupon, rm_user_queue_default, rm_rapi, rm_mds, rm_feynman)
- **Downstream dependencies**: SMTP relay, SMS Gateway, FCM/APNs, Kafka, RabbitMQ, MBus, Redis, PostgreSQL/MySQL, HDFS

## Stakeholders

| Role | Description |
|------|-------------|
| Push Platform Engineering (Rocketman team) | Owns and operates the service |
| Marketing Engineering | Upstream — triggers campaign and promotional messages |
| Transactional Systems | Upstream — triggers order confirmation, alert, and notification messages |
| SRE / Operations | Monitors delivery throughput, error rates, and infrastructure health |
| Product / Marketing | Business stakeholders who depend on reliable message delivery |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Scala | 2.10.3 | `build.sbt` |
| Language (interop) | Java | 8 | `build.sbt` |
| Framework | Play Framework | 2.2.1 | `build.sbt` |
| Runtime | JVM | Java 8 | `build.sbt` |
| Build tool | SBT | 0.13.18 | `project/build.properties` |
| Package manager | SBT (Ivy) | | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| kafka-clients | 2.5.1 | message-client | Kafka producer/consumer for event-triggered messaging |
| jedis | 3.3.0 | db-client | Redis client for template cache, queues, and rate limiting |
| akka-actor | 2.2.4 | http-framework | Actor-based async processing within Play Framework |
| quartz | 2.2.1 | scheduling | Cron-style and delayed message scheduling |
| rabbitmq-client | 3.3.1 | message-client | RabbitMQ publisher for delivery status events |
| mbus-client | 1.2.9 | message-client | MBus internal messaging integration |
| mybatis | 3.4.2 | orm | SQL mapping for PostgreSQL/MySQL transactional DB |
| postgresql | 42.2.18 | db-client | JDBC driver for PostgreSQL transactional database |
| freemarker | 2.3.20 | serialization | Template rendering engine for email/push/SMS content |
| hadoop | 2.5.0-cdh5.3.1 | db-client | HDFS client for batch delivery log storage |
| metrics-core | 3.1.0 | metrics | Dropwizard metrics instrumentation for throughput/latency tracking |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
