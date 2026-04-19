---
service: "tpis-inventory-service"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Inventory & Vouchers"
platform: "Continuum"
team: "Inventory"
status: active
tech_stack:
  language: "Java"
  language_version: ""
  framework: ""
  framework_version: ""
  runtime: "JVM"
  runtime_version: ""
  build_tool: ""
  package_manager: ""
---

# Third Party Inventory Service Overview

## Purpose

The Third Party Inventory Service (TPIS) is a Java microservice within Groupon's Continuum platform that manages inventory sourced from external third-party partners. It acts as the integration and persistence layer for partner-managed inventory covering travel, events, and goods domains, enabling Groupon to offer partner-sourced deals alongside its own inventory. TPIS stores and tracks inventory events and product data from these external systems, making it available to the rest of the Continuum ecosystem through HTTP APIs.

## Scope

### In scope
- Receiving and persisting third-party inventory data from external partner platforms
- Tracking inventory events (availability changes, booking confirmations, status updates) from partners
- Exposing inventory product and unit data to internal Continuum services via REST APIs
- Providing booking flow data for third-party inventory items
- Supplying availability data for downstream feed generation and deal syndication
- Persisting TPIS events and inventory data to MySQL for querying and reporting
- Replicating inventory data to the Enterprise Data Warehouse (EDW) and BigQuery for analytics

### Out of scope
- First-party voucher inventory lifecycle (handled by Voucher Inventory Service)
- Goods-specific inventory management (handled by Goods Inventory Service)
- Travel-specific inventory management (handled by Travel Inventory Service)
- Live-event inventory management (handled by GLive Inventory Service)
- Coupon/CLO inventory management (handled by CLO Service / Coupons Inventory)
- Deal creation and creative content (handled by Deal Service / Deal Management API)
- Order processing and payment (handled by Orders service)
- Partner onboarding and contract management (handled externally)

## Domain Context

- **Business domain**: Inventory & Vouchers
- **Platform**: Continuum (Groupon's core commerce engine)
- **Upstream consumers**: Lazlo API Gateway, Deal Service, Deal Management API, CLO Service, Breakage Reduction Service, Calendar Service, CS Groupon WebApp, iTier 3PIP, MyGroupons, Mailman, MDS Feed Job, Message2Ledger, SPOG Gateway, Unit Tracer
- **Downstream dependencies**: 3rd-Party Inventory Systems (external partner platforms), 3rd Party Inventory DB (MySQL), EDW, BigQuery

## Stakeholders

| Role | Description |
|------|-------------|
| Inventory Team | Owns and operates the service, manages partner inventory integration |
| Partner Integration Team | Coordinates with external partners whose inventory flows through TPIS |
| Deal Operations | Uses TPIS data to power third-party deal availability on the platform |
| Analytics / Data Engineering | Consumes replicated data in EDW and BigQuery for reporting and insights |
| Consumer Experience Teams | Depend on TPIS data for displaying partner inventory in MyGroupons and booking flows |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | -- | containers.dsl: "Java" |
| Framework | -- | -- | Not specified in architecture DSL |
| Runtime | JVM | -- | Inferred from Java |
| Build tool | -- | -- | Not discoverable from architecture DSL |
| Package manager | -- | | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| JDBC Driver | -- | db-client | MySQL database connectivity for reading and writing inventory data |

> Only the most important libraries are listed here -- the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
