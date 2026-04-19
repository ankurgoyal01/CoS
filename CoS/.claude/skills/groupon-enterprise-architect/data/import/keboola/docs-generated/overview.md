---
service: "keboola"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Data Integration and Analytics"
platform: "Continuum"
team: "gdoop-dev@groupon.com"
status: active
tech_stack:
  language: "Not applicable"
  language_version: "Not applicable"
  framework: "Not applicable"
  framework_version: "Not applicable"
  runtime: "Keboola SaaS"
  runtime_version: "Not applicable"
  build_tool: "Not applicable"
  package_manager: "Not applicable"
---

# Keboola Connection Overview

## Purpose

Keboola Connection is a fully managed, single-tenant cloud platform deployed on Groupon's GCP environment that interconnects diverse data systems. It extracts data from source systems (such as Salesforce CRM), applies transformation and augmentation steps, and writes the resulting datasets into destination systems (such as BigQuery) for analytics consumption. Keboola is owned and operated by the Keboola team; Groupon administers configurations, connectors, and orchestration pipelines within the platform.

## Scope

### In scope

- Scheduling and triggering data extraction runs from configured source connectors
- Applying transformation and data augmentation logic to extracted datasets
- Loading transformed data into destination analytics warehouses (BigQuery)
- Sending operational run-status notifications and escalation alerts (via Google Chat)
- Supporting multi-step pipeline orchestration for end-to-end ETL workflows

### Out of scope

- Raw data storage ownership (data lands in BigQuery, which is a separate system)
- CRM data management (owned by Salesforce)
- Analytics dashboarding and reporting (owned by downstream consumers of BigQuery)
- Platform infrastructure provisioning (managed entirely by the Keboola vendor team)

## Domain Context

- **Business domain**: Data Integration and Analytics
- **Platform**: Continuum
- **Upstream consumers**: Groupon analytics and data engineering teams who rely on transformed datasets in BigQuery
- **Downstream dependencies**: Salesforce (source), BigQuery (destination), Google Chat (notifications)

## Stakeholders

| Role | Description |
|------|-------------|
| Service Owner | rpadala — primary Groupon point of contact for the Keboola integration |
| Dev Team | gdoop-dev@groupon.com — Data and engineering team managing pipeline configurations |
| Keboola Vendor | Keboola team — owns platform infrastructure, upgrades, and SLA fulfillment |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Runtime | Keboola SaaS | Not applicable | `.service.yml` — "Keboola SaaS" technology |
| Deployment | GCP (managed by Keboola) | Not applicable | `OWNERS_MANUAL.md` — "Single-Tenant Infrastructure: Deployed on our GCP cloud environment" |

### Key Libraries

> No evidence found in codebase. Keboola Connection is a fully managed SaaS platform; no application code, package manifests, or build configuration files are present in this repository. The repository contains only architecture DSL and operational documentation.
