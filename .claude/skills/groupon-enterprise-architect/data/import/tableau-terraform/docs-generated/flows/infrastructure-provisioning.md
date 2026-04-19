---
service: "tableau-terraform"
title: "Infrastructure Provisioning"
generated: "2026-03-03"
type: flow
flow_name: "infrastructure-provisioning"
flow_type: synchronous
trigger: "Manual operator invocation of Make targets in envs/"
participants:
  - "tableauTerraformRunner"
  - "tableauInstanceGroup"
  - "tableauLoadBalancer"
  - "tableauStorageBucket"
  - "tableauCertificates"
architecture_ref: "dynamic-tableauTerraform"
---

# Infrastructure Provisioning

## Summary

This flow covers how an operator provisions or updates the full Tableau Server infrastructure in a target GCP environment. The operator runs Terragrunt via Make targets from the `envs/` directory. Terragrunt resolves module sources, reads environment HCL configuration files, authenticates to GCP by impersonating the Terraform service account, and applies the Terraform plan to create or update GCE instances, the load balancer, the GCS bucket, and TLS certificates.

## Trigger

- **Type**: manual
- **Source**: Operator runs `make <env>/us-central1/<module>/apply` from `envs/`
- **Frequency**: On demand — when infrastructure changes are needed

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator | Initiates Terragrunt commands via Make | — |
| Terraform Runner | Resolves modules, reads config, authenticates, plans, and applies changes | `tableauTerraformRunner` |
| GCP IAM / Service Account | Validates service account impersonation for `grpn-sa-terraform-tableau` | external |
| GCS State Bucket | Stores and locks Terraform state | `tableauStorageBucket` (state bucket is separate) |
| Tableau Instance Group | Target: GCE VMs and unmanaged instance group | `tableauInstanceGroup` |
| Tableau Load Balancer | Target: Internal TCP load balancer, backend service, health check, forwarding rule, DNS record | `tableauLoadBalancer` |
| Tableau Storage Bucket | Target: GCS bucket for backups/logs with lifecycle rules | `tableauStorageBucket` |
| Tableau TLS Certificates | Target: Self-managed certificate in GCP Certificate Manager | `tableauCertificates` |

## Steps

1. **Load environment configuration**: Terragrunt reads `envs/global.hcl`, `envs/<env>/account.hcl`, and `envs/<env>/us-central1/region.hcl` to resolve GCP project ID, project number, VPC, subnet, DNS zone, and environment stage.
   - From: `Operator`
   - To: `tableauTerraformRunner`
   - Protocol: Make / shell

2. **Authenticate to GCP**: Terraform uses the default `google` provider to generate a short-lived access token (3600 s) by impersonating `grpn-sa-terraform-tableau@<central-sa-project>.iam.gserviceaccount.com`.
   - From: `tableauTerraformRunner`
   - To: GCP IAM
   - Protocol: GCP REST API

3. **Pull remote state**: Terragrunt initialises the GCS backend and downloads the current Terraform state for the target module from `grpn-gcp-<PROJECTNAME>-state-<PROJECT_NUMBER>/<module-path>`.
   - From: `tableauTerraformRunner`
   - To: GCS state bucket
   - Protocol: GCS

4. **Resolve module source**: The `module-ref` script resolves the local module path (`modules/instance_group`, `modules/load-balancer`, `modules/bucket`, or `modules/certificates`) and Terragrunt generates `common.tf` in the working directory.
   - From: `tableauTerraformRunner`
   - To: Local filesystem
   - Protocol: shell

5. **Plan changes**: Terraform computes the diff between current state and desired state. After-hook exports the plan to `plan.json` via `terraform show -json plan.output`.
   - From: `tableauTerraformRunner`
   - To: GCP Compute/Storage/DNS/Certificate Manager APIs
   - Protocol: GCP REST API

6. **Apply changes**: Terraform applies the plan. Resources are created or updated in order: bucket first (its URL is a dependency for the instance group), then instance group, then load balancer.
   - From: `tableauTerraformRunner`
   - To: `tableauInstanceGroup`, `tableauLoadBalancer`, `tableauStorageBucket`, `tableauCertificates`
   - Protocol: GCP REST API (Terraform)

7. **Write updated state**: Terraform writes the updated state to the GCS state bucket and releases the state lock.
   - From: `tableauTerraformRunner`
   - To: GCS state bucket
   - Protocol: GCS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Service account impersonation denied | Terraform exits with IAM error | No changes applied; operator must fix IAM permissions and retry |
| GCS state lock held by another process | Terragrunt waits then fails with lock error | No changes applied; operator must break lock manually |
| Resource creation fails (e.g., quota exceeded) | Terraform exits; partial state may be written | Partial resources created; operator must diagnose and re-apply |
| Module not found (module-ref failure) | Make target fails with shell error | No Terraform invocation occurs |

## Sequence Diagram

```
Operator -> TerragruntRunner: make prod/us-central1/instance_group/apply
TerragruntRunner -> GCP_IAM: Request access token (impersonate grpn-sa-terraform-tableau)
GCP_IAM --> TerragruntRunner: Short-lived access token
TerragruntRunner -> GCS_StateBucket: Pull Terraform state + acquire lock
GCS_StateBucket --> TerragruntRunner: Current state
TerragruntRunner -> GCP_APIs: terraform plan (Compute, GCS, DNS, CertManager)
GCP_APIs --> TerragruntRunner: Current resource state
TerragruntRunner -> GCP_APIs: terraform apply (create/update resources)
GCP_APIs --> TerragruntRunner: Resources created/updated
TerragruntRunner -> GCS_StateBucket: Write updated state + release lock
TerragruntRunner --> Operator: Apply complete
```

## Related

- Architecture dynamic view: `dynamic-tableauTerraform`
- Related flows: [Primary Node Initialisation](primary-node-initialisation.md), [Worker Node Cluster Join](worker-node-cluster-join.md)
