---
service: "gcp-dataplex-infra"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 3
---

# Flows

Process and flow documentation for GCP Dataplex Infrastructure.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Terraform Infrastructure Provisioning](terraform-infrastructure-provisioning.md) | batch | Manual operator execution of `make stable/us-central1/APPLY` | Provisions or updates Dataplex entry types, entry group, and GCS bucket in GCP via Terraform/Terragrunt |
| [GCP Authentication and Service Account Impersonation](gcp-auth-and-sa-impersonation.md) | synchronous | Operator initiates any Terraform plan or apply command | Authenticates operator with GCP ADC, impersonates the Terraform service account, and obtains a scoped access token for resource provisioning |
| [Terraform Plan and Compliance Review](terraform-plan-and-compliance-review.md) | batch | Manual operator execution of `make stable/us-central1/plan` | Generates a Terraform plan, serialises it to JSON, and optionally validates it against compliance policies |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 1 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

The Terraform provisioning flows interact with three GCP managed services (Dataplex API, GCS API, and IAM API) at provisioning time. No cross-service runtime flows exist — this is a pure infrastructure repository. Data ingestion flows that consume the provisioned Dataplex resources are defined in separate upstream services and are not documented here.
