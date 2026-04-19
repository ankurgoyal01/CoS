---
service: "aws-service-catalog"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Cloud Infrastructure / Platform Engineering"
platform: "AWS LandingZone"
team: "Cloud Core"
status: active
tech_stack:
  language: "CloudFormation YAML"
  language_version: "AWSTemplateFormatVersion 2010-09-09"
  framework: "AWS Service Catalog"
  framework_version: "N/A"
  runtime: "AWS CloudFormation"
  runtime_version: "N/A"
  build_tool: "Jenkins"
  package_manager: "N/A"
---

# AWS ServiceCatalog Overview

## Purpose

AWSServiceCatalog is Groupon's implementation of AWS Service Catalog as a mechanism for standardizing the definition of specific types of infrastructure deployed by Groupon service teams. It uses a hub-and-spoke model where portfolios are centrally managed in a single AWS account (`grpn-service-catalog-prod`, account ID `746540744976`) and then shared with other AWS accounts or AWS Organization Units in the LandingZone. The `grpn-service-catalog-prod` account is configured as the delegated administrator for AWS Organizations-level Service Catalog sharing.

## Scope

### In scope

- Defining and deploying Service Catalog portfolios via CloudFormation stacks (`ConveyorCloudPortfolio`, `Community` portfolio)
- Managing versioned CloudFormation product templates under `templates/products/` with `VERSION` manifest files
- Sharing portfolios from the central hub account to destination LandingZone accounts
- Accepting shared portfolios in destination accounts and assigning IAM principal access via share-accept stacks
- Enforcing CloudFormation template compliance rules via cfn-guard (OpenSearch security, S3 public access blocking, Cassandra tags)
- Providing Keyspaces CloudFormation macro Lambda functions (single-table and multi-table transforms)
- Terraform/Terragrunt orchestration modules for Service Catalog resources and Keyspaces macro infrastructure

### Out of scope

- Actual provisioning of AWS resources by end users (handled by ConveyorCloud operator via the Service Catalog console/API in destination accounts)
- IAM role creation in destination accounts (handled by `AWSLandingZone` repo)
- ConveyorCloud application logic (handled by the ConveyorCloud platform)

## Domain Context

- **Business domain**: Cloud Infrastructure / Platform Engineering
- **Platform**: AWS LandingZone
- **Upstream consumers**: ConveyorCloud service teams provisioning AWS resources (S3, OpenSearch, Keyspaces, RDS, SNS, Secrets Manager) via Service Catalog in their destination AWS accounts
- **Downstream dependencies**: AWS Service Catalog API, AWS CloudFormation, Amazon S3 template bucket (`grpn-prod-cloudcore-service-catalog`), AWS Organizations, AWS IAM, AWS Lambda (Keyspaces macro), AWS Secrets Manager, AWS CloudWatch

## Stakeholders

| Role | Description |
|------|-------------|
| Team Owner | Cloud Core (`cloud-core@groupon.com`) — owns and operates all portfolios |
| Portfolio Consumer | ConveyorCloud teams — provision AWS resources via the `ConveyorCloudPortfolio` |
| Community Consumer | General Groupon engineering teams — provision resources via the `Community` portfolio |
| IAM Approver | Cloud Core / LandingZone team — approves and manages launch-constraint IAM roles |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| IaC — Portfolio | CloudFormation YAML | AWSTemplateFormatVersion 2010-09-09 | `portfolios/ConveyorCloud/main.yaml` |
| IaC — Product Templates | CloudFormation YAML | AWSTemplateFormatVersion 2010-09-09 | `templates/products/` |
| IaC — Orchestration | Terraform / Terragrunt | 0.12.7 | `poc/terraform/envs/grpn-gensandbox1/.terraform-version` |
| Lambda Runtime | Python | N/A (AWS Lambda managed) | `architecture/models/components/keyspaces-single-table-macro-lambda.dsl` |
| Build tool | Jenkins | N/A | `Jenkinsfile` |
| Compliance validation | cfn-guard | v0.1.0 (Docker image `docker.groupondev.com/cloudcore/cfn-guard:v0.1.0`) | `Jenkinsfile` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| cfn-guard | v0.1.0 | validation | Policy-as-code validation of CloudFormation product templates before promotion |
| Terragrunt | compatible with Terraform 0.12.7 | orchestration | DRY Terraform orchestration across environments for Service Catalog modules |
| aws-okta | N/A | auth | CLI tool for assuming AWS IAM roles via Okta for manual deployments |
| AWS CloudFormation | managed | IaC | Deploys portfolio and share-accept stacks; backed by `AWS::ServiceCatalog::*` resource types |
| AWS Service Catalog | managed | platform | Hosts portfolios, products, provisioning artifacts, and launch constraints |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
