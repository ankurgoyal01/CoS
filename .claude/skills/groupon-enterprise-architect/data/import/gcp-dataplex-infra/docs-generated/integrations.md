---
service: "gcp-dataplex-infra"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 0
---

# Integrations

## Overview

`gcp-dataplex-infra` depends on three external GCP-managed services provisioned via the Terraform Google provider. All interactions are infrastructure-level (Terraform API calls during `plan`/`apply`) rather than runtime service calls. There are no internal Groupon service-to-service dependencies at runtime. Upstream consumers of the provisioned resources are external data ingestion pipelines that register Teradata metadata using the entry types and entry group this service provisions.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Google Cloud Dataplex API | GCP SDK (Terraform provider) | Provisions entry types and entry groups for Teradata metadata | yes | `dataplexDataCatalogConfig` |
| Google Cloud Storage API | GCP SDK (Terraform provider) | Provisions GCS bucket for Dataplex metadata storage | yes | `dataplexMetadataBucket` |
| GCP IAM / Service Account API | GCP SDK (Terraform provider) | Impersonates `grpn-sa-terraform-data-catalog` for deployment | yes | — |

### Google Cloud Dataplex API Detail

- **Protocol**: GCP REST API via `hashicorp/google` Terraform provider
- **Base URL / SDK**: `https://www.googleapis.com/auth/cloud-platform` (OAuth2 scope)
- **Auth**: Service account impersonation — `grpn-sa-terraform-data-catalog@prj-grp-central-sa-stable-66eb.iam.gserviceaccount.com`
- **Purpose**: Creates and manages `google_dataplex_entry_type` and `google_dataplex_entry_group` resources that define the Teradata metadata taxonomy in GCP Dataplex Data Catalog
- **Failure mode**: Terraform apply fails; GCP resources remain in the last-known good state; existing Data Catalog configuration is unaffected
- **Circuit breaker**: Not applicable (infrastructure provisioning)

### Google Cloud Storage API Detail

- **Protocol**: GCP REST API via `hashicorp/google` Terraform provider
- **Base URL / SDK**: `https://www.googleapis.com/auth/cloud-platform` (OAuth2 scope)
- **Auth**: Service account impersonation — `grpn-sa-terraform-data-catalog@prj-grp-central-sa-stable-66eb.iam.gserviceaccount.com`
- **Purpose**: Creates and manages the `grpn-dataplex-catalog-stable-storage` GCS bucket used to store Dataplex metadata files
- **Failure mode**: Terraform apply fails; existing bucket and its contents are unaffected
- **Circuit breaker**: Not applicable (infrastructure provisioning)

### GCP IAM / Service Account API Detail

- **Protocol**: GCP REST API via `hashicorp/google` Terraform provider (impersonation)
- **Base URL / SDK**: `https://www.googleapis.com/auth/cloud-platform`, `https://www.googleapis.com/auth/userinfo.email`
- **Auth**: Application Default Credentials (`gcloud auth application-default login`) used to impersonate `grpn-sa-terraform-data-catalog`; access token lifetime 3600s
- **Purpose**: Ensures all GCP resource operations are performed under the designated Terraform service account rather than individual operator credentials
- **Failure mode**: Terraform cannot authenticate; no changes are applied to GCP
- **Circuit breaker**: Not applicable

## Internal Dependencies

> No evidence found in codebase. This repository has no runtime dependencies on other internal Groupon services.

## Consumed By

> Upstream consumers are tracked in the central architecture model.

Data ingestion tooling and analytics pipelines (external to this repo) consume the provisioned Dataplex entry types and entry group to register Teradata data assets in the GCP Data Catalog.

## Dependency Health

GCP service availability is the only runtime health concern. Terraform apply operations will fail cleanly if GCP APIs are unavailable. The remote state backend (GCS) must be accessible for any Terraform operation to proceed. No retry or circuit-breaker logic is implemented in this repository — standard Terraform provider retry behaviour applies.
