---
service: "message2ledger"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Finance / Ledger"
platform: "Continuum"
team: "Finance Engineering (FED)"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "JTier / Dropwizard"
  framework_version: "5.14.0"
  runtime: "JVM"
  runtime_version: ""
  build_tool: "Maven"
  package_manager: "Maven"
---

# message2ledger Overview

## Purpose

message2ledger is a Continuum platform service responsible for consuming order and inventory lifecycle events from MBus, enriching each event with cost and unit-level inventory details, and posting the resulting ledger entries to the Accounting Service. It provides Finance Engineering with a reliable, auditable pipeline that translates transactional commerce events into accounting ledger records for both NA and EMEA regions.

## Scope

### In scope

- Subscribing to MBus topics for order transactional ledger events and inventory unit update events (NA and EMEA regions)
- Persisting inbound message envelopes and tracking processing attempts in MySQL
- Enriching messages with unit and product details from VIS, TPIS, and GLive inventory APIs
- Fetching cost details from the Accounting Service and posting decorated ledger payloads
- Providing admin endpoints for manual message replay, retry, and lifecycle investigation
- Scheduled reconciliation and automated replay of failed messages via Quartz/KillBill Queue
- Forwarding missing order messages to the Orders Service for republish

### Out of scope

- Generating or originating order or inventory events (upstream responsibility of Orders and Inventory services)
- Direct customer-facing APIs or user authentication flows
- Ledger storage and accounting logic (owned by the Accounting Service)
- EDW data ingestion and warehousing (EDW is queried read-only for reconciliation datasets)

## Domain Context

- **Business domain**: Finance / Ledger
- **Platform**: Continuum
- **Upstream consumers**: No known direct API consumers; triggered by MBus events
- **Downstream dependencies**: Accounting Service, VIS (continuumVoucherInventoryApi), TPIS (continuumThirdPartyInventoryService), GLive (continuumGLiveInventoryService), Orders Service (continuumOrdersService), EDW, MBus, message2ledger MySQL

## Stakeholders

| Role | Description |
|------|-------------|
| Finance Engineering (FED) | Owns and operates the service; responsible for ledger accuracy and pipeline health |
| Accounting Service team | Downstream consumer of posted ledger payloads |
| Platform / SRE | Infrastructure, deployment, and incident response support |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | Summary / architecture DSL |
| Framework | JTier / Dropwizard | 5.14.0 | Summary |
| Runtime | JVM | — | Summary |
| Build tool | Maven | — | Summary |
| Package manager | Maven | — | Summary |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| mbus-client | — | message-client | Subscribes to MBus JMS topics for order and inventory events |
| jtier-jdbi | — | db-client | JDBI-based data access layer for MySQL reads/writes |
| jtier-daas-mysql | — | db-client | JTier managed MySQL datasource configuration |
| quartz | 1.8.3 | scheduling | Drives the Async Task Processor for processing attempt scheduling |
| killbill-queue | 0.23.5 | scheduling | Persistent job queue backing the async processing pipeline |
| retrofit2 | — | http-framework | HTTP client for calls to Accounting Service, VIS, TPIS, and Orders Service |
| flyway | 7.15.0 | db-client | Database schema migrations for MySQL |
| steno | — | logging | Structured JSON logging |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
