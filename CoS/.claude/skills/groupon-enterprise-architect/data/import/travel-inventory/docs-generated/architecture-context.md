---
service: "travel-inventory"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumTravelInventoryService, continuumTravelInventoryCron, continuumTravelInventoryDb, continuumTravelInventoryHotelProductCache, continuumTravelInventoryInventoryProductCache, continuumBackpackAvailabilityCache, continuumAwsSftpTransfer, continuumContentService, continuumBackpackReservationService]
---

# Architecture Context

## System Context

Getaways Inventory Service lives within Groupon's **Continuum** platform -- the core commerce engine. It is the authoritative backend for hotel inventory, room types, rate plans, availability, and reservation management in the Getaways vertical. The service exposes REST APIs consumed by Extranet UIs (merchant-facing), consumer shopping services, OTA partners, and channel managers. It depends on Content Service for hotel content, Backpack Reservation Service for reservation workflows, Voucher Inventory Service for voucher-based inventory, Forex Service for multi-currency pricing, and the Groupon message bus for async event processing. A companion Python cron container triggers daily inventory report generation.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Getaways Inventory Service | `continuumTravelInventoryService` | Web Application / API | Java 8, Jersey, Skeletor, Tomcat on GCP | -- | Primary HTTP API for hotel inventory, room types, rate plans, bookings, calendar availability, OTA updates, audit, and worker/task endpoints |
| Getaways Inventory Daily Report Cron | `continuumTravelInventoryCron` | Batch / Cron | Python 3.8, Requests | -- | Python cron job that periodically triggers generation of daily inventory reports via the Getaways Inventory Service API |
| Getaways Inventory DB | `continuumTravelInventoryDb` | Database | MySQL | -- | Stores hotel inventory, room types, rate plans, availability, audit logs, worker tasks, and reporting data |
| Hotel Product Detail Cache | `continuumTravelInventoryHotelProductCache` | Cache | Redis | -- | Redis cache for hotel product detail data used during shopping and availability queries |
| Inventory Product Cache | `continuumTravelInventoryInventoryProductCache` | Cache | Redis | -- | Redis cache for inventory product snapshots used during shopping and booking flows |
| Backpack Availability Cache | `continuumBackpackAvailabilityCache` | Cache | Memcached | -- | Memcached cache holding Backpack availability results to speed up subsequent shopping requests |
| AWS SFTP Transfer | `continuumAwsSftpTransfer` | Storage / Transfer | SFTP | -- | Managed SFTP endpoint where daily inventory report CSV files are pushed for downstream consumption |
| Getaways Content Service | `continuumContentService` | Backend Service | HTTP, JSON | -- | External content service providing hotel contact details and localized content for Getaways inventory |
| Backpack Reservation Service | `continuumBackpackReservationService` | Backend Service | HTTP, JSON, MBus | -- | External itinerary and reservation service (Backpack/TIS) that receives reservation and cancel events and exposes reservation APIs |

## Components by Container

