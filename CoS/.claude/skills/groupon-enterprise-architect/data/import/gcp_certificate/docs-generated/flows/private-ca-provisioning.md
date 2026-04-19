---
service: "gcp_certificate"
title: "Private CA Provisioning"
generated: "2026-03-03"
type: flow
flow_name: "private-ca-provisioning"
flow_type: batch
trigger: "Manual Terraform apply by infosec operator"
participants:
  - "continuumPrivateCaModule"
architecture_ref: "containers-gcp-certificate"
---

# Private CA Provisioning

## Summary

This flow describes how Groupon's GCP Private Certificate Authority infrastructure is bootstrapped for a new environment. An infosec operator applies the `private-ca` Terraform module, which creates the CA pool with an ENTERPRISE-tier issuance policy, provisions the subordinate intermediate CA chained to the Groupon Root CA, and binds per-template certificate requester IAM policies. Because GCP cannot automatically activate a subordinate CA, a manual console step is required to complete the activation after the initial apply.

## Trigger

- **Type**: manual
- **Source**: Infosec operator runs `make grp-security-<env>/APPLY` targeting the `private-ca` module path
- **Frequency**: On demand — once per environment, or when CA infrastructure changes are needed

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Infosec operator | Initiates the Terraform apply | n/a |
| Terragrunt | Merges variable layers and invokes Terraform | n/a |
| `private-ca` Terraform module | Provisions all GCP Private CA resources | `continuumPrivateCaModule` |
| GCP Private CA API (`privateca.googleapis.com`) | Creates and stores the CA pool and subordinate CA | external |
| GCP IAM API | Enforces the issuance IAM policy on the CA pool | external |
| GCS | Stores and retrieves Terraform remote state | external |
| Groupon Root CA | Signs the CSR to activate the subordinate CA | external / manual |

## Steps

1. **Enable Private CA API**: Terraform enables `privateca.googleapis.com` on the target GCP project via `google_project_service`.
   - From: `continuumPrivateCaModule`
   - To: GCP Service Usage API
   - Protocol: GCP SDK

2. **Create CA Pool**: Terraform provisions `google_privateca_ca_pool` named `ca-pool-<env_short_name>-<random_hex>` with ENTERPRISE tier, allows CSR-based and config-based issuance, restricts SANs to Groupon domain suffixes via CEL expression, and sets `publish_ca_cert = true`.
   - From: `continuumPrivateCaModule`
   - To: GCP Private CA API
   - Protocol: GCP SDK

3. **Provision Subordinate Intermediate CA**: Terraform creates `google_privateca_certificate_authority` of type `SUBORDINATE` with RSA_PKCS1_4096_SHA256 key, 15-year lifetime, `Groupon GCP Intermediate CA` subject, and attaches the Groupon Root CA PEM as the issuer chain.
   - From: `continuumPrivateCaModule`
   - To: GCP Private CA API
   - Protocol: GCP SDK

4. **Apply Issuance IAM Policy**: Terraform computes per-certificate-entry IAM conditions (template name + common name + SAN constraints) and applies `google_privateca_ca_pool_iam_policy` granting `roles/privateca.certificateRequester` to approved Google Groups.
   - From: `continuumPrivateCaModule`
   - To: GCP IAM API
   - Protocol: GCP SDK

5. **Manual CA Activation (first-time only)**: Operator navigates to GCP Console, downloads the CSR from the new CA, signs it with the Groupon Root CA, and uploads the signed certificate to activate the subordinate CA.
   - From: Infosec operator
   - To: GCP Console / Groupon Root CA
   - Protocol: Manual

6. **Write Terraform State**: After apply, Terragrunt writes updated state to the GCS bucket (`grpn-gcp-<PROJECTNAME>-state-<GCP_PROJECT_NUMBER>`) under the `us-central1/private-ca` prefix.
   - From: Terraform
   - To: GCS
   - Protocol: GCP SDK

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `Error activating subordinate CA with first party issuer` | Expected on initial apply — requires manual console activation (see Step 5) | CA created but not active; must complete manual step |
| GCP API permission denied | Verify `grpn-sa-terraform-security` has required roles; contact CloudCore | Apply fails; no resources created |
| GCS state lock conflict | Wait for previous operation to complete; release lock if operator session died | Apply blocked until lock released |
| CEL expression syntax error in issuance policy | Fix CEL expression in `modules/private-ca/main.tf`; re-apply | IAM policy not updated; previous policy retained |

## Sequence Diagram

```
Operator -> Terragrunt: make grp-security-prod/APPLY (private-ca module)
Terragrunt -> Terraform: merge vars (global.hcl + account.hcl + region.hcl) + apply
Terraform -> GCP Service Usage API: enable privateca.googleapis.com
Terraform -> GCP Private CA API: create ca-pool-security-prod-<hex> (ENTERPRISE)
Terraform -> GCP Private CA API: create gcp-intermediate-security-prod-<hex> (SUBORDINATE)
GCP Private CA API --> Terraform: CA created (pending activation)
Terraform -> GCP IAM API: apply ca_pool_iam_policy (certificateRequester bindings)
GCP IAM API --> Terraform: policy applied
Terraform -> GCS: write state (us-central1/private-ca/terraform.tfstate)
Terraform --> Operator: apply complete (CA pending activation)
Operator -> GCP Console: download CSR
Operator -> Root CA: sign CSR
Operator -> GCP Console: upload signed certificate
GCP Console --> Operator: CA activated
```

## Related

- Architecture dynamic view: `containers-gcp-certificate`
- Related flows: [Certificate Template Registration](certificate-template-registration.md)
