---
service: "gcp-aiaas-cloud-functions"
title: "gcp-aiaas-cloud-functions Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumAiaasAidgFunction"
    - "continuumAiaasDealScoreFunction"
    - "continuumAiaasGoogleScraperFunction"
    - "continuumAiaasInferPdsApiService"
    - "continuumAiaasMadInferPdsApiService"
    - "continuumAiaasInferPdsV3Function"
    - "continuumAiaasPdsPriorityFunction"
    - "continuumAiaasSocialLinkScraperFunction"
    - "continuumAiaasPostgres"
    - "continuumAiaasLangSmith"
    - "continuumAiaasTinyUrlApi"
tech_stack:
  language: "Python 3.11"
  framework: "Flask 3.x / FastAPI 0.104+"
  runtime: "GCP Cloud Functions (gen2) / GCP Cloud Run"
---

# GCP AIaaS Cloud Functions Documentation

A collection of AI-as-a-Service Python functions and Cloud Run services that power Groupon's merchant intelligence platform — providing deal generation, deal scoring, merchant potential prediction, PDS (Product and Deal Service) taxonomy inference, and social link enrichment capabilities.

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
| Language | Python 3.11 |
| Framework | Flask 3.x (Cloud Functions), FastAPI 0.104+ (Cloud Run) |
| Runtime | GCP Cloud Functions (gen2) / GCP Cloud Run |
| Build tool | pip / Docker |
| Platform | GCP (Continuum AIaaS) |
| Domain | Merchant Intelligence / AI-assisted Deal Operations |
| Team | AIaaS / Merchant Advisor |
