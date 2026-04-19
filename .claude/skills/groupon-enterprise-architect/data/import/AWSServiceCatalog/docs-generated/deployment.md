---
service: "aws-service-catalog"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "cloudformation"
environments: ["dev", "stable", "prod"]
---

# Deployment

## Overview

AWSServiceCatalog is deployed as a set of AWS CloudFormation stacks. There are no application containers, Kubernetes pods, or long-running processes. The hub account `grpn-service-catalog-prod` (account ID `746540744976`) hosts all portfolio stacks. Destination accounts receive share-accept stacks. Deployments are currently performed manually via `aws-okta` authenticated AWS CLI commands. A Jenkins pipeline performs CloudFormation template compliance validation using cfn-guard on every commit but does not automate stack deployments.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | No Docker containers — pure IaC |
| Portfolio stacks | AWS CloudFormation | `portfolios/ConveyorCloud/main.yaml`, `portfolios/Community/main.yaml` |
| Share-accept stacks | AWS CloudFormation | `portfolios/ConveyorCloud/share-accept/main.yaml`, `portfolios/Community/share-accept/main.yaml` |
| Common portfolio template | AWS CloudFormation (nested stack) | `templates/common/sc-portfolio.yaml` |
| Product templates | AWS CloudFormation (S3-hosted) | `templates/products/ConveyorCloud/` and `templates/products/generic/` |
| Compliance validator | cfn-guard v0.1.0 (Docker) | `docker.groupondev.com/cloudcore/cfn-guard:v0.1.0` run in Jenkins |
| Terraform orchestration | Terraform 0.12.7 / Terragrunt | `poc/terraform/` (POC state; production orchestration separate) |
| Load balancer | None | N/A |
| CDN | None | N/A |

## Environments

| Environment | Purpose | Region(s) | Stack Name |
|-------------|---------|-----------|-----------|
| dev | Pre-production testing of new product versions | `us-west-2` | `ServiceCatalog-ConveyorCloud-dev` |
| stable | Staging environment for ConveyorCloud stable accounts | `eu-west-1`, `us-west-1`, `us-west-2` | `ServiceCatalog-ConveyorCloud-stable` |
| prod | Production environment for ConveyorCloud prod and cstools-prod accounts | `eu-west-1`, `us-west-1`, `us-west-2` | `ServiceCatalog-ConveyorCloud-prod` |

### Destination AWS Accounts (Portfolio Share Targets)

| Stage | Account ID | Account Name |
|-------|-----------|-------------|
| dev | `236248269315` | conveyor-sandbox |
| dev | `549734399709` | grpn-gensandbox1 |
| dev | `842687832885` | cstools-dev |
| stable | `286052569778` | conveyor-stable |
| prod | `497256801702` | conveyor-prod |
| prod | `821816581610` | cstools-prod |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Trigger**: On push (every branch)

### Pipeline Stages

1. **cfn-validate**: Pulls Docker image `docker.groupondev.com/cloudcore/cfn-guard:v0.1.0` and runs `validate -r /opt/rules/guard_rules.guard -d /opt/tests/ConveyorCloud/` against all product templates under `templates/products/ConveyorCloud/`
2. *(No automated deploy stage)* — Stack deployments are performed manually by Cloud Core operators using `aws-okta` authenticated AWS CLI commands as described in `README.md`

## Product Template Promotion Flow

New product versions are promoted through stages in sequence:

1. **Author and test**: Template authored locally, assigned version in `VERSION` file, added under `OnlyInDev` condition in portfolio template
2. **Upload to S3**: `aws s3 sync` + `aws s3 mv` to version-stamp the file on `grpn-prod-cloudcore-service-catalog`
3. **Deploy to dev**: `aws cloudformation update-stack --stack-name ServiceCatalog-ConveyorCloud-dev` in `us-west-2`
4. **Promote to stable**: Update condition to `PromoteToStable`; run `update-stack` in all three regions for `ServiceCatalog-ConveyorCloud-stable`
5. **Promote to prod**: Update condition to `PromoteToAll`; run `update-stack` in all three regions for `ServiceCatalog-ConveyorCloud-prod`

## Scaling

> Not applicable — AWS CloudFormation and AWS Service Catalog are fully managed AWS services. No scaling configuration is required.

## Resource Requirements

> Not applicable — no compute resources are owned by this service. All infrastructure is AWS-managed.
