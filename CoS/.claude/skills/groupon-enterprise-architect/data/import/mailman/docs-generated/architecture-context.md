---
service: "mailman"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumMailmanService", "mailmanPostgres"]
---

# Architecture Context

## System Context

Mailman sits within the `continuumSystem` as the transactional notification orchestrator. It bridges event producers (internal Continuum services and MBus message originators) with Rocketman, the email delivery service. Mailman's role is data aggregation and routing: it calls up to eleven downstream Continuum APIs to enrich a notification request, then publishes the complete payload onto MBus for Rocketman to consume and deliver. It owns its own PostgreSQL database for operational state (deduplication, retry, Quartz scheduling).

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Mailman Service | `continuumMailmanService` | Backend service | Java 11, Spring Boot | 1.2.2 | Mail delivery orchestration — receives requests, aggregates context, publishes to MBus |
| Mailman PostgreSQL | `mailmanPostgres` | Database | PostgreSQL | 13.1 | Persistent store for deduplication, retry payloads, Quartz scheduling metadata, and operational state |
| Message Bus | `messageBus` | Messaging infrastructure | MBus/JMS | — | Async message transport; Mailman consumes `MailmanQueue` and publishes `TransactionalEmailRequest` |

## Components by Container

### Mailman Service (`continuumMailmanService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `continuumMailmanApiController` | Exposes HTTP endpoints for mail submission, duplicate check, retry, context, and client registration; validates and forwards requests to the workflow engine | Spring MVC |
| `continuumMailmanWorkflowEngine` | Routes validated requests to the appropriate mail processor; coordinates asynchronous context enrichment across downstream service clients | MailProcessorResolver + WorkflowService |
| `continuumMailmanMessageBusIntegration` | Consumes messages from `MailmanQueue` and DLQ; publishes enriched `TransactionalEmailRequest` payloads to MBus | MBus client + JMS listeners |
| `continuumMailmanOutboundClients` | Retrofit-based HTTP clients for Orders, Users, Deal Catalog, Marketing Deal, Voucher Inventory, Relevance API, Universal Merchant API, API Lazlo, Goods Inventory, Travel Itinerary, and ThirdParty Inventory | Retrofit |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumMailmanApiController` | `continuumMailmanWorkflowEngine` | Submits validated requests for processing | In-process call |
| `continuumMailmanMessageBusIntegration` | `continuumMailmanWorkflowEngine` | Dispatches consumed messages for orchestration | In-process call |
| `continuumMailmanWorkflowEngine` | `continuumMailmanOutboundClients` | Retrieves domain context before rendering notifications | In-process call |
| `continuumMailmanService` | `mailmanPostgres` | Reads/writes request, retry, and deduplication state | JDBC |
| `continuumMailmanService` | `messageBus` | Consumes and publishes transactional notification messages | MBus/JMS |
| `continuumMailmanService` | `continuumOrdersService` | Fetches order and transaction details for order-related notifications | HTTP/JSON |
| `continuumMailmanService` | `continuumUsersService` | Fetches user/account profiles for personalization and targeting | HTTP/JSON |
| `continuumMailmanService` | `continuumDealCatalogService` | Fetches deal catalog and product metadata | HTTP/JSON |
| `continuumMailmanService` | `continuumMarketingDealService` | Fetches deal-management metadata and lifecycle details | HTTP/JSON |
| `continuumMailmanService` | `continuumVoucherInventoryService` | Fetches voucher and inventory-unit data | HTTP/JSON |
| `continuumMailmanService` | `continuumRelevanceApi` | Fetches relevance and recommendation context | HTTP/JSON |
| `continuumMailmanService` | `continuumUniversalMerchantApi` | Fetches merchant and location data | HTTP/JSON |
| `continuumMailmanService` | `continuumApiLazloService` | Fetches legacy API data paths for market-specific flows | HTTP/JSON |
| `continuumMailmanService` | `continuumGoodsInventoryService` | Fetches goods inventory data for goods notifications | HTTP/JSON |
| `continuumMailmanService` | `continuumTravelInventoryService` | Fetches travel itinerary and inventory data | HTTP/JSON |
| `continuumMailmanService` | `continuumThirdPartyInventoryService` | Fetches partner inventory data | HTTP/JSON |

## Architecture Diagram References

- Component: `components-continuum-mailman-service`
- Dynamic flow: `dynamic-mail-processing-flow`
