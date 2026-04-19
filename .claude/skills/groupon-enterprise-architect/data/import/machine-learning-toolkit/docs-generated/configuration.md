---
service: "machine-learning-toolkit"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["terraform-variables", "aws-ssm", "aws-secrets-manager", "terragrunt-hcl"]
---

# Configuration

## Overview

The Machine Learning Toolkit is configured through three layers: (1) Terragrunt HCL input variables defined per environment in `envs/`, (2) AWS SSM Parameter Store for runtime Airflow variables consumed by DAGs, and (3) AWS Secrets Manager for Airflow connection strings and per-project model/API secret payloads. There are no application-level environment variables (no running process; the service is infrastructure-as-code). Terraform variables are the primary configuration mechanism at provisioning time.

## Environment Variables

> Not applicable. This service provisions AWS infrastructure via Terraform/Terragrunt; it does not run a process with environment variables. Terraform variables serve an equivalent role and are documented below.

## Terraform / Terragrunt Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `aws_region` | AWS region for all resources | yes | `us-west-2` | `envs/global.hcl` |
| `service_name` | Canonical service name | yes | `dssi-airflow-platform` | `envs/global.hcl` |
| `service_name_prefix` | Short prefix used in all resource names | yes | — | `envs/global.hcl` |
| `owner` | Owner email address | yes | `cs_ds@groupon.com` | `envs/global.hcl` |
| `aws_default_role` | IAM role for Terraform/Terragrunt execution | yes | `grpn-dnd-dssi-af` | `envs/global.hcl` |
| `team_name` | Short team name (used in resource naming prefixes) | yes | `dssi` | `envs/global.hcl` |
| `team_email` | Team email | yes | `cs_ds@groupon.com` | `envs/global.hcl` |
| `slack_alerts_email` | Slack inbound email address for SNS alert subscriptions | yes | `dnd-dssi-service-aler-...@groupon.slack.com` | `envs/global.hcl` |
| `slack_post_url` | Slack webhook URL stored as Airflow connection in SSM/Secrets Manager | yes | — | `envs/global.hcl` |
| `upload_dockers` | Whether to push Docker images to ECR during apply | yes | `true` | `envs/global.hcl` |
| `env` | Short environment name (`dev`, `stable`) | yes | — | per-env `account.hcl` |
| `env_stage` | Full stage name used in S3 bucket suffixes | yes | — | per-env `account.hcl` |
| `env_short_name` | Short environment name used in EMR resource naming | yes | — | per-env `account.hcl` |
| `aws_account_id` | AWS account ID for the environment | yes | `575209962483` (dev), `965578965255` (stable) | `Jenkinsfile` env block |
| `mwaa_name` | MWAA environment name suffix | yes | — | per-env terragrunt |
| `lz_vpc_name` | Name of the primary LandingZone VPC | no | `PrimaryVPC` | `variables.tf` |
| `dag_bucket_suffix` | Suffix appended to DAG bucket name | no | `-1` | `variables.tf` |
| `dags_s3_foldername` | S3 key prefix for DAG objects | no | `dags` | `variables.tf` |
| `kms_keys` | List of additional KMS key ARNs | no | `[]` | `variables.tf` |
| `emr_empty_config` | Placeholder EMR config list | no | `[]` | `variables.tf` |
| `key_pair` | EC2 key pair name for EMR | no | `""` | `variables.tf` |
| `kinesis_stream_arn` | ARN of Kinesis stream for CloudWatch log forwarding | no | `""` | `variables.tf` |
| `kinesis_stream_name` | Name of Kinesis stream | no | `""` | `variables.tf` |
| `sage_endpoint_name` | SageMaker endpoint name (legacy override) | no | `""` | `variables.tf` |
| `metric_gateway` | Metrics push gateway URL | no | `""` | `variables.tf` |
| `hive_db` | Hive database name (for EMR Hive connectivity) | yes | — | per-env input |
| `hive_user` | Hive/HDFS user for EMR jobs | yes | — | per-env input |
| `hdfs_host` | HDFS hostname for EMR connectivity | yes | — | per-env input |
| `hive_hdfs_location` | Base HDFS location for Hive tables | yes | — | per-env input |
| `slack_channel_name` | Airflow connection ID for the Slack channel | yes | — | per-env input |
| `boundary_policy` | IAM boundary policy name for EMR roles | yes | — | per-env input |
| `emr_role_name` | Base EMR role name | yes | — | per-env input |
| `role_name_prefix` | Prefix for all IAM role names | yes | — | per-env input |
| `service_role_name` | Service role name for MWAA | yes | — | per-env input |

