---
service: "sem-blacklist-service"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, k8s-secret]
---

# Configuration

## Overview

The SEM Blacklist Service is configured through a combination of JTier YAML configuration files (selected via the `JTIER_RUN_CONFIG` environment variable), Kubernetes deployment manifests (in `.meta/deployment/cloud/`), and secrets injected at runtime. Application-specific config (Google Sheets IDs, Asana credentials, program/channel/country sets) is managed under the `app:` YAML block, mapped to `BlacklistingApplicationConfig`. Quartz scheduler and PostgreSQL connection settings are managed under their respective YAML blocks.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Absolute path to the JTier YAML config file to load | yes | (none) | env (set per deployment target) |
| `MALLOC_ARENA_MAX` | Limits glibc memory arenas to prevent container OOM from vmem explosion | no | `4` | Kubernetes deployment manifest (`common.yml`) |

## Feature Flags

> No evidence found in codebase of runtime feature flags.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/api/common.yml` | YAML | Shared Kubernetes deployment config (image, ports, scaling, resource requests, log config) |
| `.meta/deployment/cloud/components/api/production-us-central1.yml` | YAML | Production GCP overrides (region, namespace, replica count, VPA) |
| `.meta/deployment/cloud/components/api/staging-us-central1.yml` | YAML | Staging GCP overrides (region, VPC, replica count, VPA) |
| `.meta/.raptor.yml` | YAML | Raptor component manifest (component type, secret path) |
| `.deploy_bot.yml` | YAML | DeployBot pipeline targets (staging and production Kubernetes contexts) |
| `Jenkinsfile` | Groovy DSL | Jenkins pipeline configuration (JTier DSL, deploy targets, release branches) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `asanaApiKey` | Bearer token for authenticating with the Asana REST API | k8s-secret (path: `.meta/deployment/cloud/secrets`) |
| `credentialLocation` (OAuth2 stored credential) | OAuth2 credentials for Google Sheets API access | Filesystem credential file (`credLocation/StoredCredential`) |
| PostgreSQL credentials | Database username and password for the DaaS PostgreSQL instance | k8s-secret (managed by DaaS / JTier `jtier-daas-postgres`) |

> Secret values are NEVER documented. Only names and rotation policies.

## Application Config Reference (`BlacklistingApplicationConfig`)

The following keys are nested under `app:` in the JTier YAML configuration file:

| Config Key | Type | Purpose |
|------------|------|---------|
| `gdocMeta` | string | Google Sheets ID for the meta-sheet mapping programs/channels/countries to sheet IDs |
| `gdocDealSheet` | string | Google Sheets ID for the general deal blacklist sheet |
| `gdocMerchantSheet` | string | Google Sheets ID for the merchant blacklist sheet |
| `gdocBrandSheet` | string | Google Sheets ID for the brand blacklist sheet |
| `gdocPrograms` | Set\<String\> | Set of program identifiers to process during GDoc refresh |
| `gdocChannels` | Set\<String\> | Set of channel identifiers to process during GDoc refresh |
| `gdocCountries` | Set\<String\> | Set of country codes to process during GDoc refresh |
| `plaGdoc` | string | Google Sheets file ID for the PLA (Product Listing Ads) spreadsheet |
| `plaUsGDocDealSheet` | string | Sheet name/ID within the PLA spreadsheet for PLA deal blacklist (client: `pla-deal`) |
| `plaUsGDocDealOptionSheet` | string | Sheet name/ID within the PLA spreadsheet for PLA deal option blacklist (client: `pla-deal-option`) |
| `asanaApiKey` | string (secret) | Asana personal access token for API authentication |
| `asanaProjectGid` | string | Asana project GID to scope task queries |
| `asanaSectionGid` | string | Asana section GID to fetch open tasks from |

## Per-Environment Overrides

| Setting | Staging | Production |
|---------|---------|------------|
| GCP VPC | `stable` | `prod` |
| Kubernetes cluster | `gcp-stable-us-central1` | `gcp-production-us-central1` |
| Kubernetes namespace | (default staging namespace) | `sem-blacklist-service-production` |
| Min replicas | 1 | 2 |
| Max replicas | 1 | 2 |
| Memory request | (common default: 2Gi) | 3Gi |
| CPU request | (common default: 1000m) | 100m |
| VPA | enabled | enabled |
| `JTIER_RUN_CONFIG` | `/var/groupon/jtier/config/cloud/staging-us-central1.yml` | `/var/groupon/jtier/config/cloud/production-us-central1.yml` |
| Log source type | `sem_denylisting_service` | `sem_denylisting_service` |
