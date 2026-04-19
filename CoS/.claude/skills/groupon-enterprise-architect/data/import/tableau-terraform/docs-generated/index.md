---
service: "tableau-terraform"
title: "tableau-terraform Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [tableauTerraformRunner, tableauInstanceGroup, tableauLoadBalancer, tableauStorageBucket, tableauCertificates]
tech_stack:
  language: "HCL"
  framework: "Terraform / Terragrunt 0.30.7"
  runtime: "Terraform 0.15.5"
---

# Tableau Server Infrastructure Documentation

Infrastructure-as-Code repository that provisions and manages the full Tableau Server cluster on GCP across dev, stable, and prod environments using Terraform and Terragrunt.

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
| Language | HCL |
| Framework | Terragrunt 0.30.7 |
| Runtime | Terraform 0.15.5 |
| Build tool | Make + Terragrunt |
| Platform | GCP (Google Cloud Platform) |
| Domain | Analytics / DnD Tools |
| Team | analytics@groupon.com |
