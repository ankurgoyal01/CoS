---
service: "incentive-service"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumIncentiveService, continuumIncentivePostgres, continuumIncentiveCassandra, continuumIncentiveKeyspaces, continuumIncentiveRedis]
---

# Architecture Context

## System Context

The Incentive Service (`continuumIncentiveService`) is a core component of the Continuum platform within Groupon's CRM domain. It sits at the intersection of commerce and marketing: checkout systems call it synchronously to validate and redeem promo codes, while asynchronous consumers handle order events from MBus and publish qualification and redemption outcomes to Kafka. Admin users interact with it via a server-rendered UI (Play views supplemented by Next.js pages) to manage campaign lifecycles. The service depends on several Continuum platform services for pricing, deal catalog, taxonomy, and messaging, and owns its own multi-store data tier (PostgreSQL, Cassandra/Keyspaces, Redis, and Bigtable).

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Incentive Service | `continuumIncentiveService` | Service | Scala / Play Framework | 2.8.20 | Central incentive management platform; runs in 5 operational modes |
| Incentive PostgreSQL | `continuumIncentivePostgres` | Database | PostgreSQL | — | Incentive metadata, campaign control tables, approval workflow state |
| Incentive Cassandra | `continuumIncentiveCassandra` | Database | Apache Cassandra | — | Qualification and redemption datasets (high volume, on-prem) |
| Incentive Keyspaces | `continuumIncentiveKeyspaces` | Database | Amazon Keyspaces | — | Cassandra-compatible managed store for cloud environments |
| Incentive Redis | `continuumIncentiveRedis` | Cache | Redis | — | Distributed cache refresh, state pub/sub, session-level caching |

## Components by Container

### Incentive Service (`continuumIncentiveService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `incentiveApi` | Serves HTTP endpoints for validation, redemption, audience qualification, and bulk export | Play Controllers (Scala) |
| `incentiveAdminUi` | Renders campaign management and approval workflow pages | Play Views / Next.js |
| `incentiveBackgroundJobs` | Schedules and executes audience qualification sweeps and bulk export jobs | Akka Actors |
| `incentiveMessaging` | Consumes and produces events on Kafka and MBus | Alpakka Kafka / STOMP |
| `incentiveDataAccess` | Manages reads and writes across PostgreSQL, Cassandra, Keyspaces, Redis, and Bigtable | play-slick / phantom-dsl / jedis / Bigtable SDK |
| `incentiveExternalClients` | Typed HTTP clients for AMS, Taxonomy, Pricing, MDS, Deal Catalog, and Messaging services | Play WS |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumIncentiveService` | `continuumIncentivePostgres` | Stores incentive metadata and control data | JDBC/PostgreSQL |
| `continuumIncentiveService` | `continuumIncentiveCassandra` | Reads and writes qualification and redemption datasets | Cassandra CQL |
| `continuumIncentiveService` | `continuumIncentiveKeyspaces` | Reads and writes Cassandra-compatible datasets in managed environments | Cassandra CQL |
| `continuumIncentiveService` | `continuumIncentiveRedis` | Uses caches and pub/sub coordination channels | Redis |
| `continuumIncentiveService` | `continuumKafkaBroker` | Consumes and produces audience/event streams | Kafka |
| `continuumIncentiveService` | `messageBus` | Consumes and produces order and user population events | MBus/STOMP |
| `continuumIncentiveService` | `continuumAudienceManagementService` | Calls audience management APIs | REST/HTTP |
| `continuumIncentiveService` | `continuumTaxonomyService` | Loads taxonomy data for targeting and filtering | REST/HTTP |
| `continuumIncentiveService` | `continuumPricingService` | Requests pricing context for incentive eligibility | REST/HTTP |
| `continuumIncentiveService` | `continuumDealCatalogService` | Fetches deal/product details | REST/HTTP |
| `continuumIncentiveService` | `continuumMarketingDealService` | Performs MDS deal and product set loading | REST/HTTP |
| `continuumIncentiveService` | `continuumMessagingService` | Creates and updates messaging campaigns | REST/HTTP |

### Stub-only integrations (not yet in federated architecture model)

| Stub ID | Description |
|---------|-------------|
| `extBigtableInstance_0f21` | Google Cloud Bigtable — high-throughput audience and qualification data |
| `extRealtimeAudienceService_6bf1` | Realtime Audience Service — realtime audience qualification |
| `extRaas_276f` | RAAS — campaign state change signals |
| `extEmailCampaignManagement_8a72` | Email Campaign Management — email automation coordination |
| `extRocketmanCommercialEds_3de0` | Rocketman Commercial EDS — destination and campaign metadata |
| `extDaasPostgres_bf75` | DAAS Postgres — shared reporting dataset |

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-continuum`
- Component: `components-continuumIncentiveService`
- Dynamic flow: `dynamic-incentive-request-flow`
