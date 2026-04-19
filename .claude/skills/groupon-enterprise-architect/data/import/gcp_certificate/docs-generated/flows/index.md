---
service: "gcp_certificate"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for GCP Private Certificate Authority.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Private CA Provisioning](private-ca-provisioning.md) | batch | Manual Terraform apply | Creates the GCP CA pool, subordinate intermediate CA, and issuance IAM policy for a new environment |
| [Certificate Template Registration](certificate-template-registration.md) | batch | Manual Terraform apply | Registers standard and custom certificate templates with access bindings on the CA pool |
| [Certificate Issuance](certificate-issuance.md) | synchronous | Authorized service team API call | An approved requester uses the GCP Private CA API to issue a leaf certificate using a pre-approved template |
| [Custom Template Provisioning with Name Constraints](custom-template-provisioning.md) | batch | Manual Terraform apply | Provisions a custom certificate template with x509v3 nameConstraints extension for subordinate CA delegation |
| [Certificate Retrieval via AWS ACM](certificate-retrieval-aws-acm.md) | synchronous | Manual script execution | Fetches an existing certificate and private key from AWS ACM into the local filesystem using a tagged IAM role |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 3 |

## Cross-Service Flows

The certificate issuance flow spans multiple services: the `gcp_certificate` infrastructure (provisioned by this repo) is consumed directly by internal service teams (e.g., `encore-service`, `mbus`, `conveyor`, `tableau-server`) via the GCP Private CA API. Cross-service certificate lifecycle flows are tracked in the central architecture model under `continuumSystem`.
