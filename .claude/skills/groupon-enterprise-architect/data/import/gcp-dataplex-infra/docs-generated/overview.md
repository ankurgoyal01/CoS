---
service: "gcp-dataplex-infra"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Data / Analytics Infrastructure"
platform: "GCP"
team: "dnd-tools (analytics@groupon.com)"
status: active
tech_stack:
  language: "HCL"
  language_version: "Terraform 0.15.5"
  framework: "Terragrunt"
  framework_version: "0.30.7"
  runtime: "Terraform CLI"
  runtime_version: "0.15.5"
  build_tool: "Make"
  package_manager: "Terragrunt (module resolution)"
---

# GCP Dataplex Infrastructure Overview

## Purpose

`gcp-dataplex-infra` is an infrastructure-as-code repository that provisions and manages Google Cloud Dataplex Data Catalog resources at Groupon. It defines custom entry types and entry groups for Teradata metadata (tables, databases, views, and columns) in GCP Dataplex, and creates a GCS bucket used to store Dataplex metadata artifacts. The repository enables data governance and discoverability for Teradata data assets by registering them in a centralised GCP Data Catalog.

## Scope

### In scope

- Provisioning `google_dataplex_entry_type` resources for Teradata data assets: `teradata-table`, `teradata-database`, `teradata-view`, `teradata-column`
- Provisioning the `teradata-dataplex` `google_dataplex_entry_group` for grouping Teradata metadata entries
- Provisioning a GCS bucket (`grpn-dataplex-catalog-stable-storage`) for storing Dataplex metadata
- Terragrunt-based environment configuration for the `stable` environment in `us-central1`
- Terraform remote state management in a GCS backend
- Service account impersonation for secure Terraform deployments

### Out of scope

- Populating the Dataplex Data Catalog with actual data asset entries (done by external ingestion tooling)
- Querying or searching the Data Catalog (consumer concern)
- BigQuery dataset or table provisioning
- Teradata database administration
- Data pipeline orchestration

## Domain Context

- **Business domain**: Data / Analytics Infrastructure
- **Platform**: GCP (Google Cloud Platform)
- **Upstream consumers**: Data ingestion tooling and analytics pipelines that register Teradata metadata into Dataplex
- **Downstream dependencies**: Google Cloud Dataplex API, Google Cloud Storage API, GCP IAM / service accounts

## Stakeholders

| Role | Description |
|------|-------------|
| Owner | `analytics@groupon.com` (dnd-tools team) — accountable for data catalog infrastructure |
| Infrastructure Engineer | Manages Terraform module changes and environment deployments |
| Data Engineer | Consumes entry types and entry groups to register Teradata assets in the catalog |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | HCL (Terraform) | 0.15.5 | `envs/stable/.terraform-version` |
| Framework | Terragrunt | 0.30.7 | `envs/Makefile` (`TERRAGRUNT_VERSION := 0.30.7`) |
| Runtime | Terraform CLI | 0.15.5 | `envs/stable/.terraform-version` |
| Build tool | Make | — | `envs/Makefile`, `envs/.terraform-tooling/Makefile` |
| Package manager | Terragrunt (module resolution via `module-ref` helper) | — | `envs/.terraform-tooling/bin/module-ref` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| hashicorp/google (Terraform provider) | — | cloud-provider | Provisions GCP Dataplex, GCS, and IAM resources |
| hashicorp/google-beta (Terraform provider) | — | cloud-provider | Access to beta GCP features where needed |
| Terragrunt | 0.30.7 | infrastructure | DRY wrapper around Terraform for multi-environment orchestration |
| CloudCore gcp-terraform-base | — | tooling | Groupon-internal Make/Terragrunt tooling scaffold |
| terraform-compliance | — | testing | Compliance policy checks on Terraform plans |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
