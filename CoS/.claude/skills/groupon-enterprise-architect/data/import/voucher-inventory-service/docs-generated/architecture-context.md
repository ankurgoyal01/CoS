---
service: "voucher-inventory-service"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumVoucherInventoryService", "continuumVoucherInventoryApi", "continuumVoucherInventoryWorkers", "continuumVoucherInventoryDb", "continuumVoucherInventoryUnitsDb", "continuumVoucherInventoryRedisCache", "continuumVoucherInventoryMessageBus"]
---

# Architecture Context

## System Context

The Voucher Inventory Service sits within the Continuum Platform (`continuumSystem`), Groupon's core commerce engine. It is a critical inventory domain service that manages voucher product configuration and unit lifecycle. The API container handles synchronous HTTP requests from upstream services (Orders, checkout, merchant tools) and coordinates with downstream services for pricing, deal metadata, merchant data, geo validation, booking, and fulfillment. The Workers container processes asynchronous events from the message bus, performs reconciliation, backfills, GDPR anonymization, and publishes domain events to downstream consumers.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| Voucher Inventory Service | `continuumVoucherInventoryService` | Logical | JRuby, Rails, Sidekiq | Logical aggregation of API and Workers as a single service in Continuum diagrams |
| Voucher Inventory API | `continuumVoucherInventoryApi` | Application | JRuby, Rails | Primary REST API handling inventory product and unit operations (owned by voucher-inventory-jtier) |
| Voucher Inventory Workers | `continuumVoucherInventoryWorkers` | Application | JRuby, Sidekiq, ActiveMessaging | Background processing for message bus consumption, async publishing, backfills, and reconciliation jobs |
| Voucher Inventory DB | `continuumVoucherInventoryDb` | Database | MySQL (AWS RDS) | Primary relational database for product-level configuration including inventory products, consumer contracts, and redemption policies |
| Voucher Inventory Units DB | `continuumVoucherInventoryUnitsDb` | Database | MySQL (AWS RDS) | Relational database for inventory units, unit redemptions, and order mappings (owned by voucher-inventory-jtier) |
| Voucher Inventory Redis Cache | `continuumVoucherInventoryRedisCache` | Cache | Redis (AWS ElastiCache) | Redis cache and queue backend for distributed locking, temporary data storage, rate limiting, and Sidekiq job queues |
| Voucher Inventory Message Bus | `continuumVoucherInventoryMessageBus` | Messaging | Apache ActiveMQ, JMS | Message broker for publishing and consuming domain events for inventory products, units, redemptions, and integrations |

## Components by Container

