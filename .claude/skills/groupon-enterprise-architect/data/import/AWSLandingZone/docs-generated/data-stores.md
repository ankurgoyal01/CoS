---
service: "aws-landing-zone"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "grpn-stackset-admin"
    type: "s3"
    purpose: "CloudFormation template staging for StackSet deployments"
  - id: "{account_id}-grpn-cloudtrail-logs"
    type: "s3"
    purpose: "CloudTrail audit log archive per account"
  - id: "GRPNCloudTrailLogs"
    type: "cloudwatch-logs"
    purpose: "Real-time CloudTrail log streaming for alerting and Custodian triggers"
  - id: "terraform-state"
    type: "s3"
    purpose: "Terraform remote state storage (managed by terragrunt per environment)"
---

# Data Stores

## Overview

AWS Landing Zone does not own a relational database or cache. Its persistent state lives in AWS-managed stores: S3 buckets for Terraform remote state and CloudFormation template staging, CloudWatch Log Groups for CloudTrail audit logs, and the AWS Organizations/IAM control plane itself as the authoritative record of account configuration.

## Stores

### CloudFormation Template Staging Bucket (`grpn-stackset-admin`)

| Property | Value |
|----------|-------|
| Type | S3 |
| Architecture ref | `continuumLandingZoneCloudFormationBaseline` |
| Purpose | Staging bucket for packaged CloudFormation templates before StackSet deployment |
| Ownership | owned |
| Migrations path | Not applicable |

#### Access Patterns

- **Write**: `CloudformationDeploy.py` runs `aws cloudformation package` which uploads packaged templates to `grpn-stackset-admin` before deploying StackSets
- **Read**: AWS CloudFormation StackSet service reads templates from this bucket during stack operations

### CloudTrail Log Archive (`{account_id}-grpn-cloudtrail-logs`)

| Property | Value |
|----------|-------|
| Type | S3 |
| Architecture ref | `continuumLandingZoneCloudFormationBaseline` |
| Purpose | Long-term immutable audit log archive for each AWS account (enabled via `EnableTrail.yaml`) |
| Ownership | owned (one bucket per account) |
| Migrations path | Not applicable |

#### Access Patterns

- **Write**: CloudTrail service (`cloudtrail.amazonaws.com`) writes log files via the `AWSCloudTrailWrite` bucket policy statement
- **Read**: Security and compliance tooling reads log files for audit purposes

### CloudTrail Log Group (`GRPNCloudTrailLogs`)

| Property | Value |
|----------|-------|
| Type | CloudWatch Logs |
| Architecture ref | `continuumLandingZoneCloudFormationBaseline` |
| Purpose | Real-time CloudTrail event streaming for monitoring, alerting, and Cloud Custodian Lambda triggers |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| CloudTrail log stream | Per-trail event stream | `eventName`, `eventSource`, `userIdentity.arn`, `errorCode`, `errorMessage` |

#### Access Patterns

- **Write**: IAM role `grpn-all-cloudtrail-log` (created by `EnableTrail.yaml`) writes log events via `logs:CreateLogStream` and `logs:PutLogEvents`
- **Read**: Cloud Custodian Lambda functions and CloudWatch alarms query log events; retention is 180 days

### Terraform Remote State

| Property | Value |
|----------|-------|
| Type | S3 (managed by Terragrunt per environment) |
| Architecture ref | `continuumLandingZoneTerraform` |
| Purpose | Stores Terraform state files for all environment and module deployments |
| Ownership | owned |
| Migrations path | Not applicable — state managed automatically by Terragrunt |

#### Access Patterns

- **Read/Write**: Terragrunt reads and writes state during `plan` and `apply` operations, assuming role `grpn-all-landingzone-tf-admin` in each target account

## Caches

> No evidence found in codebase. No caches are used by this service.

## Data Flows

CloudFormation templates flow from the repository through `cloudFormationDeployScript` to `grpn-stackset-admin` S3, then are consumed by the AWS CloudFormation StackSets service to bootstrap target accounts. CloudTrail events flow from AWS API calls into `{account_id}-grpn-cloudtrail-logs` S3 (archive) and `GRPNCloudTrailLogs` CloudWatch log group (real-time), where they may trigger Cloud Custodian Lambda remediations.
