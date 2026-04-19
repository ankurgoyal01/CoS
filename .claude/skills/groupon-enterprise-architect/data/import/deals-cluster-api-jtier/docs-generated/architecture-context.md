---
service: "deals-cluster-api-jtier"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumDealsClusterApi, continuumDealsClusterDatabase]
---

# Architecture Context

## System Context

The Deals Cluster API is a container within the `continuumSystem` (Continuum Platform). It sits in the Marketing Services subdomain and acts as the rule authority and cluster data store for deal grouping. The Deals Cluster Spark Job (a separate container, `continuumDealsClusterSparkJob`) is its primary upstream call-initiator: it fetches cluster rules from this API, runs Spark jobs on GDOOP to compute clusters, and writes results back through this API. Marketing and navigation surfaces query the API for top-cluster data. The tagging workflow within this API bridges deal clustering to the `continuumMarketingDealService` by publishing JMS tagging/untagging messages.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Deals Cluster API (JTier) | `continuumDealsClusterApi` | Backend API | Java, JTier, Dropwizard | Java 11 | REST API exposing deal clustering rules and clusters, plus marketing tagging workflows |
| Deals Cluster Postgres | `continuumDealsClusterDatabase` | Database | PostgreSQL | — | Stores deal clusters, rules, top-cluster rules, and tagging audit data |

## Components by Container

### Deals Cluster API (`continuumDealsClusterApi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Deals Cluster Resource | Exposes cluster read endpoints (`/clusters`, `/clusters/{id}`) | JAX-RS |
| Rules Resource | Exposes cluster rules CRUD endpoints (`/rules`) | JAX-RS |
| Top Clusters Resource | Exposes top clusters query endpoint (`/topclusters`) | JAX-RS |
| Top Cluster Rules Resource | Exposes top cluster rules CRUD endpoints (`/topclustersrules`) | JAX-RS |
| Use Case Resource | Exposes marketing tagging use case endpoints | JAX-RS |
| Tagging Audit Resource | Exposes tagging audit query endpoint (`/mts/taggingaudit`) | JAX-RS |
| Deals Cluster DAO Service | Business logic for cluster lookups | Java |
| Deals Cluster Rules Service | Business logic for cluster rule management | Java |
| Top Clusters Service | Business logic for top-cluster lookups with in-memory cache | Java |
| Top Clusters Rules Service | Business logic for top-cluster rule management | Java |
| Use Case Service | Manages tagging use cases and scheduling | Java |
| Use Case Execute Service | Executes tagging use cases and publishes JMS messages | Java |
| Tagging Scheduler Service | Schedules tagging workflows via Quartz | Java |
| Tagging Audit Service | Persists and retrieves tagging audit entries | Java |
| Deal Catalog Client | Fetches deal catalog data from `continuumDealCatalogService` | Retrofit |
| DM API Client | Sends tagging/untagging HTTP requests to `continuumMarketingDealService` | Retrofit |
| Message Bus Sender | Publishes tagging and untagging requests to JMS queues | JMS |
| Tagging Worker | Consumes tagging messages from JMS queue and calls DM API | JMS Worker |
| Untagging Worker | Consumes untagging messages from JMS queue and calls DM API | JMS Worker |
| Deals Cluster DAO | JDBI data access for clusters table | JDBI |
| Deals Cluster Rules DAO | JDBI data access for cluster rules table | JDBI |
| Top Clusters DAO | JDBI data access for top clusters table | JDBI |
| Top Clusters Rules DAO | JDBI data access for top cluster rules table | JDBI |
| Tagging Audit DAO | JDBI data access for tagging audit table | JDBI |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumDealsClusterSparkJob` | `continuumDealsClusterApi` | Fetches cluster rules to drive Spark computation | REST/HTTP |
| `continuumDealsClusterApi` | `continuumDealsClusterDatabase` | Reads/writes clusters, rules, top clusters, tagging audit data | JDBC/PostgreSQL |
| `continuumDealsClusterApi` | `continuumMarketingDealService` | Sends tagging/untagging requests via DM API client | REST/HTTP |
| `continuumDealsClusterApi` | `continuumDealCatalogService` | Fetches deal catalog data via Deal Catalog Client | REST/HTTP |
| `continuumDealsClusterApi` | `messageBusTaggingQueue` | Publishes tagging messages via JMS | JMS |
| `continuumDealsClusterApi` | `messageBusUntaggingQueue` | Publishes untagging messages via JMS | JMS |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-deals-cluster-api-components`
