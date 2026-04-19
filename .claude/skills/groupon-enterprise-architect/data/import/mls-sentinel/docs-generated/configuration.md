---
service: "mls-sentinel"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, k8s-secret]
---

# Configuration

## Overview

MLS Sentinel is configured via a JTier YAML config file whose path is injected at runtime via the `JTIER_RUN_CONFIG` environment variable. Per-environment config files reside at `config/cloud/<env>-<region>.yml` inside the container. Cloud deployments additionally receive non-secret environment variables via the Conveyor deployment manifests (`.meta/deployment/cloud/components/app/<env-region>.yml`). Secrets (database credentials, Kafka TLS certificates, client credentials) are mounted from Kubernetes secrets into the container filesystem.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the JTier YAML config file inside the container | yes | — | Conveyor deployment manifest (env-specific) |
| `OTEL_SDK_DISABLED` | Enables or disables the OpenTelemetry Java agent | no | `true` (Dockerfile default) | Conveyor manifest overrides to `false` in cloud envs |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | OTLP endpoint for trace export | no | — | Conveyor manifest; e.g., `http://otel-collector-opentelemetry-collector.tempo-production:4318` |
| `OTEL_RESOURCE_ATTRIBUTES` | Service name for distributed tracing | no | — | Conveyor manifest; value: `service.name=mls-sentinel` |
| `JAVA_OPTS` | JVM options; includes OpenTelemetry javaagent path | no | `-javaagent:/var/groupon/jtier/opentelemetry-javaagent.jar` | Dockerfile |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `saveHistoryEventInHistoryService` | When enabled, history events are persisted to the History DB | — | per-service (JTier YAML) |
| `sendHistoryEventToYang` | When enabled, history events are forwarded to MLS Yang via `mls.HistoryEvent` Kafka topic | — | per-service (JTier YAML) |
| `useMerchantBlacklistOnVisTimeout` | When enabled, merchants that caused VIS count timeouts are temporarily blacklisted | — | per-service (JTier YAML) |
| `mbusConfiguration[*].enabled` | Enables or disables individual MBus processor registrations at startup | — | per-processor (JTier YAML) |

Note: `saveHistoryEventInHistoryService` and `sendHistoryEventToYang` are mutually exclusive — at least one must be `true` (enforced by a `@Value.Check` validation at startup).

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/cloud/production-us-central1.yml` | YAML | JTier runtime config for production US (GCP us-central1) |
| `config/cloud/staging-us-central1.yml` | YAML | JTier runtime config for staging US (GCP us-central1) |
| `config/cloud/production-eu-west-1.yml` | YAML | JTier runtime config for production EU (AWS eu-west-1) |
| `config/cloud/production-europe-west1.yml` | YAML | JTier runtime config for production EU (GCP europe-west1) |
| `config/cloud/staging-europe-west1.yml` | YAML | JTier runtime config for staging EU (GCP europe-west1) |
| `config/cloud/staging-us-west-2.yml` | YAML | JTier runtime config for staging US (AWS us-west-2) |
| `development.yml` | YAML | JTier config for local development |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Conveyor common deployment config (image, ports, scaling, logging) |
| `.meta/deployment/cloud/components/app/<env-region>.yml` | YAML | Per-environment deployment overrides (replicas, CPU/memory, env vars) |

**Key JTier YAML config sections** (derived from `MlsSentinelConfiguration`):

| Section | Purpose |
|---------|---------|
| `databases.history` | PostgreSQL connection config for History DB |
| `databases.dealIndex` | PostgreSQL connection config for Deal Index DB |
| `databases.unitIndex` | PostgreSQL connection config for Unit Index DB |
| `clients.vis` | HTTP client config for Voucher Inventory Service |
| `clients.readingRainbow` | HTTP client config for Reading Rainbow |
| `clients.m3Merchant` | HTTP client config for M3 Merchant Service |
| `clients.dealCatalog` | HTTP client config for Deal Catalog Service (optional) |
| `mbusConfiguration` | Map of MBus processor definitions (destination, messageType, processorClass, enabled flag) |
| `commandRouter.kafka.producer` | Kafka producer properties (bootstrap servers, serializer, etc.) |
| `commandRouter.kafka.router` | Kafka topic routing rules |
| `commandRouter.mBus` | MBus destination for outbound command routing |
| `commandRouter.sendToKafka` | Set of payload types to route to Kafka |
| `commandRouter.sendToMBus` | Set of payload types to route to MBus |
| `supportedInventoryServices` | Set of inventory service IDs considered valid for processing |
| `visCountTimeoutLimit` | Number of VIS count check timeout retries before blacklisting |
| `merchantBlacklistTimeoutMillis` | Duration (ms) to blacklist a merchant after VIS timeout |
| `maxConcurrentVisMessages` | Max concurrent VIS validation calls |
| `maxWaitBeforeVisMessageProcessingInMillis` | Max wait time before VIS message processing begins |
| `clientIdAuth.clientIds` | Map of client IDs to allowed roles for trigger API authentication |
| `sentinelHistoryEventConfig` | Controls `saveHistoryEventInHistoryService` and `sendHistoryEventToYang` flags |
| `rxJava` | RxJava3 thread pool configuration |
| `fis` | FIS (Federated Inventory Service) client configuration |
| `opsLog` | Operational log configuration |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Database credentials (history, dealIndex, unitIndex) | PostgreSQL username/password for all three databases | Kubernetes secret (mounted via `mls-secrets` submodule) |
| Kafka TLS certificates | Mutual TLS for Kafka broker connection (configured by `kafka-tls.sh`) | Kubernetes secret / mounted volume at `/var/groupon/certs` |
| MBus broker credentials | Authentication for MessageBus consumer/producer connections | Kubernetes secret |
| HTTP client credentials | Client-ID credentials for calls to VIS, M3, Reading Rainbow, Deal Catalog | Kubernetes secret |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Staging (GCP us-central1)**: 1–2 replicas; CPU 1500m–1800m; Memory 3–5 GiB; `JTIER_RUN_CONFIG` = `staging-us-central1.yml`
- **Production (GCP us-central1)**: 3–18 replicas; CPU 1000m–2400m; Memory 5–8 GiB; `JTIER_RUN_CONFIG` = `production-us-central1.yml`
- **Common (all cloud)**: HTTP port 8080, admin port 8081, HPA target 100% CPU utilization, OpenTelemetry agent enabled, Splunk log sourceType `mls-sentinel-app`
- **On-prem (snc1/sac1/dub1)**: Deployed via Capistrano (`cap <datacenter>:<environment> deploy:app_servers`); config managed by on-prem JTier config; VIP URLs defined in `.service.yml` colos section
