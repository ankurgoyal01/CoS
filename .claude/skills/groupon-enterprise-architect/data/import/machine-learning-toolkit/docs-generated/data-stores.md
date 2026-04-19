---
service: "machine-learning-toolkit"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumMlToolkitDagBucket"
    type: "s3"
    purpose: "Airflow DAG definitions and Python requirements"
  - id: "continuumMlToolkitDataBuckets"
    type: "s3"
    purpose: "Client input/output, ETL data, feature store, model artifacts"
  - id: "continuumMlToolkitEmrArtifactsBucket"
    type: "s3"
    purpose: "EMR bootstrap scripts and dependency artifacts"
  - id: "continuumMlToolkitEmrLogBucket"
    type: "s3"
    purpose: "EMR execution logs and diagnostics"
  - id: "continuumMlToolkitModelRegistry"
    type: "sagemaker-model-registry"
    purpose: "Versioned SageMaker model packages"
  - id: "continuumMlToolkitParameterStore"
    type: "aws-ssm"
    purpose: "Runtime Airflow config, model configs, REST API configs"
  - id: "continuumMlToolkitSecretsManager"
    type: "aws-secrets-manager"
    purpose: "Airflow connections, model secret payloads"
  - id: "continuumMlToolkitAsyncQueues"
    type: "sqs"
    purpose: "Async inference result queues and dead-letter queues"
---

# Data Stores

## Overview

The Machine Learning Toolkit manages eight categories of data stores, all on AWS. There is no relational database. Primary storage is AWS S3, organized into five purpose-specific buckets. Model versioning uses the SageMaker Model Registry. Runtime configuration is stored in SSM Parameter Store and Secrets Manager. Async inference results are buffered in SQS queues. All buckets have public access blocked and are encrypted using KMS keys managed by the platform.

## Stores

### ML Toolkit DAG Bucket (`continuumMlToolkitDagBucket`)

| Property | Value |
|----------|-------|
| Type | S3 |
| Architecture ref | `continuumMlToolkitDagBucket` |
| Purpose | Stores Airflow DAG Python files and the `requirements.txt` file consumed by MWAA at environment startup |
| Ownership | owned |
| Naming pattern | `{service_name_prefix}{dag_bucket_suffix}-{env_stage}` |

#### Key Entities

| Object Path | Purpose | Key Fields |
|-------------|---------|-----------|
| `dags/{project}/` | Per-project DAG files, synced from repo on deploy | Airflow DAG definitions |
| `requirements.txt` | Python package requirements for MWAA workers | S3 object version ID tracked by MWAA |

#### Access Patterns

- **Read**: MWAA reads DAG files on schedule parsing and requirements.txt on environment boot/update
- **Write**: Terraform `aws_s3_object` syncs DAG files on `terraform apply`; GitHub Actions workflow (`deploy.yml`) syncs DAGs to S3 on push to `main` via `aws s3 sync`
- **Indexes**: S3 versioning enabled — MWAA tracks `requirements_s3_object_version` to detect changes

---

### ML Toolkit Data Buckets (`continuumMlToolkitDataBuckets`)

This logical grouping covers four S3 buckets provisioned as separate Terraform resources:

| Bucket | Naming Pattern | Purpose |
|--------|---------------|---------|
| Data bucket | `{service_name_prefix}-data-{env_stage}` | ETL pipeline input and output datasets |
| Client bucket | `{service_name_prefix}-client-{env_stage}` | Project input and output shared with external clients |
| Feature store bucket | `{service_name_prefix}-feat-store-{env_stage}` | Offline feature store data for SageMaker Feature Groups |
| Model artifacts bucket | `{service_name_prefix}-models-{env_stage}` | Trained model artifacts and SageMaker model packages |

| Property | Value |
|----------|-------|
| Type | S3 |
| Architecture ref | `continuumMlToolkitDataBuckets` |
| Purpose | ETL input/output, client data exchange, offline feature storage, model artifact storage |
| Ownership | owned |

#### Key Entities

| Path Pattern | Purpose |
|-------------|---------|
| `{project}/input/` | Project-specific input data (client and data buckets) |
| `{project}/output/` | Project-specific output data (client and data buckets) |
| `{project}/` | Per-project feature store and model artifact directories |

#### Access Patterns

- **Read**: EMR clusters read input datasets; SageMaker endpoints read feature/model artifacts
- **Write**: EMR clusters write transformed datasets; SageMaker endpoints write inference artifacts; Terraform initializes empty project folders on `apply`
- **Indexes**: No indexes (S3 key-prefix based)

---

### EMR Artifacts Bucket (`continuumMlToolkitEmrArtifactsBucket`)

| Property | Value |
|----------|-------|
| Type | S3 |
| Architecture ref | `continuumMlToolkitEmrArtifactsBucket` |
| Purpose | Stores bootstrap scripts and dependency artifacts (zip) used when initializing transient EMR clusters |
| Ownership | owned |
| Naming pattern | `{service_name_prefix}-emr-artifacts-{env_short_name}` |

#### Access Patterns

- **Read**: EMR clusters pull the `build.zip` bootstrap archive during cluster bootstrapping
- **Write**: Terraform uploads bootstrap files from the `bootstrap/` directory; `null_resource` uploads the zip to Artifactory as a secondary distribution point (`https://artifactory.groupondev.com/artifactory/artifacts-generic/{team_name}/airflow/emr/bootstrap/build.zip`)

---

### EMR Log Bucket (`continuumMlToolkitEmrLogBucket`)

| Property | Value |
|----------|-------|
| Type | S3 |
| Architecture ref | `continuumMlToolkitEmrLogBucket` |
| Purpose | Stores EMR step logs and cluster diagnostics for debugging failed jobs |
| Ownership | owned |
| Naming pattern | `{service_name_prefix}-core-emr-logs-{env_short_name}` |

