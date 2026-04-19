---
service: "bq_orr"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

The BigQuery Orchestration Service is configured through two mechanisms: environment variables injected by `deploybot_gcs` at deployment time (defined in `.deploy_bot.yml`), and Airflow DAG-level defaults coded directly in each DAG Python file. There is no external config store (Consul, Vault, Helm values file) observed in this repository. Environment-specific behaviour is driven entirely by the `COMPOSER_DAGS_BUCKET` and `KUBERNETES_NAMESPACE` variables set per deployment target.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `COMPOSER_DAGS_BUCKET` | GCS bucket name where DAG artifacts are uploaded for the target Cloud Composer environment | yes | None | `.deploy_bot.yml` (per-environment) |
| `KUBERNETES_NAMESPACE` | Kubernetes namespace in the target cluster where the deployment job runs | yes | None | `.deploy_bot.yml` (per-environment) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed above.

### Per-environment values

| Environment | `COMPOSER_DAGS_BUCKET` | `KUBERNETES_NAMESPACE` |
|-------------|------------------------|------------------------|
| dev | `us-central1-grp-shared-comp-155675d0-bucket` | `bigquery-dev` |
| staging | `us-central1-grp-shared-comp-03dba3de-bucket` | `bigquery-staging` |
| production | `us-central1-grp-shared-comp-9260309b-bucket` | `bigquery-production` |

## Feature Flags

> No evidence found in codebase.

No feature flags are defined or consumed by this service.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.deploy_bot.yml` | YAML | Defines deployment targets (dev, staging, production), Kubernetes cluster contexts, GCS bucket names, namespaces, Slack notification channels, and promotion chain |
| `.service.yml` | YAML | Service registry metadata — name, title, description, team owner, SRE dashboards, dependencies, and documentation links |
| `Jenkinsfile` | Groovy (Jenkins DSL) | Specifies the CI/CD shared library version (`java-pipeline-dsl@dpgm-1396-pipeline-cicd`) and the deployment target for the initial build (`dev-gcp-composer-us-central1`) |

## Secrets

> No evidence found in codebase.

No secret references (Vault paths, AWS Secrets Manager ARNs, or Kubernetes Secret names) are declared in this repository. GCP authentication credentials are assumed to be provided by the Kubernetes service account bound to the deployment namespace in each cluster.

## Per-Environment Overrides

All environment-specific configuration is centralised in `.deploy_bot.yml`:

- **dev**: Deploys to `gcp-stable-us-central1` cluster, namespace `bigquery-dev`, bucket `us-central1-grp-shared-comp-155675d0-bucket`. Slack notifications go to `rma-pipeline-notifications`. Automatically promotes to staging on success.
- **staging**: Deploys to `gcp-stable-us-central1` cluster, namespace `bigquery-staging`, bucket `us-central1-grp-shared-comp-03dba3de-bucket`. Automatically promotes to production on success.
- **production**: Deploys to `gcp-production-us-central1` cluster, namespace `bigquery-production`, bucket `us-central1-grp-shared-comp-9260309b-bucket`. Manual approval required (`manual: true`). Slack notifications go to `grim---pit`.

DAG-level defaults (retry count, retry delay, start date, email settings) are hardcoded in each DAG Python file and are not environment-specific.
