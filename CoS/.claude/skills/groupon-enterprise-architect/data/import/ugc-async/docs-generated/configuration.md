---
service: "ugc-async"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [config-files, env-vars, vault]
---

# Configuration

## Overview

ugc-async is configured via per-environment YAML configuration files loaded at startup using the Dropwizard / JTIER configuration system. The active config file is selected by the `JTIER_RUN_CONFIG` environment variable, which points to the environment-specific YAML (e.g., `production-us-central1.yml`). Secrets such as database passwords and API keys are injected at runtime via the JTIER secret service integration (`secret-service-v2`). All configuration is bound to the `UgcAsyncConfiguration` class.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the active environment YAML config file (e.g., `/var/groupon/jtier/config/cloud/production-us-central1.yml`) | yes | None | env (Kubernetes overlay) |
| `MALLOC_ARENA_MAX` | Tunes JVM native memory arena count to prevent vmem explosion / OOM kills | yes | `4` | env (common.yml Kubernetes config) |

> IMPORTANT: Secret values are never documented. Only variable names and purposes are shown.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `erasureRequestListener` | Enables GDPR erasure request MBus consumer | not specified (boolean) | per-instance |
| `urlCacheExpiryListener` | Enables URL cache expiry MBus consumer | not specified | per-instance |
| `externalContentListener` | Enables external content sync MBus consumer | not specified | per-instance |
| `dealCatalogDealUpdatesListener` | Enables deal catalog deal-updates MBus consumer | not specified | per-instance |
| `dealCatalogDealPublishedListener` | Enables deal catalog deal-published MBus consumer | not specified | per-instance |
| `ratingAggregatorListener` | Enables ratings aggregation MBus consumer | not specified | per-instance |
| `localSurveyCreator` | Enables local survey creation MBus consumer (V1) | not specified | per-instance |
| `localSurveyCreatorV2` | Enables local survey creation MBus consumer (V2) | not specified | per-instance |
| `thirdPartySurveyCreator` | Enables third-party survey creation MBus consumer | not specified | per-instance |
| `goodsSurveyCreator` | Enables goods survey creation MBus consumer | not specified | per-instance |
| `reviewUpdateListener` | Enables review update MBus consumer | not specified | per-instance |
| `merchantPlacesChangeListener` | Enables merchant places change MBus consumer | not specified | per-instance |
| `essenceListener` | Enables Essence NLP MBus consumer | not specified | per-instance |
| `aspectsListener` | Enables aspects sub-topic MBus consumer | not specified | per-instance |
| `videoUpdateListener` | Enables video update MBus consumer | not specified | per-instance |
| `answerCreateListener` | Enables answer create MBus consumer | not specified | per-instance |
| `postPurchaseVISListener` | Enables post-purchase voucher inventory MBus consumer | not specified | per-instance |
| `noShowEnabled` | Enables no-show survey creation path | false (boolean field) | per-instance |
| `bookingEnabled` | Enables booking-linked survey creation path | false (boolean field) | per-instance |
| `multiSurveySendingEnabled` | Enables sending multiple survey notifications per survey | false | per-instance |
| `updatedGoodsSurveyCreationQuery` | Switches to the updated Goods survey creation Teradata query | false | per-instance |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/config/development.yml` | YAML | Local development configuration (path referenced by `development.yml` pointer file) |
| `.meta/deployment/cloud/components/worker/common.yml` | YAML | Kubernetes common deployment config (replicas, ports, resource requests, APM, env vars) |
| `.meta/deployment/cloud/components/worker/production-us-central1.yml` | YAML | Production GCP us-central1 region overrides (replicas 2-3, 23Gi/25Gi memory, 1500m CPU) |
| `.meta/deployment/cloud/components/worker/production-eu-west-1.yml` | YAML | Production AWS eu-west-1 region overrides |
| `.meta/deployment/cloud/components/worker/production-europe-west1.yml` | YAML | Production GCP europe-west1 region overrides |
| `.meta/deployment/cloud/components/worker/staging-us-central1.yml` | YAML | Staging GCP us-central1 overrides (1 replica, 17Gi/18Gi memory, 50m CPU) |
| `.meta/deployment/cloud/components/worker/staging-europe-west1.yml` | YAML | Staging GCP europe-west1 overrides |
| `.meta/deployment/cloud/components/worker/staging-us-west-2.yml` | YAML | Staging AWS us-west-2 overrides |
| `.meta/kustomize/base/kustomization.yaml` | YAML | Kustomize base manifest reference |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `teraDataConfig.host` / `.user` / `.password` | Teradata warehouse connection credentials | vault (via secret-service-v2) |
| `aws3Model` credentials | AWS S3 access key and secret for image/video bucket | vault (via secret-service-v2) |
| `imageServiceConfig.clientId` / `.apiKey` | Credentials for Image Service upload API | vault (via secret-service-v2) |
| `postgresQLConfig` credentials | PostgreSQL primary database credentials | vault (via secret-service-v2) |
| `postgresQLReadOnlyConfig` credentials | PostgreSQL read-replica credentials | vault (via secret-service-v2) |
| `redis` connection password | Jedis Redis connection authentication | vault (via secret-service-v2) |
| Email/push/inbox service credentials | Credentials for Rocketman and CRM messaging | vault (via secret-service-v2) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: Uses `src/main/resources/config/development.yml` loaded via JAR startup argument `server ./development.yml`
- **Staging (GCP us-central1)**: 1 replica, 17Gi memory request, 50m CPU request; config path `/var/groupon/jtier/config/cloud/staging-us-central1.yml`
- **Staging (GCP europe-west1)**: Similar low-resource profile for EMEA staging
- **Production (GCP us-central1)**: 2-3 replicas, 23Gi/25Gi memory, 1500m CPU request; config path `/var/groupon/jtier/config/cloud/production-us-central1.yml`
- **Production (AWS eu-west-1 / GCP europe-west1)**: EMEA production deployments with region-specific config paths
- HPA target utilization set to 50% in common config; min replicas 3, max 15 in common (overridden per environment)
