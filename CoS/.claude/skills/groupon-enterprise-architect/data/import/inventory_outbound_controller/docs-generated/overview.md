---
service: "inventory_outbound_controller"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Logistics & Fulfillment"
platform: "continuum"
team: "Goods & Logistics"
status: active
tech_stack:
  language: "Java"
  language_version: "OpenJDK 8"
  framework: "Play Framework"
  framework_version: "2.2"
  runtime: "JVM / Java 8"
  runtime_version: "Java 8"
  build_tool: "SBT"
  package_manager: "SBT / Ivy"
---

# inventory_outbound_controller (Goods Outbound Controller) Overview

## Purpose

inventory_outbound_controller is the core logistics orchestration service for Continuum's physical goods business. It manages the end-to-end lifecycle of order fulfillment: from ingesting fulfillment manifests and routing inventory to third-party logistics (3PL) providers, through shipment acknowledgement, to order cancellation and GDPR-compliant account erasure. The service connects internal Continuum systems (Orders, Inventory, Deal Catalog, Pricing, Users) with external logistics partners via a message bus and HTTP APIs.

## Scope

### In scope

- Importing and parsing fulfillment manifests from scheduled jobs
- Routing orders to appropriate fulfillment providers based on inventory eligibility and deal configuration
- Processing inbound message bus events for inventory updates and logistics gateway shipment notifications
- Tracking shipment status and publishing marketplace order-shipped events
- Handling order cancellation via both API and message bus, pre- and post-shipment
- Scheduled retry and reaper jobs for failed or expired fulfillments via Quartz
- GDPR account erasure: anonymizing PII for deleted user accounts
- Providing admin APIs for job scheduling, consumer management, and fulfillment tooling
- Carrier and rate estimation queries

### Out of scope

- Inventory quantity ownership (managed by Inventory Service and Goods Inventory Service)
- Order creation and payment processing (managed by Orders Service)
- Deal content and pricing ownership (managed by Deal Catalog Service and Pricing Service)
- User account management beyond GDPR anonymization (managed by Users Service)
- Physical shipment carrier operations (delegated to Landmark Global 3PL)
- Email delivery (delegated to Rocketman Email service)

## Domain Context

- **Business domain**: Logistics & Fulfillment
- **Platform**: Continuum
- **Upstream consumers**: Orders Service (cancellation API), internal admin tooling, message bus event producers (Inventory Service, logistics gateway, GDPR pipeline)
- **Downstream dependencies**: Inventory Service, Goods Inventory Service, Orders Service, Deal Catalog Service, Users Service, Pricing Service, Message Bus (JMS), Landmark Global 3PL, Rocketman Email, Google Sheets

## Stakeholders

| Role | Description |
|------|-------------|
| Goods & Logistics team | Owns service development, deployment, and on-call |
| Operations / Fulfillment team | Uses admin tooling and fulfillment state tools |
| Legal / Compliance | Relies on GDPR erasure flow for regulatory obligations |
| External 3PL partners (Landmark Global) | Receives fulfillment instructions; sends shipment acknowledgement events |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | OpenJDK 8 | build.sbt / project config |
| Framework | Play Framework | 2.2 | build.sbt dependencies |
| Runtime | JVM / Java 8 | Java 8 | Dockerfile / project config |
| Build tool | SBT | — | build.sbt |
| Package manager | SBT / Ivy | — | build.sbt |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Play Framework | 2.2 | http-framework | HTTP routing, dependency injection, async I/O |
| Hibernate | 4.3.11.Final | orm | Object-relational mapping for MySQL persistence |
| MySQL Connector | 8.0.29 | db-client | JDBC driver for MySQL connectivity |
| mbus-client | 1.2.16 | message-client | JMS message bus client for publishing and consuming events |
| Quartz | 2.3.0 | scheduling | Scheduled job execution (retry, reaper, import jobs) |
| Jackson | 2.13.3 | serialization | JSON serialization and deserialization |
| Liquibase | 3.3 | db-client | Database schema migration management |
| Lombok | 1.18.2 | http-framework | Boilerplate reduction (getters, builders, logging) |
| logback-steno | 1.18.5 | logging | Structured JSON logging |
| Mockito | 1.9.5 | testing | Unit test mocking framework |
| WireMock | 1.46 | testing | HTTP service virtualization for integration tests |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
