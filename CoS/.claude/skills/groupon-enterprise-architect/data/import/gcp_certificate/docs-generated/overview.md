---
service: "gcp_certificate"
title: Overview
generated: "2026-03-03"
type: overview
domain: "cyber-security / PKI"
platform: "GCP"
team: "infosec@groupon.com"
status: active
tech_stack:
  language: "HCL (Terraform)"
  language_version: "1.x"
  framework: "Terragrunt"
  framework_version: "0.58.4"
  runtime: "GCP Private CA (privateca.googleapis.com)"
  runtime_version: ""
  build_tool: "Make"
  package_manager: ""
---

# GCP Private Certificate Authority Overview

## Purpose

The `gcp_certificate` service provisions and manages Groupon's internal GCP Private Certificate Authority infrastructure using Terraform and Terragrunt. It creates a subordinate CA pool, certificate templates, and IAM issuance policies so that authorized internal services can obtain non-publicly-trusted X.509 certificates for mutual TLS, client authentication, server authentication, and custom subordinate CA delegation. Publicly trusted certificates are managed separately via the `letsencrypt_certificates` repository.

## Scope

### In scope

- Provisioning the GCP CA pool (`google_privateca_ca_pool`) with ENTERPRISE tier in `us-central1`
- Creating and activating a subordinate intermediate CA (`Groupon GCP Intermediate CA`) chained to the Groupon Root CA
- Defining and managing certificate templates: `mTLS_template`, `client_auth_template`, `server_auth_template`, and custom templates (e.g., `conveyor_subordinate_cert_authority`)
- Enforcing per-template IAM bindings (`roles/privateca.templateUser`, `roles/privateca.certificateRequester`) scoped to approved Google Groups and common name constraints
- Constraining allowable SANs to Groupon-controlled domain suffixes (`.groupondev.com`, `.production.service`, `.staging.service`, `.dev.service`, `.sandbox.service`, etc.)
- Encoding x509v3 `nameConstraints` extensions (RFC 5280) for custom subordinate CA templates via Python ASN.1 encoding
- Storing Terraform remote state in GCS buckets per environment
- Providing `scripts/issue_cert` and `scripts/fetch_cert` helper scripts for certificate retrieval via AWS ACM

### Out of scope

- Publicly trusted TLS certificates (handled by `letsencrypt_certificates`)
- Runtime certificate renewal or ACME protocol automation
- Application-level TLS configuration within consumer services
- Certificate revocation list (CRL) publishing — `publish_crl = false` is set by policy

## Domain Context

- **Business domain**: cyber-security / PKI
- **Platform**: GCP (`prj-grp-security-dev-ce40`, `prj-grp-security-prod-1403`)
- **Upstream consumers**: Internal services and teams that request certificates — including `encore-tagging`, `encore-service`, `mbus`, `tableau-server`, `deadbolt`, `conveyor`, `kafka`, `hybrid-boundary`, `privateca` admin group
- **Downstream dependencies**: GCP Private CA API (`privateca.googleapis.com`), GCP IAM API, GCS (remote state), AWS STS and ACM (for `fetch_cert`/`issue_cert` scripts)

## Stakeholders

| Role | Description |
|------|-------------|
| Service Owner | infosec@groupon.com — Information Security team |
| Certificate Requesters | Teams holding `roles/privateca.certificateRequester` scoped to their service template (e.g., `grp_gcloud_mbus_admin`, `grp_gcloud_tableau_admin`, `mx-galactic-bridge`) |
| Platform Admins | `grp_gcloud_security_admin@groupon.com` — manages CA pool and global access |
| Terraform Executor | `grpn-sa-terraform-security` service account (impersonated via `prj-grp-central-sa-{stage}`) |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | HCL (Terraform) | 1.x | `envs/grp-security-prod/us-central1/**/.terraform.lock.hcl` |
| Framework | Terragrunt | 0.58.4 | `envs/Makefile` — `TERRAGRUNT_VERSION := 0.58.4` |
| Runtime | GCP Private CA API | current | `modules/private-ca/main.tf` — `google_project_service "privateca_api"` |
| Build tool | Make | system | `envs/Makefile`, `envs/.terraform-tooling/Makefile` |
| Scripting | Python 3 | 3.x | `modules/certificate-templates/custom/name_constraints.py` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `google` Terraform provider | pinned in `.terraform.lock.hcl` | cloud-sdk | Creates GCP Private CA resources, IAM policies |
| `google-beta` Terraform provider | pinned in `.terraform.lock.hcl` | cloud-sdk | Access to beta GCP resource types |
| `random` Terraform provider | pinned in `.terraform.lock.hcl` | utility | Generates unique suffix IDs for CA pool and CA names |
| `external` Terraform provider | pinned in `.terraform.lock.hcl` | utility | Invokes `name_constraints.py` to compute ASN.1-encoded x509v3 extension values |
| `openssl` (CLI) | system | crypto | Decrypts private key passphrase in `scripts/fetch_cert` |
| `aws` CLI | system | cloud-sdk | Assumes IAM role and exports ACM certificate in `scripts/fetch_cert`/`issue_cert` |
| `jq` | system | serialization | Parses JSON from AWS CLI responses in helper scripts |
