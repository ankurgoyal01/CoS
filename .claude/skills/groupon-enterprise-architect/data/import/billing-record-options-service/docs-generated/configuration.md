---
service: "billing-record-options-service"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, vault]
---

# Configuration

## Overview

BROS is configured via a YAML configuration file whose path is supplied through the `JTIER_RUN_CONFIG` environment variable. This file is injected into the container at deploy time from a region-specific cloud config. Secret values (database credentials, cache credentials) are managed in a separate git submodule (`billing-record-options-service-secrets`) and mounted into the container by the Conveyor/Raptor deployment platform. The Java application reads configuration through the Dropwizard JTier `JTierConfiguration` mechanism, which maps the YAML file into the `BillingRecordOptionsServiceConfiguration` class.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Absolute path to the YAML runtime configuration file loaded on startup | yes | — | env (injected per-environment in Conveyor cloud config) |
| `AUTOMIGRATE` | When `"true"`, runs Flyway migrations on service startup | no | `"false"` | env (cloud config) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

> No evidence found in codebase. No feature flag system is referenced.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Shared Conveyor deployment config — Docker image, port, HPA settings, APM, resource requests |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production NA (GCP us-central1) deployment overrides — VIP, replica counts, memory limits, env vars |
| `.meta/deployment/cloud/components/app/production-eu-west-1.yml` | YAML | Production EMEA (AWS eu-west-1) deployment overrides — VIP, replica counts, memory limits, Telegraf, Filebeat |
| `.meta/deployment/cloud/components/app/production-europe-west1.yml` | YAML | Production EMEA (GCP europe-west1) deployment overrides — VIP, replica counts |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging NA (GCP us-central1) deployment overrides — VIP, replica counts, Telegraf, Filebeat |
| `.meta/deployment/cloud/components/app/staging-europe-west1.yml` | YAML | Staging EMEA (GCP europe-west1) deployment overrides — VIP, replica counts, env vars |
| `src/main/resources/config/development.yml` | YAML | Local development configuration (referenced via `development.yml` symlink at repo root) |
| `.meta/.raptor.yml` | YAML | Raptor/Conveyor archetype declaration — component type (`api`), secret path |
| `.service.yml` | YAML | Service registry metadata — team, on-call, SRE dashboards, PagerDuty, dependencies |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `.meta/deployment/cloud/secrets/cloud/<env>.yml` | Database credentials (PostgreSQL username/password for `bros` schema) and cache credentials | Git submodule (`billing-record-options-service-secrets`) mounted by Conveyor |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Configuration differs per environment through region-specific YAML files injected via `JTIER_RUN_CONFIG`:

- **Local development**: `src/main/resources/config/development.yml` — connects to local Docker PostgreSQL (`test_dev`) and local Redis
- **Staging NA** (`staging-us-central1`): GCP us-central1, 1-2 replicas, `bros_stg` database, `bros.us-central1.conveyor.stable.gcp.groupondev.com` VIP
- **Staging EMEA** (`staging-europe-west1`): GCP europe-west1, 1-2 replicas, `bros_emea_stg` database, `bros.europe-west1.conveyor.stable.gcp.groupondev.com` VIP
- **Production NA** (`production-us-central1`): GCP us-central1, 2-15 replicas, 4Gi-8Gi memory, `bros.us-central1.conveyor.prod.gcp.groupondev.com` VIP
- **Production EMEA** (`production-eu-west-1`): AWS eu-west-1, 6-15 replicas, 4Gi-8Gi memory, `bros.prod.eu-west-1.aws.groupondev.com` VIP
- **Production EMEA GCP** (`production-europe-west1`): GCP europe-west1, 2-15 replicas, `bros.europe-west1.conveyor.prod.gcp.groupondev.com` VIP
