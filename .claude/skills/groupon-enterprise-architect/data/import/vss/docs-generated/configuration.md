---
service: "vss"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [config-files, env-vars, k8s-secrets]
---

# Configuration

## Overview

VSS is configured via YAML configuration files following the JTier/Dropwizard convention. The active config file is selected at startup via the `JTIER_RUN_CONFIG` environment variable, which points to an environment-specific YAML file. Secrets (database credentials, API keys, mbus credentials) are injected via Kubernetes secrets managed through the RAPT secrets toolchain. Non-secret environment-specific values are set via `envVars` in the `.meta/deployment/cloud/components/app/` files.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the active JTier YAML configuration file for the running environment | yes | None | env (Kubernetes `envVars`) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `mbusEnable` | Enables or disables JMS message bus consumer subscription | — | global (per config file) |
| `quartzJobEnable` | Enables or disables the Quartz backfill scheduler | — | global (per config file) |
| `displaySearchQuery` | Controls whether the raw search query string is logged | — | global (per config file) |
| `isVssService` | Feature flag to enable/disable core VSS service processing | — | global (per config file) |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `development.yml` | YAML (symlink) | Points to `src/main/resources/config/development.yml`; used for local development |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Common Kubernetes deployment settings (image, ports, resource requests, scaling defaults) |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging environment overrides (region, namespace, scaling, memory) |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production environment overrides (region, namespace, scaling, memory) |
| `doc/swagger/swagger.yaml` | YAML | OpenAPI 2.0 API spec |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `mysql_ro_config` | Read-only MySQL connection credentials (host, port, user, password) | k8s-secret (RAPT-managed) |
| `mysql_rw_config` | Read-write MySQL connection credentials (host, port, user, password) | k8s-secret (RAPT-managed) |
| `messageBus` credentials | JMS mbus connection credentials | k8s-secret (RAPT-managed) |
| `deleteUserSecretKey` | API key for authorizing `POST /v1/obfuscate/users` requests | k8s-secret (RAPT-managed) |
| `serviceClients` | Retrofit client base URLs and credentials for Users Service, VIS, VIS 2.0 | k8s-secret (RAPT-managed) |
| `producerConfig` | JMS producer host/port/topic configuration | k8s-secret (RAPT-managed) |

> Secret values are NEVER documented. Only names and rotation policies. Secrets are managed via `.meta/deployment/cloud/secrets/` and the `raptor-cli` toolchain.

## Per-Environment Overrides

| Setting | Staging (`staging-us-central1`) | Production (`production-us-central1`) |
|---------|---------------------------------|---------------------------------------|
| `JTIER_RUN_CONFIG` | `/var/groupon/jtier/config/cloud/staging-us-central1.yml` | `/var/groupon/jtier/config/cloud/production-us-central1.yml` |
| `minReplicas` | 1 | 1 |
| `maxReplicas` | 2 | 15 |
| Memory request | 3 Gi | 10 Gi |
| Memory limit | 3 Gi | 13 Gi |
| CPU request | 200m | 300m |
| Kubernetes namespace | `vss-staging` | `vss-production` |
| VIP | `vss.us-central1.conveyor.stable.gcp.groupondev.com` | `vss.us-central1.conveyor.prod.gcp.groupondev.com` |
| Filebeat Kafka endpoint | `kafka-elk-broker-staging.snc1` | `kafka-elk-broker.snc1` |

## Key Application Configuration Properties

| Property | Config Key | Purpose |
|----------|-----------|---------|
| Voucher units batch size | `voucherUnitsBatchSize` | Controls the number of voucher units processed per backfill batch |
| Backfill thread count | `numberOfThreadsForBackfill` | Number of concurrent threads used by the backfill scheduler |
| Allowed client IDs | `clientIds` | Whitelist of client IDs permitted to call the search API |
| API query threshold | Constant `API_QUERY_THRESHOLD=3` | Minimum query length before search is executed |
| Thread pool size | Constant `THREAD_POOL=800` | Maximum number of threads in the service thread pool |
| Max users per delete | Constant `MAX_DELETE_USERS_ALLOWED=50` | Maximum number of users that can be obfuscated in a single request |
