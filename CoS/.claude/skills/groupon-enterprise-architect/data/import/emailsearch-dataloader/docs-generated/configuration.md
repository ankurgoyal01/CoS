---
service: "emailsearch-dataloader"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, k8s-secret]
---

# Configuration

## Overview

The Email Search Dataloader is configured through a combination of JTier runtime YAML configuration files and environment variables. The active configuration file is selected by the `JTIER_RUN_CONFIG` environment variable, which points to an environment- and region-specific YAML file inside the container (e.g., `/var/groupon/jtier/config/cloud/production-us-central1.yml`). The YAML files are not present in the source repository — they are injected at deployment time by the JTier platform. Kafka TLS certificates are injected as Kubernetes secrets. All secret values (database credentials, API tokens, webhook URLs) are stored externally and referenced by name in the deployment configuration.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the JTier runtime YAML config file inside the container | yes | None | helm / deployment |
| `KAFKA_ENDPOINT` | Kafka broker bootstrap address (e.g., `kafka-grpn-kafka-bootstrap.kafka-production.svc.cluster.local:9093`) | yes (Kafka regions) | None | helm / deployment env |
| `MALLOC_ARENA_MAX` | Limits glibc memory arenas to prevent virtual memory explosion causing OOM kills | no | `4` | common deployment YAML |
| `MIN_RAM_PERCENTAGE` | JVM minimum heap as percentage of container memory | no | `80.0` | common deployment YAML |
| `MAX_RAM_PERCENTAGE` | JVM maximum heap as percentage of container memory | no | `80.0` | common deployment YAML |
| `AVAILABILITY_ZONE_ID` | Populated at runtime from EC2 instance metadata (AWS regions only); used for zone-aware configuration | no | Fetched from `169.254.169.254` | Dockerfile CMD |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

## Feature Flags

> No evidence found in codebase of feature flags managed by a flag system (e.g., LaunchDarkly, Unleash). Behavioral flags such as `dryRun` (in `DecisionConfig`) and `autoRollout` (per campaign) are part of the JTier runtime YAML config and are campaign-level properties respectively.

### Notable Runtime Config Flags

| Flag (config key) | Purpose | Scope |
|---|---|---|
| `appConfig.dryRun` (inferred via `DecisionConfig.dryRun()`) | When true, decision evaluation runs but rollout commands are not sent to Campaign Management Service | global (per job config) |
| `appConfig.countries` | Set of country codes the service processes campaigns for | global |
| `appConfig.casExploitSendSlotMinutes` | Per-country, per-media-type exploit send slot configuration for CAS campaigns | per-country |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `/var/groupon/jtier/config/cloud/production-us-west-1.yml` | YAML | Production US West 1 runtime config (injected at deploy) |
| `/var/groupon/jtier/config/cloud/production-us-central1.yml` | YAML | Production US Central 1 runtime config (injected at deploy) |
| `/var/groupon/jtier/config/cloud/production-eu-west-1.yml` | YAML | Production EU West 1 runtime config (injected at deploy) |
| `/var/groupon/jtier/config/cloud/staging-us-central1.yml` | YAML | Staging US Central 1 runtime config (injected at deploy) |
| `/var/groupon/jtier/config/cloud/staging-europe-west1.yml` | YAML | Staging Europe West 1 runtime config (injected at deploy) |
| `/var/groupon/jtier/config/cloud/staging-us-west-1.yml` | YAML | Staging US West 1 runtime config (injected at deploy) |
| `/var/groupon/jtier/config/cloud/staging-us-west-2.yml` | YAML | Staging US West 2 runtime config (injected at deploy) |
| `/var/groupon/jtier/logs/steno.log` | JSON | Structured application log output (Steno format) |

### Known Configuration Keys (from `EmailSearchDataloaderConfiguration`)

