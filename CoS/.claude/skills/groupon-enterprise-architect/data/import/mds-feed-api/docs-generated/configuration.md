---
service: "mds-feed-api"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, k8s-secrets]
---

# Configuration

## Overview

The service uses the JTier Dropwizard configuration pattern: a YAML configuration file is selected at startup via the `JTIER_RUN_CONFIG` environment variable, which points to an environment-specific YAML file bundled in the container. Configuration covers PostgreSQL connection, Quartz scheduler, Spark/Livy client settings, message bus (Mbus) destinations, feed uploader settings, GCP credentials, security keys, and dispatcher settings. Secrets (database credentials, GCP service account keys, Mbus credentials) are injected at runtime via Kubernetes secrets and not stored in source code.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the active YAML config file inside the container | yes | None | Kubernetes env (`envVars`) |
| `JTIER_USER_HOME` | Home directory used to locate `~/.aws/credentials` for S3 uploads | yes | None | JTier platform |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

## Feature Flags

> No evidence found in codebase. No explicit feature flag system is in use; feature-level control is achieved via feed configuration `status` field (ACTIVE/DRAFT/PENDING/DELETED) and the `feedJobStaging.isolatedEnvIds` config list for isolated staging environments.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/config/development.yml` (referenced by `development.yml`) | YAML | Local development configuration |
| `/var/groupon/jtier/config/cloud/production-us-central1.yml` | YAML | Production GCP (us-central1) runtime config |
| `/var/groupon/jtier/config/cloud/staging-us-central1.yml` | YAML | Staging GCP (us-central1) runtime config |
| `/var/groupon/jtier/config/cloud/rde-dev-us-west-2.yml` | YAML | RDE dev (us-west-2) runtime config |
| `doc/swagger/swagger.yaml` | YAML | OpenAPI 2.0 specification |
| `doc/swagger/config.yml` | YAML | Swagger UI configuration |
| `.meta/deployment/cloud/components/api/common.yml` | YAML | Shared Kubernetes deployment config (image, ports, resources) |
| `.meta/deployment/cloud/components/api/production-us-central1.yml` | YAML | Production-specific Kubernetes overrides (scaling, VPA, volumes) |
| `.meta/deployment/cloud/components/api/staging-us-central1.yml` | YAML | Staging-specific Kubernetes overrides |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `postgres` credentials | PostgreSQL username, password, host | k8s-secret (mds-feed-api-secrets) |
| `mbus.destinations[0].username` / `password` | Mbus authentication | k8s-secret |
| `googleCloud.clientId` / `clientEmail` / `privateKey` / `privateKeyId` | GCP service account for GCS access | k8s-secret |
| `security.*` (RSA key config) | Encryption key for SFTP private keys stored in DB | k8s-secret |
| AWS credentials | S3 upload access (`~/.aws/credentials` per pod) | k8s-secret / pod volume |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Setting | Development | Staging (us-central1) | Production (us-central1) |
|---------|------------|----------------------|--------------------------|
| `JTIER_RUN_CONFIG` | `config/development.yml` | `cloud/staging-us-central1.yml` | `cloud/production-us-central1.yml` |
| Kubernetes namespace | - | `mds-feed-staging` | `mds-feed-production` |
| Min replicas | - | 1 | 3 |
| Max replicas | - | 2 | 10 |
| Memory request/limit | 1 Gi / 2 Gi | 1 Gi / 4 Gi | 5 Gi / 7 Gi |
| CPU request (main) | 50m | 50m | 500m |
| VPA | disabled | enabled | enabled |
| Feed download volume (`/var/tmp/`) | - | 100G | 100G |
| Filebeat Kafka endpoint | - | MSK (staging) | `kafka-elk-broker.snc1` |

### Key configuration block names (in YAML config files)

| Config Key | Type | Purpose |
|------------|------|---------|
| `postgres` | PostgresConfig | Database connection, pool settings |
| `quartz` | QuartzConfiguration | Quartz scheduler and job definitions |
| `sparkConfig` | SparkConfig | Spark job artifact URL, Livy cluster settings |
| `livyServiceGCPClient` | RetrofitConfiguration | Livy REST client base URL and timeout |
| `dispatcher` | DispatcherConfig | GCS bucket/path settings for download URL generation |
| `cleanOldDataConfig` | CleanOldDataConfig | Retention age for batch/metrics cleanup |
| `clientId` | ClientIdConfiguration | Client ID auth configuration |
| `mbus` | MbusConfiguration | Mbus host, port, destination (`mds-feed-publishing`) |
| `feedUploader` | UploaderCoreConfig | Thread pool settings for async upload executor |
| `security` | SecurityConfig | RSA key for encrypting SFTP credentials |
| `promoteConfig` | PromoteConfig | Configuration for the feed promote operation |
| `feedJobStaging.isolatedEnvIds` | List<String> | Allowed isolated staging environment IDs |
| `googleCloud` | GoogleCloudConfig | GCP project ID and service account credentials |
| `feedOverrides` | FeedOverrides | Global feed generation overrides |
