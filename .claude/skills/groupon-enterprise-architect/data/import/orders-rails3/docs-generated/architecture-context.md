---
service: "orders-rails3"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumOrdersService, continuumOrdersWorkers, continuumOrdersDaemons, continuumOrdersDb, continuumFraudDb, continuumOrdersMsgDb, continuumRedis, continuumAnalyticsWarehouse, continuumIncentivesService]
---

# Architecture Context

## System Context

orders-rails3 sits within the **Continuum** commerce platform as the authoritative system for order state and payment collection. It is called by storefront and mobile clients to place and manage orders. Internally it depends on a mesh of Continuum services (users, deal catalog, voucher inventory, payments, fraud, geo, taxonomy, merchants) and external payment gateways. It publishes order lifecycle events to the shared Message Bus, which downstream analytics, billing, and notification systems consume.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Orders Service | `continuumOrdersService` | Backend API | Ruby on Rails 3 | Rails 3.2.22.5 | REST API handling order placement, payment, inventory, tax, and account redaction |
| Orders Workers | `continuumOrdersWorkers` | Background Workers | Ruby, Resque | 1.20.0 | Async job pool for collection, payments, fraud review, cancellations, and redaction |
| Orders Daemons | `continuumOrdersDaemons` | Scheduled/Cron | Ruby | — | Daemonized cron tasks for collection retries, delayed cancellations, exchange expirations |
| Orders DB | `continuumOrdersDb` | Database | MySQL/PostgreSQL | — | Primary relational store for orders, billing, payments, and inventory units |
| Fraud DB | `continuumFraudDb` | Database | MySQL/PostgreSQL | — | Fraud-specific data store; read during payment authorization and fraud review |
| Orders Messaging DB | `continuumOrdersMsgDb` | Database | MySQL/PostgreSQL | — | Persistence for order messages and transactional ledger events |
| Redis Cache/Queue | `continuumRedis` | Cache / Queue | Redis | — | Shared Redis for Resque job queues, distributed locks, and response caching |
| Analytics Warehouse | `continuumAnalyticsWarehouse` | Data Warehouse | Vertica | — | Analytics sink receiving reporting data extracts from Workers |
| Incentives Service | `continuumIncentivesService` | Backend Service | HTTP API | — | Internal incentives/credits service called during order checkout |

## Components by Container

### Orders Service (`continuumOrdersService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Orders REST Controllers (`continuumOrdersApi_ordersControllers`) | Handles orders, units, inventory, and user-specific order workflows | Ruby on Rails controllers |
| Payments & Transactions API (`continuumOrdersApi_paymentsControllers`) | Manages payments, payment events, transactions, refunds, and billing record interactions | Ruby on Rails controllers |
| Tax & Merchant Accounts API (`continuumOrdersApi_taxControllers`) | Handles merchant tax accounts and tax document commit flows | Ruby on Rails controllers |
| Account Redaction API (`continuumOrdersApi_accountRedactionApi`) | Orchestrates anonymization workflows and enqueues background redaction jobs | Ruby on Rails controllers |
| Message Bus Publishers (`continuumOrdersApi_messageBusPublishers`) | Builds and publishes order-related messages to Message Bus | Ruby, ActiveRecord |
| External Service Clients (`continuumOrdersApi_serviceClientsGateway`) | HTTP/REST clients to all downstream services and payment providers | Ruby, ServiceRequestFactory, HTTP |

### Orders Workers (`continuumOrdersWorkers`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Order Collection Workers (`continuumOrdersWorkers_orderCollectionWorkers`) | Order collection lifecycle: auth, priority auth, batch, and retry collection | Ruby, Resque |
| Payment & Transaction Workers (`continuumOrdersWorkers_paymentProcessingWorkers`) | Payment completion, order completion, and transaction attribution | Ruby, Resque |
| Cancellation & Refund Workers (`continuumOrdersWorkers_cancellationWorkers`) | Delayed cancellation, mass refund, credit card storage, and billing record deactivation | Ruby, Resque |
| Fraud & Risk Workers (`continuumOrdersWorkers_fraudAndRiskWorkers`) | Fraud review, Accertify resolution, and fraud retry logic | Ruby, Resque |
| Inventory & Voucher Workers (`continuumOrdersWorkers_inventoryWorkers`) | Inventory and voucher collection, guard, and retry flows | Ruby, Resque |
| Account Redaction Workers (`continuumOrdersWorkers_accountRedactionWorkers`) | Background account redaction, account updater batch, and PCI billing record deactivation | Ruby, Resque |
| Domain Utility Workers (`continuumOrdersWorkers_miscDomainWorkers`) | Tax document commit, expired exchanges, gift card refunds, Adyen tokenization | Ruby, Resque |