| Key | Type | Purpose |
|-----|------|---------|
| `postgresED` | `PostgresConfig` | Email Search PostgreSQL connection (host, port, db, pool) |
| `postgresDE` | `PostgresConfig` | Decision Engine PostgreSQL connection |
| `postgresCP` | `PostgresConfig` | Campaign Performance PostgreSQL connection |
| `mysql` | `MySQLConfig` | Campaign Performance MySQL connection |
| `kafka` | `KafkaConfig` | Kafka consumer configuration map |
| `parser` | `List<ParserConfig>` | Kafka message parser definitions (separator, field index) |
| `hive` | `HiveConfig` | Hive JDBC URL, database name, user, pool size, connection timeout |
| `quartz` | `QuartzConfiguration` | Quartz scheduler settings and job definitions |
| `subscription` | `RetrofitConfiguration` | Subscription Service client base URL and timeouts |
| `wavefront_api` | `RetrofitConfiguration` | Wavefront metrics API client |
| `notification` | `RetrofitConfiguration` | Slack notification webhook client |
| `gchat_notification` | `RetrofitConfiguration` | Google Chat notification webhook client |
| `elk_data_service_na` | `RetrofitConfiguration` | ELK Data Service NA client |
| `elk_data_service_emea` | `RetrofitConfiguration` | ELK Data Service EMEA client |
| `campaignPerformanceServiceClient` | `RetrofitConfiguration` | Campaign Performance Service client |
| `inboxManagementEmailUiServiceClient` | `RetrofitConfiguration` | Inbox Management Email UI client |
| `inboxManagementPushUiServiceClient` | `RetrofitConfiguration` | Inbox Management Push UI client |
| `campaignManagementServiceClient` | `RetrofitConfiguration` | Campaign Management Service client |
| `phraseeClient` | `RetrofitConfiguration` | Phrasee Service client |
| `arbitrationServiceClient` | `RetrofitConfiguration` | Arbitration Service client |
| `rocketman-commercial` | `RocketmanCommercialConfig` | Rocketman Commercial Service config |
| `appConfig` | `AppConfig` | Application-level config (countries, timezones, experiment settings) |
| `filter_emails` | `List<String>` | Email addresses to exclude from processing |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `emailsearch-dataloader-staging-tls-identity` | Kafka mTLS client certificate and key for staging regions | k8s-secret |
| Production Kafka TLS secret | Kafka mTLS client certificate and key for production regions | k8s-secret (name not in source) |
| Database credentials | Usernames and passwords for PostgreSQL (ED, DE, CP) and MySQL connections | Not directly observable; injected via JTier config |
| Hive credentials | Hive JDBC username and password | Not directly observable; injected via JTier config |
| Wavefront API token | Authentication for Wavefront metrics API | Not directly observable; injected via JTier config |
| Slack/GChat webhook URLs | Notification webhook endpoint URLs | Not directly observable; injected via JTier config |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Environment | Region | Cloud | Notable Overrides |
|------------|--------|-------|------------------|
| staging | us-central1 | GCP | 1–2 replicas; VPA enabled; `KAFKA_ENDPOINT` set; mTLS secret mounted; TLS script as entrypoint |
| staging | europe-west1 | GCP | 1–2 replicas; mTLS secret mounted |
| staging | us-west-1 | AWS | 1–2 replicas; mTLS secret mounted |
| staging | us-west-2 | AWS | 1–2 replicas |
| production | us-central1 | GCP | 12 replicas fixed; VPA enabled; `KAFKA_ENDPOINT` set; 600m CPU / 1Gi–6Gi memory; TLS script as entrypoint |
| production | us-west-1 | AWS | 12 replicas fixed; TLS script as entrypoint (no explicit Kafka endpoint — inferred from config file) |
| production | eu-west-1 | AWS | 8–12 replicas; `KAFKA_ENDPOINT` set; TLS script as entrypoint |
| common (all) | all | — | `MALLOC_ARENA_MAX=4`, `MIN_RAM_PERCENTAGE=80.0`, `MAX_RAM_PERCENTAGE=80.0`; HTTP port 9000; JMX port 8009; APM enabled; readiness/liveness at `/grpn/healthcheck:9000` |
