---
service: "deal-performance-api-v2"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 0
internal_count: 1
---

# Integrations

## Overview

Deal Performance API V2 has a single downstream dependency: the GDS-managed PostgreSQL database. It has no external third-party integrations, no outbound HTTP calls to other Groupon microservices, and no message bus connections. The service's only integration touchpoint is the database read path. The service is consumed by internal Groupon tools and pipelines via its REST API.

## External Dependencies

> No evidence found in codebase of any external (third-party) system integrations.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Deal Performance PostgreSQL (GDS) | JDBC/PostgreSQL | Read pre-aggregated deal performance and attribute metrics | `continuumDealPerformancePostgres` |

### Deal Performance PostgreSQL Detail

- **Protocol**: JDBC over PostgreSQL wire protocol (port 5432)
- **Connection management**: JTier `jtier-daas-postgres` connection pool; separate pool for primary (read-write) and session/replica (read-only) connections
- **Auth**: `${DAAS_APP_USERNAME}` / `${DAAS_APP_PASSWORD}` injected at runtime via Kubernetes secrets
- **Purpose**: All query results served by the API originate from this database
- **Failure mode**: If the database is unavailable, all API endpoints return errors; no fallback or cached response is served
- **Circuit breaker**: No evidence found in codebase of a circuit breaker pattern; connection pool exhaustion produces JDBC errors propagated to API consumers

## Consumed By

> Upstream consumers are tracked in the central architecture model. Known consumers based on `.service.yml` and `doc/OWNERS_MANUAL.md`:

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Marketing Services tools | REST/HTTP | Deal campaign analysis and performance reporting |
| Search and Recommendation Ranking pipeline | REST/HTTP | Scoring and ranking signal data |

## Dependency Health

The service exposes a heartbeat-based health check at `/grpn/healthcheck`. Database connectivity is tested via the JTier `DealPerformanceApiV2HealthCheck`. Wavefront dashboards track DB-out latency metrics. If database latency is high, the `#gds-daas` Slack channel is the recommended escalation path (per `doc/OWNERS_MANUAL.md`).