### Orders Daemons (`continuumOrdersDaemons`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Collection Daemons (`continuumOrdersDaemons_collectionDaemons`) | Schedules collection retries and delayed operations into Resque queues | Ruby, Resque |
| Cron Task Runner (`continuumOrdersDaemons_cronTaskRunner`) | Invokes cron-scheduled tasks and operational checks | Ruby |
| Retry Schedulers (`continuumOrdersDaemons_retrySchedulers`) | Triggers retry enqueue flows for orders, line items, fraud, account redaction, and exchanges | Ruby |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumOrdersService` | `continuumOrdersDb` | Reads/writes orders, billing, payments, inventory units | ActiveRecord |
| `continuumOrdersService` | `continuumOrdersMsgDb` | Persists order messages and transactional ledger events | ActiveRecord |
| `continuumOrdersService` | `continuumFraudDb` | Reads fraud data during payment authorization | ActiveRecord |
| `continuumOrdersService` | `continuumRedis` | Caches, obtains locks, and enqueues jobs | Redis client |
| `continuumOrdersService` | `continuumOrdersWorkers` | Enqueues asynchronous jobs | Resque |
| `continuumOrdersService` | `continuumOrdersDaemons` | Triggers daemon-monitored workflows via queues | Resque |
| `continuumOrdersService` | `continuumUsersService` | Fetches account details, email/password changes | HTTP |
| `continuumOrdersService` | `continuumDealCatalogService` | Fetches deal and taxonomy data | HTTP |
| `continuumOrdersService` | `continuumVoucherInventoryService` | Reserves voucher inventory | HTTP |
| `continuumOrdersService` | `continuumGeoDetailsService` | Performs geocoding and address normalization | HTTP |
| `continuumOrdersService` | `continuumFraudArbiterService` | Requests fraud decisions | HTTP |
| `continuumOrdersService` | `continuumIncentivesService` | Applies incentives/credits | HTTP |
| `continuumOrdersService` | `continuumPaymentsService` | Payment authorization, capture, refund, and billing record operations | HTTP |
| `continuumOrdersService` | `continuumTaxonomyService` | Reads taxonomy data used by order and voucher flows | HTTP |
| `continuumOrdersService` | `continuumM3MerchantService` | Reads merchant account data for fulfillment and reconciliation | HTTP |
| `continuumOrdersService` | `continuumM3PlacesService` | Reads place/location data for merchant and order context | HTTP |
| `continuumOrdersService` | `messageBus` | Publishes asynchronous order and billing events | Message Bus |
| `continuumOrdersWorkers` | `continuumOrdersDb` | Processes collections, payments, refunds, inventory updates | ActiveRecord |
| `continuumOrdersWorkers` | `continuumFraudDb` | Reads/writes fraud review state | ActiveRecord |
| `continuumOrdersWorkers` | `continuumAnalyticsWarehouse` | Extracts or loads analytics data | Batch export |
| `continuumOrdersWorkers` | `paymentGateways` | Executes payment operations in background | HTTP |
| `continuumOrdersDaemons` | `continuumOrdersWorkers` | Enqueues scheduled jobs | Resque |
| `continuumOrdersDaemons` | `continuumRedis` | Uses Redis-backed queues and locks | Redis client |

## Architecture Diagram References

- System context: `contexts-continuum-orders`
- Container: `containers-continuum-orders`
- Component (API): `components-continuum-orders-continuumOrdersApi_accountRedactionApi`
- Component (Workers): `components-continuum-orders-continuumOrdersWorkers_orderCollectionWorkers`
- Component (Daemons): `components-continuum-orders-continuumOrdersDaemons_collectionDaemons`
