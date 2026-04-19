---
service: "machine-learning-toolkit"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumMlToolkitMwaaEnvironment"
    - "continuumMlToolkitApiGateway"
    - "continuumMlToolkitSageMakerEndpoints"
    - "continuumMlToolkitModelRegistry"
    - "continuumMlToolkitEmrCompute"
    - "continuumMlToolkitContainerRegistry"
    - "continuumMlToolkitDagBucket"
    - "continuumMlToolkitDataBuckets"
    - "continuumMlToolkitEmrArtifactsBucket"
    - "continuumMlToolkitEmrLogBucket"
    - "continuumMlToolkitAlertingTopics"
    - "continuumMlToolkitAsyncQueues"
    - "continuumMlToolkitParameterStore"
    - "continuumMlToolkitSecretsManager"
    - "continuumMlToolkitKmsKeys"
    - "continuumMlToolkitCloudWatch"
---

# Architecture Context

## System Context

The Machine Learning Toolkit sits within the Continuum platform as an AWS-native ML infrastructure service operated by the Pricing and Promotions Data Science team. It provides two primary interaction surfaces: (1) a private API Gateway through which authorized callers invoke trained SageMaker endpoints for inference, and (2) a managed Airflow environment through which ML practitioners author and trigger DAGs that orchestrate model training, feature engineering, and endpoint deployment. The platform depends on the Groupon centralized logging stack and Wavefront metrics stack for observability.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| ML Toolkit MWAA Environment | `continuumMlToolkitMwaaEnvironment` | Compute / Workflow | AWS MWAA (Airflow 2.2.2) | Managed Apache Airflow environment orchestrating model training, deployment, and data workflows. `mw1.small`, 1–10 workers. |
| ML Toolkit API Gateway | `continuumMlToolkitApiGateway` | API | AWS API Gateway (PRIVATE) | Private API Gateway exposing healthcheck and inference endpoints for model services. API-key secured. |
| ML Toolkit SageMaker Endpoints | `continuumMlToolkitSageMakerEndpoints` | ML Compute | AWS SageMaker | Runtime endpoints serving synchronous and asynchronous inference requests. Autoscaling configured per endpoint. |
| ML Toolkit Model Registry | `continuumMlToolkitModelRegistry` | DataStore | AWS SageMaker Model Registry | SageMaker Model Package Groups used to version and register deployable models. |
| ML Toolkit EMR Compute | `continuumMlToolkitEmrCompute` | Batch Compute | AWS EMR | Transient EMR clusters for batch processing and feature/model preparation jobs. Supports spot instances with failover. |
| ML Toolkit Container Registry | `continuumMlToolkitContainerRegistry` | Registry | AWS ECR | ECR repositories containing inference and processing container images. Scan-on-push enabled. |
| ML Toolkit DAG Bucket | `continuumMlToolkitDagBucket` | DataStore | AWS S3 | Stores Airflow DAG definitions and runtime requirements files. Versioning enabled, public access blocked. |
| ML Toolkit Data Buckets | `continuumMlToolkitDataBuckets` | DataStore | AWS S3 | S3 buckets for client input, processed data, feature store data, and model artifacts. All private. |
| EMR Artifacts Bucket | `continuumMlToolkitEmrArtifactsBucket` | DataStore | AWS S3 | S3 bucket containing bootstrap scripts and dependency artifacts for transient EMR clusters. |
| EMR Log Bucket | `continuumMlToolkitEmrLogBucket` | DataStore | AWS S3 | S3 bucket for EMR execution logs and diagnostics. |
| ML Toolkit Alerting Topics | `continuumMlToolkitAlertingTopics` | Messaging | AWS SNS | SNS topics for success, failure, and general workflow notifications. Email and SQS subscriptions. |
| ML Toolkit Async Queues | `continuumMlToolkitAsyncQueues` | Messaging | AWS SQS | SQS queues and dead-letter queues for async inference and alert fanout. 24-hour retention, long-poll. |
| ML Toolkit Parameter Store | `continuumMlToolkitParameterStore` | Config | AWS SSM Parameter Store | SSM parameters for default Airflow settings, model configs, and REST API configs. |
| ML Toolkit Secrets Manager | `continuumMlToolkitSecretsManager` | Security | AWS Secrets Manager | Secrets Manager entries for Airflow connections and model/API secret payloads. Airflow uses as secrets backend. |
| ML Toolkit KMS Keys | `continuumMlToolkitKmsKeys` | Security | AWS KMS | KMS keys for MWAA and EMR data encryption at rest and in transit. Key rotation enabled. |
| ML Toolkit CloudWatch | `continuumMlToolkitCloudWatch` | Observability | AWS CloudWatch | CloudWatch logs, subscription filters, and deployment alarms for platform observability. Streams to Kinesis. |

## Components by Container

### ML Toolkit API Gateway (`continuumMlToolkitApiGateway`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Version Routing (`continuumMlToolkitVersionRouting`) | Builds versioned API path resources and healthcheck resources for each model API version | Terraform `aws_api_gateway_resource/method/integration` |
| Inference Routing (`continuumMlToolkitInferenceRouting`) | Defines POST inference resources and SageMaker integration mappings for each model endpoint | Terraform `aws_api_gateway_resource/method/integration` |
| Request Validation and Models (`continuumMlToolkitRequestValidation`) | Validates headers, body, query, and path inputs and enforces JSON schemas per endpoint | Terraform `aws_api_gateway_request_validator/model` |
| Usage Plans and API Keys (`continuumMlToolkitUsagePlans`) | Applies API key provisioning, usage plans, and stage-specific throttle settings | Terraform `aws_api_gateway_usage_plan/api_key/method_settings` |
| SageMaker Invocation Adapter (`continuumMlToolkitSageMakerInvocationAdapter`) | Maps API Gateway requests to SageMaker runtime invocation URIs and credentials | Terraform `aws_api_gateway_integration` |
| Async Dispatch Policy (`continuumMlToolkitAsyncDispatchPolicy`) | Adds async invocation input-location headers and response mappings for async APIs | Terraform request/response templates |

