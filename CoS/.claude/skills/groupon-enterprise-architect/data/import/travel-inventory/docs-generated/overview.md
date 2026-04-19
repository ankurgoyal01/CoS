---
service: "travel-inventory"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Getaways / Travel Inventory"
platform: "Continuum"
team: "Getaways Inventory"
status: active
tech_stack:
  language: "Java"
  language_version: "8"
  framework: "Jersey / Skeletor"
  framework_version: ""
  runtime: "Tomcat"
  runtime_version: ""
  build_tool: "Maven (assumed)"
  package_manager: "Maven"
---

# Getaways Inventory Service Overview

## Purpose

Getaways Inventory Service is the central inventory management backend for Groupon's Getaways (travel/hotel) vertical. It owns the full lifecycle of hotel inventory: creating and managing hotels, room types, rate plans, availability calendars, pricing, reservations, and daily reporting. The service powers both the Extranet (merchant-facing) and Shopping (consumer-facing) sides of the Getaways experience, and acts as the coordination hub between content, reservation, and voucher systems.

## Scope

### In scope

- Hotel inventory CRUD operations (hotels, room types, rate plans, product sets, taxes, booking fees)
- Consumer shopping flows: availability summary, availability detail, calendar availability, Unity product APIs
- Reservation creation, cancellation, and reverse fulfilment
- OTA (OpenTravel Alliance) inventory and rate update ingestion
- Connect hierarchy mapping for channel managers and external systems
- Backfill jobs for inventory product data
- Audit logging of inventory changes
- Daily inventory report generation and SFTP export
- Caching of hotel product details, inventory products, and Backpack availability
- Integration with Backpack Reservation Service for itinerary and reservation events
- Integration with Content Service for hotel contact and localized content
- Integration with Voucher Inventory Service for voucher-based inventory flows
- Multi-currency pricing via Forex Service
- Worker/task management for background processing

### Out of scope

- Hotel content authoring and media management (handled by `continuumContentService`)
- Voucher generation and lifecycle (handled by `continuumVoucherInventoryService`)
- Consumer-facing UI rendering (handled by downstream presentation services)
- Payment processing (handled by order/payment services)
- Foreign exchange rate management (handled by Forex Service / `forex-ng`)
- Itinerary and reservation storage of record (handled by `continuumBackpackReservationService`)

## Domain Context

- **Business domain**: Getaways / Travel Inventory
- **Platform**: Continuum
- **Upstream consumers**: Getaways Extranet UI, consumer shopping services, channel managers via Connect API, OTA partners, internal tooling
- **Downstream dependencies**: Getaways Content Service, Backpack Reservation Service, Voucher Inventory Service, Forex Service, Message Bus, AWS SFTP Transfer

## Stakeholders

| Role | Description |
|------|-------------|
| Getaways Inventory Team | Service owners responsible for development and operations |
| Getaways Merchant Operations | Uses Extranet APIs for hotel, room type, and rate plan management |
| Getaways Consumer Experience | Consumes shopping APIs for availability and booking flows |
| Channel Management / OTA Partners | Uses Connect and OTA APIs for inventory synchronization |
| Finance / Reporting | Consumes daily inventory report CSV files via SFTP |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 8 | Architecture DSL |
| Framework | Jersey / Skeletor | -- | Architecture DSL |
| Runtime | Tomcat on GCP | -- | Architecture DSL |
| Build tool | Maven | -- | Assumed from Java/Tomcat stack |
| Package manager | Maven | -- | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Jersey | -- | http-framework | JAX-RS REST framework for HTTP endpoint definitions |
| Skeletor | -- | http-framework | Groupon internal microservice framework for Java services |
| Ebean ORM | -- | orm | Object-relational mapping for MySQL data access |
| Flyway | -- | db-client | Database migration management |
| Redis client | -- | db-client | Client for Hotel Product Detail Cache and Inventory Product Cache |
| Memcached client | -- | db-client | Client for Backpack Availability Cache |
| MBus (JMS/STOMP) | -- | message-client | Groupon message bus client for async event publish/consume |
| SFTP client | -- | integration | SSH-based file transfer for daily report export |
| Log4j2 | -- | logging | Application logging framework |
| Jersey Client | -- | http-framework | Outbound HTTP client for cross-service REST calls |

> Only the most important libraries are listed here -- the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
