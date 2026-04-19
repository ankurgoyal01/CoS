---
service: "deal-catalog-service"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumDealCatalogService", "continuumDealCatalogDb", "continuumDealCatalogRedis"]
---

# Architecture Context

## System Context

The Deal Catalog Service sits within the **Continuum Platform** (`continuumSystem`), Groupon's core commerce engine. It is the central repository of deal merchandising metadata, positioned between deal creation (Salesforce / Deal Management API) and deal consumption (Lazlo API gateway, inventory services, booking, affiliates). Salesforce pushes deal metadata into the service via REST integrations. The service persists this data to MySQL, applies merchandising rules, publishes deal lifecycle events to the Message Bus, and exposes REST APIs for a wide range of internal consumers including the Lazlo API layer, multiple inventory services, the Online Booking API, and Travel Affiliates.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| Deal Catalog | `continuumDealCatalogService` | Application | Java, Dropwizard (JTier) | Microservice that stores and serves merchandising information for deals (titles, categories, availability, merchandising attributes). Exposes Deal Catalog APIs and executes merchandising workflows. |
| Deal Catalog DB | `continuumDealCatalogDb` | Database | MySQL (DaaS) | Primary relational data store for deal catalog metadata. |
| Deal Catalog Redis | `continuumDealCatalogRedis` | Cache | Redis | Redis store used for PWA queueing and short-lived coordination state. |

## Components by Container

### Deal Catalog (`continuumDealCatalogService`)

| Component | ID | Responsibility | Technology |
|-----------|----|---------------|-----------|
| Catalog API | `dealCatalog_api` | Endpoints for deal metadata -- receives inbound requests from Salesforce and internal consumers. | Spring Boot |
| Merchandising Service | `dealCatalog_merchandisingService` | Business rules for merchandising -- applies merchandising logic, reads/writes deals, publishes deal lifecycle events. | Spring Boot |
| Catalog Repository | `dealCatalog_repository` | CRUD operations for deals -- data access layer for deal entity persistence. | JPA |
| Search Indexer | `dealCatalog_indexer` | Publishes updates to the search platform when deal metadata changes. | Worker |
| Message Publisher | `dealCatalog_messagePublisher` | Writes and publishes deal lifecycle events to configured MBus topics. | MBus Producer |
| Node Payload Fetcher | `dealCatalog_nodePayloadFetcher` | Scheduled jobs that fetch remote node payloads and update node state. Reads/writes node payload metadata and emits updates after payload refresh. | Quartz Jobs + Java HTTP Client |

## Key Relationships

### Container-Level

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumDealCatalogService` | `continuumDealCatalogDb` | Persistence of deal catalog metadata | JDBC |
| `continuumDealCatalogService` | `continuumDealCatalogRedis` | Enqueues and de-duplicates PWA work | Redis |
| `continuumDealCatalogService` | `continuumCouponsInventoryService` | Supports coupons for deals | HTTP/JSON |
| `continuumDealCatalogService` | `messageBus` | Publishes deal snapshot and update events | Async |
| `continuumDealCatalogService` | `continuumMarketingDealService` | Notifies MDS of new deal | HTTP/JSON |
| `continuumDealCatalogDb` | `edw` | Replicates data for analysis | Batch |
| `continuumDealCatalogDb` | `bigQuery` | Replicates data for analysis | Batch |

### Inbound (services that call Deal Catalog)

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `salesForce` | `dealCatalog_api` | Push deal metadata (title, category, availability) | REST / Integration |
| `continuumApiLazloService` | `continuumDealCatalogService` | Fetch deal metadata for consumer browsing | HTTP/JSON over internal network |
| `continuumApiLazloSoxService` | `continuumDealCatalogService` | Fetch deal metadata (SOX-compliant) | HTTP/JSON over internal network |
| `continuumCloInventoryService` | `continuumDealCatalogService` | Resolve deal attributes for CLO inventory | HTTP/JSON via DealCatalogClient |
| `continuumVoucherInventoryApi` | `continuumDealCatalogService` | Resolve deal attributes for voucher inventory | HTTPS/JSON |
| `continuumGoodsInventoryService` | `continuumDealCatalogService` | Resolve deal attributes for goods inventory | HTTP/JSON via DealCatalogClient |
| `continuumCouponsInventoryService` | `continuumDealCatalogService` | Resolve deal attributes for coupons inventory | HTTP/JSON over OkHttp |
| `continuumOnlineBookingApi` | `continuumDealCatalogService` | Fetch deal configuration for booking | HTTP/JSON |
| `continuumDealAlertsWorkflows` | `continuumDealCatalogService` | Fetch deal data for alert workflows | API |
| `coffeeWorkflows` | `continuumDealCatalogService` | Fetch deal data for coffee-to-go workflows | REST |
| `continuumS2sService` | `continuumDealCatalogService` | Retrieves deal catalog attributes for booster mappings | HTTP/JSON |
| `continuumTravelAffiliatesApi` | `continuumDealCatalogService` | Retrieves active deals and distribution regions | REST/JSON |
| `continuumTravelAffiliatesCron` | `continuumDealCatalogService` | Fetches active deal UUIDs and region data | REST/JSON |
| `continuumDealManagementApi` | `continuumDealCatalogService` | Register deal metadata during deal creation | HTTP/JSON |

### Component-Level (internal)

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `dealCatalog_api` | `dealCatalog_merchandisingService` | Apply merchandising rules | Direct |
| `dealCatalog_api` | `dealCatalog_repository` | Persist deal metadata | SQL |
| `dealCatalog_api` | `dealCatalog_indexer` | Emit reindex event | Event / Batch |
| `dealCatalog_merchandisingService` | `dealCatalog_repository` | Read/write deals | Direct |
| `dealCatalog_merchandisingService` | `dealCatalog_messagePublisher` | Publishes deal lifecycle events | Direct |
| `dealCatalog_nodePayloadFetcher` | `dealCatalog_repository` | Reads/writes node payload metadata | Direct |
| `dealCatalog_nodePayloadFetcher` | `dealCatalog_messagePublisher` | Emits updates after payload refresh | Direct |

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-continuum`
- Component: `components-deal-catalog-dealCatalog_merchandisingService`
- Dynamic (browsing): `dynamic-continuum-deal-catalog`
- Dynamic (creation): `dynamic-continuum-deal-creation`
- Dynamic (booking): `dynamic-continuum-online-booking`
