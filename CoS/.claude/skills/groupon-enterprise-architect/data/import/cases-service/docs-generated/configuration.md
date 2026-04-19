---
service: "cases-service"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

MCS is configured via YAML files loaded at startup. The active config file is determined by the `JTIER_RUN_CONFIG` environment variable, which points to a per-environment YAML file (e.g., `production-us-central1.yml`). Secrets are injected via environment variable substitution (`${VAR_NAME}`) in the YAML files. For local development, `src/main/resources/config/development.yml` is used. Cloud deployments use files under `src/main/resources/config/cloud/`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the active YAML config file | yes | None | env |
| `OTEL_SDK_DISABLED` | Disables OpenTelemetry tracing when true | no | `true` (Dockerfile) | env |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | OTLP endpoint for trace export | no | None | env (cloud deployment manifest) |
| `OTEL_RESOURCE_ATTRIBUTES` | OTel resource attributes (e.g., `service.name=mx-cases-service`) | no | None | env (cloud deployment manifest) |
| `MALLOC_ARENA_MAX` | Tunes glibc memory arena count to prevent VM memory explosion | no | `4` | cloud deployment manifest |
| `DEPLOY_ENV` | Current deployment environment name injected into `casesConfig.environment` | no | `staging` (default) | env |
| `CSF_PASSWORD` | Salesforce OAuth2 password | yes | None | env / vault |
| `CSF_CLIENT_SECRET` | Salesforce OAuth2 client secret | yes | None | env / vault |
| `DC_AUTH_OPTS_VALUE` | Deal Catalog client auth token | yes | None | env / vault |
| `M3_AUTH_OPTS_VALUE` | M3 Merchant Service client auth token | yes | None | env / vault |
| `USERS_AUTH_OPTS_VALUE` | Users Service API key | yes | None | env / vault |
| `NOTS_AUTH_OPTS_VALUE` | MX Notification Service API key | yes | None | env / vault |
| `RAINBOW_AUTH_OPTS_VALUE` | Salesforce Cache Service (Reading Rainbow) basic auth password | yes | None | env / vault |
| `MAS_AUTH_OPTS_VALUE` | MX Merchant Access Service API key | yes | None | env / vault |
| `ROCKETMAN_AUTH_OPTS_VALUE` | Rocketman transactional email client ID | yes | None | env / vault |
| `MCS_DEV_CLIENT_ID` | Client ID for dev/internal MCS callers | yes | None | env / vault |
| `METRO_CLIENT_ID` | Client ID for Metro (Merchant Center) callers | yes | None | env / vault |
| `EN_APIKEY`, `DE_APIKEY`, `ES_APIKEY`, `FR_APIKEY`, `IT_APIKEY`, `JA_APIKEY`, `NL_APIKEY`, `PL_APIKEY`, etc. | Per-locale Inbenta API keys | yes (per locale) | None | env / vault |
| `EN_SECRET`, `DE_SECRET`, `ES_SECRET`, etc. | Per-locale Inbenta JWT secrets | yes (per locale) | None | env / vault |

