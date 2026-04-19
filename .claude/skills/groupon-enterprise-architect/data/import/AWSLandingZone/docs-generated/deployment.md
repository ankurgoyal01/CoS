---
service: "aws-landing-zone"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "jenkins"
environments:
  - conveyorsandbox
  - dev-cloudcore
  - edwsandbox
  - gensandbox
  - recreate
  - grpn-mta-dev
  - grpn-netops-dev
  - grpn-logging-dev
  - grpn-security-dev
  - grpn-cstools-dev
  - stable-grouponinternal
  - grpn-edw-stable
  - staging
  - grpn-backup-stable
  - stable-corp-it
  - grpn-dse-stable
  - grpn-logging-stable
  - grpn-mta-stable
  - grpn-netops-stable
  - prod-grouponinternal
  - edwprod
  - grpn-billing
  - grpn-mta-prod
---

# Deployment

## Overview

AWS Landing Zone is deployed as an infrastructure-as-code delivery system, not a runtime service. Terraform/Terragrunt changes are applied to AWS accounts via a Jenkins pipeline running Docker containers. Two CI Docker images are used: `accounts-terrabase-ci:0.1.7` (Terragrunt wrapper) for most environments, and `accounts-terraform-ci:0.13.2` (Makefile-based) for the billing environment. The pipeline runs on labeled Jenkins EC2 worker nodes in each target AWS account, assuming the role `grpn-all-landingzone-tf-admin` via `TERRAGRUNT_IAM_ROLE`.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container (CI) | Docker | `docker.groupondev.com/cloudcore/accounts-terrabase-ci:0.1.7` |
| Container (fallback) | Docker | `docker.groupondev.com/cloudcore/accounts-terraform-ci:0.13.2` |
| Orchestration | Jenkins | `Jenkinsfile` (declarative pipeline) |
| IaC tool | Terraform + Terragrunt | Modules under `terraform/modules/`, envs under `terraform/envs/` |
| CFN deploy | Python + AWS CLI | `CloudFormationBaseline/DeployScript/CloudformationDeploy.py` |
| Custodian deploy | Python + c7n | `CloudCustodian/RunCustodianPolicy.py` |
| Load balancer | None | Not applicable — no runtime service |
| CDN | None | Not applicable |

## Environments

| Environment | Purpose | Region | AWS Account ID |
|-------------|---------|--------|----------------|
| `conveyorsandbox` | Conveyor sandbox | — | 236248269315 |
| `dev-cloudcore` | CloudCore playground (no auto-apply) | — | 130530573605 |
| `edwsandbox` | EDW / Data sandbox | — | 575209962483 |
| `gensandbox` | General sandbox | — | 549734399709 |
| `recreate` | Recreate dev (auto-plan + auto-apply) | — | 778785420119 |
| `grpn-mta-dev` | MTA dev | — | 517722358313 |
| `grpn-netops-dev` | NetOps dev | — | 194232222349 |
| `grpn-logging-dev` | Logging dev | — | 847484009727 |
| `grpn-security-dev` | Security dev | — | 337730317610 |
| `grpn-cstools-dev` | CS Tools dev | — | 842687832885 |
| `stable-grouponinternal` | Internal stable (manual only) | — | 787676117833 |
| `grpn-edw-stable` | EDW stable (manual only) | — | 965578965255 |
| `staging` | Conveyor stable / staging (manual only) | — | 286052569778 |
| `grpn-backup-stable` | Backup stable (manual only) | — | 098571475921 |
| `stable-corp-it` | Corp IT stable (manual only) | — | 582203765208 |
| `grpn-dse-stable` | DSE stable (manual only) | — | 571665594762 |
| `grpn-logging-stable` | Logging stable (manual only) | — | 787096956869 |
| `grpn-mta-stable` | MTA stable (manual only) | — | 558426683473 |
| `grpn-netops-stable` | NetOps stable (manual only) | — | 814818517365 |
| `prod-grouponinternal` | Internal production (manual only) | — | — |
| `edwprod` | EDW production (manual only) | — | — |
| `grpn-billing` | Billing / Organizations management (manual only) | — | — |
| `grpn-mta-prod` | MTA production (manual only) | — | 281253778804 |

Primary AWS regions: `us-west-1` (primary prod), `us-west-2` (sandboxes, stable, prod services not needing SAC/SNC latency), `eu-west-1` (EMEA).

## CI/CD Pipeline

- **Tool**: Jenkins (Pipeline DSL)
- **Config**: `Jenkinsfile` (repo root)
- **Trigger**: GitHub webhook on push/PR merge to master; manual dispatch from Jenkins UI; scheduled (implicit via GitHub webhook)

### Pipeline Stages

1. **Update build name**: Sets display name based on trigger type (autocheck, autoApply, or selected environments + action)
2. **Detect Terraform Modules Change**: Checks `git diff` against master for changes under `terraform/modules/`
3. **CloudFormationBaseline format-check**: Runs `cfn-lint` against all `CloudFormationBaseline/**/*.yaml` via terrabase image
4. **tfvalidate**: Runs `terragrunt validate` on the `recreate` environment if Terraform module changes are detected and `validateAll` is enabled
5. **Terragrunt (parallel)**: For each selected environment in parallel — validates then runs `plan`, `apply`, or `unlock` depending on trigger and environment flags; uses `TERRAGRUNT_IAM_ROLE` for cross-account access
6. **Post (always)**: Sends Slack alert to `#cloudcoreteam-notify` if any `apply` stage failed

### Deployment IAM Role

All Terraform/Terragrunt operations assume the role `grpn-all-landingzone-tf-admin` in each target account. The role ARN is constructed as `arn:aws:iam::{account_id}:role/grpn-all-landingzone-tf-admin`.

## Scaling

> Not applicable — this service is a delivery pipeline, not a runtime service. Jenkins worker capacity scales with AWS EC2 labeled agents.

## Resource Requirements

> Not applicable — execution is handled by Jenkins EC2 worker nodes and Docker containers. No fixed resource requests are configured.
