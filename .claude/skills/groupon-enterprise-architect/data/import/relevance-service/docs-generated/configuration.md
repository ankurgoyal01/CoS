---
service: "relevance-service"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

The Relevance Service is configured through environment variables for infrastructure and deployment settings, and application configuration files for search tuning, ranking model parameters, and feature flags controlling the Booster migration. Exact configuration sources and formats are defined in the source repository.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `ELASTICSEARCH_HOSTS` | Elasticsearch cluster endpoints for Feynman Search | yes | none | env |
| `ELASTICSEARCH_CLUSTER_NAME` | Elasticsearch cluster name | yes | none | env |
| `EDW_CONNECTION_STRING` | Enterprise Data Warehouse connection details for batch reads | yes | none | env / vault |
| `BOOSTER_API_URL` | Booster engine API endpoint | yes | none | env |
| `SERVER_PORT` | HTTP port for the Vert.x server | no | 8080 | env |
| `LOG_LEVEL` | Application log level | no | INFO | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed. Exact variable names may differ; see the source repository for the canonical list.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `booster.migration.enabled` | Enable progressive offload of search/ranking workloads to Booster | false | global |
| `booster.migration.traffic_percentage` | Percentage of search traffic routed to Booster vs. Feynman Search | 0 | global |
| `ranking.model.version` | Active ranking model version for relevance scoring | latest | global |
| `indexer.batch.enabled` | Enable/disable the batch indexing process | true | global |

> Feature flag names are inferred from the architecture's progressive migration pattern. See the source repository for the exact flag names and configuration mechanism.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `application.yml` | yaml | Primary application configuration (server, Elasticsearch, EDW settings) |
| `ranking-config.yml` | yaml | Ranking model configuration and feature weight tuning |

> Exact config file paths and formats should be verified against the source repository.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| EDW credentials | Authentication for Enterprise Data Warehouse batch reads | vault |
| Elasticsearch credentials | Authentication for Elasticsearch cluster access (if secured) | vault |
| Booster API key | Authentication for Booster API calls (if required) | vault |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: Points to local or shared-dev Elasticsearch cluster; Booster migration disabled; reduced index size
- **Staging**: Points to staging Elasticsearch and EDW; Booster migration enabled at low traffic percentage for validation
- **Production**: Full Elasticsearch cluster; Booster migration percentage tuned based on rollout status; production ranking models active
