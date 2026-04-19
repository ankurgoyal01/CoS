---
service: "voucher-inventory-service"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 9
internal_count: 2
---

# Integrations

## Overview

The Voucher Inventory Service integrates with 9 external Continuum platform services via synchronous HTTPS/JSON calls and asynchronous JMS/ActiveMQ events. Internally, the service coordinates between its API and Workers containers through shared databases and the message bus. External integrations cover order management, pricing, deal catalog, merchant data, geospatial validation, booking, physical goods fulfillment, GDPR compliance, feature experimentation, and data warehousing.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Merchant Service | HTTPS/JSON | Merchant and redemption location data for vouchers | yes | `continuumMerchantService` |
| JTier Service | HTTPS/JSON | Product availability and configuration checks (post-migration) | yes | `continuumJtierService` |
| Goods Central Service | HTTPS/JSON, JMS | Physical goods fulfillment coordination for eligible products | no | `continuumGoodsCentralService` |
| Geo Service | HTTPS/JSON | Distance calculation and redemption location validation | no | `continuumGeoService` |
| Booking Appointments Service | HTTPS/JSON | Booking creation and confirmation for voucher-linked appointments | no | `continuumBookingService` |
| Enterprise Data Warehouse (EDW) | Batch ETL/S3 | Daily analytical snapshot exports and historical data corrections | no | `continuumEdw` |
| Reading Rainbow | HTTPS/JSON | Feature flag and experiment evaluation for voucher flows | no | `continuumReadingRainbow` |
| GDPR Service | JMS/ActiveMQ | Right-to-forget event consumption for PII anonymization | yes | `continuumGdprService` |
| Shipping Service | JMS/ActiveMQ | Shipping tracking confirmation event consumption | no | `continuumShippingService` |

### Merchant Service Detail

- **Protocol**: HTTPS/JSON
- **Base URL / SDK**: Ruby `MerchantServiceClient` and related helpers
- **Auth**: Internal service-to-service authentication
- **Purpose**: Provides merchant details, location information, and feature country data needed during voucher redemption flows
- **Failure mode**: Redemption flows that require merchant/location validation will fail
- **Circuit breaker**: Expected (standard Continuum service client pattern)

### JTier Service Detail

- **Protocol**: HTTPS/JSON
- **Base URL / SDK**: Ruby `JTierClient` and associated HTTP client configuration
- **Auth**: Internal service-to-service authentication
- **Purpose**: Product availability and configuration APIs that were migrated from VIS to JTier; VIS delegates these checks post-migration
- **Failure mode**: Product availability checks will fail, impacting inventory product operations
- **Circuit breaker**: Expected (standard Continuum service client pattern)

### Goods Central Service Detail

- **Protocol**: HTTPS/JSON (API calls from VIS API), JMS/ActiveMQ (shipping events to VIS Workers)
- **Base URL / SDK**: Ruby `GoodsCentral::ServiceClient`
- **Auth**: Internal service-to-service authentication
- **Purpose**: Coordinates EMEA physical goods fulfillment and shipping for eligible inventory products
- **Failure mode**: Physical goods fulfillment requests will fail; non-physical vouchers unaffected
- **Circuit breaker**: Expected (standard Continuum service client pattern)

### Geo Service Detail

- **Protocol**: HTTPS/JSON
- **Base URL / SDK**: Ruby `GeoServiceClient`, `GeoServiceIntegration`
- **Auth**: Internal service-to-service authentication
- **Purpose**: Validates merchant redemption locations and computes geospatial distances for location-based redemption constraints
- **Failure mode**: Location-constrained redemptions may fail or fall back to unconstrained behavior
- **Circuit breaker**: Expected (standard Continuum service client pattern)

### Booking Appointments Service Detail

- **Protocol**: HTTPS/JSON
- **Base URL / SDK**: Ruby `BookingAppointments::ServiceClient`, `BookingIntegration`
- **Auth**: Internal service-to-service authentication
- **Purpose**: Creates and confirms appointment bookings that are tied to voucher units
- **Failure mode**: Booking-linked voucher operations will fail; standard voucher flows unaffected
- **Circuit breaker**: Expected (standard Continuum service client pattern)

### Enterprise Data Warehouse (EDW) Detail

- **Protocol**: Batch ETL/S3
- **Base URL / SDK**: Ruby `EDWExporter` and ETL rake tasks
- **Auth**: AWS credentials for S3 access
- **Purpose**: Builds daily VIS analytical snapshots and uploads them to S3 for ingestion into the Enterprise Data Warehouse
- **Failure mode**: Analytics data will be stale until next successful export
- **Circuit breaker**: Not applicable (batch process)

### Reading Rainbow Detail

- **Protocol**: HTTPS/JSON
- **Base URL / SDK**: Ruby `ExperimentationIntegration`, `ReadingRainbow::ServiceClient`
- **Auth**: Internal service-to-service authentication
- **Purpose**: Evaluates feature flags and experiments that gate voucher flow behavior (e.g., new redemption logic, UI experiments)
- **Failure mode**: Feature flags may default to off/control, disabling experimental features
- **Circuit breaker**: Expected (standard Continuum service client pattern)

### GDPR Service Detail

- **Protocol**: JMS/ActiveMQ (event consumption)
- **Base URL / SDK**: Message bus consumer (`RightToForgetListener`, `RightToForgetWorkerJob`)
- **Auth**: JMS broker credentials
- **Purpose**: Consumes right-to-forget events to trigger PII anonymization across voucher and order data in VIS databases
- **Failure mode**: GDPR anonymization requests will queue in DLQ until workers recover
- **Circuit breaker**: Not applicable (async event consumption)

### Shipping Service Detail

- **Protocol**: JMS/ActiveMQ (event consumption)
- **Base URL / SDK**: Message bus consumer (`Goods::ShippingDetailsUpdateListener`)
- **Auth**: JMS broker credentials
- **Purpose**: Consumes shipping tracking confirmation events to update shipment tracking for physical voucher units
- **Failure mode**: Tracking information updates will be delayed; voucher units remain functional
- **Circuit breaker**: Not applicable (async event consumption)

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Voucher Inventory API | REST/HTTP | Primary API container serving synchronous requests | `continuumVoucherInventoryApi` |
| Voucher Inventory Workers | Background processing | Async event consumption, reconciliation, backfills, publishing | `continuumVoucherInventoryWorkers` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. Known consumers based on the architecture DSL include:
> - Orders Service (`orders_api`) -- calls VIS for reservation and unit operations during checkout
> - Third-party inventory systems (`thirdPartyInventory`) -- integrates via redemption code pools
> - Internal analytics and reporting pipelines -- consume VIS domain events and EDW exports

## Dependency Health

The Voucher Inventory Service uses standard Continuum service client patterns for dependency health management:
- **Health checks**: The Status & Health API (`continuumVoucherInventoryApi_statusAndHealthApi`) exposes `/status` and `/healthcheck` endpoints that verify connectivity to databases, Redis, and the message bus
- **Retry logic**: HTTP service clients (Orders, Pricing, Deal Catalog, Merchant, JTier, Goods Central, Geo, Booking) implement retry with backoff
- **Distributed locking**: Redis-backed locks (`continuumVoucherInventoryApi_cacheAccessors`) prevent concurrent modifications to the same inventory unit
- **DLQ processing**: The Dead Letter Queue Processor (`continuumVoucherInventoryWorkers_dlqProcessor`) handles failed message consumption with retry, archive, and manual review strategies
- **Reconciliation**: Dedicated reconciliation workers (`continuumVoucherInventoryWorkers_reconciliationWorkers`) detect and correct unit status drift against the Orders service
