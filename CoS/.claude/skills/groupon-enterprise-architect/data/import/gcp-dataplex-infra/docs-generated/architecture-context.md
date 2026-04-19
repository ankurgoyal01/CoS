---
service: "gcp-dataplex-infra"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["dataplexDataCatalogConfig", "dataplexMetadataBucket"]
---

# Architecture Context

## System Context

`gcp-dataplex-infra` is a GCP infrastructure provisioning service within the Continuum Platform (`continuumSystem`). It does not serve runtime traffic; instead, it manages the GCP Dataplex Data Catalog configuration that underpins Groupon's data governance layer. External data ingestion tooling references the entry types and entry group provisioned here to register Teradata data assets into GCP Dataplex. The repository sits in the GCP project `prj-grp-data-cat-stable-0b72` and uses a dedicated Terraform service account (`grpn-sa-terraform-data-catalog`) for all provisioning operations.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Dataplex Data Catalog Configuration | `dataplexDataCatalogConfig` | Configuration | Google Cloud Dataplex | — | Terraform-managed Dataplex entry types (`teradata-table`, `teradata-database`, `teradata-view`, `teradata-column`) and entry group (`teradata-dataplex`) for Teradata metadata |
| Dataplex Metadata Bucket | `dataplexMetadataBucket` | Datastore | Google Cloud Storage | — | GCS bucket (`grpn-dataplex-catalog-stable-storage`) storing Dataplex metadata artifacts |

## Components by Container

### Dataplex Data Catalog Configuration (`dataplexDataCatalogConfig`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `teradata-table` entry type | Classifies Teradata table assets in the Data Catalog | Google Dataplex Entry Type |
| `teradata-database` entry type | Classifies Teradata database assets in the Data Catalog | Google Dataplex Entry Type |
| `teradata-view` entry type | Classifies Teradata view assets in the Data Catalog | Google Dataplex Entry Type |
| `teradata-column` entry type | Classifies Teradata column assets in the Data Catalog | Google Dataplex Entry Type |
| `teradata-dataplex` entry group | Groups all Teradata metadata entries for unified discovery | Google Dataplex Entry Group |

### Dataplex Metadata Bucket (`dataplexMetadataBucket`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `grpn-dataplex-catalog-stable-storage` | Stores Dataplex metadata files; uniform bucket-level access, versioning disabled | Google Cloud Storage |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `dataplexDataCatalogConfig` | Google Cloud Dataplex API | Registers entry types and entry group | GCP API (Terraform) |
| `dataplexMetadataBucket` | Google Cloud Storage API | Creates and manages GCS bucket | GCP API (Terraform) |
| Terraform Service Account (`grpn-sa-terraform-data-catalog`) | `dataplexDataCatalogConfig` | Impersonated to apply changes | GCP IAM |
| Terraform Service Account (`grpn-sa-terraform-data-catalog`) | `dataplexMetadataBucket` | Impersonated to apply changes | GCP IAM |

## Architecture Diagram References

- Container: `gcp-dataplex-infra-containers`
- Component: `components-gcp-dataplex-infra`
