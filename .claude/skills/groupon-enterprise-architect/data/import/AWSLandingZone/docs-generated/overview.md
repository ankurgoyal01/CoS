---
service: "aws-landing-zone"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Cloud Governance / Infrastructure"
platform: "AWS"
team: "Cloud Core"
status: active
tech_stack:
  language: "Python 3 / HCL"
  language_version: "Python 3.x / HCL2"
  framework: "Terraform / Terragrunt"
  framework_version: "Terraform (compliance test v0.4)"
  runtime: "Jenkins"
  runtime_version: "pipeline model"
  build_tool: "Make"
  package_manager: "pip / terragrunt"
---

# AWS Landing Zone Overview

## Purpose

AWS Landing Zone is Groupon's official framework for managing AWS account governance. It provisions and enforces baseline IAM roles and policies, VPC configurations, DNS, Service Control Policies (SCPs), and security guardrails across all Groupon AWS accounts. The Landing Zone ensures that all AWS resource creation — users, roles, VPCs, and policies — happens through a peer-reviewed, version-controlled process rather than direct manual changes.

## Scope

### In scope

- AWS account provisioning and lifecycle management via Terraform/Terragrunt
- IAM user, role, and policy management (all changes via PR)
- VPC and subnet configuration — Groupon's only approved VPCs
- DNS infrastructure via AWS Route 53
- Service Control Policy (SCP) and AWS Organizations management
- CloudFormation baseline stack deployment for account-type bootstrapping (Billing, Global, SAML, Security, SecurityBase accounts)
- Cloud Custodian governance policies: tagging enforcement, IAM key deactivation, S3 public access removal, security group remediation
- CloudTrail enablement across all accounts (multi-region trail `GRPNCloudTrail`, 180-day log retention)
- IAM Access Analyzer enablement per account
- Approved region enforcement (us-west-1, us-west-2, eu-west-1 primary; unapproved regions blocked)
- Default VPC deletion across all accounts
- Operational scripts for auditing users, roles, AMIs, and permission drift

### Out of scope

- Application-level infrastructure (handled by consumer services via terraform-modules)
- Kubernetes cluster provisioning (handled by separate platform teams)
- CI/CD pipelines for application services (handled per service)
- Monitoring and alerting for application services (handled by SRE)

## Domain Context

- **Business domain**: Cloud Governance / Infrastructure
- **Platform**: AWS (Continuum Platform umbrella)
- **Upstream consumers**: All Groupon engineering teams that deploy to AWS; consume VPCs, IAM roles, and DNS records created by this service
- **Downstream dependencies**: AWS Organizations, AWS IAM, AWS Route 53, AWS CloudFormation StackSets

## Stakeholders

| Role | Description |
|------|-------------|
| Cloud Core team | Owns and maintains the Landing Zone; reviews and merges all PRs |
| Cloud SRE team | Co-owns Terraform modules and networking; reviews VPC and region changes |
| Cloud Networking team | Reviews VPC modules and `region.hcl` changes |
| Cloud Security team | Reviews Organizations/SCP modules and security-scoped environments |
| Data & Analytics (D&D) team | Co-owns EDW environment configurations |
| All Groupon engineers | Consumers — open PRs to request new AWS resources |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Infrastructure language | HCL (Terraform/Terragrunt) | Terraform compliance v0.4 | `PROJECT.ini` |
| Scripting language | Python 3 | 3.x | `bin/audit-users/main.py`, `CloudCustodian/RunCustodianPolicy.py` |
| Build tool | Make | — | `Makefile` |
| CI/CD | Jenkins (Pipeline DSL) | — | `Jenkinsfile` |
| Container image | accounts-terraform-ci | 0.13.2 | `Jenkinsfile` |
| Container image | accounts-terrabase-ci | 0.1.7 | `Jenkinsfile` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| boto3 | 1.20.21 | aws-client | AWS SDK for Python — used in audit scripts and Custodian runner |
| botocore | 1.23.21 | aws-client | Core AWS API request layer |
| cloud-custodian (c7n) | (pip install c7n) | governance | Cloud policy engine for governance rule enforcement |
| loguru | 0.5.3 | logging | Structured logging in Python audit scripts |
| prettytable | 2.2.1 | reporting | Tabular report output for audit-users script |
| python-dateutil | 2.8.2 | utility | Date/time parsing for credential age calculations |
| jmespath | 0.10.0 | utility | JSON path queries on AWS API responses |
| urllib3 | 1.26.7 | http-client | HTTP transport layer for boto3 |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
