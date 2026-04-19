---
service: "gcp_certificate"
title: "Certificate Template Registration"
generated: "2026-03-03"
type: flow
flow_name: "certificate-template-registration"
flow_type: batch
trigger: "Manual Terraform apply by infosec operator (certificates module)"
participants:
  - "continuumCertificatesModule"
  - "continuumCertificateTemplateMtlsModule"
  - "continuumCertificateTemplateClientAuthModule"
  - "continuumCertificateTemplateServerAuthModule"
  - "continuumCertificateTemplateCustomModule"
architecture_ref: "containers-gcp-certificate"
---

# Certificate Template Registration

## Summary

This flow registers all GCP Private CA certificate templates for an environment by applying the `certificates` Terraform module. The module orchestrates four template sub-modules — `mTLS`, `client_auth`, `server_auth`, and `custom` — each of which creates a named `google_privateca_certificate_template` and binds `roles/privateca.templateUser` to the approved Google Groups for that template. After this flow completes, authorized service teams can self-serve certificate issuance using their approved template without infosec involvement.

## Trigger

- **Type**: manual
- **Source**: Infosec operator runs `make grp-security-<env>/APPLY` targeting the `certificates` module path; also triggered when a new service is added to `account.hcl`
- **Frequency**: On demand — when a new template or service certificate entry is added or modified

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Infosec operator | Initiates apply; reviews and merges `account.hcl` changes | n/a |
| Terragrunt | Merges variable layers and invokes Terraform | n/a |
| `certificates` Terraform module | Routes certificate requests to the appropriate template sub-module | `continuumCertificatesModule` |
| `mTLS` template module | Creates `mTLS_template` for mutual TLS leaf certificates | `continuumCertificateTemplateMtlsModule` |
| `client_auth` template module | Creates `client_auth_template` for client authentication leaf certificates | `continuumCertificateTemplateClientAuthModule` |
| `server_auth` template module | Creates `server_auth_template` for server authentication leaf certificates | `continuumCertificateTemplateServerAuthModule` |
| `custom` template module | Creates named custom templates with per-service constraints | `continuumCertificateTemplateCustomModule` |
| GCP Private CA API | Stores certificate templates | external |
| GCP IAM API | Stores template IAM policies | external |

## Steps

1. **Receive template configuration**: Terragrunt passes the `certificates` map variable (from `account.hcl`) to the `certificates` module, containing lists of approved certificate entries per type: `mTLS`, `client_auth`, `server_auth`, `custom`.
   - From: Terragrunt
   - To: `continuumCertificatesModule`
   - Protocol: Terraform variable

2. **Invoke mTLS template module**: Creates `google_privateca_certificate_template` named `mTLS_template` with `digital_signature = true`, `client_auth = true`, `server_auth = true` EKU, 400-day maximum lifetime, and passes requester groups to the IAM policy.
   - From: `continuumCertificatesModule`
   - To: `continuumCertificateTemplateMtlsModule`
   - Protocol: Terraform module call

3. **Invoke client_auth template module**: Creates `google_privateca_certificate_template` named `client_auth_template` with `digital_signature = true`, `client_auth = true` EKU only, 400-day maximum lifetime.
   - From: `continuumCertificatesModule`
   - To: `continuumCertificateTemplateClientAuthModule`
   - Protocol: Terraform module call

4. **Invoke server_auth template module**: Creates `google_privateca_certificate_template` named `server_auth_template` with `digital_signature = true`, `server_auth = true` EKU only, 400-day maximum lifetime.
   - From: `continuumCertificatesModule`
   - To: `continuumCertificateTemplateServerAuthModule`
   - Protocol: Terraform module call

5. **Invoke custom template module(s)**: For each entry in the `custom` list, creates a uniquely named `google_privateca_certificate_template` with CEL-based identity constraints, configurable key usages, and optionally ASN.1-encoded nameConstraints extension (via `name_constraints.py`).
   - From: `continuumCertificatesModule`
   - To: `continuumCertificateTemplateCustomModule`
   - Protocol: Terraform module call (one instance per unique `template_name`)

6. **Apply template IAM policies**: Each template module creates a `google_privateca_certificate_template_iam_policy` granting `roles/privateca.templateUser` to the flattened list of requesters for that template.
   - From: Each template module
   - To: GCP IAM API
   - Protocol: GCP SDK

7. **Write Terraform state**: Terragrunt writes updated state to GCS under `us-central1/certificates`.
   - From: Terraform
   - To: GCS
   - Protocol: GCP SDK

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Domain suffix not in `valid_domain_suffixes` | CA pool issuance policy will reject issuance at request time (not at template creation time) | Template created; certificate requests fail at issuance |
| Duplicate template name | GCP returns an error; Terraform apply fails | Existing template unchanged; must use unique `template_name` |
| `name_constraints.py` encoding failure | `external` data source fails; Terraform apply aborts | Custom template not created |
| IAM group not found in Google Workspace | GCP IAM API returns error; apply fails | Template IAM policy not applied; template may be created without access |

## Sequence Diagram

```
Operator -> Terragrunt: make grp-security-prod/APPLY (certificates module)
Terragrunt -> Terraform: merge vars + apply (certificates map from account.hcl)
Terraform -> GCP Private CA API: create mTLS_template
Terraform -> GCP IAM API: set templateUser policy (mTLS_template)
Terraform -> GCP Private CA API: create client_auth_template
Terraform -> GCP IAM API: set templateUser policy (client_auth_template)
Terraform -> GCP Private CA API: create server_auth_template
Terraform -> GCP IAM API: set templateUser policy (server_auth_template)
Terraform -> name_constraints.py: encode nameConstraints for conveyor template
name_constraints.py --> Terraform: base64(ASN.1 DER) for OID 2.5.29.30
Terraform -> GCP Private CA API: create conveyor_subordinate_cert_authority (custom)
Terraform -> GCP IAM API: set templateUser policy (conveyor_subordinate_cert_authority)
Terraform -> GCS: write state (us-central1/certificates/terraform.tfstate)
Terraform --> Operator: apply complete
```

## Related

- Architecture dynamic view: `containers-gcp-certificate`
- Related flows: [Private CA Provisioning](private-ca-provisioning.md), [Certificate Issuance](certificate-issuance.md), [Custom Template Provisioning with Name Constraints](custom-template-provisioning.md)
