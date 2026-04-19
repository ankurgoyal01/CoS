---
service: "ckod-backend-jtier"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, yaml-config-file, k8s-secrets]
---

# Configuration

## Overview

CKOD Backend JTier is configured through a combination of JTier YAML config files (mounted per environment at the path specified by `JTIER_RUN_CONFIG`) and environment variables. Non-secret values such as resource limits and scaling parameters are defined in per-environment deployment YAML files under `.meta/deployment/cloud/`. Secrets (database credentials, API tokens) are stored in the `ckod-api-secrets` repository and injected as Kubernetes secrets. The JTier framework reads `mysql`, `jiraServer`, and `token` fields from the YAML config file at startup.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the JTier YAML config file for the running environment | yes | None | k8s deployment env |
| `GITHUB_API_TOKEN` | Bearer token for GitHub Enterprise API calls (diff authors, contributors, SOX CSV) | yes | None | k8s-secret |
| `JIRA_SERVER` | Base URL of the Jira Cloud server for ticket creation | yes | None | k8s-secret |
| `JIRA_AUTH` | Authorization header value for Jira REST API calls (Bearer token or Basic auth) | yes | None | k8s-secret |
| `MYSQL_RO_HOST` | Hostname of the MySQL read-only replica | yes | None | k8s-secret |
| `MYSQL_RW_HOST` | Hostname of the MySQL read-write primary | yes | None | k8s-secret |
| `MYSQL_DATABASE` | MySQL database name | yes | None | k8s-secret |
| `MYSQL_RO_USER` | Username for MySQL read-only connection | yes | None | k8s-secret |
| `MYSQL_RO_PASSWORD` | Password for MySQL read-only connection | yes | None | k8s-secret |
| `MYSQL_RW_USER` | Username for MySQL read-write connection | yes | None | k8s-secret |
| `MYSQL_RW_PASSWORD` | Password for MySQL read-write connection | yes | None | k8s-secret |
| `MALLOC_ARENA_MAX` | JVM memory arena limit (prevents vmem explosion in containers) | no | 4 | k8s deployment env (common.yml) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed above.

## Feature Flags

> No evidence found in codebase. No feature flag system is used.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `/var/groupon/jtier/config/cloud/staging-us-west-2.yml` | YAML | JTier runtime config for staging AWS us-west-2 |
| `/var/groupon/jtier/config/cloud/staging-us-central1.yml` | YAML | JTier runtime config for staging GCP us-central1 |
| `/var/groupon/jtier/config/cloud/production-us-central1.yml` | YAML | JTier runtime config for production GCP us-central1 |
| `/var/groupon/jtier/config/cloud/dev-us-central1.yml` | YAML | JTier runtime config for dev GCP us-central1 |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Common Kubernetes app component config (ports, scaling, logging) |
| `.meta/deployment/cloud/components/worker/common.yml` | YAML | Common Kubernetes worker component config |
| `.meta/deployment/cloud/components/app/{env}.yml` | YAML | Per-environment overrides for the app component |
| `.meta/deployment/cloud/components/worker/{env}.yml` | YAML | Per-environment overrides for the worker component |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `ckod-api-secrets` (repo) | All database credentials and API tokens for all environments | GitHub Enterprise (PRE/ckod-api-secrets) |
| `.meta/deployment/cloud/secrets` | Kubernetes secret manifest path referenced by `.meta/.raptor.yml` | k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Environment | Cloud | Region | Notable Overrides |
|-------------|-------|--------|-------------------|
| dev | GCP | us-central1 | `minReplicas: 1`, `maxReplicas: 2`, Hybrid Boundary `customSubdomain: dev` |
| staging | AWS | us-west-2 | `minReplicas: 1`, `maxReplicas: 2`, `filebeat.volumeType: low` |
| staging | GCP | us-central1 | `minReplicas: 1`, `maxReplicas: 2`, `filebeat.volumeType: low` |
| production | GCP | us-central1 | `minReplicas: 1`, `maxReplicas: 2`, VIP `ckod-api.production.service.us-central1.gcp.groupondev.com` |
| production | AWS | us-west-1, us-west-2 | Separate Kubernetes contexts per region |
| production | AWS | eu-west-1 | Separate Kubernetes context for EMEA region |

The common app config sets `minReplicas: 2`, `maxReplicas: 15`, `hpaTargetUtilization: 50`, `cpus.main.request: 1000m`, `memory.main.request: 500Mi`, `memory.main.limit: 500Mi`. Per-environment files override scaling bounds downward for non-production environments.
