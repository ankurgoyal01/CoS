---
service: "salesforce-cache"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
    - continuumSalesforceCacheDatabase
    - continuumSalesforceCacheRedis
    - salesforceCacheApi
    - salesforceCacheReplicationWorker
---

# Architecture Context

## System Context

Salesforce Cache sits within the Continuum Platform as a caching intermediary between Groupon's internal services and the external Salesforce CRM. Internal services query the cache rather than Salesforce directly, reducing latency and API quota usage. The `salesforceCacheReplicationWorker` periodically pulls data from Salesforce and writes it to the shared PostgreSQL database; the `salesforceCacheApi` reads that database and serves requests. The service also notifies the Quantum Lead system when relevant lead records are updated.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| Salesforce Cache API | `salesforceCacheApi` | Backend service | Java, Dropwizard | Read-only REST API for cached Salesforce data |
| Salesforce Cache Replication Worker | `salesforceCacheReplicationWorker` | Background worker | Java, Quartz | Quartz-based workers that replicate Salesforce data into the cache |
| Salesforce Cache Database | `continuumSalesforceCacheDatabase` | Data store | PostgreSQL | Stores cached Salesforce objects and replication state |
| Salesforce Cache Redis | `continuumSalesforceCacheRedis` | Cache | Redis | Cache and lookup store used by the service |

## Components by Container

### Salesforce Cache API (`salesforceCacheApi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Salesforce Cache Resource | Handles incoming HTTP requests for `/v0` endpoints | Dropwizard JAX-RS |
| Custom Authorizer | Authenticates and authorizes API requests using Basic Auth | Dropwizard Auth |
| Query Parser | Parses filter expressions submitted in API query parameters | ANTLR |
| Salesforce Cache Service | Business logic for querying cached Salesforce data | Java |
| Salesforce Cache DAO | Database access for cached objects and configuration records | JDBI |
| Redis Client | Reads and writes cached values for lookup and auth | Jedis |
| API Metrics | Publishes API metrics to the metrics pipeline | Telegraf |

### Salesforce Cache Replication Worker (`salesforceCacheReplicationWorker`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Job Runner | Schedules and coordinates replication jobs | Quartz |
| Cacher Job Source | Builds Quartz jobs and triggers from cached object config | Quartz |
| Cacher Job | Fetches Salesforce records and persists updates | Quartz |
| Unstaler Job | Removes stale cached records from the database | Quartz |
| Salesforce Batch Iterator | Fetches Salesforce records in configurable batch sizes | Java |
| Read-only Salesforce Client | HTTP client for Salesforce API calls | OkHttp |
| Salesforce Update Persister | Writes updates and notifies downstream systems | Java |
| Quantum Lead Updater | Sends lead-related updates to the Quantum Lead system | HTTP Client |
| Replication Metrics | Publishes replication metrics to the metrics pipeline | Telegraf |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `salesforceCacheApi` | `continuumSalesforceCacheDatabase` | Reads cached objects | JDBI/PostgreSQL |
| `salesforceCacheApi` | `continuumSalesforceCacheRedis` | Reads and writes cached values | Redis |
| `salesforceCacheReplicationWorker` | `salesForce` | Reads Salesforce data | Salesforce API |
| `salesforceCacheReplicationWorker` | `continuumSalesforceCacheDatabase` | Writes cached objects | JDBI/PostgreSQL |
| `salesforceCacheReplicationWorker` | `quantumLeadSystem` | Sends lead updates | HTTP |

## Architecture Diagram References

- System context: `contexts-salesforce-cache`
- Container: `containers-salesforce-cache`
- Component (API): `components-salesforce-cache-api`
- Component (Replication Worker): `components-salesforce-cache-replication-worker`
