---
service: "netops_awsinfra"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "terraform-terragrunt"
environments: ["grpn-netops (prod)", "grpn-netops-stable", "grpn-netops-dev", "28+ workload accounts"]
---

# Deployment

## Overview

`netops_awsinfra` is not a containerized application. It is an infrastructure-as-code repository that manages AWS network resources across 28+ AWS accounts and 7 AWS regions using Terraform and Terragrunt. Deployment means running Terragrunt plan/apply operations from a developer workstation or Jenkins CI. Each module is applied independently per account/region/environment path. There is no container image, no Kubernetes manifest, and no runtime process to scale.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| IaC engine | Terraform + Terragrunt 0.38.6 | All AWS resources managed as HCL modules under `modules/` |
| Execution | Developer workstation / Jenkins | `make <path>/plan` and `make <path>/APPLY` via Makefile wrappers |
| Auth | aws-okta SAML + IAM roles | Profile `grpn-all-netops-admin` assumed per account |
| Remote state | S3 (CloudCore managed) | Project identifier `netops::netops_awsinfra` |
| Module structure | `envs/<account>/<region>/<env>/<module>/terragrunt.hcl` | Each stack is independently plan/apply-able |

## Environments

| Environment | Purpose | Region | Account ID |
|-------------|---------|--------|-----------|
| grpn-netops (prod) | Primary NetOps production account — owns TGWs, DCGs, DX connections | us-west-2, us-west-1, eu-west-1, eu-west-2, us-east-1, us-east-2, ap-southeast-1 | `455278749095` |
| grpn-netops-stable | Stable/pre-prod NetOps account | us-west-2 | `814818517365` |
| grpn-netops-dev | Development NetOps account | us-west-2 | `194232222349` |
| grpn-cloudcore-dev | CloudCore development — receives TGW share | us-west-2, eu-west-1 | `130530573605` |
| grpn-prod | Main Groupon production workload account | us-west-2, eu-west-1 | `497256801702` |
| grpn-stable | Main Groupon stable workload account | us-west-2, eu-west-1 | `286052569778` |
| grpn-edw-prod | Enterprise data warehouse production | us-west-2, eu-west-1 | `458721635755` |
| grpn-logging-prod | Logging infrastructure production | us-west-2, eu-west-1 | `671796276641` |
| grpn-teradata-prod | Teradata connectivity account | us-west-2 | `851725417994` |
| vouchercloud-prod | VoucherCloud production (third party) | eu-west-1 | `000536203183` |
| giftcloud-prod | GiftCloud production (third party) | eu-west-2 | `437442137890` |
| teradata-vantage | Teradata Vantage managed account (third party) | us-west-2 | `018373563450` |
| 16+ additional accounts | Various dev/stable/prod workload accounts | multiple | See `envs/customers.yml` |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile` (minimal — currently only runs `echo 'Hello World'`)
- **Trigger**: Manual (engineers run plan/apply directly via Make targets from workstations)

### Pipeline Stages

1. **Validate**: Run `make <path>/validate` — executes `terragrunt run-all validate` to check HCL syntax and provider configuration
2. **Plan**: Run `make <path>/plan` — generates Terraform execution plan showing resource changes
3. **Review**: Engineer reviews plan output; applies are manual and require capitalised Make target
4. **Apply**: Run `make <path>/APPLY` — executes `terragrunt run-all apply` to provision resources in the target account/region

### Module Deployment Order (dependency-aware)

For a new account onboarding, modules are applied in this sequence:

1. `grpn-netops/global/dcg/<env>` — creates Direct Connect Gateway
2. `grpn-netops/<region>/tgw/<env>` — creates Transit Gateway and RAM share
3. `grpn-netops/<region>/<account>/prod/tgw_share` — shares TGW to workload account (writes `tgw_data.yml`)
4. `<account>/<region>/prod/tgw_accept` — accepts RAM share and creates VPC attachment in workload account
5. `grpn-netops/<region>/tgw_dcg_associations/<env>` — associates DCG with TGW
6. `grpn-netops/<region>/tgw_crossregion_peering_create/<env>` — creates cross-region peering
7. `grpn-netops/<region>/tgw_crossregion_peering_accept/<env>` — accepts cross-region peering on remote region side
8. `grpn-netops/<region>/tgw_crossregion_routes/<env>` — configures managed prefix lists and routes

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Accounts | Manual onboarding — add new account directory under `envs/` | `envs/customers.yml` registry |
| Regions | Manual — add region directory and `region.hcl` under account | Account `account.hcl` `tgws` map |
| TGW capacity | AWS-managed (up to 5,000 attachments per TGW) | Not configurable via this repo |

## Resource Requirements

> Not applicable — this is an IaC orchestration tool, not a running service. No compute resources are allocated to the Terragrunt/Terraform execution environment itself beyond developer workstations and Jenkins agent nodes.
