---
service: "gcp_certificate"
title: "Custom Template Provisioning with Name Constraints"
generated: "2026-03-03"
type: flow
flow_name: "custom-template-provisioning"
flow_type: batch
trigger: "Manual Terraform apply — custom certificate template entry added to account.hcl"
participants:
  - "continuumCertificatesModule"
  - "continuumCertificateTemplateCustomModule"
architecture_ref: "containers-gcp-certificate"
---

# Custom Template Provisioning with Name Constraints

## Summary

This flow provisions a custom GCP Private CA certificate template — specifically one that enables subordinate CA delegation (e.g., `conveyor_subordinate_cert_authority`) with x509v3 `nameConstraints` extensions. Because GCP Private CA does not natively support the nameConstraints x509v3 extension via a simple field, the `custom` module invokes a Python script (`name_constraints.py`) to compute the correct ASN.1 DER-encoded value and passes it as a base64 string to the `additional_extensions` block in the Terraform resource. CEL expressions govern subject identity constraints.

## Trigger

- **Type**: manual
- **Source**: Infosec operator adds a new entry to the `custom` list in `account.hcl` with a unique `template_name` and applies the `certificates` module
- **Frequency**: On demand — rare; typically once per service that needs subordinate CA or highly constrained certificate capabilities

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Infosec operator | Authors the custom template entry; initiates apply | n/a |
| Terragrunt | Merges variable layers and invokes Terraform | n/a |
| `certificates` Terraform module | Routes `custom` entries to the custom template module | `continuumCertificatesModule` |
| `custom` template module | Calls `name_constraints.py`, creates the template, applies IAM policy | `continuumCertificateTemplateCustomModule` |
| `name_constraints.py` | Encodes DNS name constraints as ASN.1 DER per RFC 5280, base64-encodes for GCP | Python 3 (invoked via Terraform `external` data source) |
| GCP Private CA API | Creates the certificate template with embedded `nameConstraints` extension | external |
| GCP IAM API | Applies `roles/privateca.templateUser` to the requester group | external |

## Steps

1. **Author custom template entry**: Infosec operator adds an entry to the `custom` list in `account.hcl` specifying: `template_name`, `service`, `requesters`, `identity_contraints` (CEL expression for subject CN matching), `maximum_lifetime`, `ca_options` (e.g., `is_ca = true`, `max_issuer_path_length = 0`), `base_key_usage` map, `extended_key_usage` map, and `name_constraints` (list of allowed domain strings, e.g., `["groupondev.com", "service", "local", "svc"]`).
   - From: Infosec operator
   - To: `account.hcl`
   - Protocol: file edit + pull request

2. **Invoke custom template module**: Terragrunt passes the `custom` list to the `certificates` module; Terraform iterates over entries and creates one `custom` module instance per unique `template_name`.
   - From: `continuumCertificatesModule`
   - To: `continuumCertificateTemplateCustomModule`
   - Protocol: Terraform module call (`for_each`)

3. **Encode nameConstraints via ASN.1**: Terraform invokes `name_constraints.py` via the `external` data source, passing the `name_constraints` list as a space-separated string. The Python script encodes each domain as an ASN.1 `[2]` (DNS name) wrapped in a SEQUENCE, wraps all domains in a `[0]` permitted subtrees SEQUENCE, and base64-encodes the result. Returns `object_id = "2.5.29.30"` and `value = <base64-encoded DER>`.
   - From: `continuumCertificateTemplateCustomModule` (Terraform `external` data source)
   - To: `name_constraints.py` (Python 3 subprocess)
   - Protocol: JSON stdin/stdout (Terraform external data source protocol)

4. **Create custom certificate template**: Terraform creates `google_privateca_certificate_template` with the template name (e.g., `conveyor_subordinate_cert_authority`), the CEL-based identity constraint expression, configurable `maximum_lifetime`, `ca_options`, full key usage map, and the `additional_extensions` block containing the nameConstraints DER value marked as `critical = true`.
   - From: `continuumCertificateTemplateCustomModule`
   - To: GCP Private CA API
   - Protocol: GCP SDK

5. **Apply template IAM policy**: Terraform creates `google_privateca_certificate_template_iam_policy` granting `roles/privateca.templateUser` to the `requesters` group (e.g., `group:grp_gcloud_conveyor_admin@groupon.com`).
   - From: `continuumCertificateTemplateCustomModule`
   - To: GCP IAM API
   - Protocol: GCP SDK

6. **Write Terraform state**: Terragrunt writes updated state to GCS.
   - From: Terraform
   - To: GCS
   - Protocol: GCP SDK

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `name_constraints.py` crashes or returns invalid JSON | Terraform `external` data source fails; apply aborts | Custom template not created; fix Python script or domain list |
| CEL expression syntax error in `identity_contraints.cel_expression` | GCP Private CA API returns validation error | Template not created; fix CEL expression |
| `max_issuer_path_length` set incorrectly for non-CA template | GCP returns validation error (`ca_options` inconsistency) | Template not created; align `is_ca` and `max_issuer_path_length` |
| `maximum_lifetime` exceeds CA pool maximum | GCP clamps or rejects; check CA pool `maximum_lifetime = "475200000s"` (15 years) | Template created with clamped lifetime |
| Requester group not found in Google Workspace | GCP IAM API returns error | Template IAM policy not applied |

## Sequence Diagram

```
Operator -> account.hcl: add conveyor_subordinate_cert_authority entry (name_constraints=[groupondev.com, service, local, svc])
Operator -> Terragrunt: make grp-security-prod/APPLY (certificates module)
Terragrunt -> Terraform: merge vars + apply
Terraform -> name_constraints.py: stdin={domains: "groupondev.com service local svc"}
name_constraints.py -> name_constraints.py: ASN.1 encode each domain as [2] SEQUENCE; wrap in [0] SEQUENCE; base64 encode
name_constraints.py --> Terraform: {object_id: "2.5.29.30", value: "<base64-DER>"}
Terraform -> GCP Private CA API: create conveyor_subordinate_cert_authority template (nameConstraints extension, CEL, is_ca=true, cert_sign=true, crl_sign=true, client_auth=true, server_auth=true, ocsp_signing=true, lifetime=475200000s)
GCP Private CA API --> Terraform: template created
Terraform -> GCP IAM API: set templateUser policy (group:grp_gcloud_conveyor_admin@groupon.com)
GCP IAM API --> Terraform: policy applied
Terraform -> GCS: write state
Terraform --> Operator: apply complete
```

## Related

- Architecture dynamic view: `containers-gcp-certificate`
- Related flows: [Certificate Template Registration](certificate-template-registration.md), [Certificate Issuance](certificate-issuance.md)
