---
service: "ingestion-jtier"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumIngestionJtierService, continuumIngestionJtierPostgres, continuumIngestionJtierRedis]
---

# Architecture Context

## System Context

ingestion-jtier sits within the **Continuum** platform as the dedicated inbound pipeline for third-party inventory partner (3PIP) feeds. It is positioned between external partner APIs/SFTP sources (Viator, Mindbody, Booker, RewardsNetwork) and Groupon's internal deal management infrastructure. Internally, it depends on Deal Management API, TPIS, Partner Service, Taxonomy Service, and the Message Bus. It does not serve end-consumer traffic directly; it operates as a backend processing pipeline triggered by schedules and internal API calls.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Ingestion JTier Service | `continuumIngestionJtierService` | Application | Java / Dropwizard | 5.15.0 | Main application container — hosts JAX-RS API resources, Quartz scheduler, ingestion pipeline, and all client gateways |
| Ingestion PostgreSQL | `continuumIngestionJtierPostgres` | Database | PostgreSQL | — | Primary relational store for partners, offers, availability state, and ingestion run history |
| Ingestion Redis | `continuumIngestionJtierRedis` | Cache | Redis | — | Cache and distributed lock store for ingestion coordination |

## Components by Container

### Ingestion JTier Service (`continuumIngestionJtierService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `ingestionApiResources` | Exposes JAX-RS REST endpoints for ingest triggers, deal state management, offer blacklisting, and availability queries | JAX-RS (Dropwizard) |
| `ingestionSchedulers` | Runs periodic Quartz jobs for feed extraction and availability synchronization | jtier-quartz-bundle |
| `ingestionPipeline` | Orchestrates the end-to-end extract-transform-load process from raw partner feeds to deal creation | Java |
| `ingestionClientGateway` | Wraps all outbound HTTP calls to external partners and internal services (Retrofit + httpclient) | jtier-retrofit / httpclient |
| `ingestionPersistence` | Manages all SQL read/write operations against PostgreSQL via JDBI3 SQL objects | jtier-jdbi3 |
| `ingestionMessaging` | Publishes ingestion lifecycle events (FeedExtractionCompleteEvent, OfferIngestionEvent, IngestionOperationalEvent) to the Message Bus | jtier-messagebus-client |
| `ingestionCache` | Provides Redis-backed cache operations and distributed lock acquisition/release | jedis |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumIngestionJtierService` | `continuumIngestionJtierPostgres` | Reads and writes partner, offer, and availability data | JDBI / PostgreSQL |
| `continuumIngestionJtierService` | `continuumIngestionJtierRedis` | Caches ingestion state; acquires distributed locks | Redis |
| `continuumIngestionJtierService` | `continuumDealManagementApi` | Creates and updates deals from ingested offers | HTTP / REST |
| `continuumIngestionJtierService` | `thirdPartyInventory` | Retrieves third-party inventory data (TPIS) | HTTP / REST |
| `continuumIngestionJtierService` | `continuumPartnerService` | Fetches partner configuration and metadata | HTTP / REST |
| `continuumIngestionJtierService` | `continuumTaxonomyService` | Resolves taxonomy categories for offer classification | HTTP / REST |
| `continuumIngestionJtierService` | `bookerApi` | Extracts Booker partner feed data | HTTP / REST |
| `continuumIngestionJtierService` | `mindbodyApi` | Extracts Mindbody partner feed data | HTTP / REST |
| `continuumIngestionJtierService` | `viatorApi` | Extracts Viator partner feed data | HTTP / REST |
| `continuumIngestionJtierService` | `rewardsNetworkApi` | Extracts RewardsNetwork partner feed data | HTTP / REST |
| `continuumIngestionJtierService` | `mbusPlatform` | Publishes ingestion lifecycle events | Message Bus |

## Architecture Diagram References

- System context: `contexts-ingestion-jtier`
- Container: `containers-ingestion-jtier`
- Component: `components-ingestionJtierService`
