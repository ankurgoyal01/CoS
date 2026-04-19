---
service: "marketplace-ticketing-service"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumMarketplaceTicketingService, continuumMarketplaceTicketingPostgres]
---

# Architecture Context

## System Context

The Marketplace Ticketing Service sits within the **Continuum** platform as a backend integration microservice. It acts as the single gateway between Groupon's internal marketplace tooling (Gazebo operations console, merchant portal) and Salesforce, which is the authoritative system of record for all support tickets. The service exposes two REST API namespaces — one for merchant-facing interactions and one for internal Groupon operations — and bridges async Salesforce case events from the MBus message bus. It depends on several internal Continuum services (GPAPI, Order Service, Goods Stores Service, Goods Outbound Service, Deal Center Service, Customer Support Service, Rocketman) to enrich ticket context.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Marketplace Ticketing Service | `continuumMarketplaceTicketingService` | Service | Java, Dropwizard | JTier 5.14.0 | JTier/Dropwizard API for marketplace and internal ticket workflows; orchestrates Salesforce updates and related integrations |
| Marketplace Ticketing Postgres | `continuumMarketplaceTicketingPostgres` | Database | PostgreSQL | DaaS-managed | Postgres datastore for merchant-ticket mappings, internal ticket history, feature flags, and OAuth tokens |

## Components by Container

### Marketplace Ticketing Service (`continuumMarketplaceTicketingService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Resources (`mts_apiResources`) | Exposes REST resources for all marketplace and internal ticketing endpoints | JAX-RS |
| MBus Consumer Processor (`mts_mbusConsumerProcessor`) | Listens on `jms.topic.salesforce.caseevent.create` and triggers ticket update workflows | MBus Consumer |
| Ticket Orchestration Service (`mts_ticketOrchestration`) | Coordinates merchant and internal ticket flows, routing, and business rules | Domain Services |
| Salesforce Ticketing Core (`mts_salesforceTicketingCore`) | Manages Salesforce OAuth/session lifecycle; executes ticket, comment, tag, and attachment operations | Salesforce Integration |
| Integration Adapters (`mts_integrationAdapters`) | HTTP adapter clients for Order Service, Goods Stores, Deal Center, Customer Support, GPAPI, Goods Outbound, and Rocketman | HTTP Clients |
| Persistence Adapters (`mts_persistenceAdapters`) | DAO layer and in-service caches for merchant-ticket mapping, ticket history, feature flags, and OAuth tokens | JDBI/Cache |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumMarketplaceTicketingService` | `continuumMarketplaceTicketingPostgres` | Reads/writes mappings, flags, history, and tokens | SQL/JDBI |
| `continuumMarketplaceTicketingService` | `salesForce` | Creates, queries, and updates tickets/comments/tags/attachments | HTTPS/REST |
| `continuumMarketplaceTicketingService` | `messageBus` | Consumes case events and publishes information-request updates | JMS/MBus |
| `mts_apiResources` | `mts_ticketOrchestration` | Routes API requests to ticket workflows | Internal |
| `mts_mbusConsumerProcessor` | `mts_ticketOrchestration` | Consumes Salesforce case events and delegates processing | Internal |
| `mts_ticketOrchestration` | `mts_integrationAdapters` | Fetches order/deal/merchant/support context and sends notifications | Internal |
| `mts_ticketOrchestration` | `mts_salesforceTicketingCore` | Creates, updates, and queries tickets in Salesforce | Internal |
| `mts_salesforceTicketingCore` | `mts_persistenceAdapters` | Reads and writes ticket mappings/cache/tokens | Internal |

> Stub-only (not yet fully modelled) relationships include: GPAPI, Goods Stores Service, Rocketman Service, Order Service, Customer Support Service, Goods Outbound Service, and Deal Center Service. These are confirmed in `development.yml` client configs.

## Architecture Diagram References

- Component: `components-continuumMarketplaceTicketingService`
- Dynamic view: `dynamic-ticket-update-flow`