### ML Toolkit MWAA Environment (`continuumMlToolkitMwaaEnvironment`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| DAG Orchestrator (`continuumMlToolkitDagOrchestrator`) | Schedules and executes Airflow DAGs for model deployment and batch workflows | Apache Airflow on MWAA |
| Config Resolver (`continuumMlToolkitConfigResolver`) | Loads runtime variables and connection details from SSM Parameter Store and Secrets Manager | Airflow AWS Provider |
| EMR Job Launcher (`continuumMlToolkitEmrJobLauncher`) | Submits and monitors transient EMR processing steps from workflow tasks | Airflow EMR Operators |
| Model Deployment Controller (`continuumMlToolkitModelDeploymentController`) | Coordinates SageMaker endpoint deployment and rollout steps | Airflow SageMaker Operators |
| Alert Publisher (`continuumMlToolkitAlertPublisher`) | Publishes success/failure/general notifications to SNS topics | Airflow Notifications |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumMlToolkitMwaaEnvironment` | `continuumMlToolkitDagBucket` | Loads DAGs and Python requirements | S3 |
| `continuumMlToolkitMwaaEnvironment` | `continuumMlToolkitParameterStore` | Reads default, model, and REST API runtime configs | AWS SDK |
| `continuumMlToolkitMwaaEnvironment` | `continuumMlToolkitSecretsManager` | Reads Airflow connection and model secrets (secrets backend) | AWS SDK |
| `continuumMlToolkitMwaaEnvironment` | `continuumMlToolkitEmrCompute` | Submits and monitors transient EMR jobs | Airflow EMR Operators |
| `continuumMlToolkitMwaaEnvironment` | `continuumMlToolkitSageMakerEndpoints` | Orchestrates model deployment and runtime operations | Airflow SageMaker Operators |
| `continuumMlToolkitMwaaEnvironment` | `continuumMlToolkitAlertingTopics` | Publishes success/failure/general workflow events | SNS |
| `continuumMlToolkitMwaaEnvironment` | `continuumMlToolkitCloudWatch` | Writes scheduler/worker/webserver logs and metrics | CloudWatch |
| `continuumMlToolkitMwaaEnvironment` | `continuumMlToolkitKmsKeys` | Uses encryption keys | AWS KMS |
| `continuumMlToolkitApiGateway` | `continuumMlToolkitSageMakerEndpoints` | Routes inference requests | HTTPS / SageMaker Runtime |
| `continuumMlToolkitApiGateway` | `continuumMlToolkitCloudWatch` | Publishes access logs and gateway metrics | CloudWatch |
| `continuumMlToolkitSageMakerEndpoints` | `continuumMlToolkitModelRegistry` | Resolves deployable model packages | SageMaker API |
| `continuumMlToolkitSageMakerEndpoints` | `continuumMlToolkitContainerRegistry` | Pulls inference images | ECR |
| `continuumMlToolkitSageMakerEndpoints` | `continuumMlToolkitDataBuckets` | Reads features and writes inference artifacts | S3 |
| `continuumMlToolkitEmrCompute` | `continuumMlToolkitDataBuckets` | Reads input datasets and writes transformed output | S3 |
| `continuumMlToolkitEmrCompute` | `continuumMlToolkitEmrArtifactsBucket` | Downloads bootstrap artifacts and dependencies | S3 |
| `continuumMlToolkitEmrCompute` | `continuumMlToolkitEmrLogBucket` | Writes execution logs and step diagnostics | S3 |
| `continuumMlToolkitAlertingTopics` | `continuumMlToolkitAsyncQueues` | Delivers async success/failure notifications | SNS → SQS |
| `continuumMlToolkitCloudWatch` | `loggingStack` | Streams centralized logs via Kinesis subscription filters | Kinesis |
| `continuumMlToolkitCloudWatch` | `metricsStack` | Publishes operational metrics (Wavefront) | CloudWatch metrics |
| `continuumMlToolkitVersionRouting` | `continuumMlToolkitInferenceRouting` | Resolves version roots and delegates requests | Internal API GW |
| `continuumMlToolkitUsagePlans` | `continuumMlToolkitInferenceRouting` | Guards model inference routes with API keys and limits | Internal API GW |
| `continuumMlToolkitDagOrchestrator` | `continuumMlToolkitConfigResolver` | Loads workflow parameters and connection settings | Internal Airflow |
| `continuumMlToolkitDagOrchestrator` | `continuumMlToolkitModelDeploymentController` | Runs deployment DAG steps for endpoints | Internal Airflow |
| `continuumMlToolkitDagOrchestrator` | `continuumMlToolkitEmrJobLauncher` | Runs EMR-backed data preparation tasks | Internal Airflow |
| `continuumMlToolkitDagOrchestrator` | `continuumMlToolkitAlertPublisher` | Emits workflow completion and failure alerts | Internal Airflow |

## Architecture Diagram References

- Component (API Gateway): `components-continuumMlToolkitApiGateway`
- Component (MWAA Environment): `components-continuumMlToolkitMwaaEnvironment`
- Dynamic (Inference Request Flow): `dynamic-inference-request-flow`
- Dynamic (Training and Deployment Flow): `dynamic-training-deployment-flow`
