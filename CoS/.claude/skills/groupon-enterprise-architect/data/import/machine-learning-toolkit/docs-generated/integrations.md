---
service: "machine-learning-toolkit"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 8
internal_count: 2
---

# Integrations

## Overview

The Machine Learning Toolkit integrates with eight AWS-managed services as external dependencies and two Groupon-internal platform services. All AWS service integrations are through the AWS SDK and Terraform provider (no direct HTTP calls). The two internal dependencies are the centralized logging stack (ELK via Kinesis) and the centralized metrics stack (Wavefront). There are no REST API calls to other Groupon microservices.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| AWS MWAA | AWS SDK / Terraform | Managed Airflow environment for workflow orchestration | yes | `continuumMlToolkitMwaaEnvironment` |
| AWS SageMaker | AWS SDK / Airflow Operators | Model endpoint deployment, training, batch transform, async inference | yes | `continuumMlToolkitSageMakerEndpoints`, `continuumMlToolkitModelRegistry` |
| AWS EMR | AWS SDK / Airflow EMR Operators | Transient Spark clusters for feature engineering and batch data prep | yes | `continuumMlToolkitEmrCompute` |
| AWS API Gateway | Terraform | Private HTTPS API exposing inference endpoints | yes | `continuumMlToolkitApiGateway` |
| AWS S3 | AWS SDK | DAG storage, ETL data, model artifacts, feature store, EMR logs, client data | yes | `continuumMlToolkitDagBucket`, `continuumMlToolkitDataBuckets`, `continuumMlToolkitEmrArtifactsBucket`, `continuumMlToolkitEmrLogBucket` |
| AWS SNS | AWS SDK | Workflow success/failure/general alert notifications | no | `continuumMlToolkitAlertingTopics` |
| AWS SQS | AWS SDK | Async inference result queuing and dead-letter queuing | no | `continuumMlToolkitAsyncQueues` |
| AWS Secrets Manager + SSM Parameter Store | AWS SDK / Airflow secrets backend | Runtime config and secrets resolution for Airflow and model DAGs | yes | `continuumMlToolkitSecretsManager`, `continuumMlToolkitParameterStore` |
| AWS ECR | AWS SDK / Docker provider | Container image storage for SageMaker inference containers | yes | `continuumMlToolkitContainerRegistry` |
| AWS KMS | AWS SDK | Encryption key management for MWAA and EMR at rest/in transit | yes | `continuumMlToolkitKmsKeys` |
| AWS CloudWatch | AWS SDK | Log aggregation, subscription filters, and deployment alarms | yes | `continuumMlToolkitCloudWatch` |
| Artifactory (groupondev.com) | HTTPS (curl) | Hosts EMR bootstrap zip artifact for cluster initialization | no | `null_resource.upload_articfactory` in `archive.tf` |

### AWS MWAA Detail

- **Protocol**: Terraform `aws_mwaa_environment` resource + Airflow Operators
- **Base URL / SDK**: `aws_mwaa_environment.af1`, version 2.2.2, `mw1.small` class, 1–10 workers
- **Auth**: IAM execution role `grpn-dnd-dssi-af`; KMS key for environment encryption
- **Purpose**: Central workflow orchestration platform; runs DAGs for model training, EMR job submission, SageMaker endpoint deployment, and alert publishing
- **Failure mode**: Workflows stop executing; Wavefront alert "Airflow - No Scheduler Heartbeats" fires at severity 5
- **Circuit breaker**: No circuit breaker; AWS MWAA SLA is 99.9%

### AWS SageMaker Detail

- **Protocol**: Airflow SageMaker Operators (in DAGs); API Gateway integration to SageMaker Runtime for inference
- **Base URL / SDK**: Airflow `SageMakerDeployOperator`, `SageMakerEndpointOperator`; API Gateway URI `arn:aws:apigateway:{region}:runtime.sagemaker:path//endpoints/{endpoint}/invocations`
- **Auth**: IAM service role per project (`{role_name_prefix}-{project}-service-role`); API Gateway passes role credentials via `credentials` parameter
- **Purpose**: Model training jobs, preprocessing jobs, batch transform jobs, endpoint deployment, synchronous and asynchronous inference serving
- **Failure mode**: Inference returns 503 (endpoint unavailable) or 424 (model error); deployment DAG fails and SNS failure topic fires
- **Circuit breaker**: No circuit breaker; SageMaker autoscaling policy handles high load

### AWS EMR Detail

- **Protocol**: Airflow EMR Operators
- **Base URL / SDK**: `EmrCreateJobFlowOperator`, `EmrAddStepsOperator`, `EmrStepSensor`
- **Auth**: IAM EC2 instance profile and service role provisioned per project; KMS log encryption key
- **Purpose**: Transient Spark clusters launched by MWAA DAGs to run feature engineering, data transformation, and model preparation steps
- **Failure mode**: EMR bootstrap failures or step failures trigger Wavefront alert "Ephemeral EMR - Failed to deploy" (severity 2) or "Ephemeral EMR - Query Failed" (severity 2)
- **Circuit breaker**: No circuit breaker

### Artifactory Detail

- **Protocol**: HTTPS (`curl -T` upload)
- **Base URL / SDK**: `https://artifactory.groupondev.com/artifactory/artifacts-generic/{team_name}/airflow/emr/bootstrap/build.zip`
- **Auth**: Not evidenced in repo (Terraform `null_resource.upload_articfactory` uses `curl -T`)
- **Purpose**: Secondary distribution point for the EMR bootstrap zip; EMR clusters can also download directly from the EMR artifacts S3 bucket
- **Failure mode**: Bootstrap artifact unavailable; EMR cluster fails to initialize
- **Circuit breaker**: No circuit breaker

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Centralized Logging Stack (ELK) | Kinesis (CloudWatch Subscription Filter) | Receives MWAA log streams (Task, DAGProcessing, WebServer, Scheduler, Worker) and EMR logs (via Filebeat) | `loggingStack` (stub) |
| Centralized Metrics Stack (Wavefront) | CloudWatch metrics → Wavefront | Receives MWAA scheduler heartbeat metrics, CPU/memory stats, and SageMaker invocation metrics | `metricsStack` (stub) |

## Consumed By

> Upstream consumers are tracked in the central architecture model. The platform is consumed by:
- ML project teams within Groupon who author Airflow DAGs against the MWAA environment.
- Authorized internal API callers who hold `X-API-Key` credentials for specific model inference endpoints.

## Dependency Health

- **MWAA health**: Monitored via Wavefront scheduler heartbeat metric. Wavefront alert "Airflow - No Scheduler Heartbeats" (severity 5) fires when heartbeats stop. Resolution: run `terraform apply` to update MWAA environment or destroy and redeploy.
- **EMR health**: Monitored via Wavefront alerts "Ephemeral EMR - Failed to deploy" and "Ephemeral EMR - Query Failed" (both severity 2). Resolution: check CloudCore SCPs, spot instance availability, and bootstrap scripts.
- **SageMaker endpoint health**: Monitored via CloudWatch deployment alarms (`{project}-deployment-alarm`). API Gateway returns 503 when endpoint is unavailable.
- **Logging stack health**: CloudWatch subscription filters relay to Kinesis; no explicit health check configured in this repo.
