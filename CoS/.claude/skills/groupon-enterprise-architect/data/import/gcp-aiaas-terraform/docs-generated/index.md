---
service: "gcp-aiaas-terraform"
title: "gcp-aiaas-terraform Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumApiGateway"
    - "continuumCloudRunService"
    - "continuumCloudFunctionsGen2"
    - "continuumCloudScheduler"
    - "continuumCloudTasks"
    - "continuumComposer"
    - "continuumBigQuery"
    - "continuumStorageBuckets"
    - "continuumSecretManager"
    - "continuumVertexAi"
tech_stack:
  language: "HCL (Terraform)"
  framework: "Terragrunt 0.30.7"
  runtime: "GCP"
---

# GCP AIaaS Terraform Documentation

Infrastructure-as-Code platform that provisions and manages all GCP resources for Groupon's AI-as-a-Service (AIaaS) platform, enabling Data Science teams to deploy ML models, data pipelines, and inference APIs.

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
| Runtime | GCP (us-central1) |
| Build tool | Make + Terragrunt |
| Platform | Continuum |
| Domain | Data Science / Machine Learning |
| Team | DSSI (Deal Structure and Supply Intelligence) — cs_ds@groupon.com |
