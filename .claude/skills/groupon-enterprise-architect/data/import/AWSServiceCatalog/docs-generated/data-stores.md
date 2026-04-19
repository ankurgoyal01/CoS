---
service: "aws-service-catalog"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "amazonS3TemplatesBucket"
    type: "s3"
    purpose: "Stores versioned CloudFormation product templates referenced by Service Catalog portfolio stacks"
---

# Data Stores

## Overview

AWSServiceCatalog uses a single AWS S3 bucket as its primary artifact store. No relational databases, caches, or message queues are owned by this service. The S3 bucket holds the versioned CloudFormation templates that back each Service Catalog product provisioning artifact. The service itself is stateless — all durable state is managed by AWS Service Catalog and AWS CloudFormation.

## Stores

### Product Template S3 Bucket (`amazonS3TemplatesBucket`)

| Property | Value |
|----------|-------|
| Type | s3 |
| Architecture ref | `amazonS3TemplatesBucket` (stub in DSL) |
| Bucket name | `grpn-prod-cloudcore-service-catalog` |
| Region | `us-west-2` (primary; templates referenced cross-region via URL) |
| Purpose | Stores all versioned product CloudFormation templates for portfolio artifact references |
| Ownership | owned (managed by Cloud Core) |
| Migrations path | N/A |

#### Key Entities

| Path Pattern | Purpose | Key Fields |
|--------------|---------|-----------|
| `templates/products/ConveyorCloud/s3-with-iam-role-access/template-v{N}.yaml` | Versioned S3 bucket product template (current: v1.11) | SSE encryption, IAM role access, lifecycle policies |
| `templates/products/ConveyorCloud/opensearch/template-v{N}.yaml` | Versioned OpenSearch product template (current: v0.13) | Multi-AZ, master nodes, node-to-node encryption, EBS volume |
| `templates/products/ConveyorCloud/conveyor-operator-tester/template-v{N}.yaml` | Conveyor operator tester product template (current: v0.3) | Empty stack for operator testing |
| `templates/products/generic/aws-keyspaces-tables/template-v{N}.yaml` | Multi-table Keyspaces product template | Cassandra keyspaces, IAM access policy |
| `templates/products/generic/aws-keyspaces-no-tables/template-v{N}.yaml` | Keyspaces (no tables) product template | Cassandra keyspace only |
| `templates/products/generic/aws-keyspaces-single-table/template-v{N}.yaml` | Single-table Keyspaces product template | Single Cassandra table with columns |
| `templates/products/generic/aws-rds/template-v{N}.yaml` | RDS product template | MySQL, MariaDB, or Postgres instance |
| `templates/products/generic/aws-secret/template-v{N}.yaml` | Secrets Manager secret product template | AWS Secrets Manager secret |
| `templates/products/generic/aws-sns-topic/template-v{N}.yaml` | SNS topic product template | SNS topic configuration |
| `templates/products/generic/aws-sns-topic-subscription/template-v{N}.yaml` | SNS topic subscription product template | SNS subscription configuration |
| `templates/products/generic/aws-elasticsearch/template-v{N}.yaml` | Elasticsearch product template | ElasticSearch domain |
| `templates/common/sc-portfolio.yaml` | Shared portfolio nested stack template | Portfolio display name, provider, tags |

#### Access Patterns

- **Read**: Portfolio CloudFormation stacks reference template URLs via `!Sub 'https://s3-${ProductTemplateS3Region}.amazonaws.com/${ProductTemplateS3BucketName}/templates/...'`
- **Write**: Engineers upload templates using `aws s3 sync . s3://grpn-prod-cloudcore-service-catalog/templates --region us-west-2` then rename with version suffix via `aws s3 mv`
- **Indexes**: Not applicable (S3 key-based access)

## Caches

> Not applicable — no cache layer used.

## Data Flows

Template files are authored locally in the `templates/` directory, uploaded to the S3 bucket by the operator, renamed with a version suffix matching the `VERSION` file, then referenced by URL in the portfolio CloudFormation template's `ProvisioningArtifactParameters`. AWS Service Catalog fetches templates directly from S3 when provisioning artifacts are created or updated.
