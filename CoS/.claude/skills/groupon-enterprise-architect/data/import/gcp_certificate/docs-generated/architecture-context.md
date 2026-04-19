---
service: "gcp_certificate"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
    - continuumPrivateCaModule
    - continuumCertificatesModule
    - continuumCertificateTemplateMtlsModule
    - continuumCertificateTemplateClientAuthModule
    - continuumCertificateTemplateServerAuthModule
    - continuumCertificateTemplateCustomModule
---

# Architecture Context

## System Context

The `gcp_certificate` service is modeled as part of the `continuumSystem` (Continuum Platform) within Groupon's C4 architecture. It is a pure infrastructure-as-code service: it provisions GCP Private CA resources and enforces IAM policies so that internal engineering teams can self-serve certificate issuance within approved scope. The service itself does not have a runtime process; its outputs are long-lived GCP resources consumed by other services. Authorized Google Groups hold `roles/privateca.certificateRequester` or `roles/privateca.templateUser` on specific templates, enabling them to request certificates through the GCP API directly without infosec involvement for each issuance.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| private-ca module | `continuumPrivateCaModule` | Terraform module | HCL / GCP Private CA API | current | Creates the GCP Private CA pool, subordinate CA, and issuance IAM policy |
| certificates module | `continuumCertificatesModule` | Terraform module | HCL | current | Orchestrates certificate template modules for private CA issuance |
| mTLS template module | `continuumCertificateTemplateMtlsModule` | Terraform module | HCL / GCP Private CA API | current | Creates the `mTLS_template` certificate template and access bindings |
| client_auth template module | `continuumCertificateTemplateClientAuthModule` | Terraform module | HCL / GCP Private CA API | current | Creates the `client_auth_template` certificate template and access bindings |
| server_auth template module | `continuumCertificateTemplateServerAuthModule` | Terraform module | HCL / GCP Private CA API | current | Creates the `server_auth_template` certificate template and access bindings |
| custom template module | `continuumCertificateTemplateCustomModule` | Terraform module | HCL / Python / GCP Private CA API | current | Creates custom certificate templates with per-service CEL constraints, name constraints, and access bindings |

## Components by Container

### private-ca module (`continuumPrivateCaModule`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| CA Pool (`google_privateca_ca_pool`) | Holds the CA with ENTERPRISE tier, publishes CA cert, enforces domain suffix issuance policy via CEL | Terraform / GCP Private CA |
| Intermediate CA (`google_privateca_certificate_authority`) | SUBORDINATE CA with RSA_PKCS1_4096_SHA256 key, 15-year lifetime, chained to Groupon Root CA via PEM issuer chain | Terraform / GCP Private CA |
| CA Pool IAM Policy (`google_privateca_ca_pool_iam_policy`) | Binds `roles/privateca.certificateRequester` to approved groups per template and common name | Terraform / GCP IAM |

### certificates module (`continuumCertificatesModule`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Module router | Instantiates each certificate template sub-module (mTLS, client_auth, server_auth, custom) passing environment-specific certificate request lists | Terraform |

### mTLS template module (`continuumCertificateTemplateMtlsModule`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| mTLS certificate template | Creates `mTLS_template` with digital_signature + client_auth + server_auth EKU, 400-day maximum lifetime | Terraform / GCP Private CA |
| Template IAM policy | Grants `roles/privateca.templateUser` to requester groups | Terraform / GCP IAM |

### client_auth template module (`continuumCertificateTemplateClientAuthModule`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| client_auth certificate template | Creates `client_auth_template` with digital_signature + client_auth EKU, 400-day maximum lifetime | Terraform / GCP Private CA |
| Template IAM policy | Grants `roles/privateca.templateUser` to requester groups | Terraform / GCP IAM |

### server_auth template module (`continuumCertificateTemplateServerAuthModule`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| server_auth certificate template | Creates `server_auth_template` with digital_signature + server_auth EKU, 400-day maximum lifetime | Terraform / GCP Private CA |
| Template IAM policy | Grants `roles/privateca.templateUser` to requester groups | Terraform / GCP IAM |

### custom template module (`continuumCertificateTemplateCustomModule`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| name_constraints encoder | Encodes domain name constraints as ASN.1 DER (x509v3 OID `2.5.29.30`) using Python and base64 for GCP Private CA consumption | Python 3 |
| Custom certificate template | Creates named template (e.g., `conveyor_subordinate_cert_authority`) with CEL identity constraints, configurable key usage, and optional name constraints | Terraform / GCP Private CA |
| Template IAM policy | Grants `roles/privateca.templateUser` to the specified requester group | Terraform / GCP IAM |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumCertificatesModule` | `continuumCertificateTemplateMtlsModule` | Invokes template module for mTLS certificates | Terraform module call |
| `continuumCertificatesModule` | `continuumCertificateTemplateClientAuthModule` | Invokes template module for client authentication certificates | Terraform module call |
| `continuumCertificatesModule` | `continuumCertificateTemplateServerAuthModule` | Invokes template module for server authentication certificates | Terraform module call |
| `continuumCertificatesModule` | `continuumCertificateTemplateCustomModule` | Invokes template module for custom certificates | Terraform module call |

## Architecture Diagram References

- Container: `containers-gcp-certificate`
