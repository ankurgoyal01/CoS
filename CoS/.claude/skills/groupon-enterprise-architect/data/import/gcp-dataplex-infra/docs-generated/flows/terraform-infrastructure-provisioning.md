---
service: "gcp-dataplex-infra"
title: "Terraform Infrastructure Provisioning"
generated: "2026-03-03"
type: flow
flow_name: "terraform-infrastructure-provisioning"
flow_type: batch
trigger: "Manual operator execution of make stable/us-central1/APPLY"
participants:
  - "operator"
  - "terragrunt"
  - "terraform-cli"
  - "dataplexDataCatalogConfig"
  - "dataplexMetadataBucket"
  - "gcp-dataplex-api"
  - "gcp-gcs-api"
architecture_ref: "gcp-dataplex-infra-containers"
---

# Terraform Infrastructure Provisioning

## Summary

This flow describes how an operator applies infrastructure changes to the GCP Dataplex Data Catalog and GCS bucket using Terragrunt and Terraform. The operator authenticates with GCP, runs a Make target that invokes Terragrunt to orchestrate Terraform, and Terraform calls the GCP Dataplex and GCS APIs using an impersonated service account to create or update the entry types, entry group, and storage bucket defined in the modules.

## Trigger

- **Type**: manual
- **Source**: Operator runs `make stable/us-central1/APPLY` in the `envs/` directory
- **Frequency**: On-demand, whenever infrastructure changes are merged and need to be applied

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator | Initiates apply; provides GCP credentials | — |
| Terragrunt | Orchestrates Terraform; assembles variable files from `global.hcl`, `account.hcl`, `region.hcl` | — |
| Terraform CLI 0.15.5 | Executes resource provisioning against GCP APIs | — |
| `dataplexDataCatalogConfig` | Target: Dataplex entry types and entry group being created/updated | `dataplexDataCatalogConfig` |
| `dataplexMetadataBucket` | Target: GCS metadata bucket being created/updated | `dataplexMetadataBucket` |
| Google Cloud Dataplex API | Receives API calls to create/update entry types and entry group | — |
| Google Cloud Storage API | Receives API calls to create/update the GCS bucket | — |

## Steps

1. **Authenticate with GCP**: Operator authenticates via Application Default Credentials (`gcloud auth application-default login`)
   - From: `operator`
   - To: GCP Identity endpoint
   - Protocol: HTTPS / gcloud CLI

2. **Invoke Make target**: Operator runs `make stable/us-central1/APPLY` in `envs/`
   - From: `operator`
   - To: Make / Terragrunt
   - Protocol: local shell

3. **Assemble variable files**: Terragrunt resolves `global.hcl`, `account.hcl` (`prj-grp-data-cat-stable-0b72`, `198003841171`, `stable`), and `region.hcl` (`us-central1`); injects them as Terraform variable files
   - From: Terragrunt
   - To: Terraform CLI
   - Protocol: local file / process

4. **Impersonate Terraform service account**: Terraform requests a scoped access token (lifetime: 3600s) for `grpn-sa-terraform-data-catalog@prj-grp-central-sa-stable-66eb.iam.gserviceaccount.com` using ADC
   - From: Terraform CLI (google provider)
   - To: GCP IAM API
   - Protocol: HTTPS (OAuth2 token exchange)

5. **Load remote state**: Terraform reads existing state from the GCS remote state backend (`grpn-gcp-<PROJECTNAME>-state-<GCP_PROJECT_NUMBER>`) to determine delta
   - From: Terraform CLI
   - To: Google Cloud Storage (state bucket)
   - Protocol: HTTPS (GCS API)

6. **Apply Dataplex module**: Terraform calls the GCP Dataplex API to create or update the four entry types (`teradata-table`, `teradata-database`, `teradata-view`, `teradata-column`) and the `teradata-dataplex` entry group in project `prj-grp-data-cat-stable-0b72`, region `us-central1`
   - From: Terraform CLI
   - To: `dataplexDataCatalogConfig` (Google Cloud Dataplex API)
   - Protocol: HTTPS (GCP REST API)

7. **Apply bucket module**: Terraform calls the GCP Storage API to create or update the `grpn-dataplex-catalog-stable-storage` GCS bucket with uniform bucket-level access and labels
   - From: Terraform CLI
   - To: `dataplexMetadataBucket` (Google Cloud Storage API)
   - Protocol: HTTPS (GCP REST API)

8. **Save updated remote state**: Terraform writes the updated state JSON back to the GCS state bucket
   - From: Terraform CLI
   - To: Google Cloud Storage (state bucket)
   - Protocol: HTTPS (GCS API)

9. **Report outcome**: Terragrunt and Make print apply results to the operator's terminal
   - From: Terragrunt / Terraform CLI
   - To: `operator`
   - Protocol: stdout

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| GCP authentication failure | Terraform exits with error; no changes applied | Operator re-authenticates and retries |
| GCP API permission denied | Terraform exits with 403 error during apply | Operator verifies SA roles and retries |
| Terraform state lock conflict | Terraform exits with lock error; no changes applied | Operator waits or force-unlocks if stale |
| GCP API unavailable | Terraform exits with network/HTTP error | No changes applied; retry when GCP service recovers |
| Resource already exists (409) | Terraform reports conflict; state out of sync | Import existing resource into state and re-apply |

## Sequence Diagram

```
Operator -> Make: make stable/us-central1/APPLY
Make -> Terragrunt: invoke apply-all with GCP env vars
Terragrunt -> Terraform: resolve vars (global.hcl, account.hcl, region.hcl) + call apply
Terraform -> GCP IAM API: request impersonation token for grpn-sa-terraform-data-catalog
GCP IAM API --> Terraform: access_token (3600s)
Terraform -> GCS State Bucket: read current state
GCS State Bucket --> Terraform: state JSON
Terraform -> GCP Dataplex API: create/update entry types + entry group
GCP Dataplex API --> Terraform: 200 OK
Terraform -> GCP Storage API: create/update grpn-dataplex-catalog-stable-storage
GCP Storage API --> Terraform: 200 OK
Terraform -> GCS State Bucket: write updated state
Terraform --> Terragrunt: apply complete
Terragrunt --> Make: exit 0
Make --> Operator: apply output
```

## Related

- Architecture dynamic view: `gcp-dataplex-infra-containers`
- Related flows: [GCP Authentication and Service Account Impersonation](gcp-auth-and-sa-impersonation.md), [Terraform Plan and Compliance Review](terraform-plan-and-compliance-review.md)
