---
service: "netops_awsinfra"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "terraform-remote-state"
    type: "s3"
    purpose: "Terraform state storage per account/region/module stack"
  - id: "tgw-data-yaml-files"
    type: "local-file"
    purpose: "Cross-module data sharing for TGW IDs, RAM ARNs, and VPC attachment IDs"
---

# Data Stores

## Overview

`netops_awsinfra` is a stateless infrastructure-as-code repository. It does not own any relational databases, caches, or application data stores. State is stored in two forms: remote Terraform state backends (S3, managed by the CloudCore Landing Zone tooling under project name `netops::netops_awsinfra`) and local YAML files written by Terraform's `local_file` resource to share data between modules within the same run.

## Stores

### Terraform Remote State (`terraform-remote-state`)

| Property | Value |
|----------|-------|
| Type | S3 (Terraform backend) |
| Architecture ref | External — managed by CloudCore Landing Zone tooling |
| Purpose | Stores Terraform state per account, region, and module stack; enables safe plan/apply operations |
| Ownership | shared (managed by CloudCore; consumed by this repo) |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Terraform state file per stack | Records all provisioned AWS resource IDs and their current configuration | resource type, resource ID, attributes |

#### Access Patterns

- **Read**: Terraform reads state before each plan to compute the diff against desired configuration
- **Write**: Terraform writes updated state after each successful apply
- **Indexes**: State files are keyed by project path under `netops::netops_awsinfra`

### TGW Data YAML Files (`tgw-data-yaml-files`)

| Property | Value |
|----------|-------|
| Type | Local file (YAML, written by `local_file` Terraform resource) |
| Architecture ref | `continuumTransitGatewayShareModule`, `continuumTransitGatewayAcceptModule` |
| Purpose | Shares TGW IDs, RAM ARNs, and VPC attachment IDs between modules without requiring direct Terraform data source lookups across account boundaries |
| Ownership | owned |
| Migrations path | `envs/<account>/<region>/<env>/tgw_accept/tgw_data.yml` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `tgw_data.yml` | Provides TGW connection details to the `tgw_accept` module in each workload account | `tgw_id`, `tgw_name`, `tgw_owner_account`, `tgw_ram_arn` |
| `<account>.yml` (attachment data) | Provides VPC attachment ID back to the NetOps tagging module | `tgw_attachment_id`, `tgw_attachment_vpc` |

#### Access Patterns

- **Read**: `tgw_accept` module reads `tgw_data.yml` via `yamldecode(file("./tgw_data.yml"))` in its `terragrunt.hcl` inputs
- **Write**: `tgw_share` module writes `tgw_data.yml` to the consumer account's module path; `tgw_accept` writes attachment data YAML to the NetOps account's tagging module path
- **Indexes**: Files are addressed by directory path convention: `envs/<consumer-account>/<region>/<env>/tgw_accept/tgw_data.yml`

## Caches

> No evidence found in codebase. No caching layer is used by this infrastructure repository.

## Data Flows

Terraform apply in `tgw_share` writes `tgw_data.yml` to the consumer account directory. A subsequent apply of `tgw_accept` in that consumer account reads this file as input. Similarly, `tgw_accept` writes attachment metadata YAML back to the NetOps account's `tgw_vpc_attachments_tag` module directory. This file-based handoff replaces cross-account Terraform data source queries and allows each module to be applied independently.
