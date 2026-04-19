---
service: "transporter-jtier"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, k8s-configmap, aws-secrets-manager]
---

# Configuration

## Overview

Transporter JTier is configured through environment variables injected into Kubernetes pods by the Conveyor deployment platform, supplemented by environment-specific JTier YAML config files. Secrets are managed via the `.meta/deployment/cloud/secrets` path (referenced in `.meta/.raptor.yml`). Non-secret environment values are provided via Kubernetes ConfigMaps. The active JTier config file is selected at runtime by the `JTIER_RUN_CONFIG` environment variable.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Absolute path to the active JTier YAML configuration file for the current environment | yes | None | Kubernetes `envVars` in deployment config |
| `AWS_DEFAULT_REGION` | AWS region for S3 and STS operations in the `sf-upload-worker` pod | yes (worker) | `us-west-1` | Kustomize patch (`iamrole-env-variables.yml`) |
| `AWS_REGION` | AWS region override for the AWS SDK | yes (worker) | `us-west-1` | Kustomize patch (`iamrole-env-variables.yml`) |
| `AWS_WEB_IDENTITY_TOKEN_FILE` | Path to the Kubernetes-projected service account token used for IRSA | yes (worker) | `/var/run/secrets/conveyor/serviceaccount/token` | Kustomize patch (`iamrole-env-variables.yml`) |
| `AWS_ROLE_ARN` | IAM role ARN for S3 access (sourced from ConfigMap) | yes (worker) | None | ConfigMap `iamrole-tr-iam-role-upload-production-config` |
| `RUNNING_IN_DOCKER` | Signals local Docker Compose environment | no | unset | Local `.local/docker-compose.yml` |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

> No evidence found in codebase.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `/var/groupon/jtier/config/cloud/production-us-central1.yml` | YAML | JTier runtime config for production us-central1 environment |
| `/var/groupon/jtier/config/cloud/staging-us-central1.yml` | YAML | JTier runtime config for staging us-central1 environment |
| `doc/swagger/swagger.yaml` | YAML | OpenAPI 2.0 specification for the REST API |
| `.meta/.raptor.yml` | YAML | Raptor/Conveyor component definitions (`api` and `sf-upload-worker`) |
| `.meta/deployment/cloud/components/api/common.yml` | YAML | Common API component deployment config (replicas, ports, resources) |
| `.meta/deployment/cloud/components/sf-upload-worker/common.yml` | YAML | Common worker component deployment config |
| `.meta/deployment/cloud/.tenant.yml` | YAML | Conveyor Tenant resource definition |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Salesforce OAuth credentials | Client ID, client secret, and OAuth endpoints for Salesforce connected app | `.meta/deployment/cloud/secrets` (managed by Conveyor secret path) |
| MySQL credentials | Database host, username, password for `transporter` database | `.meta/deployment/cloud/secrets` |
| Redis credentials | Redis connection details | `.meta/deployment/cloud/secrets` |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Setting | Staging (us-central1) | Production (us-central1) |
|---------|----------------------|--------------------------|
| `JTIER_RUN_CONFIG` | `/var/groupon/jtier/config/cloud/staging-us-central1.yml` | `/var/groupon/jtier/config/cloud/production-us-central1.yml` |
| Namespace | `transporter-jtier-staging` | `transporter-jtier-production` |
| GCP service account | `con-sa-transporter-jtier@prj-grp-central-sa-stable-66eb.iam.gserviceaccount.com` | `con-sa-transporter-jtier@prj-grp-central-sa-prod-0b25.iam.gserviceaccount.com` |
| API min/max replicas | 1 / 2 | 2 / 6 |
| Worker min/max replicas | 1 / 2 | 2 / 6 |
| Filebeat Kafka endpoint | `kafka-elk-broker-staging.snc1` | `kafka-elk-broker.snc1` |
| IAM role name (worker) | `tr-iam-role-upload-staging` | `tr-iam-role-upload-production` |
| AWS ConfigMap name | `iamrole-tr-iam-role-upload-staging-config` | `iamrole-tr-iam-role-upload-production-config` |
| Product ConfigMap | `product-aws-transporter-uploads-config` | `product-aws-transporter-uploads-config` |
