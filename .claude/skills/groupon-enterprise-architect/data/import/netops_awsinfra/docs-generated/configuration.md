---
service: "netops_awsinfra"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["hcl-files", "yaml-files", "env-vars"]
---

# Configuration

## Overview

`netops_awsinfra` uses a layered HCL configuration hierarchy managed by Terragrunt. Configuration is split across three levels: global (`envs/global.hcl`), account (`envs/<account>/account.hcl`), and region (`envs/<account>/<region>/region.hcl`). Module-specific inputs are defined in `terragrunt.hcl` files within each stack directory. Cross-module data is passed via YAML files (`tgw_data.yml`, attachment YAML files) written by Terraform's `local_file` resource. AWS credentials are managed via `aws-okta` SAML federation with per-account IAM role profiles stored in `~/.aws/netops-netops-awsinfra.config`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `AWS_PROFILE` | Selects the aws-okta profile for the target account | yes | derived from account path | Make / `gen-aws-config` script |
| `AWS_ROLE` | Overrides the IAM role used for profile generation | no | `grpn-all-netops-admin` (from `global.hcl`) | env |
| `TERRAGRUNT_VERSION` | Pins the Terragrunt CLI version | yes | `0.38.6` (from `envs/Makefile`) | Makefile |
| `PROJECTNAME` | Terraform remote state project identifier | yes | `netops::netops_awsinfra` | Makefile |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

> No evidence found in codebase. No feature flags are used; infrastructure changes are gated by plan/apply workflow and human review.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `envs/global.hcl` | HCL | Global defaults: `aws_default_role`, `aws_region`, `lz_vpc_name`, `global_network_name`, per-region CIDR prefix lists (`global_prefixes`), common tags |
| `envs/<account>/account.hcl` | HCL | Per-account settings: `aws_account_id`, `env_short_name`, `env_stage`, DX connection definitions (`dxcons`), DX gateway definitions (`dcgs`), TGW definitions (`tgws`), BGP ASN, route table routes |
| `envs/<account>/<region>/region.hcl` | HCL | Per-region overrides (region-specific settings) |
| `envs/<account>/<region>/<env>/tgw_accept/tgw_data.yml` | YAML | TGW connection data written by `tgw_share` module: `tgw_id`, `tgw_name`, `tgw_owner_account`, `tgw_ram_arn` |
| `envs/customers.yml` | YAML | Registry of all 36+ customer/workload accounts: `owner_id`, `dc_vlan` assignments (VLAN IDs), `third_party` flag |
| `envs/<account>/<region>/<env>/<module>/terragrunt.hcl` | HCL | Per-stack Terragrunt configuration: module source path and input variable values |
| `envs/.terraform-tooling/Makefiles/*.mk` | Makefile | Shared Make targets for plan, apply, destroy, validate, init, console operations |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| AWS SAML credentials (via `aws-okta`) | Authenticates to AWS accounts by assuming IAM role `grpn-all-netops-admin` via Okta SAML (`home/amazon_aws/0oa1drin1zvdpxBdo1d8/272`) | aws-okta (SAML IdP) |
| Terraform remote state backend credentials | Accesses S3 bucket for Terraform state | AWS IAM (assumed role) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Configuration varies per account using the `account.hcl` file. Key differences:

- **grpn-netops (prod account `455278749095`)**: Full DX connection definitions (`dxcons`) for `us-east-2` via Equinix ECX, two DCGs (`DCG-NETOPS-PROD` ASN `65312`, `DCG-NETOPS-TERADATA` ASN `65332`), two TGW sets (`grpn-netops-TGW` for production, `grpn-netops-teradata-TGW` for Teradata), BGP ASN `12269`, route table routes including `10.0.0.0/8`, Teradata CIDRs (`141.206.0.0/23`, `141.206.4.0/22`), and GCP DNS forwarders (`35.199.192.0/19`)
- **grpn-cloudcore-dev (account `130530573605`)**: Single DCG (`DCG-DEV-CLOUDCORE` ASN `65314`), route table route `10.0.0.0/8` only; no DX connections defined
- **grpn-conveyor-sandbox (account `236248269315`)**: TGW accept only across `eu-west-1`, `us-west-1`, `us-west-2`
- **Third-party accounts** (e.g., `vouchercloud-prod`, `giftcloud-prod`, `teradata-vantage`): Marked `third_party: true` in `customers.yml`; `tgw_data.yml` is not written for these accounts (conditional on `third_party` flag in `tgw_share` module)
- **Global CIDR prefix ranges** (`global_prefixes` in `global.hcl`) define the aggregate IP space per region used for managed prefix lists, covering all Groupon AWS VPCs, corporate IT networks, Teradata ranges, and VoucherCloud/GiftCloud CIDRs