## Feature Flags

> No evidence found in codebase. No runtime feature flags are configured.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `envs/global.hcl` | HCL | Global Terragrunt inputs shared across all environments |
| `envs/dev/account.hcl` | HCL | Dev environment account-level inputs |
| `envs/stable/account.hcl` | HCL | Stable environment account-level inputs |
| `envs/sandbox/account.hcl` | HCL | Sandbox environment account-level inputs |
| `envs/{env}/us-west-2/region.hcl` | HCL | Region-level inputs for each environment |
| `envs/{env}/us-west-2/airflow_platform/terragrunt.hcl` | HCL | Module source reference for the airflow_platform module per environment |
| `envs/terragrunt.hcl` | HCL | Root Terragrunt config (S3 backend, provider config) |
| `modules/airflow_platform/variables.tf` | HCL | All Terraform variable declarations for the airflow_platform module |
| `modules/airflow_platform/bootstrap/config.json` | JSON | Bootstrap configuration for EMR cluster initialization |
| `modules/airflow_platform/bootstrap/dssi-build-*/` | Shell scripts + configs | EMR node bootstrap scripts: authorized keys, Filebeat, log rotation, banner |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `/{team_name}/af/variables/default_configs` | Platform-wide Airflow variables: bucket names, subnet IDs, security groups, EMR config, region, metric gateway | AWS Secrets Manager (mirrored to SSM) |
| `/{team_name}/af/connections/{slack_channel_name}` | Slack webhook URL as an Airflow connection string | AWS Secrets Manager + SSM |
| `/{team_name}/af/variables/{project}-model-configs` | Per-project model deployment config: prefix, service role ARN, model group name, EMR name, release label, instance profile | AWS Secrets Manager |
| `/{team_name}/af/variables/{project}-{version}-{api_name}-rest-api-configs` | Per-API endpoint name, model name, CloudWatch deployment alarm name | AWS Secrets Manager |
| `modules/airflow_platform/projects/api-keys.json` | API key definitions for API Gateway; pulled from `dssi-credentials` repo at CI time | Git (external `dssi-credentials` repo, not stored in this repo) |

> Secret values are NEVER documented. Only names and rotation policies are shown above. The `dssi-credentials` repository is cloned at Jenkins build time and the `api-keys.json` file is injected into the Terraform working directory.

## Per-Environment Overrides

| Environment | Account ID | Jenkins label | Auto-plan | Auto-apply |
|-------------|-----------|---------------|-----------|-----------|
| `dev` | `575209962483` | `aws-dssiaf-edwsandbox` | yes | no |
| `stable` | `965578965255` | `aws-dssiaf-edwstable` | no | no |
| `production` | (commented out in Jenkinsfile) | — | no | no |

All environments use the same `us-west-2` region and the same `airflow_platform` Terraform module. Environment-specific differences (VPC subnets, bucket names, account IDs) are resolved via Terragrunt `account.hcl` and `region.hcl` files. MWAA and EMR resource names are suffixed with the environment short name to distinguish them. In dev, DAGs can be synced directly to S3 via `aws s3 sync`; in stable and production, all changes require a PR and Jenkins pipeline execution.

The Airflow runtime configuration options set at the platform level:

| Airflow Config Key | Value | Purpose |
|-------------------|-------|---------|
| `core.enable_xcom_pickling` | `True` | Enables XCom serialization compatibility |
| `secrets.backend` | `airflow.providers.amazon.aws.secrets.secrets_manager.SecretsManagerBackend` | Redirects connection/variable lookups to Secrets Manager |
| `secrets.backend_kwargs` | `{"connections_prefix": "/{team_name}/af/connections", "variables_prefix": "/{team_name}/af/variables"}` | Prefix paths for Secrets Manager lookups |
| `celery.sync_parallelism` | `1` | Limits Celery sync parallelism |
