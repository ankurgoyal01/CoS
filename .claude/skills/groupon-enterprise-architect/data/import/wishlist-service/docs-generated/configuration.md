---
service: "wishlist-service"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, helm-values]
---

# Configuration

## Overview

The Wishlist Service is configured via YAML configuration files located at `src/main/resources/config/` (one per environment and region). The config file to load at startup is selected by the `JTIER_RUN_CONFIG` environment variable, which points to the appropriate YAML file path. Sensitive values (database passwords, MBus credentials) are injected as environment variables at runtime via Kubernetes secrets. The worker component activates background processing and MBus consumers via `ENABLE_JOBS` and `ENABLE_MBUS` environment variables.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the YAML config file to load at startup | Yes | None | helm values (per-environment deployment YAML) |
| `ENABLE_JOBS` | Enables the Quartz background job scheduler on the worker component | No (worker only) | `"false"` | helm values (`worker/common.yml`) |
| `ENABLE_MBUS` | Enables MBus consumer connections on the worker component | No (worker only) | `"false"` | helm values (`worker/common.yml`) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `featureToggleConfig.enableDbCache` | Enables DB-level caching layer | `false` | global (per config file) |
| `featureToggleConfig.enableClientCache` | Enables client-side caching of external service responses in Redis | `false` | global (per config file) |
| `featureToggleConfig.enableJedisCluster` | Routes Redis operations to the cluster endpoint instead of standalone | `false` | global (per config file) |
| `messageBusConfig.enableMbus` | Enables MBus consumer connections (also controlled by `ENABLE_MBUS` env var) | `true` | global (per config file) |
| `serviceConfig.enableRestApi` | Enables the REST API resources | `true` | global (per config file) |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/config/cloud/production-us-central1.yml` | YAML | Production US Central 1 (GCP) configuration |
| `src/main/resources/config/cloud/production-eu-west-1.yml` | YAML | Production EU West 1 configuration |
| `src/main/resources/config/cloud/staging-us-central1.yml` | YAML | Staging US Central 1 (GCP) configuration |
| `src/main/resources/config/cloud/staging-europe-west1.yml` | YAML | Staging Europe West 1 (GCP) configuration |
| `src/main/resources/config/cloud/staging-us-west-2.yml` | YAML | Staging US West 2 configuration |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Kubernetes app component deployment defaults (replicas, ports, resources) |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production GCP US Central 1 app overrides (min 2, max 60 replicas; 7Gi memory) |
| `.meta/deployment/cloud/components/worker/common.yml` | YAML | Kubernetes worker component deployment defaults (ENABLE_JOBS, ENABLE_MBUS) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| PostgreSQL application credentials | Database username and password for runtime connections | k8s-secret (injected via helm, path `.meta/deployment/cloud/secrets/cloud/<env>.yml`) |
| PostgreSQL DBA credentials | Database admin username and password for migration runs | k8s-secret |
| MBus credentials | STOMP username/password for MBus authentication | k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Staging**: Uses staging GCP DaaS PostgreSQL hosts; background processing enabled (`ENABLE_JOBS=true`, `ENABLE_MBUS=true`); all external service URLs use staging VIPs; Redis cluster enabled; MBus pointing to staging broker.
- **Production**: Uses production GCP DaaS PostgreSQL hosts; background processing controlled exclusively via `ENABLE_JOBS` and `ENABLE_MBUS` env vars on the worker component; Redis cluster enabled; MBus pointing to production broker (`mbus-prod-na.us-central1.mbus.prod.gcp.groupondev.com`).

## Service Limits (from `ServiceConfig`)

| Parameter | Default Value | Config Key |
|-----------|---------------|-----------|
| Max wishlist lists per user | 50 | `serviceConfig.maxLists` |
| Max wishlist items per list | 100 | `serviceConfig.maxItems` |
| Default page size | 100 | `serviceConfig.defaultPageSize` |
| Max search results | 20 | `serviceConfig.maxSearches` |
| Max user bucket partitions | 5000 | `serviceConfig.maxUserBuckets` |
| Background task thread pool size | 200 | `serviceConfig.backgroundTasksThreadPoolSize` |
| DAO thread pool size | 100 | `serviceConfig.daoThreadPoolSize` |
| Price-drop cache expiry | 24 hours | `serviceConfig.priceDropCacheExpiry` |
| User cache expiry | 24 hours | `serviceConfig.userCacheExpiry` |
| List cache expiry | 24 hours | `serviceConfig.listCacheExpiry` |

## Quartz Scheduler Configuration

Background jobs are configured with two Quartz triggers in the YAML config under the `quartz` section:

| Job Name | Class | Schedule (cron) |
|----------|-------|-----------------|
| `UserDequeueJob` | `backgroundjobs.jobs.UserDequeueJob` | Every 2 seconds (`0/2 * * ? * * *`) |
| `UserEnqueueJob` | `backgroundjobs.jobs.UserEnqueueJob` | Every 5 seconds (`0/5 * * ? * * *`) |
