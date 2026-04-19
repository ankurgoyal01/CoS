---
service: "aws-backups"
title: "aws-backups Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumBackupPolicies"
    - "continuumGdsBackupPolicies"
    - "continuumDeadboltBackupPolicies"
    - "continuumBackupServiceRole"
    - "continuumBackupVault"
    - "continuumGdsBackupVault"
    - "continuumDeadboltBackupVault"
tech_stack:
  language: "HCL (HashiCorp Configuration Language)"
  framework: "Terraform / Terragrunt"
  runtime: "AWS Provider"
---

# AWS Backups Documentation

Terraform-managed infrastructure that provisions and governs AWS Backup vaults, organization-level backup policies, and the IAM service role needed to protect GDS and Deadbolt team data stores across Groupon's multi-account AWS Landing Zone.

## Contents

| Document | Description |
|----------|-------------|
| [Overview](overview.md) | Service identity, purpose, domain context, tech stack |
| [Architecture Context](architecture-context.md) | Containers, components, C4 references |
| [API Surface](api-surface.md) | Endpoints, contracts, protocols |
| [Events](events.md) | Async messages published and consumed |
| [Data Stores](data-stores.md) | Databases, caches, storage |
| [Integrations](integrations.md) | External and internal dependencies |
| [Configuration](configuration.md) | Environment, flags, secrets |
| [Flows](flows/index.md) | Process and flow documentation |
| [Deployment](deployment.md) | Infrastructure and environments |
| [Runbook](runbook.md) | Operations, monitoring, troubleshooting |

## Quick Facts

| Property | Value |
|----------|-------|
| Language | HCL (HashiCorp Configuration Language) |
| Framework | Terraform / Terragrunt |
| Runtime | AWS Provider (hashicorp/aws) |
| Build tool | Terragrunt + GNU Make |
| Platform | Continuum (AWS Landing Zone) |
| Domain | Infrastructure / Cloud Operations |
| Team | Infrastructure Engineering (infrastructure-engineering@groupon.com) |
