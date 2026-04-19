---
service: "partner-attributes-mapping-service"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, helm-values, k8s-secrets]
---

# Configuration

## Overview

PAMS is configured through a combination of Dropwizard YAML configuration files and environment variables injected at runtime by the JTier/Kubernetes deployment platform. The active configuration file is selected by the `JTIER_RUN_CONFIG` environment variable. Partner secrets can be sourced from both the PostgreSQL database (at runtime via the `PartnerRegistry`) and from the YAML config file's `partnerSecretsConfig` block; the two sources are merged at startup by `EnvPartnerConfigurationHelper`. Non-secret deployment tuning (replicas, resource limits, ports) is managed via Helm chart values in `.meta/deployment/cloud/components/app/`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the active Dropwizard YAML config file on the container filesystem | Yes (in cloud environments) | None (uses `development.yml` locally) | `helm` / Kubernetes env injection |
| `MALLOC_ARENA_MAX` | Limits JVM memory arena count to prevent virtual memory explosion on Linux containers | No | `4` | `common.yml` Helm values |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

> No evidence found in codebase. No feature flag system (LaunchDarkly, Unleash, etc.) was identified.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/config/development.yml` | YAML | Local development Dropwizard configuration (PostgreSQL, partnerConfig, partnerSecretsConfig) |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Helm values shared across all environments (ports, resource requests, scaling defaults, APM, logging) |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging-environment Helm overrides (GCP `stable` VPC, `JTIER_RUN_CONFIG` path, replica bounds) |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production-environment Helm overrides (GCP `prod` VPC, `JTIER_RUN_CONFIG` path, replica bounds) |
| `.meta/deployment/cloud/secrets/cloud/<env>.yml` | YAML | Per-environment secret injection for Helm (path: `.meta/deployment/cloud/secrets/cloud/`) |

### Key config blocks (Dropwizard YAML)

| Block | Purpose |
|-------|---------|
| `postgres` | Read-write PostgreSQL connection configuration (`PostgresConfig`) |
| `postgresReadOnly` | Read-only PostgreSQL connection configuration (`PostgresConfig`) |
| `partnerConfig` | Lists of partner namespaces authorized for `updatable` and `deletable` operations |
| `partnerSecretsConfig` | Static partner signing secrets (merged with database secrets at startup); each entry contains `version`, `digest`, and `secret` |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| PostgreSQL credentials | Database username/password for read-write and read-only pools | k8s-secret (via `.meta/deployment/cloud/secrets/cloud/<env>.yml`) |
| `partnerSecretsConfig.partners.<name>.secret` | HMAC signing key material for a named partner | k8s-secret / YAML config |
| `partner_secrets` table | Runtime HMAC secrets managed via the `/v1/partners/{partner_name}/secrets/*` API | PostgreSQL (owned by service) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Setting | Local/Dev | Staging | Production |
|---------|-----------|---------|------------|
| `JTIER_RUN_CONFIG` | None (uses `development.yml`) | `/var/groupon/jtier/config/cloud/staging-us-central1.yml` | `/var/groupon/jtier/config/cloud/production-us-central1.yml` |
| `minReplicas` | N/A (single process) | 1 | 2 |
| `maxReplicas` | N/A | 3 | 15 |
| `hpaTargetUtilization` | N/A | (inherited) | (inherited from common: 50) |
| GCP VPC | N/A | `stable` | `prod` |
| PostgreSQL host | `localhost` (`pams_dev` DB) | DaaS staging endpoint | DaaS production endpoint |
| APM | N/A | Enabled (inherited from common) | Enabled |
