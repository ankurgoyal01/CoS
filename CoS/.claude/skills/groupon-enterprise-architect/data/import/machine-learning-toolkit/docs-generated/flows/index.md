---
service: "machine-learning-toolkit"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for the Pricing and Promotions Data Science Machine Learning Toolkit.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Synchronous Inference Request](inference-request-sync.md) | synchronous | API call (POST to API Gateway) | External caller submits a JSON inference request; API Gateway validates and routes it to the SageMaker endpoint synchronously |
| [Asynchronous Inference Request](inference-request-async.md) | asynchronous | API call (POST to API Gateway with s3loc header) | Caller submits a reference to an S3-located payload; SageMaker processes asynchronously and notifies via SNS/SQS |
| [Model Training and Deployment](model-training-deployment.md) | batch | Manual DAG trigger by data scientist | MWAA DAG orchestrates feature engineering on EMR, trains or updates a SageMaker model, registers it in the Model Registry, and deploys the endpoint |
| [Platform Terraform Deployment](platform-terraform-deployment.md) | batch | Jenkins CI trigger (PR or manual) | Jenkins pipeline validates, plans, and applies Terraform/Terragrunt to provision or update all platform AWS infrastructure |
| [DAG File Sync](dag-file-sync.md) | event-driven | Push to `main` branch on GitHub | GitHub Actions workflow syncs Airflow DAG files from the repository to the MWAA DAG S3 bucket |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 1 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

- The [Synchronous Inference Request](inference-request-sync.md) and [Asynchronous Inference Request](inference-request-async.md) flows cross service boundaries between the private API Gateway and SageMaker runtime. These are modeled in the architecture dynamic view `dynamic-inference-request-flow`.
- The [Model Training and Deployment](model-training-deployment.md) flow spans MWAA, EMR, SageMaker, and S3. It is modeled in the architecture dynamic view `dynamic-training-deployment-flow`.
- CloudWatch log streams cross to the centralized logging stack (`loggingStack`) and metrics cross to the Wavefront metrics stack (`metricsStack`) in all flows.
