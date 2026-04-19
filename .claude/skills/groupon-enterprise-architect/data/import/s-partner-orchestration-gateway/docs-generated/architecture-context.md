---
service: "s-partner-orchestration-gateway"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSpogGateway"
  containers: ["continuumSpogGateway", "continuumSpogPostgres"]
---

# Architecture Context

## System Context

S-POG sits within the Continuum platform as the dedicated outbound gateway for significant partner wallet integrations. Google Pay calls S-POG over HTTPS to request wallet payloads and deliver save-to-wallet callbacks. The Groupon MessageBus delivers inventory unit update events inbound. S-POG calls outward to multiple internal inventory services, the Deal Catalog, API Lazlo, and the external Google Wallet API. All wallet unit mappings and resource locks are persisted in a dedicated PostgreSQL instance provisioned by the DaaS layer.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| S Partner Orchestration Gateway | `continuumSpogGateway` | Backend service | Java, Dropwizard/JTier | Orchestrator and gateway for partner wallet integrations such as Google Pay |
| SPOG Postgres | `continuumSpogPostgres` | Database | PostgreSQL | Primary datastore for wallet units, partners, offers, and locks |

## Components by Container

### S Partner Orchestration Gateway (`continuumSpogGateway`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Resources (`spog_apiResources`) | HTTP resources for wallet payloads, callbacks, and basic service endpoints | Jersey/Dropwizard |
| Wallet Services (`walletServices`) | Wallet orchestration and business logic | Java |
| Wallet Payload Generator (`walletPayloadGenerator`) | Builds wallet payloads and JWT tokens signed with Google service account credentials | Java |
| Inventory Service Clients (`inventoryServiceClients`) | Clients for VIS, TPIS, GIS, Getaways, GLive inventory services | Retrofit/HTTP |
| Deal Catalog Client (`spog_dealCatalogClient`) | Fetches deal metadata from Deal Catalog | HTTP/Retrofit |
| API Lazlo Client (`apiLazloClient`) | Fetches deal details and content from API Lazlo | HTTP/Retrofit |
| GPay Pass Client (`gpayPassClient`) | Calls Google Wallet Objects API with OAuth2 service account auth | HTTP/OAuth2 |
| MBus Consumers (`sPartnerOrchestrationGateway_mbusConsumers`) | Consumes inventory unit update events from VIS and TPIS topics | MBus/JMS |
| Wallet Unit Update Orchestrator (`walletUpdateOrchestrator`) | Processes inventory unit updates and syncs Google Wallet offer objects | Java |
| Wallet Persistence (`walletPersistence`) | JDBI DAOs for wallet units and resource locks | JDBI3/PostgreSQL |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `googlePay` | `continuumSpogGateway` | Requests wallet payloads and delivers callbacks | HTTPS |
| `messageBus` | `continuumSpogGateway` | Delivers inventory unit update events (VIS) | MBus/JMS |
| `messageBus` | `continuumSpogGateway` | Delivers inventory unit update events (TPIS) | MBus/JMS |
| `continuumSpogGateway` | `continuumSpogPostgres` | Reads and writes wallet unit and attribution data | JDBC/JDBI |
| `continuumSpogGateway` | `continuumVoucherInventoryService` | Fetches and updates inventory units | HTTP/REST |
| `continuumSpogGateway` | `continuumThirdPartyInventoryService` | Fetches inventory units for TPIS | HTTP/REST |
| `continuumSpogGateway` | `continuumGoodsInventoryService` | Fetches inventory units for goods | HTTP/REST |
| `continuumSpogGateway` | `continuumTravelInventoryService` | Fetches inventory units for getaways and getaways-maris | HTTP/REST |
| `continuumSpogGateway` | `continuumDealCatalogService` | Fetches deal metadata | HTTP/REST |
| `continuumSpogGateway` | `continuumApiLazloService` | Fetches deal content | HTTP/REST |
| `continuumSpogGateway` | `googleWalletApi` | Reads and updates wallet offer objects | HTTP/REST |
| `continuumSpogGateway` | `metricsStack` | Emits service metrics | Metrics |

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-continuum`
- Component: `components-continuum-spog-gateway`
