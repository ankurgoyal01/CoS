---
service: "relevance-service"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 2
internal_count: 1
---

# Integrations

## Overview

The Relevance Service integrates with two external systems (Booster and the Enterprise Data Warehouse) and one internal container (Feynman Search). The service is in a transitional state where search workloads are being migrated from the legacy Feynman Search / Elasticsearch stack to the next-generation Booster engine.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Booster | API | Next-generation search and ranking engine; progressively receiving offloaded workloads from Feynman Search | yes | `booster` |
| Enterprise Data Warehouse (EDW) | Batch | Feature vector source for ranking models and data source for index building | yes | `edw` |

### Booster Detail

- **Protocol**: API (REST)
- **Base URL / SDK**: Internal service endpoint
- **Auth**: Internal service authentication
- **Purpose**: Booster is the next-generation search and ranking engine that is progressively replacing Feynman Search. The Feynman Search component within RAPI offloads an increasing share of ranking and search workloads to Booster via its API.
- **Failure mode**: If Booster is unavailable, the service falls back to Feynman Search / Elasticsearch for the affected workloads. During the migration period, Feynman Search remains the fallback path.
- **Circuit breaker**: Expected given the progressive migration pattern; exact implementation details in source repository

### Enterprise Data Warehouse (EDW) Detail

- **Protocol**: Batch
- **Base URL / SDK**: Internal data warehouse connectivity
- **Auth**: Service credentials
- **Purpose**: EDW serves two roles: (1) the Features Client reads feature vectors used by the Ranking Engine for ML-based relevance scoring, and (2) the Indexer reads deal data for building and refreshing Elasticsearch indexes.
- **Failure mode**: If EDW is unavailable, the Indexer cannot rebuild indexes and the Features Client cannot fetch fresh feature vectors. Stale cached features and existing indexes continue to serve queries at reduced quality.
- **Circuit breaker**: Batch operations are retried on schedule; exact retry policy in source repository

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Feynman Search | REST (SyncAPI) | Legacy Elasticsearch-backed search for deal browse and search queries | `continuumFeynmanSearch` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| API Proxy | REST | Routes consumer search and browse requests to RAPI |
| Consumer web/mobile apps | REST (via API Proxy) | End-user search and browse experiences |

> Upstream consumers are tracked in the central architecture model. The API Proxy is the primary gateway routing traffic to the Relevance API.

## Dependency Health

- **Feynman Search (Elasticsearch)**: Health monitored via Elasticsearch cluster health API; degraded cluster status triggers alerts. Search queries fail fast if the cluster is red.
- **Booster**: Health monitored via API health endpoints; traffic is gradually shifted via feature flags, allowing rollback to Feynman Search if Booster degrades.
- **EDW**: Batch jobs monitored for completion; stale index or feature data triggers alerting but does not cause immediate service failure since existing indexes continue serving.
