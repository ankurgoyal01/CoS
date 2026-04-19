---
service: "mbus-sigint-configuration-v2"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, helm-values, k8s-secret]
---

# Configuration

## Overview

The service is configured through a layered YAML file system controlled by the `JTIER_RUN_CONFIG` environment variable that selects the active config file at startup. Environment-specific YAML files under `src/main/resources/config/cloud/` and `src/main/resources/config/snc1/` supply non-secret values. Secrets (database credentials, Jira API token) are appended from a separate secrets repository at deploy time and injected as environment variables (`DAAS_APP_USERNAME`, `DAAS_APP_PASSWORD`, `DAAS_DBA_USERNAME`, `DAAS_DBA_PASSWORD`, `JIRA_API_PASSWORD`). Kubernetes deployments use Helm chart `cmf-jtier-api` version `3.88.1`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Selects the active YAML config file path for the JTier runtime | yes | none | helm/k8s env |
| `DAAS_APP_USERNAME` | PostgreSQL application user login | yes | none | k8s-secret |
| `DAAS_APP_PASSWORD` | PostgreSQL application user password | yes | none | k8s-secret |
| `DAAS_DBA_USERNAME` | PostgreSQL DBA user login (for migrations) | yes | none | k8s-secret |
| `DAAS_DBA_PASSWORD` | PostgreSQL DBA user password | yes | none | k8s-secret |
| `JIRA_API_PASSWORD` | Jira API token for `mbus-jira@groupon.com` | yes | none | k8s-secret |
| `MALLOC_ARENA_MAX` | Limits glibc memory arena count to prevent vmem explosion in containers | no | `4` | helm common.yml |

> IMPORTANT: Actual secret values are never documented here. Only variable names and purposes.

## Feature Flags

> No evidence found in codebase of runtime feature flags. Role-based access to admin operations acts as a functional gate.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/config/development.yml` | YAML | Local development defaults (localhost PostgreSQL, console logging, open admin access) |
| `src/main/resources/config/cloud/staging-us-central1.yml` | YAML | Staging environment config for GCP us-central1 cluster |
| `src/main/resources/config/cloud/staging-us-west-1.yml` | YAML | Staging environment config for on-prem us-west-1 cluster |
| `src/main/resources/config/cloud/production-us-central1.yml` | YAML | Production config for GCP us-central1 cluster |
| `src/main/resources/config/cloud/production-us-west-1.yml` | YAML | Production config for on-prem us-west-1 cluster |
| `src/main/resources/config/snc1/staging.yml` | YAML | Legacy SNC1 staging config |
| `src/main/resources/config/snc1/production.yml` | YAML | Legacy SNC1 production config |
| `src/main/resources/metrics.yml` | YAML | Metrics pipeline configuration (Telegraf destination, flush frequency) |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Kubernetes Helm values shared across all environments |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Helm overrides for production GCP us-central1 |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Helm overrides for staging GCP us-central1 |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DAAS_APP_PASSWORD` | PostgreSQL application user password | k8s-secret (DaaS) |
| `DAAS_DBA_PASSWORD` | PostgreSQL DBA password for migrations | k8s-secret (DaaS) |
| `JIRA_API_PASSWORD` | Jira Atlassian API token | k8s-secret (secrets repo) |

> Secret values are NEVER documented. The production secrets file is sourced from `MBus/mbus-sigint-configuration-v2-secrets` repository at deploy time.

## Per-Environment Overrides

| Setting | Development | Staging (GCP us-central1) | Production (GCP us-central1) |
|---------|-------------|--------------------------|------------------------------|
| PostgreSQL host | `localhost:35432` | `mbus-sigint-config-rw-na-staging-db.gds.stable.gcp.groupondev.com` | `mbus-sigint-config-rw-na-production-db.gds.prod.gcp.groupondev.com` |
| PostgreSQL database | `sigint_config` | `mbus_sigint_cnf_stg` | `mbus_sigint_cnf_prod` |
| Jira URL | `https://jira-staging.groupondev.com` | `https://jira-staging.groupondev.com` | `https://jira.groupondev.com` |
| Jira API URL | `http://jira-api-staging-vip.snc1:80` | `https://groupondev-sandbox-572.atlassian.net` | `https://groupondev.atlassian.net` |
| ProdCat URL | `http://cat-app-staging-vip.snc1/v1/changes` | `http://prodcat.staging.service/v1/changes/` | `http://prodcat.production.service/v1/changes/` |
| Ansible SSH host | `./src/test/resources/shell/mbusible.sh` (mock) | `mbus1-na-ansible.us-central1.mbus.stable.gcp.groupondev.com` | `mbus1-na-ansible.us-central1.mbus.prod.gcp.groupondev.com` |
| Logging | Console / DEBUG | steno-trace / INFO | steno-trace / INFO |
| Client auth | Anonymous (`defaultRoles: [admin]`) | `x-grpn-username` header required | `x-grpn-username` header required |
| Quartz DeployReschedule trigger | `0 13,28,43,58 * * * ?` (every 15 min) | `0 58 3 * * ?` (daily 03:58) | `0 58 3 * * ?` (daily 03:58) |

### Role configuration (production)

The `clientIds.roles` block in production config defines named users granted elevated roles:
- `admin`: named MBus team members plus `mbusible`
- `full-config-reader`: `mbusible`
- `change-request-approver`: empty list (approval is handled via admin role or ProdCat)
