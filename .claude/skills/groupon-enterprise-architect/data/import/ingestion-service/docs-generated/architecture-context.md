---
service: "ingestion-service"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumIngestionService", "continuumIngestionServiceMysql"]
---

# Architecture Context

## System Context

The ingestion-service (`continuumIngestionService`) sits within the **Continuum Platform** (`continuumSystem`) — Groupon's core commerce and operations engine. It is the primary integration broker between Groupon's Customer Support tooling (especially the Zingtree chatbot) and external SaaS platforms (Salesforce, Signifyd) as well as internal Groupon services (CAAP, Lazlo, Users Service, Orders RO). External callers authenticate using API key (`X-API-KEY`) and client ID (`client_id`) and invoke REST endpoints to manage support cases, retrieve deal/user/memo data, process refunds, and generate JWT tokens.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Ingestion Service | `continuumIngestionService` | Backend service | Java, Dropwizard (JTier) | 1.42.x | Dropwizard-based ingestion API handling ticketing, memos, refunds, deals, users, JWT, and proxy endpoints |
| Ingestion Service MySQL | `continuumIngestionServiceMysql` | Database | MySQL (DaaS) | — | Operational datastore for auth client IDs, Salesforce token/ticket job records, and merchant-approved refunds audit data |

## Components by Container

### Ingestion Service (`continuumIngestionService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Resources (`ingestionService_apiResources`) | Exposes all REST endpoints under `/odis/api/v1/` and `/proxy/` — handles request deserialization, auth filtering, and response serialization | JAX-RS (Jersey) |
| Core Services (`coreServices`) | Implements business logic: ticketing (standard and escalation), memo retrieval, refund processing, deal/user/merchant lookups, incentive fetching, JWT generation, and utility workflows | Java Services |
| Integration Clients (`ingestionService_integrationClients`) | Retrofit HTTP clients for Salesforce, CAAP, Lazlo API, Orders RO Service, Users Service, and Zingtree | Retrofit / OkHttp |
| Auth and JWT (`authAndJwt`) | Validates `X-API-KEY` + `client_id` credentials against the database; generates and signs JWT tokens using JWK keys | Custom Auth, Nimbus OAuth2/OIDC SDK |
| Background Jobs (`ingestionService_backgroundJobs`) | Quartz scheduled jobs: `SfCreateTicketFailuresJob` (retries failed SF ticket creation) and `RefundMerchantApprovedOrdersJob` (processes SF merchant-approved refunds) | Quartz |
| Persistence Layer (`ingestionService_persistenceLayer`) | JDBI DAOs for auth client credentials (`JdbiClientIdDao`), Salesforce OAuth tokens (`SfTokenDBI`), ticket job records (`SfTicketCreationJobDBI`), and merchant-approved refund audit records (`MerchantApprovedRefundsAuditDBI`) | JDBI |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumIngestionService` | `continuumIngestionServiceMysql` | Reads and writes auth client IDs, SF token state, failed ticket jobs, and refund audit records | JDBC/MySQL |
| `continuumIngestionService` | `salesForce` | Creates/updates Salesforce cases and tickets; fetches case, account, opportunity, messaging session, and survey data | HTTPS/REST (Salesforce REST API v56.0 / v59.0) |
| `continuumIngestionService` | `lazloApi` | Fetches deal and merchant details for context enrichment in ticket creation | HTTPS/REST |
| `continuumIngestionService` | `continuumUsersService` | Loads user attributes and customer details | HTTPS/REST |
| `ingestionService_apiResources` | `coreServices` | Delegates incoming requests to business service layer | Jersey (in-process) |
| `coreServices` | `ingestionService_integrationClients` | Calls downstream services and SaaS APIs for data and actions | HTTP/Retrofit |
| `coreServices` | `ingestionService_persistenceLayer` | Reads and writes business and job state | JDBI (in-process) |
| `ingestionService_backgroundJobs` | `coreServices` | Executes scheduled refund and ticket retry logic | Quartz (in-process) |
| `authAndJwt` | `ingestionService_persistenceLayer` | Validates API client credentials and reads token data | JDBI (in-process) |

> Note: Relationships to CAAP API (`extCaapApi_85f2db0d`), Orders RO Service (`extOrdersRoService_416339e8`), and Zingtree (`extZingtree_0f159531`) are implemented in code but are not currently in the federated Structurizr model (stub-only references).

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-continuumIngestionService`
- Dynamic (ticket escalation flow): `dynamic-ticketEscalationFlow`