### Voucher Inventory API (`continuumVoucherInventoryApi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Status & Health API | Exposes heartbeat, healthcheck, and basic environment/status endpoints | Ruby on Rails controllers (`StatusesController`) |
| Inventory Products API | REST APIs for managing and querying inventory products, quantity summaries, and configuration across v1 and v2 namespaces | Ruby on Rails controllers (`V1::InventoryProductsController`, `V2::InventoryProductsController`) |
| Units & Redemptions API | APIs for voucher units search, status updates, and redemption lifecycle operations including bulk updates and GDPR-aware flows | Ruby on Rails controllers (`Inventory::V1::InventoryUnitsController`, `Inventory::V2::UnitsController`, `Inventory::V2::RedemptionsController`) |
| Reservation API | Reservation endpoints used during checkout to reserve inventory against orders with pricing and policy validation | Ruby on Rails controllers and presenters for `/inventory/v1/reservation` |
| Redemption Code Pools API | APIs for managing third-party redemption code pools, uploads, and quantity summaries | Ruby on Rails controllers (`V1::RedemptionCodePoolsController`, `V2::RedemptionCodePools::QuantitySummaryController`, `V2::RedemptionCodePools::UploadsController`) |
| Features & Config API | Internal APIs for feature flag inspection and configuration reload of VIS runtime behavior | Ruby on Rails controllers (`FeaturesController`, `ConfigController`) |
| Inventory Product Manager | Domain service managing inventory product lifecycle, attributes, pricing integration, and synchronization with deal catalog | Ruby module `InventoryProductManager` |
| Inventory Unit Manager | Domain service managing voucher unit lifecycle including reservations, redemptions, gifting, refunds, expirations, booking, and GDPR flows | Ruby module `InventoryUnitManager` |
| Redemption Code Pool Manager | Domain service for managing third-party redemption code pools, thresholds, and consumption metrics | Ruby classes `RedemptionCodePoolManager`, `RedemptionCodePoolAccessor` |
| Booking Appointments Manager | Coordinates voucher bookings and appointment windows with the Booking Appointments service | Ruby `BookingAppointmentsManager` |
| Voucher Barcode Reports Service | Generates voucher barcode status reports and orchestrates background jobs to publish CSVs to S3 | Ruby class `VoucherBarcodeReportsService` |
| Inventory Data Accessors | Data access layer for inventory products, units, redemption pools, quantity summaries, and related entities backed by MySQL | Ruby data accessor classes under `app/data_accessors` and ActiveRecord models |
| Cache & Lock Accessors | Provides Redis-backed caching, distributed locks, and counters for VIS operations | Ruby `CacheAccessor`, `RedisClient`, `CacheLock` |
| Orders Client | HTTP client and mappers for the Orders Service used to fetch order details, sync status, and reconcile payments | Ruby `OrdersClient`, `Orders::ServiceClient` |
| Pricing Client | Client for the Pricing Service, handling dynamic pricing updates, retries, and local caching | Ruby `PricingService::ServiceClient`, `PricingClient` |
| Deal Catalog Client | Client and listeners for Deal Catalog service to synchronize deal metadata, creative content, and redemption instructions | Ruby `DealCatalogService`, `DealCatalog::ServiceClient` |
| Merchant Service Client | Client for Merchant Service providing merchant, location, and feature country data for redemption flows | Ruby `MerchantServiceClient` |
| JTier Client | Client for JTier Service that now owns product availability and configuration APIs | Ruby `JTierClient` |
| Goods Central Client | Integration with Goods Central for EMEA physical goods fulfillment and shipping coordination | Ruby `GoodsCentral::ServiceClient` |
| Geo Service Client | Integration with Geo Service to validate merchant redemption locations and compute geospatial distances | Ruby `GeoServiceClient`, `GeoServiceIntegration` |
| Booking Service Client | Client for Booking Appointments service used to create and confirm bookings tied to vouchers | Ruby `BookingAppointments::ServiceClient`, `BookingIntegration` |
| EDW Exporter | Batch ETL exporter that builds daily VIS snapshots and uploads them to S3 and the Enterprise Data Warehouse | Ruby `EDWExporter` and ETL rake tasks |
| Experimentation Integration | Integration with Reading Rainbow experimentation service to evaluate feature flags and experiments | Ruby `ExperimentationIntegration`, `ReadingRainbow::ServiceClient` |
| Inventory Products Message Producer | Publishes inventory product update events to ActiveMQ topics for downstream consumers | Ruby class `InventoryProductsMessageProducer` |
| Observability & Logging | Centralized logging, metrics, APM, and tracing integration for VIS Rails pods | Ruby `ApplicationLogger`, `WorkerLogger`, New Relic, Wavefront, ELK |

