---
service: "gcp-dataplex-infra"
title: "Terraform Plan and Compliance Review"
generated: "2026-03-03"
type: flow
flow_name: "terraform-plan-and-compliance-review"
flow_type: batch
trigger: "Manual operator execution of make stable/us-central1/plan"
participants:
  - "operator"
  - "terragrunt"
  - "terraform-cli"
  - "gcp-gcs-state-bucket"
  - "terraform-compliance"
architecture_ref: "gcp-dataplex-infra-containers"
---

# Terraform Plan and Compliance Review

## Summary

Before applying any infrastructure changes, operators generate a Terraform plan to preview what GCP resources will be created, modified, or destroyed. The plan output is serialised to `plan.json` via a Terragrunt after-hook, enabling automated compliance validation against Groupon's infrastructure policies. This flow acts as the safety gate before the [Terraform Infrastructure Provisioning](terraform-infrastructure-provisioning.md) flow.

## Trigger

- **Type**: manual
- **Source**: Operator runs `make stable/us-central1/plan` in the `envs/` directory
- **Frequency**: On-demand, prior to each apply; also useful for drift detection

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator | Initiates plan and reviews output | — |
| Terragrunt | Orchestrates Terraform plan-all; assembles variable files | — |
| Terraform CLI 0.15.5 | Executes plan against GCP state; computes resource delta | — |
| GCS State Bucket | Provides current Terraform state for comparison | `dataplexMetadataBucket` (state bucket is a separate GCS bucket) |
| terraform-compliance | Validates generated `plan.json` against compliance policies | — |

## Steps

1. **Invoke plan make target**: Operator runs `make stable/us-central1/plan` (optionally with `PARALLEL=N` for concurrent module planning)
   - From: `operator`
   - To: Make / Terragrunt
   - Protocol: local shell

2. **Assemble variable files**: Terragrunt resolves and injects `global.hcl`, `account.hcl`, and `region.hcl` as Terraform variable files; also passes `GCP_PROJECT_NUMBER`, `GCP_PROJECT_ID`, `GCP_ENV_STAGE`, and `GCP_TF_SA` as environment variables
   - From: Terragrunt
   - To: Terraform CLI
   - Protocol: local file / process env

3. **Impersonate Terraform service account**: Terraform requests an impersonation token for `grpn-sa-terraform-data-catalog` (see [GCP Authentication and Service Account Impersonation](gcp-auth-and-sa-impersonation.md))
   - From: Terraform CLI (google provider)
   - To: GCP IAM API
   - Protocol: HTTPS

4. **Read remote state**: Terraform reads the current state from the GCS remote state backend to understand existing resources
   - From: Terraform CLI
   - To: GCS State Bucket
   - Protocol: HTTPS (GCS API)

5. **Compute resource delta**: Terraform compares desired state (module definitions in `modules/dataplex-datacatalog/main.tf` and `modules/bucket/main.tf`) against current GCP state, producing a plan
   - From: Terraform CLI (internal)
   - To: GCP Dataplex API / GCS API (read-only refresh)
   - Protocol: HTTPS

6. **Save plan binary**: Terraform writes the plan to `plan.output` (binary format) in the module directory
   - From: Terraform CLI
   - To: local filesystem
   - Protocol: local file

7. **Serialise plan to JSON** (after-hook): Terragrunt after-hook executes `terraform show -json plan.output > plan.json`, producing a human- and machine-readable plan
   - From: Terragrunt (after_hook "after_hook_plan")
   - To: local filesystem (`plan.json`)
   - Protocol: local shell

8. **Operator reviews plan**: Operator reads `plan.json` or plan output in terminal to verify expected changes
   - From: `operator`
   - To: `plan.json`
   - Protocol: local file

9. **Compliance test** (optional, if `DISABLE_AUTOMATIC_COMPLIANCE_TESTS=false`): `make stable/us-central1/test-compliance SKIP_TF_PLAN=true` runs terraform-compliance against `plan.json` using policy level `recommended`
   - From: Make
   - To: terraform-compliance
   - Protocol: local process

10. **Review compliance results**: Operator confirms all mandatory and recommended policies pass before proceeding to apply
    - From: terraform-compliance
    - To: `operator`
    - Protocol: stdout

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Authentication failure during plan | Terraform exits; no plan generated | Operator re-authenticates (`make stable/gcp-login`) and retries |
| GCS state bucket inaccessible | Terraform cannot read state; exits with error | Verify GCS bucket exists and SA has `storage.objectAdmin` role |
| Plan shows unexpected deletions | Operator aborts; investigates drift | Check GCP Console for out-of-band changes; import resources if needed |
| Compliance test failures | Make exits with non-zero; apply is blocked by convention | Operator fixes HCL to satisfy failing compliance rules, then re-plans |
| `plan.json` serialisation fails | After-hook `terraform show` exits with error | Verify `plan.output` exists; rerun plan |

## Sequence Diagram

```
Operator -> Make: make stable/us-central1/plan
Make -> Terragrunt: plan-all with var files + env vars
Terragrunt -> Terraform: assemble vars + invoke plan
Terraform -> GCP IAM API: get impersonation token
GCP IAM API --> Terraform: access_token
Terraform -> GCS State Bucket: read current state
GCS State Bucket --> Terraform: state JSON
Terraform -> GCP Dataplex API: refresh current resource state (read-only)
Terraform -> GCP Storage API: refresh current resource state (read-only)
Terraform --> Terragrunt: plan complete (plan.output)
Terragrunt -> Terraform: terraform show -json plan.output > plan.json
Terraform --> Terragrunt: plan.json written
Terragrunt --> Make: plan-all complete
Make -> terraform-compliance: (optional) validate plan.json
terraform-compliance --> Make: pass/fail
Make --> Operator: plan output + compliance results
```

## Related

- Architecture dynamic view: `gcp-dataplex-infra-containers`
- Related flows: [Terraform Infrastructure Provisioning](terraform-infrastructure-provisioning.md), [GCP Authentication and Service Account Impersonation](gcp-auth-and-sa-impersonation.md)