#### Access Patterns

- **Read**: Engineers query via Kibana (logs forwarded from EMR via Filebeat during cluster bootstrapping)
- **Write**: EMR cluster writes step and application logs; `log_s3_uri` SSM variable points MWAA DAGs to this bucket

---

### ML Toolkit Model Registry (`continuumMlToolkitModelRegistry`)

| Property | Value |
|----------|-------|
| Type | SageMaker Model Registry (Model Package Groups) |
| Architecture ref | `continuumMlToolkitModelRegistry` |
| Purpose | Version and register trained ML models for reproducible deployment; SageMaker endpoints resolve model packages from here |
| Ownership | owned |

#### Key Entities

| Entity | Purpose | Key Fields |
|--------|---------|-----------|
| Model Package Group | Groups model versions by project | `model_group_name`, provisioned per project |
| Model Package | Individual trained model version | ARN, approval status, container image URI |

#### Access Patterns

- **Read**: SageMaker endpoints pull the approved model package version at deployment time
- **Write**: MWAA DAGs register new model packages via SageMaker Operators after training completes

---

### ML Toolkit Parameter Store (`continuumMlToolkitParameterStore`)

| Property | Value |
|----------|-------|
| Type | AWS SSM Parameter Store |
| Architecture ref | `continuumMlToolkitParameterStore` |
| Purpose | Stores Airflow runtime variables (bucket names, subnet IDs, EMR configs, connection IDs) and project model/API configs |
| Ownership | owned |

#### Key Entities

| Parameter Path | Purpose |
|---------------|---------|
| `/{team_name}/af/variables/default_configs` | JSON blob of platform defaults: bucket names, subnet IDs, EMR cluster IDs, Airflow name, region, etc. |
| `/{team_name}/af-configs/empty` | Empty EMR config placeholder |
| `/{team_name}/af/connections/{slack_channel_name}` | Slack webhook URL for alert connections |

#### Access Patterns

- **Read**: MWAA Config Resolver loads `default_configs` on DAG startup; DAGs reference bucket names, security groups, and EMR config through this parameter
- **Write**: Terraform `aws_ssm_parameter` resources overwrite on each `apply`

---

### ML Toolkit Secrets Manager (`continuumMlToolkitSecretsManager`)

| Property | Value |
|----------|-------|
| Type | AWS Secrets Manager |
| Architecture ref | `continuumMlToolkitSecretsManager` |
| Purpose | Stores Airflow connection credentials and per-project model/API secret payloads; used as Airflow secrets backend |
| Ownership | owned |

#### Key Entities

| Secret Path | Purpose |
|------------|---------|
| `/{team_name}/af/variables/default_configs` | Default platform config (mirrors SSM, Airflow secrets backend prefix) |
| `/{team_name}/af/connections/{slack_channel_name}` | Slack connection string for Airflow |
| `/{team_name}/af/variables/{project}-model-configs` | Per-project model deployment config (prefix, service role ARN, model group name, EMR cluster name, etc.) |
| `/{team_name}/af/variables/{project}-{version}-{api_name}-rest-api-configs` | Per-API endpoint name, model name, CloudWatch alarm name |

#### Access Patterns

- **Read**: MWAA uses `airflow.providers.amazon.aws.secrets.secrets_manager.SecretsManagerBackend` with prefix `/{team_name}/af/connections` (connections) and `/{team_name}/af/variables` (variables)
- **Write**: Terraform `local_file` + `local-exec` provisioners seed secret values on `apply`

---

### ML Toolkit Async Queues (`continuumMlToolkitAsyncQueues`)

| Property | Value |
|----------|-------|
| Type | AWS SQS (Standard Queue) |
| Architecture ref | `continuumMlToolkitAsyncQueues` |
| Purpose | Buffers async SageMaker inference results subscribed from SNS success/failure topics; dead-letter queues catch failed deliveries |
| Ownership | owned |

#### Key Entities

| Queue Naming Pattern | Purpose |
|---------------------|---------|
| `{service_name_prefix}-sage-async-{project}_{version}_{api_name}-{env}` | Per-model async inference result queue |
| `{service_name_prefix}-sage-async-dead-letter-{project}_{version}_{api_name}-{env}` | Dead-letter queue for the above |

#### Access Patterns

- **Read**: Downstream application polls the SQS queue to retrieve async inference results; long-poll wait time is 20 seconds
- **Write**: SNS topics publish to SQS via subscription; max message size 2048 bytes; retention 86400 seconds (24 hours); max 4 receive attempts before DLQ

## Caches

> No evidence found in codebase. The platform does not configure any cache layer (Redis, Memcached, or in-memory).

## Data Flows

1. Source data is written to the data bucket (`{service_name_prefix}-data-{env_stage}`) by upstream ETL pipelines or client upload to the client bucket.
2. MWAA DAGs trigger transient EMR clusters, which read raw data from the data bucket, apply Spark transformations, and write feature-engineered datasets back to the data bucket or the feature store bucket.
3. MWAA then invokes SageMaker training/deployment operators; trained model artifacts are written to the models bucket and registered in the Model Registry.
4. SageMaker endpoints pull model packages from the Model Registry and container images from ECR to serve inference.
5. Async inference requests write input payloads to S3, receive async notifications via SNS → SQS; sync inference requests return inline.
6. EMR step logs are written to the EMR log bucket and forwarded to ELK via Filebeat. MWAA logs go to CloudWatch log groups (`airflow-{prefix}-{env}-{type}`) and are forwarded to ELK via Kinesis subscription filters.