### Getaways Inventory Service (`continuumTravelInventoryService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Extranet API | REST endpoints for hotel, room type, rate plan, product set, tax, booking fee and related Extranet operations under `/v2/getaways/inventory/*` | Java, Jersey, Skeletor |
| Shopping API | REST endpoints for consumer shopping flows including availability summary/detail, calendars, Unity product APIs, reservations and reverse fulfilment | Java, Jersey, Skeletor |
| Connect API | REST endpoints exposing inventory hierarchy mappings for channel managers and external systems | Java, Jersey, Skeletor |
| Backfill API | REST endpoints to configure and trigger backfill jobs for inventory products | Java, Jersey, Skeletor |
| OTA Update API | REST endpoints for OTA (OpenTravel Alliance) inventory and rate updates under `/v2/getaways/inventory/ota` | Java, Jersey, Skeletor |
| Audit API | REST endpoints for querying inventory-related audit logs | Java, Jersey, Skeletor |
| Worker API | Internal worker endpoints for managing background tasks and triggering daily inventory report generation | Java, Jersey, Skeletor |
| Configuration API | Endpoints to update application configuration in development environments | Java, Jersey, Skeletor |
| Operational Utility API | Utility endpoints for database status and logging level diagnostics | Java, Jersey, Skeletor |
| Extranet Domain Services | Domain managers handling Extranet hotel, room type, rate plan, inventory, product set, tax, value-add and booking fee business logic | Java |
| Shopping Domain Services | Domain managers for shopping availability, pricing, booking flows, Unity integration and preshopping processing | Java |
| Connect Hierarchy Services | Domain managers and mappers for Connect hierarchy requests and responses | Java |
| OTA Domain Services | Domain managers that transform OTA rate and inventory updates into internal inventory structures | Java |
| Audit Domain Services | Domain services that construct and query audit log entries for inventory changes | Java |
| Worker Domain Services | Managers and task framework for background worker tasks including daily inventory report generation | Java |
| Persistence Layer | Ebean/Hibernate repositories, Flyway-managed migrations, and database role routing for read, write, audit and reporting workloads | Java, Ebean ORM, Flyway, MySQL |
| Domain Entities | Inventory domain entity model including hotels, room types, rate plans, restrictions, fees, report jobs and worker entities | Java |
| Caching Layer | In-memory and Redis-based caching for hotel product details, inventory products, lookup tables and localization helpers | Java, Redis, In-memory |
| Backpack Memcache Integration | Memcache integration for storing and retrieving Backpack availability entries during shopping flows | Java, Memcached |
| External HTTP Clients | HTTP client abstractions for Content Service, Voucher Inventory Service, Custom Fields Service, User Service and other REST integrations | Java, Jersey Client |
| Forex Client | Client for fetching foreign exchange rates from the Forex Service for multi-currency pricing | Java, HTTP |
| Message Bus Integration | Producers and consumers that publish and consume reservation, cancel, order status and worker task messages via MBus | Java, MBus |
| AWS SFTP Client | SFTP client for transferring generated daily inventory report files to the AWS SFTP Transfer endpoint | Java, SFTP |
| Configuration & Environment | AppConfig and ConfigReader-based configuration loading for environments, database roles, feature flags and external endpoints | Java |
| Metrics & Logging | Logging and metrics components including DB metrics schedulers, connection pool metrics, Log4j2 and application-level event logging | Java, Log4j2 |

### Getaways Inventory Daily Report Cron (`continuumTravelInventoryCron`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Daily Inventory Report Cron Job | Command-line entrypoint and scheduler that triggers the Getaways Inventory Daily Inventory Reporter endpoint on a schedule | Python 3.8, argparse |
| HTTP Client (Requests) | HTTP client wrapper using the Requests library to invoke `/v2/getaways/inventory/reporter/generate` on the Getaways Inventory Service | Python, Requests |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumTravelInventoryService` | `continuumTravelInventoryDb` | Reads from and writes to inventory, rate plans, room types, audit logs, worker and reporting tables | JDBC, Ebean ORM |
| `continuumTravelInventoryService` | `continuumTravelInventoryHotelProductCache` | Caches hotel product detail data to improve read performance | Redis |
| `continuumTravelInventoryService` | `continuumTravelInventoryInventoryProductCache` | Caches inventory product data to speed up shopping and booking flows | Redis |
| `continuumTravelInventoryService` | `continuumBackpackAvailabilityCache` | Stores and retrieves Backpack availability entries during shopping flows | Memcached |
| `continuumTravelInventoryService` | `messageBus` | Publishes and consumes reservation, cancel, order status and worker task messages | MBus over JMS/STOMP |
| `continuumTravelInventoryService` | `continuumContentService` | Retrieves hotel contact and content information for inventory responses | HTTP, JSON |
| `continuumTravelInventoryService` | `continuumVoucherInventoryService` | Requests voucher-based inventory product information during availability and booking flows | HTTP, JSON |
| `continuumTravelInventoryService` | `continuumBackpackReservationService` | Sends reservation and cancel events and interacts with asynchronous reservation workflows | HTTP, JSON, MBus |
| `continuumTravelInventoryService` | `continuumAwsSftpTransfer` | Transfers generated daily inventory report CSV files | SFTP |
| `continuumTravelInventoryCron` | `continuumTravelInventoryService` | Invokes `/v2/getaways/inventory/reporter/generate` to trigger daily inventory report generation | HTTP, JSON |

## Architecture Diagram References

- System context: `contexts-travel-inventory`
- Container: `containers-travel-inventory`
- Component: `components-continuum-travel-inventory-service`
- Component: `components-continuum-travel-inventory-cron`
