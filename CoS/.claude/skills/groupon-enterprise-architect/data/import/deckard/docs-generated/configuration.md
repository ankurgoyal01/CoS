---
service: "deckard"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

Deckard is configured through a hierarchy of JSON config files (one set per environment) and a small number of Docker environment variables. The main entry point is `mainConf.json`, which references environment-specific sub-configs (`applicationConf.json`, `asyncUpdateConf.json`, and files under `config/`). Secrets (Redis host addresses, mbus credentials) are embedded in environment-specific config files stored in a separate `deckard-config` repository. The active config file is selected at container startup via the `CONFIG` environment variable.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `CONFIG` | Path to the environment-specific `mainConf.json` to load at startup | Yes | `conf/mainConfStagingNA.json` | Docker / Kubernetes deployment YAML |
| `MIN_HEAP_SIZE` | JVM minimum heap size (`-Xms`) | Yes | `1G` | Docker / Kubernetes deployment YAML |
| `MAX_HEAP_SIZE` | JVM maximum heap size (`-Xmx`) | Yes | `1G` | Docker / Kubernetes deployment YAML |
| `HTTP_PORT` | HTTP listener port | No | `8001` | Dockerfile |
| `INSTANCES` | Number of Vert.x instance threads | No | `1` | Dockerfile |
| `AINT_DISABLED` | Disables AINT monitoring agent | No | `true` | Dockerfile |
| `MALLOC_ARENA_MAX` | Linux memory arena limit to prevent vmem explosion | No | `4` | Kubernetes common.yml |
| `VAR_DIR_PREFIX` | Base directory for heartbeat and status files | No | `/var/groupon/deckard` | Dockerfile |
| `ELASTIC_APM_VERIFY_SERVER_CERT` | Disables APM TLS cert verification | No | `"false"` | Kubernetes environment YAMLs |
| `VERTX_OPTS` | Full JVM / Vert.x options string (heap dump, JMX, Jolokia, logging) | No | (set in Dockerfile) | Dockerfile |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `servingStaleData` | When `true`, returns stale cache data rather than blocking on a fresh fetch | `false` | global (per-environment via `config/cache.json`) |
| `fail` | When `true`, fails the entire request if any inventory service errors | `false` | global (per-environment via `config/partialResults.json`) |
| `failOnGift` | When `true`, fails if gifted unit retrieval encounters errors | `false` | global (per-environment via `config/partialResults.json`) |
| `enabled` (per client) | Enables or disables a specific inventory service client (e.g., glive, vis) | `true` | per-service client in `mainConf.json` |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/conf/{env}/mainConf.json` | JSON | Root config: wires all verticles, metrics, and sub-configs; loaded at startup via `CONFIG` env var |
| `src/main/conf/{env}/applicationConf.json` | JSON | Application-level config: HTTP port, Redis cache host/port, mbus host/port/topics, subscription IDs |
| `src/main/conf/{env}/asyncUpdateConf.json` | JSON | Async updater config: Redis async queue host/port, dequeue interval (1000 ms), dequeue batch size (100) |
| `src/main/conf/{env}/config/cache.json` | JSON | Cache TTL policy: `referenceConsumerCacheStaleAge` (PT15M), `referenceConsumerCacheExpirationAge` (P1D), `servingStaleData` flag |
| `src/main/conf/{env}/config/inventoryClient.json` | JSON | Inventory service mapping: maps service IDs (`getaways`, `goods`, `vis`, etc.) to client names, unit ID prefixes, and data model overrides |
| `src/main/conf/{env}/config/pagination.json` | JSON | Internal pagination limit: `limit` (500 — max units fetched before slicing for API response) |
| `src/main/conf/{env}/config/partialResults.json` | JSON | Partial result policy: `fail` and `failOnGift` flags controlling error propagation |
| `src/main/conf/bundle/exception.properties` | properties | Exception message bundle for localized error messages |
| `src/main/conf/{env}/stubs/` | YAML | Local development stubs for inventory client responses (development environment only) |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Kubernetes common deployment config: scaling, ports, probes, logging, APM, Jolokia, VPA |
| `.meta/deployment/cloud/components/app/{env}.yml` | YAML | Per-environment Kubernetes overrides: region, VPC, replica counts, resource limits, APM endpoint |
| `.meta/deployment/cloud/components/telegraf-agent/{env}.yml` | YAML | Telegraf sidecar config per environment for metrics collection |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Redis cache host/port | Connection details for `continuumCacheRedisCluster` | Environment-specific `applicationConf.json` (deckard-config repo) |
| Redis async host/port | Connection details for `continuumAsyncUpdateRedis` | Environment-specific `asyncUpdateConf.json` (deckard-config repo) |
| mbus `serviceHost` / `port` | Groupon Message Bus STOMP connection endpoint | Environment-specific `applicationConf.json` (deckard-config repo) |
| Elastic APM endpoint | APM server URL for production tracing | Kubernetes environment YAML (`apm.endpoint`) |

> Secret values are NEVER documented. Only names and rotation policies are listed here.

## Per-Environment Overrides

| Environment | Config Key | Notable Differences |
|-------------|-----------|---------------------|
| `development` | `conf/development/mainConf.json` | Uses local stubs for inventory clients; local Redis on port 7000 (cluster) and 6379 (standalone) |
| `dev_us_west_1` | `conf/dev_us_west_1/mainConf.json` | mbus at `mbus-na-stable.grpn-dse-stable.us-west-1.aws.groupondev.com:61613` |
| `dev_us_west_2` | `conf/dev_us_west_2/mainConf.json` | West-2 region variant |
| `staging_us_central_1` | `conf/staging_us_central_1/mainConf.json` | GCP us-central1 staging; 2–4 GB heap; 1–6 replicas; APM enabled |
| `staging_europe_west_1` | `conf/staging_europe_west_1/mainConf.json` | GCP europe-west1 staging |
| `production_us_central_1` | `conf/production_us_central_1/mainConf.json` | GCP us-central1 production; 5 GB heap; 4–20 replicas; 8–10 GB memory |
| `production_europe_west_1` | `conf/production_europe_west_1/mainConf.json` | GCP europe-west1 production; 5 GB heap; 2–20 replicas; 8–10 GB memory |
