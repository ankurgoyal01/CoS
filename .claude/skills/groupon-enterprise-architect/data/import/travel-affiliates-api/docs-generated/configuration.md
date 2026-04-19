---
service: "travel-affiliates-api"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, k8s-secret]
---

# Configuration

## Overview

The Travel Affiliates API is configured through a combination of environment variables injected by the Kubernetes/Conveyor deployment platform and YAML/properties config files loaded from the container filesystem. The `ConfigReader` singleton loads all properties from Groupon's internal `app-config` library (`AppConfig.getAllProperties()`). The cron container additionally resolves the active environment name from the `APP_ENVIRONMENT` environment variable and loads classpath property files (`settings.properties` and `{env}-US-settings.properties`). Secrets are stored in Kubernetes secrets and mounted via `.meta/deployment/cloud/secrets`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `CONFIG_FILE` | Path to the environment-specific YAML config file | yes | None | k8s deployment manifest |
| `ACTIVE_ENV` | Active deployment environment name (`staging`, `production`) | yes | None | k8s deployment manifest |
| `ACTIVE_COLO` | Active colocation/region identifier (e.g., `us-central1`, `eu-west-1`) | yes | None | k8s deployment manifest |
| `CATALINA_OPTS` | JVM flags for Tomcat; sets active Spring profile and heap sizes | yes | None | k8s deployment manifest |
| `APP_ENVIRONMENT` | Environment name for cron config property file resolution (`qa`, `staging`, `live`) | yes (cron) | `qa` | k8s deployment manifest |
| `MALLOC_ARENA_MAX` | Limits glibc memory arena count to prevent vmem explosion in containers | no | System default (8 * CPU cores) | k8s deployment manifest |
| `DEPLOY_REGION` | Used by `ConfigReader.isCloud()` to detect cloud deployment regions | no | None | Platform injection |
| `ELASTIC_APM_VERIFY_SERVER_CERT` | Disables APM server certificate verification (used in production cron) | no | `true` | k8s deployment manifest |
| `ROLE` | Role identifier injected into cron container | no | None | k8s cron manifest (`reporter`) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

> No evidence found in codebase of a feature flag system. Behavior is controlled by Spring profile activation via `CATALINA_OPTS: -Dspring.profiles.active=...`.

### Spring Profiles

| Profile | Environment | Description |
|---------|-------------|-------------|
| `live-US` | Production (US and EU) | Production US configuration |
| `staging-US` | Staging | Staging US configuration |
| `integration-tests` | Local / CI | Integration test configuration (Jetty) |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `classpath:settings.properties` | Properties | Base application settings loaded by CronConfig |
| `classpath:{env}-US-settings.properties` | Properties | Environment-specific settings (e.g., `live-US-settings.properties`, `qa-US-settings.properties`) |
| `/var/groupon/config/cloud/production-us-central1.yml` | YAML | Cloud production US config file (path set via `CONFIG_FILE` env var) |
| `/var/groupon/config/cloud/production-eu-west-1.yml` | YAML | Cloud production EU config file |
| `/var/groupon/config/cloud/staging-us-central1.yml` | YAML | Cloud staging US config file |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `.meta/deployment/cloud/secrets` | AWS credentials and other secrets for S3 access and downstream API auth | k8s-secret |
| `travel-affiliates-api.properties` (secret file) | Service-specific secrets loaded by `ConfigReader.mergeSecretFile()` (currently commented out in code) | k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Setting | Staging (us-central1) | Production (us-central1) | Production (eu-west-1) |
|---------|-----------------------|--------------------------|------------------------|
| Spring profile | `staging-US` | `live-US` | `live-US` |
| JVM heap (`-Xms`/`-Xmx`) | 2048m / 2048m | 2048m / 3072m | 2048m / 4096m |
| Memory limit | 2048Mi | 3072Mi | 4096Mi |
| Min replicas | 1 | 2 | 2 |
| Max replicas | 2 | 15 | 15 |
| APM endpoint | `elastic-apm-http...staging...` | `elastic-apm-http...production...` | Not configured |
| Filebeat volume | Default (low) | medium | medium |

### Getaways API client configuration (properties-based)

| Property | Purpose | Default (from CronConfig) |
|----------|---------|--------------------------|
| `getaways.api.connection.timeout.seconds` | HTTP connection timeout for Getaways API calls | 5 |
| `getaways.api.socket.timeout.seconds` | HTTP socket/read timeout for Getaways API calls | 5 |
| `getaways.api.content.productsets.authorization` | Authorization header value for product sets endpoint | (from config) |
| `getaways.api.content.productsets.limit` | Max deals to retrieve per product sets page | (from config) |
| `getaways.api.content.productsets.dealstatus` | Deal status filter for product sets query | (from config) |
| `getaways.api.content.batchhoteldetail.batchsize` | Number of hotel UUIDs per batch detail call | (from config) |
