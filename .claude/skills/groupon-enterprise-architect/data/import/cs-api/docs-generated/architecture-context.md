---
service: "cs-api"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumCsApiService"]
---

# Architecture Context

## System Context

CS API is a container within the `continuumSystem` (Continuum Platform) software system. It sits at the boundary between the Cyclops customer support agent tooling and the broader Groupon microservices ecosystem. The service is called by the CS agent web application and in turn calls more than a dozen downstream Continuum services as well as external third-party platforms (Zendesk, Salesforce).

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| CS API Service | `continuumCsApiService` | Backend API | Java / Dropwizard | Serves all CS agent REST endpoints; aggregates multi-service data |
| CS API MySQL (primary) | `csApiMysql` | Database | MySQL | Primary read/write store for memos, snippets, agent roles, features |
| CS API MySQL (read replica) | `csApiRoMysql` | Database | MySQL | Read-only replica; used for read-heavy queries |
| CS API Redis | `csApiRedis` | Cache | Redis | Dedicated Redis instance for session and response caching |
| CS Redis Shared Cache | `continuumCsRedisCache` | Cache | Redis | Shared Continuum CS Redis cache |
| CS API Redis C2 Cache | `csApiRedisC2Cache` | Cache | Redis | Secondary Redis cache layer |

## Components by Container

### CS API Service (`continuumCsApiService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `csApi_apiResources` | Dropwizard resources serving all CS API REST endpoints; request parsing, validation, response assembly | Jersey / JAX-RS |
| `serviceClients` | HTTP clients to all downstream internal and external services; uses jtier-retrofit | JTier Retrofit |
| `csApi_repositories` | MySQL data access layer; reads/writes memos, agent roles, snippets, features | JDBI / jtier-jdbi |
| `cacheClients` | Redis cache and session clients; manages session tokens and cached responses | Dropwizard Redis |
| `authModule` | JWT authentication and CS token validation; integrates with jtier-auth-bundle and JJWT | jtier-auth-bundle / JJWT |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `csApi_apiResources` | `serviceClients` | Delegates downstream data fetching | Internal |
| `csApi_apiResources` | `csApi_repositories` | Reads and writes persistent data | Internal |
| `csApi_apiResources` | `cacheClients` | Reads and writes cached data | Internal |
| `csApi_apiResources` | `authModule` | Validates agent authentication | Internal |
| `serviceClients` | `cacheClients` | Caches downstream responses | Internal |
| `continuumCsApiService` | `continuumUsersService` | Queries user data | HTTP |
| `continuumCsApiService` | `continuumOrdersService` | Queries orders | HTTP |
| `continuumCsApiService` | `continuumDealCatalogService` | Loads deal data | HTTP |
| `continuumCsApiService` | `lazloApi` | Requests API data | HTTP |
| `continuumCsApiService` | `continuumGoodsInventoryService` | Reads goods inventory | HTTP |
| `continuumCsApiService` | `continuumAudienceManagementService` | Fetches audience data | HTTP |
| `continuumCsApiService` | `continuumConsumerDataService` | Fetches consumer data | HTTP |
| `continuumCsApiService` | `continuumIncentivesService` | Fetches incentives | HTTP |
| `continuumCsApiService` | `continuumCsTokenService` | Requests CS tokens | HTTP |
| `continuumCsApiService` | `continuumGoodsCentralService` | Fetches goods data | HTTP |
| `continuumCsApiService` | `continuumCsRedisCache` | Caches responses | Redis |
| `continuumCsApiService` | `zendesk` | Creates and reads tickets | HTTP |
| `continuumCsApiService` | `salesForce` | Queries CRM data | HTTP |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-cs-api-components`
