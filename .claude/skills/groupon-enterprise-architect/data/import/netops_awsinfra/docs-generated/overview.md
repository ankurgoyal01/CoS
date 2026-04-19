---
service: "netops_awsinfra"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Network Operations"
platform: "Continuum"
team: "Network Operations"
status: active
tech_stack:
  language: "HCL"
  language_version: ""
  framework: "Terragrunt"
  framework_version: "0.38.6"
  runtime: "Terraform AWS Provider"
  runtime_version: ""
  build_tool: "Make"
  package_manager: "Terragrunt"
---

# AWS Network (netops_awsinfra) Overview

## Purpose

`netops_awsinfra` is the Groupon Network Operations Terraform/Terragrunt repository that provisions and manages the AWS production network. It establishes and maintains on-premise-to-AWS connectivity via AWS Direct Connect, manages Transit Gateway routing hubs across multiple AWS regions and 28+ AWS accounts, provisions Client VPN endpoints for secure remote access, and deploys DNS infrastructure. The repository serves as the single source of truth for all AWS network resource definitions across Groupon's multi-account, multi-region AWS footprint.

## Scope

### In scope

- Provisioning AWS Direct Connect connections (`aws_dx_connection`) to colocation facilities (Equinix ECX)
- Creating and managing Direct Connect Gateways (`aws_dx_gateway`) for on-premise BGP peering
- Deploying Transit Gateways (`aws_ec2_transit_gateway`) per region with AWS Network Manager registration
- Sharing Transit Gateways to workload accounts via AWS RAM (`aws_ram_principal_association`)
- Accepting TGW shares and creating VPC attachments in each workload account (`aws_ec2_transit_gateway_vpc_attachment`)
- Managing cross-region TGW peering attachments (create and accept sides)
- Defining managed prefix lists and route table entries for network segmentation
- Associating Direct Connect Gateways with Transit Gateways (`aws_dx_gateway_association`)
- Creating Direct Connect virtual interfaces: private (per-account), transit (for TGW), and hosted variants
- Provisioning Client VPN endpoints (`aws_client_vpn_endpoint`) for remote access
- Deploying external DNS infrastructure via Terragrunt stacks
- Deploying legacy DNS infrastructure (EC2 instances, security groups, ALB, Route53 records)
- Publishing CloudWatch dashboards for TGW and Direct Connect observability
- Tagging TGW VPC attachments with operational metadata

### Out of scope

- Application-layer load balancers and service discovery (owned by application teams)
- VPC creation and subnet allocation (owned by Landing Zone / CloudCore)
- Firewall policy management beyond AWS-native routing
- GCP network connectivity
- Teradata managed service network (Teradata account is managed by a third party; NetOps only provides connectivity)

## Domain Context

- **Business domain**: Network Operations — AWS Network Infrastructure
- **Platform**: Continuum
- **Upstream consumers**: All 28+ Groupon AWS accounts that require network connectivity; engineers requiring VPN access; datacenter network devices using BGP over Direct Connect
- **Downstream dependencies**: AWS APIs (EC2, Direct Connect, RAM, Route53, CloudWatch, Network Manager); on-premise datacenter routers (BGP/Direct Connect)

## Stakeholders

| Role | Description |
|------|-------------|
| Network Operations Team | Owners and maintainers; manage all changes via Terragrunt plan/apply workflows |
| AWS Account Teams | Consumers of TGW shares; run `tgw_accept` module in their accounts |
| SRE / On-Call | Respond to PagerDuty alerts for Direct Connect and Transit Gateway health |
| Security / Compliance | Depend on network segmentation enforced by managed prefix lists and route tables |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| IaC language | HCL (Terraform) | — | `modules/**/*.tf` |
| Orchestration | Terragrunt | 0.38.6 | `envs/Makefile` (`TERRAGRUNT_VERSION := 0.38.6`) |
| Build tool | GNU Make | — | `envs/Makefile`, `envs/.terraform-tooling/Makefile` |
| Auth tooling | aws-okta | — | `envs/.terraform-tooling/bin/aws-okta-add`, `gen-aws-config` |
| CI/CD | Jenkins | — | `Jenkinsfile` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Terraform AWS Provider | — | cloud-provider | Provisions all `aws_*` resources (EC2, DX, RAM, Route53, CloudWatch, Network Manager) |
| Terraform Local Provider | — | utility | Writes `tgw_data.yml` and attachment metadata files to disk for cross-module data sharing |
| Terragrunt | 0.38.6 | orchestration | Wraps Terraform with DRY configuration, dependency graphs, and multi-account execution |
| GNU Make | — | build | Wraps Terragrunt with account profile switching and action capitalization conventions |
| aws-okta | — | auth | Generates `~/.aws/netops-netops-awsinfra.config` with per-account IAM role profiles |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
