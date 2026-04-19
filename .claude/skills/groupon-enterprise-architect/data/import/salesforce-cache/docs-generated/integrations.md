---
service: "salesforce-cache"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 2
---

# Integrations

## Overview

Salesforce Cache has one critical external dependency (Salesforce CRM) and two internal dependencies (PostgreSQL database and Redis cache). It notifies the internal Quantum Lead system as a downstream side-effect of replication. Internal Groupon services consume the Salesforce Cache API using Basic Auth.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Salesforce CRM | REST (Salesforce API) | Source of truth for all replicated CRM object data | yes | `salesForce` (stub) |

### Salesforce CRM Detail

- **Protocol**: REST — Salesforce REST/SOQL API
- **Base URL / SDK**: `com.groupon.salesforce.httpclient:SalesforceHttpClient:1.13` (Groupon internal Salesforce HTTP client library)
- **Auth**: Salesforce OAuth / session-based authentication managed by the SalesforceHttpClient library
- **Purpose**: The `Read-only Salesforce Client` component fetches Salesforce object records in batches using the Salesforce API, filtering by `SystemModstamp` to retrieve only records modified since the last replication run
- **Failure mode**: When Salesforce is unavailable or returns errors, the cacher jobs fail and the `Cacher Error/Exception Occurred` alert fires; data in the cache becomes stale but the API continues to serve existing cached data
- **Circuit breaker**: No evidence found of an explicit circuit breaker; Salesforce outage status is monitored at trust.salesforce.com as part of incident response

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| PostgreSQL (reading-rainbow DB) | JDBI/PostgreSQL | Primary cache storage; read by API, written by replication worker | `continuumSalesforceCacheDatabase` |
| Redis | Redis protocol | API lookup and auth caching | `continuumSalesforceCacheRedis` |
| Quantum Lead System | HTTP | Receives lead update notifications from the replication worker after Account/lead record updates | `quantumLeadSystem` (stub) |
| Metrics Pipeline | Telegraf | Receives API and replication metrics | `metricsPipeline` (stub) |

### PostgreSQL Detail

- **Protocol**: JDBI3 over JDBC (PostgreSQL)
- **Libraries**: `jtier-jdbi3`, `jtier-daas-postgres`, `jdbi3-stringtemplate4`
- **Purpose**: Stores all cached Salesforce objects and replication configuration
- **Failure mode**: API returns errors if the database is unavailable; replication jobs fail and trigger alerts

### Redis Detail

- **Protocol**: Redis (via `dropwizard-redis`)
- **Purpose**: Caches lookup values and auth information in the API layer
- **Failure mode**: No evidence found of documented fallback behavior

### Quantum Lead System Detail

- **Protocol**: HTTP (via internal HTTP client)
- **Purpose**: Receives lead update notifications when Account or lead records are updated by the replication worker
- **Failure mode**: No evidence found of specific retry or circuit breaker configuration

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Internal Groupon services (multiple) | REST / HTTP Basic Auth | Read cached Salesforce CRM data (Account, Opportunity, Task, RecordType, etc.) |

> Upstream consumers are tracked in the central architecture model. Known consumer categories include any Groupon internal service requiring Salesforce CRM data without a direct Salesforce API dependency.

## Dependency Health

- Salesforce health is monitored externally at `trust.salesforce.com`.
- PostgreSQL connectivity is validated at service startup via JTier DaaS Postgres integration.
- Replication lag is monitored via Wavefront/Grafana cacher metrics dashboards; alerts fire when caching jobs stop producing expected metrics for configured objects.
