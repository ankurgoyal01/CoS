---
service: "aws-service-catalog"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["cloudformation-parameters", "parameters-json", "hcl-files"]
---

# Configuration

## Overview

AWSServiceCatalog is configured entirely through CloudFormation parameter files (`parameters.json`) and Terragrunt HCL configuration files. There are no runtime environment variables — the service is a collection of IaC templates deployed via the AWS CLI with pre-loaded parameter files per stage and region. Configuration is stored in the repository and differs per portfolio stage (`dev`, `stable`, `prod`) and per region (`us-west-2`, `us-west-1`, `eu-west-1`).

## Environment Variables

> No evidence found in codebase.

This service does not use runtime environment variables. All configuration is supplied as CloudFormation parameters or Terragrunt HCL values at deployment time.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `OnlyInDev` | CloudFormation condition — enables a product version only in the `dev` portfolio stage | `false` unless `PortfolioStage == dev` | per-stage |
| `OnlyInStable` | CloudFormation condition — enables a product version only in the `stable` portfolio stage | `false` unless `PortfolioStage == stable` | per-stage |
| `OnlyInProd` | CloudFormation condition — enables a product version only in the `prod` portfolio stage | `false` unless `PortfolioStage == prod` | per-stage |
| `PromoteToStable` | CloudFormation condition — enables a product version in `dev` and `stable` stages | `true` when `PortfolioStage` is `dev` or `stable` | per-stage |
| `PromoteToAll` | CloudFormation condition — enables a product version across all stages | `true` when `PortfolioStage` is `dev`, `stable`, or `prod` | per-stage |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `portfolios/ConveyorCloud/dev/parameters.json` | JSON | CloudFormation parameters for ConveyorCloud `dev` portfolio stack (`PortfolioStage=dev`, `ProductTemplateS3BucketName=grpn-prod-cloudcore-service-catalog`) |
| `portfolios/ConveyorCloud/stable/parameters.json` | JSON | CloudFormation parameters for ConveyorCloud `stable` portfolio stack |
| `portfolios/ConveyorCloud/prod/parameters.json` | JSON | CloudFormation parameters for ConveyorCloud `prod` portfolio stack |
| `portfolios/ConveyorCloud/share-accept/dev/us-west-2/parameters.json` | JSON | Share-accept parameters for ConveyorCloud `dev` portfolio in `us-west-2` |
| `portfolios/ConveyorCloud/share-accept/stable/us-west-2/parameters.json` | JSON | Share-accept parameters for ConveyorCloud `stable` portfolio in `us-west-2` |
| `portfolios/ConveyorCloud/share-accept/stable/us-west-1/parameters.json` | JSON | Share-accept parameters for ConveyorCloud `stable` portfolio in `us-west-1` |
| `portfolios/ConveyorCloud/share-accept/stable/eu-west-1/parameters.json` | JSON | Share-accept parameters for ConveyorCloud `stable` portfolio in `eu-west-1` |
| `portfolios/ConveyorCloud/share-accept/prod/us-west-2/parameters.json` | JSON | Share-accept parameters for ConveyorCloud `prod` portfolio in `us-west-2` |
| `portfolios/ConveyorCloud/share-accept/prod/us-west-1/parameters.json` | JSON | Share-accept parameters for ConveyorCloud `prod` portfolio in `us-west-1` |
| `portfolios/ConveyorCloud/share-accept/prod/eu-west-1/parameters.json` | JSON | Share-accept parameters for ConveyorCloud `prod` portfolio in `eu-west-1` |
| `portfolios/Community/dev/parameters.json` | JSON | CloudFormation parameters for Community `dev` portfolio stack |
| `poc/terraform/envs/global.hcl` | HCL | Global Terragrunt configuration for POC Terraform environments |
| `poc/terraform/envs/grpn-gensandbox1/account.hcl` | HCL | Account-level Terragrunt configuration for `grpn-gensandbox1` |
| `poc/terraform/envs/grpn-gensandbox1/us-west-2/region.hcl` | HCL | Region-level Terragrunt configuration for `grpn-gensandbox1` / `us-west-2` |
| `cfn-guard/rules/guard_rules.guard` | cfn-guard DSL | Policy-as-code compliance rules for CFN product templates (OpenSearch encryption, S3 public access, Cassandra tags) |

## Secrets

> No evidence found in codebase.

No secrets are stored in this repository. IAM authentication uses `aws-okta` profiles configured locally by operators. The Terraform orchestration reads secret values from AWS Secrets Manager at runtime but no secret names are defined in the files visible in this repository.

## Per-Environment Overrides

| Environment | Stack Name Pattern | Regions | Notes |
|-------------|--------------------|---------|-------|
| `dev` | `ServiceCatalog-ConveyorCloud-dev` | `us-west-2` only | Includes pre-release product versions under `OnlyInDev` condition |
| `stable` | `ServiceCatalog-ConveyorCloud-stable` | `eu-west-1`, `us-west-1`, `us-west-2` | Includes versions at `PromoteToStable` or `PromoteToAll` conditions |
| `prod` | `ServiceCatalog-ConveyorCloud-prod` | `eu-west-1`, `us-west-1`, `us-west-2` | Includes only versions at `PromoteToAll` condition |

All three portfolio stages are deployed from the same `portfolios/ConveyorCloud/main.yaml` template but with different `parameters.json` files and region targets. Product versions are gated per stage using CloudFormation conditions.
