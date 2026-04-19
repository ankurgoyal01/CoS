---
service: "afl-3pgw"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumAfl3pgwService, continuumAfl3pgwDatabase]
---

# Architecture Context

## System Context

AFL-3PGW sits within the Continuum platform as the outbound gateway between Groupon's internal affiliate attribution pipeline and external affiliate networks. It is a downstream consumer of the MBUS message bus (fed by `afl-rta`) and an upstream caller of Commission Junction, Awin, `continuumOrdersService`, `continuumMarketingDealService`, and `continuumIncentiveService`. The service is non-customer-facing; it operates as a backend worker processing order events and running scheduled reconciliation jobs.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| AFL 3PGW Service | `continuumAfl3pgwService` | Backend service | Java, Dropwizard/JTier | 1.0.x | Affiliates Third Party Gateway — consumes attributed order events and manages affiliate-network submission and reconciliation workflows |
| AFL 3PGW MySQL | `continuumAfl3pgwDatabase` | Database | MySQL | — | Service-owned MySQL database for job state, attributions, reports, cancellations, and audit records |

## Components by Container

### AFL 3PGW Service (`continuumAfl3pgwService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Order Ingestion (`orderIngestionComponent`) | Consumes and parses real-time order events from the MBUS message bus topic `jms.topic.afl_rta.attribution.orders` | JTier MessageBus Consumer |
| Order Registration (`orderRegistrationComponent`) | Coordinates order enrichment and registration workflows for affiliate networks, including calling Orders, MDS, and Incentive services | Application Service |
| Affiliate Network Gateway (`affiliateNetworkGatewayComponent`) | Encapsulates CJ and Awin client adapters, request mapping, and retry policies for outbound submissions | HTTP Clients/Adapters (Retrofit) |
| Job Orchestration (`jobOrchestrationComponent`) | Executes Quartz-scheduled background jobs for CJ/Awin report processing, correction submission, and new-order reconciliation | Quartz Jobs |
| Persistence (`persistenceComponent`) | JDBI DAOs and mappers for reading and writing attribution, reporting, correction, and audit entities | JDBI/MySQL |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `messageBus` | `continuumAfl3pgwService` | Publishes order attribution events consumed by afl-3pgw | JMS/MBUS |
| `continuumAfl3pgwService` | `continuumAfl3pgwDatabase` | Reads and writes attribution, correction, report, and audit data | JDBC/MySQL |
| `continuumAfl3pgwService` | `continuumOrdersService` | Fetches order details for registration and verification | REST/HTTP |
| `continuumAfl3pgwService` | `continuumIncentiveService` | Fetches incentive and discount details | REST/HTTP |
| `continuumAfl3pgwService` | `continuumMarketingDealService` | Fetches taxonomy and deal metadata for payload enrichment | REST/HTTP |
| `continuumAfl3pgwService` | `cjAffiliate` | Submits and reconciles affiliate transactions and corrections | REST/HTTP (S2S), GraphQL |
| `continuumAfl3pgwService` | `awinAffiliate` | Submits and reconciles affiliate transactions and reports | REST/HTTP |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-afl3pgw-service`
- Dynamic flow: `dynamic-rta-order-registration-flow`
