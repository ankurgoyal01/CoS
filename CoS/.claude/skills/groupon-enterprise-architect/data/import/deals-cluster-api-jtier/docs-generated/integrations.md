---
service: "deals-cluster-api-jtier"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 0
internal_count: 3
---

# Integrations

## Overview

The Deals Cluster API has three internal dependencies within the Continuum platform: the PostgreSQL database (owned), the Marketing Deal Service (for applying/removing deal tags), and the Deal Catalog Service (for enriching deal data). It also depends on the Groupon JMS message bus infrastructure for the tagging workflow. No external (third-party) dependencies are evident from the codebase.

## External Dependencies

> No evidence found in codebase of third-party external integrations.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| `continuumDealsClusterDatabase` | JDBC/PostgreSQL | Primary data store for clusters, rules, top clusters, and tagging audit data | `continuumDealsClusterDatabase` |
| `continuumMarketingDealService` | REST/HTTP | Applies and removes tags on deals during tagging use case execution | `continuumMarketingDealService` |
| `continuumDealCatalogService` | REST/HTTP | Fetches deal catalog data used in cluster enrichment | `continuumDealCatalogService` |
| JMS Message Bus | JMS (mbus) | Receives tagging/untagging messages published by Use Case Execute Service; consumed by internal workers | `messageBusTaggingQueue`, `messageBusUntaggingQueue` |

### `continuumMarketingDealService` Detail

- **Protocol**: REST/HTTP
- **Base URL / SDK**: Accessed via `jtier-retrofit`-based DM API Client component
- **Auth**: JTier service-to-service auth
- **Purpose**: Receives tagging and untagging commands from the DM API Client after workers consume JMS messages; applies or removes deal tags in the Marketing Deal Service
- **Failure mode**: Worker retry via JMS; tagging audit records failures
- **Circuit breaker**: Not explicitly configured in available config

### `continuumDealCatalogService` Detail

- **Protocol**: REST/HTTP
- **Base URL / SDK**: Accessed via `jtier-retrofit`-based Deal Catalog Client component
- **Auth**: JTier service-to-service auth
- **Purpose**: Fetches deal catalog data to enrich cluster definitions
- **Failure mode**: Not explicitly documented; standard Retrofit HTTP error handling
- **Circuit breaker**: Not explicitly configured in available config

### JMS Message Bus Detail

- **Protocol**: JMS (Groupon mbus)
- **Base URL / SDK**: `jtier-messagebus-client` v0.4.1, `jtier-messagebus-dropwizard` v0.4.1
- **Auth**: Internal mbus credentials (managed via JTier secrets)
- **Purpose**: Decouples the tagging use case trigger (Use Case Execute Service) from the actual tag application (workers calling DM API)
- **Failure mode**: Messages remain in queue; workers retry on failure
- **Circuit breaker**: Not configured

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| `continuumDealsClusterSparkJob` | REST/HTTP | Fetches cluster rules to drive Spark-based cluster computation on GDOOP/Cerebro |
| Internal marketing tooling | REST/HTTP | Manages tagging use cases via `/mts/taggingaudit` and related endpoints |
| Site navigation surfaces | REST/HTTP | Queries `GET /topclusters` to power category and division navigation |

> Upstream consumers beyond the Spark Job are tracked in the central architecture model.

## Dependency Health

- Status endpoint: `GET /grpn/status` (port 8080)
- Admin/metrics port: 8081
- Wavefront dashboards monitor downstream call health (see [Runbook](runbook.md))
- No explicit circuit breaker or retry configuration found in the available repository files
