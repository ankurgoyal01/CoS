---
service: "gcp-dataplex-infra"
title: "gcp-dataplex-infra Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["dataplexDataCatalogConfig", "dataplexMetadataBucket"]
tech_stack:
  language: "HCL (Terraform)"
  framework: "Terragrunt 0.30.7"
  runtime: "Terraform 0.15.5"
---

# GCP Dataplex Infrastructure Documentation

Terraform/Terragrunt infrastructure-as-code repository that provisions and manages Google Cloud Dataplex Data Catalog resources — including custom entry types and entry groups for Teradata metadata — plus supporting GCS storage buckets in the `prj-grp-data-cat-stable-0b72` GCP project.

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
| Language | HCL (Terraform) |
| Framework | Terragrunt 0.30.7 |
| Runtime | Terraform 0.15.5 |
| Build tool | Make + Terragrunt |
| Platform | GCP |
| Domain | Data / Analytics Infrastructure |
| Team | analytics@groupon.com (dnd-tools) |
