---
service: "dynamic_pricing"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumPricingService, continuumDynamicPricingNginx, continuumPricingDb, continuumPwaDb, continuumRedisCache, continuumMbusBroker]
---

# Architecture Context

## System Context

The Pricing Service is a backend service within the `continuumSystem` — Groupon's core commerce engine. It sits behind the `apiProxy` routing layer, receives traffic through `continuumDynamicPricingNginx`, and provides REST endpoints for price management. It integrates with the `continuumMbusBroker` for asynchronous event distribution, two MySQL databases for persistent state, a Redis cache for low-latency reads, and makes outbound HTTP calls to `continuumVoucherInventoryService` and `continuumDealCatalogService` for validation data.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Pricing Service | `continuumPricingService` | Backend | Java 21, Jetty, RESTEasy | — | Manages pricing lifecycle: retail prices, program prices, price rules, history, scheduled updates, and event publication |
| Dynamic Pricing NGINX | `continuumDynamicPricingNginx` | Proxy | NGINX on Kubernetes | — | Routes dynamic-pricing read/write traffic to Pricing Service pods; serves health checks |
| Pricing Service DB | `continuumPricingDb` | Database | MySQL | — | Stores pricing state, price history, program prices, rules, schedules, and Quartz job metadata |
| PWA DB | `continuumPwaDb` | Database | MySQL | — | Inventory and program price state used for parity with voucher inventory systems |
| Pricing Redis Cache | `continuumRedisCache` | Cache | Redis | — | Caches PriceSummary records for low-latency current price lookups |
| MBus Broker | `continuumMbusBroker` | Message Broker | JMS (HornetQ/ActiveMQ) | — | Carries price update, retail price, program price, and price rule update topics; also delivers VIS inventory events to the service |

## Components by Container

### Pricing Service (`continuumPricingService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `continuumPricingService_currentPriceController` | REST endpoints for current and future price lookups (single and bulk) | Java, RESTEasy |
| `continuumPricingService_programPriceController` | Bulk program price creation and validation endpoints | Java, RESTEasy |
| `continuumPricingService_retailPriceController` | Retail price update endpoints; handles dimension changes | Java, RESTEasy |
| `continuumPricingService_priceRuleController` | Price rule CRUD and reservation endpoints | Java, RESTEasy |
| `continuumPricingService_priceHistoryController` | Quote and product price history endpoints for audit and reporting | Java, RESTEasy |
| `continuumPricingService_featureFlagController` | Product feature flag read/write endpoints | Java, RESTEasy |
| `continuumPricingService_configHeartbeatController` | Service status, config, and heartbeat endpoints | Java, RESTEasy |
| `continuumPricingService_currentPriceService` | Orchestrates price lookup, cache check, rule application, and transformation | Java |
| `continuumPricingService_retailPriceService` | Processes retail price updates: validation, DB writes, cache expiry, event publication | Java |
| `continuumPricingService_programPriceService` | Bulk program price creation pipeline with validation, deal lookups, and transactional writes | Java |
| `continuumPricingService_priceRuleService` | Retrieves and assembles price rules for products and linked products | Java |
| `continuumPricingService_priceRuleUpdateService` | Creates or updates price rules from API calls and MBus events | Java |
| `continuumPricingService_priceHistoryService` | Builds historical price timelines and established-price calculations | Java |
| `continuumPricingService_featureFlagService` | Manages product feature flags and client enablement logic | Java |
| `continuumPricingService_establishedPriceService` | Computes established price metrics for locales and goods | Java |
| `continuumPricingService_priceMetadataService` | Resolves dimensional metadata and translations used in pricing responses | Java |
| `continuumPricingService_quotePriceHistoryService` | Handles quote-based price history retrieval and storage | Java |
| `continuumPricingService_priceUpdateWorkflow` | Coordinates DB writes, cache invalidation, and event publication for all price changes | Java |
| `continuumPricingService_scheduledUpdateWorker` | Background scheduler threads processing scheduled price updates and recovery | Java |
| `continuumPricingService_quartzJobRunner` | Quartz jobs emitting price-related events on configured cadences | Java, Quartz |
| `continuumPricingService_pricingDbRepository` | Query handlers and connection management for the pricing MySQL schema | Java, JDBC |
| `continuumPricingService_pwaDbRepository` | Data access helpers for PWA inventory state and parity checks | Java, JDBC |
| `continuumPricingService_redisCacheClient` | Bulk get/set of PriceSummary CSV entries in Redis | Java, Lettuce |
| `continuumPricingService_mbusPublishers` | Publishers for price update, retail price, program price, and price rule events | Java, JMS |
| `continuumPricingService_mbusConsumers` | Consumers for VIS inventory updates and price rule updates from MBus | Java, JMS |
| `continuumPricingService_visHttpClient` | Outbound HTTP client fetching product and unit details from VIS | Java, Apache HttpClient |
| `continuumPricingService_dealCatalogClient` | Outbound HTTP client retrieving deal metadata from Deal Catalog | Java, HTTP |

### Dynamic Pricing NGINX (`continuumDynamicPricingNginx`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `continuumDynamicPricingNginx_requestRouter` | Routes incoming dynamic-pricing requests to read/write upstream pricing pods | NGINX routing rules |
| `continuumDynamicPricingNginx_healthEndpoint` | Serves `/heartbeat.txt` for Kubernetes liveness/readiness checks | NGINX static endpoint |
| `continuumDynamicPricingNginx_logEmitter` | Writes access/error logs consumed by the logging pipeline | NGINX logging |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `apiProxy` | `continuumDynamicPricingNginx` | Routes dynamic-pricing traffic through hybrid boundary | HTTPS |
| `continuumDynamicPricingNginx` | `continuumPricingService` | Proxies read/write requests to pricing service pods | HTTP |
| `continuumDynamicPricingNginx` | `loggingStack` | Ships NGINX access/error logs | Filebeat/HTTP |
| `continuumPricingService` | `continuumPricingDb` | Reads and writes pricing state, history, rules, schedules, and Quartz tables | JDBC |
| `continuumPricingService` | `continuumPwaDb` | Synchronizes price updates and program price state to PWA inventory tables | JDBC |
| `continuumPricingService` | `continuumRedisCache` | Caches and invalidates PriceSummary responses for price lookup endpoints | Redis |
| `continuumPricingService` | `continuumMbusBroker` | Publishes price updates, program price events, retail price events, and price rule updates | JMS |
| `continuumMbusBroker` | `continuumPricingService` | Delivers VIS inventory updates and price rule updates for processing | JMS |
| `continuumPricingService` | `continuumVoucherInventoryService` | Fetches inventory products and units for validation and pricing decisions | HTTP |
| `continuumPricingService` | `continuumDealCatalogService` | Queries deal metadata to validate program price requests | HTTP |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component (Pricing Service): `components-continuum-pricing-continuumPricingService_currentPriceService`
- Component (NGINX): `components-continuum-dynamic-pricing-nginx`
- Dynamic view (price update): `dynamic-pricing-update-continuumPricingService_priceUpdateWorkflow`
- Dynamic view (NGINX routing): `dynamic-pricing-nginx-request-routing`
