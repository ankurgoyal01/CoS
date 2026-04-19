---
service: "gcp-dataplex-infra"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "dataplexMetadataBucket"
    type: "gcs"
    purpose: "Stores Dataplex metadata artifacts for the stable environment"
  - id: "dataplexDataCatalogConfig"
    type: "google-dataplex"
    purpose: "Manages entry types and entry group configuration for Teradata metadata in GCP Dataplex Data Catalog"
---

# Data Stores

## Overview

`gcp-dataplex-infra` provisions two GCP-managed data stores: a Google Cloud Storage bucket for storing Dataplex metadata files, and GCP Dataplex Data Catalog configuration resources (entry types and entry group) that serve as the metadata registry for Teradata assets. Both are owned by this infrastructure repository in the `stable` environment.

## Stores

### Dataplex Metadata Bucket (`dataplexMetadataBucket`)

| Property | Value |
|----------|-------|
| Type | Google Cloud Storage (GCS) |
| Architecture ref | `dataplexMetadataBucket` |
| Purpose | Stores Dataplex metadata artifacts for the stable (`prj-grp-data-cat-stable-0b72`) environment |
| Ownership | owned |
| Bucket name | `grpn-dataplex-catalog-stable-storage` |
| Region | `us-central1` |
| Versioning | Disabled |
| Access | Uniform bucket-level access enabled |
| Labels | `service=gcp-dataplex-catalog`, `owner=dnd-tools`, `environment=stable` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Metadata files (objects) | Stores Dataplex metadata artifacts uploaded by data ingestion tooling | Object key, content |

#### Access Patterns

- **Read**: Accessed by data ingestion tooling and Dataplex metadata crawlers
- **Write**: Written to by data ingestion pipelines registering Teradata metadata
- **Indexes**: Not applicable (GCS object storage)

---

### Dataplex Data Catalog Configuration (`dataplexDataCatalogConfig`)

| Property | Value |
|----------|-------|
| Type | Google Cloud Dataplex (Entry Types + Entry Group) |
| Architecture ref | `dataplexDataCatalogConfig` |
| Purpose | Registers custom Teradata metadata types in GCP Dataplex for data governance and discoverability |
| Ownership | owned |
| GCP Project | `prj-grp-data-cat-stable-0b72` |
| Region | `us-central1` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `teradata-table` entry type | Classifies Teradata table assets in the Data Catalog | `entry_type_id`, `project`, `location`, `display_name` |
| `teradata-database` entry type | Classifies Teradata database assets | `entry_type_id`, `project`, `location`, `display_name` |
| `teradata-view` entry type | Classifies Teradata view assets | `entry_type_id`, `project`, `location`, `display_name` |
| `teradata-column` entry type | Classifies Teradata column assets | `entry_type_id`, `project`, `location`, `display_name` |
| `teradata-dataplex` entry group | Groups all Teradata metadata entries for unified catalog discovery | `entry_group_id`, `project`, `location`, `display_name` |

#### Access Patterns

- **Read**: Data consumers and catalog search tooling query entry types and groups via the GCP Dataplex API
- **Write**: Managed exclusively via Terraform apply operations; manual changes are not expected
- **Indexes**: Managed by GCP Dataplex internally

## Caches

> No evidence found in codebase. No application-level caches are provisioned.

## Data Flows

Dataplex metadata artifacts are written to the GCS bucket (`grpn-dataplex-catalog-stable-storage`) by external ingestion tooling. Those artifacts reference the entry types and entry group provisioned in GCP Dataplex (`teradata-table`, `teradata-database`, `teradata-view`, `teradata-column`, `teradata-dataplex`) to classify and organise Teradata data assets in the catalog. The Terraform state for both resources is stored remotely in a GCS state bucket managed by Terragrunt.
