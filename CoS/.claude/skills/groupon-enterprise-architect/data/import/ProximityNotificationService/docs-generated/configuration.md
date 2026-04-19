---
service: "proximity-notification-service"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, k8s-secrets]
---

# Configuration

## Overview

The service is configured via JTier YAML configuration files, with the active file selected by the `JTIER_RUN_CONFIG` environment variable at runtime. Each deployment environment has its own YAML file under `.meta/deployment/cloud/components/app/`. The configuration object `ProximitynotificationserviceConfiguration` (extending `JTierConfiguration`) reads all values at startup.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the active YAML config file loaded at startup | yes | none | Kubernetes env var (set per-environment in deployment YAML) |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `userTravelConfiguration.enabled` | Enables user travel mode detection for travel-type hotzone notifications | `false` | global |
| `parameterConfiguration.unconditionalMutePercentage` | Percentage (0–100) of traffic to mute unconditionally to shed load | `0` (disabled) | global |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Shared Kubernetes deployment settings (image, ports, resource requests, logstash sidecar) |
| `.meta/deployment/cloud/components/app/staging-us-west-1.yml` | YAML | Staging US West 1 (AWS) overrides: VIP, replicas, env vars |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging US Central 1 (GCP) overrides |
| `.meta/deployment/cloud/components/app/staging-europe-west1.yml` | YAML | Staging Europe West 1 (GCP) overrides |
| `.meta/deployment/cloud/components/app/production-us-west-1.yml` | YAML | Production US West 1 (AWS): VIP, 2–10 replicas, 6Gi memory |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production US Central 1 (GCP) overrides |
| `.meta/deployment/cloud/components/app/production-eu-west-1.yml` | YAML | Production EU West 1 (AWS) overrides |
| `.meta/deployment/cloud/components/app/production-europe-west1.yml` | YAML | Production Europe West 1 (GCP): VIP, 2–10 replicas |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `.meta/deployment/cloud/secrets` (referenced in `.meta/.raptor.yml`) | Database credentials, Redis auth, push service API keys, and other per-service secrets | Kubernetes secrets (managed via Raptor/Conveyor Cloud) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

### Staging

- `minReplicas: 1`, `maxReplicas: 3`
- Memory: 2Gi request/limit
- CPU: 500m request
- VIP: `proximity-notifications.staging.stable.us-west-1.aws.groupondev.com`
- `filebeatKafkaEnv: staging`
- Kafka: `kafka-grpn-producer.grpn-dse-stable.us-west-2.aws.groupondev.com:9094`

### Production US (AWS us-west-1)

- `minReplicas: 2`, `maxReplicas: 10`
- Memory: 6Gi request/limit
- CPU: 500m request
- VIP: `proximity-notifications.prod.us-west-1.aws.groupondev.com`
- `filebeatKafkaEnv: production`
- Kafka: `kafka-grpn-producer.grpn-dse-prod.us-west-2.aws.groupondev.com:9094`

### Production EMEA (GCP europe-west1)

- `minReplicas: 2`, `maxReplicas: 10`
- VIP: `proximity-notifications.prod.europe-west1.gcp.groupondev.com`
- Kafka: `kafka-grpn-kafka-bootstrap.kafka-production.svc.cluster.local:9093`

## Key YAML Configuration Sections

The JTier YAML config (selected by `JTIER_RUN_CONFIG`) contains the following major sections:

| Section | Type | Purpose |
|---------|------|---------|
| `postgres` | `PostgresConfig` | PostgreSQL host, port, database name, connection pool settings |
| `jedisPoolConfiguration` | `JedisPoolConfiguration` | Redis host, port, pool size (maxTotal: 300, maxIdle: 200, minIdle: 10), timeout (1000ms), maxWait (800ms) |
| `userTravelConfiguration` | `UserTravelConfiguration` | Travel detection: `enabled`, `travelDistance` (default 100000.0m), `updateTimeIntervalInMins` (default 30) |
| `parameterConfiguration` | `ParameterConfiguration` | Geofence radius, hotzone search radius, mute percentages, rate limit check windows, valid duration |
| `notificationConfiguration` | `NotificationConfiguration` | Notification template and localization settings |
| `targetedDealMessageConfiguration` | `TargetedDealMessageConfiguration` | TDM service base URL and connection settings |
| `couponConfiguration` | `CouponConfiguration` | Coupon service base URL |
| `cloConfiguration` | `CloConfiguration` | CLO service base URL |
| `pushNotificationConfiguration` | `PushNotificationConfiguration` | Rocketman push service base URL |
| `realtimeAudienceManagementServiceConfiguration` | `RealtimeAudienceManagementServiceConfiguration` | Audience management service base URL |
| `watsonConfiguration` | `WatsonConfiguration` | Watson KV service base URL |
| `voucherInventoryConfiguration` | `VoucherInventoryConfiguration` | Voucher inventory service base URL |
| `rateLimitConfiguration` | `RateLimitConfiguration` | Per-deal-type and per-send-type rate limit windows and counts |
| `client` | `HttpClientConfig` | Global outbound HTTP client timeout and pool settings |
| `quartz` | `QuartzConfiguration` | Quartz job scheduler datasource and thread pool |