> Secret values are NEVER documented. Only variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `casesConfig.ownerCacheEnabled` | Enables Redis caching for Salesforce owner/contact lookups | `true` | global |
| `casesConfig.unreadCasesCountAndNotificationsEnabled` | Enables unread case count tracking and notification dispatch | `true` | global |
| `chatEnabled` | Enables Salesforce live chat button functionality | `true` | global |
| `inboxEnabledCountries` | List of country codes for which the support inbox is enabled | US, CA, IT, DE, UK, GB, IE, PL, ES, FR, NL, BE, AU, NZ, JP, AE, QC | global |
| `caseCreationEnabledCountries` | List of country codes for which merchants can create new cases | US, CA, IT, DE, UK, GB, IE, PL, ES, FR, NL, BE, AU, NZ, JP, AE, QC | global |
| `casesConfig.excludedWebNotificationTypes` | Notification types suppressed from web notification dispatch | `CASE_EVENT_REMINDER_1`, `CASE_EVENT_REMINDER_2` | global |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/config/development.yml` | YAML | Local development configuration |
| `src/main/resources/config/cloud/staging-us-central1.yml` | YAML | GCP staging US Central1 environment config |
| `src/main/resources/config/cloud/staging-europe-west1.yml` | YAML | GCP staging Europe West1 environment config |
| `src/main/resources/config/cloud/production-us-central1.yml` | YAML | GCP production US Central1 environment config |
| `src/main/resources/config/cloud/production-europe-west1.yml` | YAML | GCP production Europe West1 environment config |
| `src/main/resources/config/cloud/production-eu-west-1.yml` | YAML | AWS production EU West1 environment config |
| `src/main/resources/config/snc1/production.yml` | YAML | On-prem SNC1 production config |
| `src/main/resources/config/snc1/staging.yml` | YAML | On-prem SNC1 staging config |
| `src/main/resources/config/sac1/production.yml` | YAML | On-prem SAC1 production config |
| `src/main/resources/config/dub1/production.yml` | YAML | On-prem DUB1 production config |
| `src/main/resources/config/common/files_configuration.json` | JSON | File attachment configuration |
| `src/main/resources/config/common/sf_case_mappings.json` | JSON | Salesforce case field mapping/support options configuration |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `CSF_PASSWORD` | Salesforce OAuth2 account password | env / vault |
| `CSF_CLIENT_SECRET` | Salesforce connected app client secret | env / vault |
| `DC_AUTH_OPTS_VALUE` | Deal Catalog service auth credential | env / vault |
| `M3_AUTH_OPTS_VALUE` | M3 Merchant Service auth credential | env / vault |
| `USERS_AUTH_OPTS_VALUE` | Users Service API key | env / vault |
| `NOTS_AUTH_OPTS_VALUE` | MX Notification Service API key | env / vault |
| `RAINBOW_AUTH_OPTS_VALUE` | Salesforce Cache Service basic auth password | env / vault |
| `MAS_AUTH_OPTS_VALUE` | MX Merchant Access Service API key | env / vault |
| `ROCKETMAN_AUTH_OPTS_VALUE` | Rocketman transactional email client ID | env / vault |
| `MCS_DEV_CLIENT_ID`, `METRO_CLIENT_ID` | Inbound API client IDs for MCS callers | env / vault |
| `{LOCALE}_APIKEY`, `{LOCALE}_SECRET` | Per-locale Inbenta API keys and JWT secrets (EN, DE, ES, FR, IT, JA, NL, PL, AE_EN, AU_EN, UK_EN, IE_EN, NZ_EN, QC_FR, BE_FR, BE_NL) | env / vault |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: Uses hardcoded staging Salesforce sandbox URLs and in-source credential placeholders; Redis points to staging GCP endpoint; message bus points to on-prem `mbus-staging-vip.snc1`; local HTTP port 9000, admin port 9001
- **Staging (GCP)**: Redis endpoint `casesservice-cache.us-central1.caches.stable.gcp.groupondev.com:6379`; message bus `mbus-stg-na.us-central1.mbus.stable.gcp.groupondev.com:61613`; all client secrets injected via env vars; `minReplicas: 1`, `maxReplicas: 2`; OTEL enabled
- **Production (GCP/AWS)**: All secrets injected via env vars; `minReplicas: 2`, `maxReplicas: 25`; OTEL enabled for GCP targets (`OTEL_SDK_DISABLED: false`); CPU 1000m request / 1500m limit; memory 3Gi request / 5Gi limit; message bus durable subscriptions with production subscription IDs
- **On-prem (SNC1/SAC1/DUB1)**: Config in `src/main/resources/config/<datacenter>/<env>.yml`; service runs on standard JTier host; accessed at `http://mx-merchant-cases.production.service`
