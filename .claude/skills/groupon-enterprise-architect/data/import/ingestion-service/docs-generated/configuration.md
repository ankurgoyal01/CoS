---
service: "ingestion-service"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, helm-values]
---

# Configuration

## Overview

The ingestion-service is configured through a layered system: a base Dropwizard YAML file (loaded at startup), environment-specific YAML overrides (injected via the `JTIER_RUN_CONFIG` environment variable pointing to a cloud config path), and non-secret environment variables set in the Conveyor Cloud deployment manifests under `.meta/deployment/cloud/components/app/`. Secrets (Salesforce credentials, DB passwords, API keys) are injected at runtime via Groupon's secrets management infrastructure and are not stored in the repository.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the environment-specific JTier YAML config file loaded at startup | yes | None | env (Conveyor/Helm) |
| `MALLOC_ARENA_MAX` | Tunes glibc memory arena count to prevent vmem explosion and OOM kills in containers | no | 4 | `.meta/deployment/cloud/components/app/common.yml` |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

> No evidence found in codebase. No runtime feature flag system (LaunchDarkly, Consul feature flags, etc.) is configured.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Conveyor Cloud base deployment config: scaling (HPA min/max replicas), probe paths, resource requests, port configuration, log source type, APM enablement |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production US-Central1 (GCP) overrides: cloud provider, region, VIP, namespace, memory/CPU limits |
| `.meta/deployment/cloud/components/app/production-eu-west-1.yml` | YAML | Production EU-West-1 (AWS) overrides: cloud provider, region, Kafka logging endpoint, memory/CPU limits |
| `.meta/deployment/cloud/components/app/production-europe-west1.yml` | YAML | Production Europe-West1 (GCP) overrides |
| `.meta/deployment/cloud/components/app/production-us-west-1.yml` | YAML | Production US-West-1 (AWS) overrides |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging US-Central1 overrides: reduced replicas (1–2), lower memory limits |
| `.meta/deployment/cloud/components/app/staging-europe-west1.yml` | YAML | Staging EU overrides |
| `.meta/deployment/cloud/components/app/staging-us-west-1.yml` | YAML | Staging US-West-1 overrides |
| `.meta/deployment/cloud/components/app/staging-us-west-2.yml` | YAML | Staging US-West-2 overrides |
| `development.yml` | (pointer) | Points to `src/main/resources/config/development.yml` for local development |
| `doc/swagger/config.yml` | YAML | Swagger UI configuration |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `salesforceConfiguration` (YAML block) | Salesforce OAuth client ID, client secret, instance URL, and channel-specific credentials for CS configuration | Injected via environment-specific JTier config (k8s-secret / Vault) |
| `salesforceMarketplaceConfiguration` (YAML block) | Salesforce OAuth credentials for Marketplace (Goods) channel | Injected via environment-specific JTier config (k8s-secret / Vault) |
| `clientId` (YAML block) | Client ID configuration for API authentication (stores registered API caller client IDs and secrets) | Injected via environment-specific JTier config backed by MySQL |
| `mysql` (YAML block) | DaaS MySQL JDBC URL, username, and password | Injected via environment-specific JTier config (k8s-secret) |
| `caapClient` (YAML block) | CAAP API base URL and any auth headers | Injected via environment-specific JTier config |
| `zingtreeClient` (YAML block) | Zingtree API base URL and auth token | Injected via environment-specific JTier config |
| `ordersROClient` (YAML block) | Orders RO Service base URL | Injected via environment-specific JTier config |
| `lazloClient` (YAML block) | Lazlo API base URL | Injected via environment-specific JTier config |
| `usersServiceClient` (YAML block) | Users Service base URL | Injected via environment-specific JTier config |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Config Dimension | Development | Staging | Production |
|-----------------|-------------|---------|------------|
| Replicas (min/max) | N/A | 1 / 2 | 3 / 15 |
| Memory request/limit (main) | 500 MiB / 500 MiB | 1500 MiB / 2500 MiB | 3072 MiB / 6144 MiB |
| CPU request (main) | 50m | 300m | 300m |
| HPA target utilization | 100% | (inherited) | 100% |
| JTier run config path | `development.yml` | `/var/groupon/jtier/config/cloud/staging-*.yml` | `/var/groupon/jtier/config/cloud/production-*.yml` |
| Cloud provider | Local | GCP | GCP (us-central1, europe-west1) / AWS (eu-west-1, us-west-1) |
| Filebeat volume type | low | low | medium |

HPA (Horizontal Pod Autoscaler) is configured via the `common.yml` manifest with a target utilization of 100% and min/max replicas defined per environment.