### Voucher Inventory Workers (`continuumVoucherInventoryWorkers`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Orders Events Listener | Consumes order-related events from the message bus to update voucher unit status, handle promise refunds, and reconcile payments | Ruby workers (`Orders::UnitsStatusUpdateListener`, `Orders::TradeinStatusListener`) |
| Voucher Inventory Events Listener | Consumes internal voucher inventory events to update sold counts, cache summaries, and propagate unit changes | Ruby workers (`VoucherInventory::SoldCountListener`, `VoucherInventory::BarcodeCountListener`) |
| Goods Shipping Listener | Processes shipping-related events to update shipment tracking information for physical voucher units | Ruby worker `Goods::ShippingDetailsUpdateListener` |
| GDPR & Right-To-Forget Listener | Consumes GDPR right-to-forget events and orchestrates PII anonymization for voucher and order data | Ruby workers `RightToForgetListener`, `RightToForgetWorkerJob` |
| Backfill Workers | Run targeted and bulk backfill operations for inventory products, units, and related aggregates | Ruby backfill jobs, rake tasks (`record_backfill`, `sold_count_backfill`, `db_backfill`) |
| Reconciliation Workers | Reconcile inventory unit status against Orders service, handling missed updates and cancelations | Ruby workers (`ReconcileUnitsStatusWorker`, `ReconsiderFailedMessagesWorker`) |
| Async Publishers | Asynchronously publish VIS domain events to downstream services via message bus and Sidekiq-backed queues | Ruby jobs using `AsyncClient`, `Background::Queue` |
| Dead Letter Queue Processor | Processes failed messages from DLQs, applying retry, archive, and manual review strategies | Ruby `DLQProcessor` and error-handling workers |
| Record Backfill Runner | Coordinates batch backfill processing for large data migrations and historical corrections | Ruby `RecordBackfill::Runner`, `RecordBackfill::Worker` |
| Message Bus Swarm | Manages clustered message bus workers and swarm configuration for high-volume JMS topics | Ruby tasks under `messagebus_swarm.rake` |
| Workers Observability & Logging | Logging, metrics, and monitoring for background workers including queue depth, lag, and error tracking | Ruby `WorkerLogger`, Wavefront/New Relic instrumentation |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumVoucherInventoryApi` | `continuumVoucherInventoryDb` | Reads and writes product configuration, consumer contracts, and redemption policies | ActiveRecord/JDBC |
| `continuumVoucherInventoryApi` | `continuumVoucherInventoryUnitsDb` | Reads and writes inventory units, unit redemptions, and order mappings | ActiveRecord/JDBC |
| `continuumVoucherInventoryApi` | `continuumVoucherInventoryRedisCache` | Uses for caching, distributed locking, and rate limiting | Redis client |
| `continuumVoucherInventoryApi` | `continuumVoucherInventoryMessageBus` | Publishes VIS domain events (products, units, redemptions, code pools) | JMS/ActiveMQ |
| `continuumVoucherInventoryApi` | `continuumMerchantService` | Retrieves merchant and redemption location data for vouchers | HTTPS/JSON |
| `continuumVoucherInventoryApi` | `continuumJtierService` | Delegates product availability and configuration checks after migration | HTTPS/JSON |
| `continuumVoucherInventoryApi` | `continuumGoodsCentralService` | Coordinates physical goods fulfillment for eligible inventory products | HTTPS/JSON |
| `continuumVoucherInventoryApi` | `continuumGeoService` | Calculates distances and validates redemption locations | HTTPS/JSON |
| `continuumVoucherInventoryApi` | `continuumBookingService` | Creates and confirms bookings associated with voucher units | HTTPS/JSON |
| `continuumVoucherInventoryApi` | `continuumEdw` | Exports analytical snapshots and metrics | Batch ETL/S3 |
| `continuumVoucherInventoryApi` | `continuumReadingRainbow` | Evaluates feature flags and experiments for voucher flows | HTTPS/JSON |
| `continuumVoucherInventoryWorkers` | `continuumVoucherInventoryDb` | Performs backfill and batch maintenance operations | ActiveRecord/JDBC |
| `continuumVoucherInventoryWorkers` | `continuumVoucherInventoryUnitsDb` | Updates voucher unit status and reconciliations | ActiveRecord/JDBC |
| `continuumVoucherInventoryWorkers` | `continuumVoucherInventoryRedisCache` | Uses for worker coordination, locks, and cached aggregates | Redis client |
| `continuumVoucherInventoryWorkers` | `continuumVoucherInventoryMessageBus` | Consumes and republishes VIS and external domain events | JMS/ActiveMQ |
| `continuumVoucherInventoryWorkers` | `continuumGoodsCentralService` | Processes shipping and fulfillment events | JMS/ActiveMQ |
| `continuumVoucherInventoryWorkers` | `continuumGdprService` | Consumes right-to-forget completion events | JMS/ActiveMQ |
| `continuumVoucherInventoryWorkers` | `continuumShippingService` | Consumes shipping tracking confirmation events | JMS/ActiveMQ |
| `continuumVoucherInventoryWorkers` | `continuumEdw` | Coordinates long-running exports and data corrections | Batch ETL |

## Architecture Diagram References

- Container: `containers-continuum-voucher-inventory`
- Component (API): `components-continuum-voucher-inventory-api`
- Component (Workers): `components-continuum-voucher-inventory-workers`
