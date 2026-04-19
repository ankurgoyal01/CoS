---
service: "gpn-data-api"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, helm-values]
---

# Configuration

## Overview

GPN Data API is configured through Dropwizard YAML configuration files, one per deployment environment. The active config file path is injected via the `JTIER_RUN_CONFIG` environment variable at container startup. Secrets (database credentials, BigQuery service-account key) are provided via Helm secrets overlays merged at deploy time. There are no runtime feature flags or external config stores (Consul/Vault) evident in the codebase.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Absolute path to the environment-specific Dropwizard YAML config file | yes | None | helm (`.meta/deployment/cloud/components/api/<env>.yml`) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

> No evidence found in codebase. No feature flag system is used.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/config/development.yml` | YAML | Local development Dropwizard configuration (MySQL credentials, Teradata credentials, BigQuery key path) |
| `.meta/deployment/cloud/components/api/common.yml` | YAML | Shared Kubernetes deployment settings (image, ports, CPU/memory requests, log config) |
| `.meta/deployment/cloud/components/api/staging-us-central1.yml` | YAML | Staging-specific overrides (namespace, VPC, VIP, resource limits, `JTIER_RUN_CONFIG` value) |
| `.meta/deployment/cloud/components/api/production-us-central1.yml` | YAML | Production-specific overrides (namespace, VPC, VIP, replica counts, APM enabled, `JTIER_RUN_CONFIG` value) |
| `.meta/.raptor.yml` | YAML | Raptor/Conveyor component registration (`archetype: jtier`, `type: api`) |
| `.service.yml` | YAML | Service registry metadata (team, SRE alerts, PagerDuty, dashboards, OpenAPI path) |

### Dropwizard Configuration Structure (`GpnDataApiConfiguration`)

The service configuration class binds three top-level blocks from the YAML file:

| Config Block | Type | Key Properties |
|--------------|------|----------------|
| `mysql` | `MySQLConfig` (JTier) | MySQL connection URL, username, password, pool settings |
| `teradata` | `TeradataConfig` | `host`, `port`, `username`, `password`, `database` |
| `bigQuery` | `BigQueryConfig` | `key` (service-account JSON key path or content), `projectId` |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `mysql.password` | MySQL database password | Helm secrets overlay (`.meta/deployment/cloud/secrets/cloud/<env>.yml`) |
| `teradata.password` | Teradata database password | Helm secrets overlay |
| `bigQuery.key` | Google Cloud service-account key for BigQuery authentication | Helm secrets overlay |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Setting | Staging | Production |
|---------|---------|------------|
| `JTIER_RUN_CONFIG` | `/var/groupon/jtier/config/cloud/staging-us-central1.yml` | `/var/groupon/jtier/config/cloud/production-us-central1.yml` |
| `deployEnv` | `staging` | `production` |
| `namespace` | `gpn-data-api-staging` | `gpn-data-api-production` |
| `vpc` | `stable` | `prod` |
| `vip` | `gpn-data-api.us-central1.conveyor.stable.gcp.groupondev.com` | `gpn-data-api.us-central1.conveyor.prod.gcp.groupondev.com` |
| `minReplicas` | 1 (common default) | 2 |
| `maxReplicas` | 2 (common default) | 5 |
| APM | disabled | enabled |
| VPA | enabled | enabled |
| Main CPU limit | 50m | 1 (common limit applies) |
