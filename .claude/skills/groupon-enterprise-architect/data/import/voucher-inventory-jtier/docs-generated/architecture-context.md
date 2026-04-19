---
service: "voucher-inventory-jtier"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
    - continuumVoucherInventoryApi
    - continuumVoucherInventoryWorker
    - continuumVoucherInventoryProductDb
    - continuumVoucherInventoryUnitsDb
    - continuumVoucherInventoryRwDb
    - continuumVoucherInventoryRedis
    - continuumVoucherInventoryTelegraf
---

# Architecture Context

## System Context

Voucher Inventory JTier is a core service within the `continuumSystem` (Continuum Platform), Groupon's commerce engine. It sits between upstream consumer clients (Deal Estate, Deal Wizard, and other product-display services) and downstream data sources (MySQL databases, Redis cache, Pricing Service, Calendar Service, and MessageBus). The service operates in a SOX-compliant scope and supports US/EU regions. It is one of the highest-throughput services in Groupon at approximately 800K RPM.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Voucher Inventory JTier API | `continuumVoucherInventoryApi` | API | Java 11, Dropwizard/JTier | 5.14.0 | HTTP API serving inventory products, pricing, availability, and acquisition methods |
| Voucher Inventory JTier Worker | `continuumVoucherInventoryWorker` | Worker | Java 11, Dropwizard/JTier, Quartz | 5.14.0 | Background workers for MessageBus processing, replenishment, and unit redeem jobs |
| Voucher Inventory Product DB | `continuumVoucherInventoryProductDb` | Database | MySQL | N/A | Product and inventory data store |
| Voucher Inventory Units DB | `continuumVoucherInventoryUnitsDb` | Database | MySQL | N/A | Units and voucher barcode data store |
| Voucher Inventory RW DB | `continuumVoucherInventoryRwDb` | Database | MySQL | N/A | Writable store for replenishment schedules, acquisition methods, and feature controls |
| Voucher Inventory Redis (RaaS) | `continuumVoucherInventoryRedis` | Cache | Redis | N/A | Cache for inventory products and unit sold counts |
| Voucher Inventory Telegraf | `continuumVoucherInventoryTelegraf` | Observability | Telegraf | N/A | Metrics sidecar collecting application metrics and forwarding to the observability pipeline |

## Components by Container

### Voucher Inventory JTier API (`continuumVoucherInventoryApi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Resources | JAX-RS resources for inventory products and acquisition methods | JAX-RS |
| Inventory Product Service | Core business logic for inventory products, pricing, and cache management | Java Service |
| Acquisition Method Service | Business logic for acquisition method management and caching | Java Service |
| Pricing Client | HTTP client for Pricing Service | OkHttp/Retrofit |
| Booking Client | HTTP client for Calendar Service availability endpoints | OkHttp/Retrofit |
| MessageBus Publisher | Publishes inventory product update events | MessageBus |
| Inventory DAOs | JDBI DAOs for inventory products, units, and feature controls | JDBI |
| Redis Cache Client | RaaS client for inventory caches | Jedis |
| Health Checks | Health checks and status endpoints | Dropwizard |

### Voucher Inventory JTier Worker (`continuumVoucherInventoryWorker`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| MessageBus Consumer | Consumes inventory and order topics from MessageBus | MessageBus |
| Message Processors | Processes inventory update and sold-out messages | MessageBus Processors |
| Inventory Processing Service | Applies inventory updates and cache refresh logic | Java Service |
| Replenishment Job | Quartz job for replenishment schedule processing | Quartz |
| Unit Redeem Job | Quartz job that pulls and processes unit redeem files | Quartz |
| Legacy VIS Client | HTTP client to legacy Voucher Inventory Service endpoints | OkHttp/Retrofit |
| SFTP Client | Client for Groupon Transfer SFTP | SFTP/JSch |
| Inventory DAOs | JDBI DAOs for inventory products, units, and replenishment schedules | JDBI |
| Redis Cache Client | RaaS client for inventory caches | Jedis |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumVoucherInventoryApi` | `continuumVoucherInventoryProductDb` | Reads inventory products | JDBI/MySQL |
| `continuumVoucherInventoryApi` | `continuumVoucherInventoryUnitsDb` | Reads units and barcode data | JDBI/MySQL |
| `continuumVoucherInventoryApi` | `continuumVoucherInventoryRwDb` | Writes feature controls and acquisition methods when enabled | JDBI/MySQL |
| `continuumVoucherInventoryApi` | `continuumVoucherInventoryRedis` | Reads and writes cached inventory data | Redis |
| `continuumVoucherInventoryApi` | `continuumPricingService` | Fetches pricing and updates feature controls | HTTP |
| `continuumVoucherInventoryApi` | `continuumCalendarService` | Fetches availability and segments | HTTP |
| `continuumVoucherInventoryApi` | `messageBus` | Publishes inventory product updates | MBus/JMS |
| `continuumVoucherInventoryApi` | `continuumVoucherInventoryTelegraf` | Emits metrics | StatsD/UDP |
| `continuumVoucherInventoryWorker` | `messageBus` | Consumes inventory and order topics | MBus/JMS |
| `continuumVoucherInventoryWorker` | `continuumVoucherInventoryProductDb` | Reads inventory products and schedules | JDBI/MySQL |
| `continuumVoucherInventoryWorker` | `continuumVoucherInventoryUnitsDb` | Reads units and barcode data | JDBI/MySQL |
| `continuumVoucherInventoryWorker` | `continuumVoucherInventoryRwDb` | Writes replenishment schedules and acquisition methods | JDBI/MySQL |
| `continuumVoucherInventoryWorker` | `continuumVoucherInventoryRedis` | Reads and writes cached inventory data | Redis |
| `continuumVoucherInventoryWorker` | `continuumVoucherInventoryTelegraf` | Emits metrics | StatsD/UDP |

## Architecture Diagram References

- System context: `contexts-continuumVoucherInventory`
- Container: `containers-continuumVoucherInventory`
- Component (API): `components-voucherInventoryApi`
- Component (Worker): `components-voucherInventoryWorker`
