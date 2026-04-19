---
service: "aes-service"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [config-files, env-vars, vault]
---

# Configuration

## Overview

AES is configured through JTier YAML configuration files (one per environment, selected via the `JTIER_RUN_CONFIG` environment variable). Secrets (API tokens, OAuth credentials, DB passwords) are injected at deploy time via the `.meta/deployment/cloud/secrets` path managed by Raptor. Non-secret environment-level values are set in the Raptor cloud component YAMLs. Feature flags controlling which background services run are part of the application YAML config.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the active JTier YAML config file for the current environment | yes | None | env (set per deployment environment) |
| `MALLOC_ARENA_MAX` | Limits glibc memory arena count to prevent virtual memory explosion in containers | no | `4` | env (Raptor common.yml) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `runErasureService` | Enables/disables the GDPR erasure MBus consumer | — | global |
| `runConsentService` | Enables/disables the consent MBus consumer | — | global |
| `runAudienceJobs` | Enables/disables the Quartz scheduler for daily audience export jobs | — | global |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Shared Raptor deployment config: image, ports (8080/8081/8009), scaling (2–15 replicas), resource requests (CPU 300m, Memory 5Gi–15Gi) |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production overrides: GCP us-central1, scaling 2–20 replicas, VPA enabled, `JTIER_RUN_CONFIG` set to production path |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging overrides: GCP us-central1, scaling 1–2 replicas, VPA enabled, `JTIER_RUN_CONFIG` set to staging path |
| `development.yml` (pointer) | — | Points to `src/main/resources/config/development.yml` (full YAML config for local development) |
| `docker-compose.yml` | YAML | Local development database setup |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `facebook.accessToken` | Facebook Ads API access token for audience management | vault (`.meta/deployment/cloud/secrets`) |
| `google.ads.refreshToken` | Google Ads OAuth2 refresh token | vault |
| `google.ads.clientId` | Google Ads OAuth2 client ID | vault |
| `google.ads.clientSecret` | Google Ads OAuth2 client secret | vault |
| `google.ads.developerToken` | Google Ads API developer token | vault |
| `microsoft.developerToken` | Microsoft Bing Ads developer token | vault |
| `microsoft.clientId` | Microsoft Bing Ads OAuth2 client ID | vault |
| `microsoft.clientSecret` | Microsoft Bing Ads OAuth2 client secret | vault |
| `microsoft.refreshToken` | Microsoft Bing Ads OAuth2 refresh token | vault |
| `tiktok.accessToken` | TikTok Ads API access token | vault |
| `tiktok.secret` | TikTok Ads API signing secret | vault |
| `cia.httpClient` credentials | CIA API auth credentials | vault |
| Database credentials | PostgreSQL username/password for primary and S2S datastores | vault |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: Full YAML at `src/main/resources/config/development.yml`; local databases started via `docker-compose up -d`; port forwarding to staging DB available for integration testing.
- **Staging**: `JTIER_RUN_CONFIG=/var/groupon/jtier/config/cloud/staging-us-central1.yml`; 1–2 replicas; VPC `stable`; GCP us-central1.
- **Production**: `JTIER_RUN_CONFIG=/var/groupon/jtier/config/cloud/production-us-central1.yml`; 2–20 replicas; VPC `prod`; VPA enabled; GCP us-central1.

Application config fields of note (from `AppConfig`):
- `env` — environment name
- `dbAppUserId` — database application user
- `aesTmpDirLocation` — temp directory for export file staging
- `amsDatabaseNameNA` / `amsDatabaseNameEMEA` — Cerebro/Hive database names per region
- `cerebroFetchBatchSize` — rows fetched per Cerebro query batch
- `facebookUpdateBatchSize` / `googleUpdateBatchSize` / `microsoftUpdateBatchSize` — upload batch sizes per partner
- `ciaAudienceTimezone` — timezone used when scheduling CIA audiences
- `audienceJobCronExpression` — default Quartz cron for daily audience runs
- `audienceJobRetryCount` — number of retry attempts per failed job (currently 3)
- `audienceJobRetryInterval` — delay between retries (milliseconds)
- `naExportId` / `emeaExportId` — CIA export IDs for NA and EMEA regions
- `naCountries` / `emeaCountries` — country lists per region
- `activePartners` — list of enabled ad-network targets (e.g., `FACEBOOK`, `GOOGLE`, `TIKTOK`, `MICROSOFT`)
