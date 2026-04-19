---
service: "gcp-dataplex-infra"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

> No evidence found in codebase.

`gcp-dataplex-infra` does not run as a service and has no health check endpoints. Health of provisioned resources can be verified directly via GCP Console or the Dataplex/GCS APIs.

| Mechanism | Type | Description |
|-----------|------|-------------|
| GCP Console — Dataplex Data Catalog | manual | Verify that entry types (`teradata-table`, `teradata-database`, `teradata-view`, `teradata-column`) and entry group (`teradata-dataplex`) exist in project `prj-grp-data-cat-stable-0b72`, region `us-central1` |
| GCP Console — Cloud Storage | manual | Verify that bucket `grpn-dataplex-catalog-stable-storage` exists and is accessible |
| `terraform plan` drift check | exec | Run `make stable/us-central1/plan` and confirm output shows "No changes" for a clean state |

## Monitoring

### Metrics

> No evidence found in codebase. No application metrics are emitted by this IaC repository.

GCP-level monitoring (Cloud Monitoring / Stackdriver) for the provisioned resources is managed separately at the GCP project level.

### Dashboards

> Operational procedures to be defined by service owner.

### Alerts

> Operational procedures to be defined by service owner.

## Common Operations

### Apply Infrastructure Changes

1. Authenticate with GCP: `cd envs && make stable/gcp-login`
2. Review planned changes: `make stable/us-central1/plan`
3. Inspect generated `plan.json` to confirm expected resource changes
4. Apply changes: `make stable/us-central1/APPLY`
5. Revoke credentials: `make stable/gcp-logout`

### Validate Configuration Without Applying

```
cd envs
make stable/us-central1/validate
```

This runs `terraform validate-all` on all modules without creating, modifying, or destroying any GCP resources.

### Check for Terraform State Drift

```
cd envs
make stable/us-central1/plan
```

Review `plan.output` / `plan.json`. If the plan shows unexpected changes, investigate whether GCP resources were modified out-of-band.

### Destroy Infrastructure

> Exercise extreme caution. Destroying Dataplex entry types that are in use by the Data Catalog will break any registered assets that reference them.

1. Review what will be destroyed: `make stable/us-central1/plan-destroy-all`
2. Confirm destruction: `make stable/us-central1/DESTROY-ALL` (requires interactive confirmation)

### Scale Up / Down

> Not applicable. Provisioned resources are GCP managed services; scaling is not a concern.

### Database Operations

> Not applicable. No relational databases are managed by this repository.

## Troubleshooting

### Terraform Authentication Failure

- **Symptoms**: `Error: error configuring Terraform AWS Provider: error validating provider credentials` or GCP permission denied errors during plan/apply
- **Cause**: Application Default Credentials are missing, expired, or the service account impersonation token has expired (lifetime: 3600s)
- **Resolution**: Re-authenticate with `make stable/gcp-login`, then retry the plan/apply

### Terraform State Lock

- **Symptoms**: `Error: Error acquiring the state lock` — another operation is in progress or a previous operation did not release the lock
- **Cause**: Concurrent Terraform operations or a crashed apply that did not clean up the GCS state lock
- **Resolution**: Verify no other apply is running; if confirmed stale, use `terraform force-unlock <LOCK_ID>` with the lock ID shown in the error message

### Resource Already Exists (Entry Type Conflict)

- **Symptoms**: `Error: googleapi: Error 409: Resource 'teradata-table' already exists` during apply
- **Cause**: A Dataplex entry type with the same ID was created outside of Terraform
- **Resolution**: Import the existing resource into Terraform state with `terraform import google_dataplex_entry_type.<resource_name> <resource_path>`, then re-run apply

### Plan Shows Unexpected Deletions

- **Symptoms**: `terraform plan` proposes deleting resources that should remain
- **Cause**: State file out of sync with actual GCP state (e.g., state bucket modified, resources manually deleted)
- **Resolution**: Run `terraform refresh` to reconcile state, then re-plan; investigate any manual changes in GCP Console

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | GCP Dataplex Data Catalog entirely unavailable for data asset registration | Immediate | analytics@groupon.com (dnd-tools) |
| P2 | Infrastructure drift detected — provisioned resources no longer match Terraform state | 30 min | analytics@groupon.com (dnd-tools) |
| P3 | Minor configuration discrepancy; no immediate data pipeline impact | Next business day | analytics@groupon.com (dnd-tools) |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Google Cloud Dataplex API | Check GCP status dashboard at status.cloud.google.com | Existing entry types and entry groups remain intact; new provisioning blocked until API is available |
| Google Cloud Storage API | Check GCP status dashboard at status.cloud.google.com | Existing GCS bucket contents are unaffected; Terraform remote state operations blocked |
| GCP IAM (service account) | Verify SA `grpn-sa-terraform-data-catalog` exists and has necessary roles in `prj-grp-central-sa-stable-66eb` | No Terraform operations can proceed without SA; manual GCP Console access may be used as emergency fallback |
