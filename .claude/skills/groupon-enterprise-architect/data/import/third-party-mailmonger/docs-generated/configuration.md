---
service: "third-party-mailmonger"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

Third Party Mailmonger is configured via JTier YAML configuration files, which vary by environment. The active config file is selected by the `JTIER_RUN_CONFIG` environment variable. A small number of non-secret environment variables are set in the Kubernetes deployment manifests under `.meta/deployment/cloud/components/app/`. Secret values (database passwords, SparkPost API keys, users-service credentials) are stored in Groupon's secrets management system and injected at runtime; their values are never committed to the repository.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the active JTier YAML configuration file | yes | (none) | Kubernetes deployment manifest |
| `MALLOC_ARENA_MAX` | Limits JVM native memory arena count to prevent OOM container kills | no | `4` | `.meta/deployment/cloud/components/app/common.yml` |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `filter.blackHole` | When `true`, the `BlackHoleRule` is added to the filter pipeline, causing all emails to be silently dropped without delivery | `false` | global (per-config-file) |
| `filter.whitelistFilter` | When `true`, the `WhiteListUrlFilter` is active and URLs in email bodies are validated against the configured whitelist | `true` | global (per-config-file) |
| `emailCarrierConfiguration.sendOnlyToGrouponDomain` | When `true`, all outbound emails are forwarded to a Groupon-internal address rather than the real recipient (used in non-production environments) | configured per environment | per-environment |
| `emailCarrierConfiguration.emailClientType` | Selects the outbound email carrier (`SPARKPOST` or `MTA`) | configured per environment | per-environment |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| JTier YAML (path set by `JTIER_RUN_CONFIG`) | YAML | Primary application configuration; contains all sections below |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Cloud-common Kubernetes deployment settings (image, ports, replicas, resources) |
| `.meta/deployment/cloud/components/app/production-us-west-1.yml` | YAML | Production US-West-1 overrides (region, VPC, namespace, replica bounds) |
| `.meta/deployment/cloud/components/app/production-eu-west-1.yml` | YAML | Production EU-West-1 overrides |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production US-Central1 overrides |
| `.meta/deployment/cloud/components/app/staging-us-west-1.yml` | YAML | Staging US-West-1 overrides |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging US-Central1 overrides |

### JTier YAML Config Sections

The JTier YAML configuration file is structured around the `ThirdPartyMailmongerConfiguration` class and contains the following top-level keys:

| Key | Type | Purpose |
|-----|------|---------|
| `postgres` | `PostgresConfig` | Database connection URL, pool sizes, credentials |
| `userServiceClient` | `RetrofitConfiguration` | Base URL and HTTP settings for users-service Retrofit client |
| `sparkpostClient.apiKey` | String (secret) | SparkPost API authentication key |
| `sparkpostClient.baseUrl` | String | SparkPost API base URL |
| `messageBus` | `MbusConfiguration` | MessageBus broker URL and queue settings |
| `filter.blackHole` | Boolean | Enables/disables the blackhole filter rule |
| `filter.whitelistFilter` | Boolean | Enables/disables the URL whitelist filter rule |
| `brandConfiguration` | `BrandConfiguration` | Per-brand settings (maps masked email domains to brand identities) |
| `logMaskerConfiguration` | `LogMaskerConfiguration` | JSON keys and log fields to redact from log output |
| `numberOfThreadsForScheduler` | Integer | Thread pool size for the Quartz scheduler executor |
| `quartz` | `QuartzConfiguration` | Quartz scheduler settings (Postgres-backed job store) |
| `emailContentIdsBatchSize` | Integer | Batch size for bulk email content ID queries |
| `mtaClient.host` | List of Strings | MTA server hostnames |
| `mtaClient.port` | String | MTA SMTP port |
| `emailCarrierConfiguration.emailClientType` | Enum (`SPARKPOST`, `MTA`) | Selects which outbound email client to use |
| `emailCarrierConfiguration.sendOnlyToGrouponDomain` | Boolean | Restricts delivery to Groupon domain (non-prod safety) |
| `emailCarrierConfiguration.addressToForwardEmailsTo` | String | Forwarding address when `sendOnlyToGrouponDomain` is true |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `sparkpostClient.apiKey` | SparkPost API key for outbound email sending | Groupon secrets repo / Kubernetes secret |
| `postgres` credentials | PostgreSQL database username and password | Groupon secrets repo / Kubernetes secret |
| `userServiceClient` auth credentials | Authentication for users-service HTTP calls | Groupon secrets repo / Kubernetes secret |

> Secret values are NEVER documented. Only names and rotation policies. See the Groupon secrets repo (access-controlled) for actual values.

## Per-Environment Overrides

| Environment | Config Path | Notable Differences |
|-------------|-------------|---------------------|
| Staging (US-West-1) | `config/cloud/staging-us-west-1.yml` | `minReplicas: 1`, `maxReplicas: 2`; `sendOnlyToGrouponDomain: true` expected |
| Production (US-West-1) | `config/cloud/production-us-west-1.yml` | `minReplicas: 2`, `maxReplicas: 25`; full SparkPost key |
| On-prem Production (SNC1) | Capistrano-deployed YAML | VIP: `mailmonger-vip.snc1`; PostgreSQL: `prod-third-pt-mm-rw-vip.us.daas.grpn` |
| On-prem Production (SAC1) | Capistrano-deployed YAML | VIP: `mailmonger-vip.sac1`; PostgreSQL: `prod-third-pt-mm-rw-vip.us.daas.grpn` |
| On-prem Production (DUB1/EU) | Capistrano-deployed YAML | VIP: `mailmonger-vip.dub1`; PostgreSQL: `gds-dub1-prod-third-party-mailmon-rw-vip.dub1` |
