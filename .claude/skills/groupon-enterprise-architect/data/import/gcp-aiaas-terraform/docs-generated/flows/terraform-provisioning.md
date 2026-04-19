---
service: "gcp-aiaas-terraform"
title: "Terraform Infrastructure Provisioning"
generated: "2026-03-03"
type: flow
flow_name: "terraform-provisioning"
flow_type: synchronous
trigger: "Manual make command or Jenkins CI/CD pipeline on PR merge to main"
participants:
  - "Engineer / CI/CD (Jenkins)"
  - "Terragrunt CLI"
  - "GCP Terraform API"
  - "GCP Resource APIs (Cloud Run, Cloud Functions, Composer, etc.)"
architecture_ref: "containers-gcp-aiaas"
---

# Terraform Infrastructure Provisioning

## Summary

All GCP resources for the AIaaS platform are created and updated exclusively through Terraform/Terragrunt. An engineer (for dev) or Jenkins CI/CD (for prod) runs a sequence of Terragrunt commands against a specific module under `envs/<env>/us-central1/<module>/`. Terragrunt resolves the module source from the CloudCore `gcp-terraform-base` library, runs `terraform plan` to show the diff, then applies changes against the target GCP project. Dependencies between modules (e.g., `gcp-cloud-functions` depends on `gcp-buckets` outputs) are declared as Terragrunt `dependency` blocks and resolved automatically.

## Trigger

- **Type**: manual (dev) / CI/CD on PR merge (prod)
- **Source**: Engineer running `make <env>/us-central1/<module>/apply` in `envs/`, or Jenkins triggered by a merged PR to `main`
- **Frequency**: On-demand (when infrastructure changes are needed)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Engineer / Jenkins | Initiates the provisioning workflow | N/A |
| Terragrunt CLI | Orchestrates module resolution, dependency ordering, and Terraform execution | N/A |
| CloudCore `gcp-terraform-base` | Provides reusable Terraform module source code | N/A |
| GCP Terraform Provider | Translates HCL resource declarations into GCP API calls | N/A |
| GCP Resource APIs | Creates and updates the actual GCP resources (Cloud Run, Composer, BigQuery, etc.) | `continuumCloudRunService`, `continuumComposer`, `continuumBigQuery`, `continuumStorageBuckets`, etc. |

## Steps

1. **Authenticates with GCP**: Engineer runs `make <env>/us-central1/<module>/gcp-login` to establish GCP credentials (developer account for dev; service account `grpn-sa-terraform-aiaas` for prod).
   - From: Engineer
   - To: GCP IAM
   - Protocol: gcloud CLI / OIDC

2. **Resolves module source**: Terragrunt runs `bin/module-ref <module-name>` to resolve the `source` URL for the CloudCore Terraform module (pinned git tag for prod, latest for dev).
   - From: Terragrunt CLI
   - To: `github.groupondev.com/CloudCore/gcp-terraform-base`
   - Protocol: HTTPS (git)

3. **Resolves module dependencies**: Terragrunt reads `dependency` blocks in `terragrunt.hcl` (e.g., `gcp-cloud-functions` depends on `gcp-buckets` outputs such as `artifacts_bucket_name`) and fetches remote state outputs.
   - From: Terragrunt CLI
   - To: GCP remote Terraform state backend
   - Protocol: GCP SDK

4. **Runs terraform plan**: Terragrunt runs `terraform plan` with resolved inputs and environment variables; outputs the resource diff to stdout.
   - From: Terragrunt CLI
   - To: GCP Resource APIs (read-only)
   - Protocol: GCP REST API

5. **Reviews plan (prod)**: For prod deployments, a peer reviews the plan output in the PR and approves before Jenkins proceeds.
   - From: Peer reviewer
   - To: GitHub PR (review approval)
   - Protocol: GitHub PR workflow

6. **Applies changes**: Terragrunt runs `terraform apply`; the GCP Terraform provider calls GCP resource APIs to create, update, or delete resources.
   - From: Terragrunt CLI / GCP Terraform Provider
   - To: GCP Resource APIs (`continuumCloudRunService`, `continuumComposer`, `continuumBigQuery`, etc.)
   - Protocol: GCP REST API

7. **Updates remote state**: Terraform writes the updated resource state to the GCP remote backend for future plan/apply runs.
   - From: Terragrunt CLI
   - To: GCP remote Terraform state backend
   - Protocol: GCP SDK

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing GCP credentials | gcloud login / service account key absent | Authentication fails; Terragrunt exits with credential error |
| Module source resolution fails | `bin/module-ref` cannot reach `github.groupondev.com` | Terragrunt fails at source resolution step |
| `terraform plan` shows destructive change | Engineer/reviewer rejects apply | No changes applied; engineer revises HCL |
| `terraform apply` fails mid-way | Terraform locks state and reports partial apply | Resources may be in inconsistent state; re-running apply usually resolves; contact CloudCore if state is corrupted |
| SCP (Service Control Policy) violation | GCP API rejects resource creation | Apply fails with permission error; check with CloudCore for allowed resource types |

## Sequence Diagram

```
Engineer / Jenkins -> Terragrunt CLI        : make <env>/<region>/<module>/apply
Terragrunt CLI     -> module-ref script     : Resolve module source URL
module-ref         -> gcp-terraform-base    : Fetch Terraform module (HTTPS/git)
Terragrunt CLI     -> GCP state backend     : Read dependency remote state outputs
Terragrunt CLI     -> GCP Resource APIs     : terraform plan (read-only)
Terragrunt CLI     --> Engineer             : Display plan diff
Engineer           -> Terragrunt CLI        : Confirm apply (or Jenkins auto-apply on PR merge)
Terragrunt CLI     -> GCP Resource APIs     : terraform apply (create/update/delete resources)
GCP Resource APIs  --> Terragrunt CLI       : Resource operation results
Terragrunt CLI     -> GCP state backend     : Write updated state
```

## Related

- Terragrunt config root: `envs/`
- Module dependency example: `envs/dev/us-central1/gcp-cloud-functions/terragrunt.hcl` (depends on `gcp-buckets`)
- Related flows: [Scheduled Background Job](scheduled-background-job.md)
- Deployment details: [Deployment](../deployment.md)
