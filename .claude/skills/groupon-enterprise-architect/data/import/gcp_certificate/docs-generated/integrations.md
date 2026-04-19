---
service: "gcp_certificate"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 4
internal_count: 0
---

# Integrations

## Overview

The `gcp_certificate` service integrates with four GCP and AWS cloud APIs at apply time. All integrations are infrastructure-plane (Terraform provider calls or shell script invocations) rather than runtime service-to-service calls. There are no internal Groupon service dependencies at the code level — the service provisions resources that other Groupon services then consume directly via GCP APIs.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| GCP Private CA API (`privateca.googleapis.com`) | GCP SDK / REST | Provisions CA pools, subordinate CAs, and certificate templates | yes | `continuumPrivateCaModule` |
| GCP IAM API | GCP SDK / REST | Applies IAM policy bindings to CA pools and certificate templates | yes | `continuumPrivateCaModule` |
| GCS (Google Cloud Storage) | GCP SDK | Stores and retrieves Terraform remote state | yes | `continuumPrivateCaModule` |
| AWS STS + ACM | AWS CLI / REST | `scripts/fetch_cert` and `scripts/issue_cert` assume an IAM role, read CertARN tag, and export the certificate via ACM | no | n/a |

### GCP Private CA API Detail

- **Protocol**: Terraform `google` provider (REST under the hood)
- **Base URL / SDK**: `google_privateca_ca_pool`, `google_privateca_certificate_authority`, `google_privateca_certificate_template` resources
- **Auth**: GCP service account impersonation — `grpn-sa-terraform-security` impersonated via `prj-grp-central-sa-{stage}`
- **Purpose**: Creates the CA pool (ENTERPRISE tier, `us-central1`), activates the subordinate intermediate CA, and registers certificate templates with issuance policy
- **Failure mode**: Terraform `apply` fails; CA pool and templates remain unchanged; existing certificates continue to be valid
- **Circuit breaker**: Not applicable (Terraform apply is idempotent)

### GCP IAM API Detail

- **Protocol**: Terraform `google` provider
- **Base URL / SDK**: `google_privateca_ca_pool_iam_policy`, `google_privateca_certificate_template_iam_policy` resources
- **Auth**: GCP service account impersonation
- **Purpose**: Enforces least-privilege access — authorized Google Groups may only request certificates for their own service using their approved template and exact common name
- **Failure mode**: Terraform `apply` fails; existing IAM bindings persist
- **Circuit breaker**: Not applicable

### GCS Remote State Detail

- **Protocol**: Terraform `gcs` backend
- **Base URL / SDK**: `backend "gcs" {}` in `modules/template/common.tf`; bucket name injected by Terragrunt environment variables (`TF_VAR_PROJECTNAME`, `TF_VAR_GCP_PROJECT_NUMBER`)
- **Auth**: GCP service account impersonation
- **Purpose**: Persistent Terraform state storage per environment and module
- **Failure mode**: Terraform cannot initialize or apply; infrastructure changes blocked
- **Circuit breaker**: Not applicable

### AWS STS + ACM Detail

- **Protocol**: AWS CLI (`aws sts assume-role`, `aws acm export-certificate`)
- **Base URL / SDK**: `scripts/fetch_cert`, `scripts/issue_cert`
- **Auth**: `--cert_role` IAM role ARN passed as argument; role is tagged with `CertARN`
- **Purpose**: Retrieves a certificate and decrypted private key from AWS ACM, writes them to `$CERT_PATH/cert-bundle.pem` and `$CERT_PATH/privkey.pem`
- **Failure mode**: Script exits non-zero; caller must handle retry
- **Circuit breaker**: No

## Internal Dependencies

> No evidence found in codebase. This service has no runtime dependencies on other Groupon internal services.

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| `encore-tagging` | GCP Private CA API | Requests `client_auth` certificate (`staging/encore-tagging`) |
| `encore-service` | GCP Private CA API | Requests `client_auth` certificates (`production/encore-service`, `staging/encore-service`) |
| `mbus` | GCP Private CA API | Requests `client_auth` certificate (`mbus.staging.service`) |
| `tableau-server` | GCP Private CA API | Requests `server_auth` certificates (`analytics.groupondev.com`, `tableau.groupondev.com`, `tableau-dev.tableau.dev.gcp.groupondev.com`) |
| `deadbolt` | GCP Private CA API | Requests `server_auth` certificate (`deadbolt.groupondev.com`) |
| `conveyor` | GCP Private CA API | Requests custom subordinate CA certificate using `conveyor_subordinate_cert_authority` template |
| `kafka` (dev) | GCP Private CA API | Requests `client_auth` certificate (`kafka.staging.service`) |
| `hybrid-boundary` (dev) | GCP Private CA API | Requests `mTLS` certificate (`hybrid-boundary.staging.service`) |

## Dependency Health

There are no runtime health checks — this is an IaC-only service. Terraform plans (`make <env>/plan`) serve as the primary mechanism to detect drift or dependency issues with GCP APIs. GCP Private CA API availability is governed by GCP SLAs. State lock conflicts are resolved via GCS object locking.
