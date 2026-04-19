---
service: "tableau-terraform"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| GCP Regional Health Check on port 80 | TCP | 5 seconds | 2 seconds |
| `https://analytics.groupondev.com/admin/systeminfo.xml` | HTTP (cron, every 5 min) | 5 minutes | — |
| Service availability ping to `analytics.groupondev.com` and `tableau.groupondev.com` | HTTP (cron, every 15 min) | 15 minutes | — |

## Monitoring

### Metrics

> No evidence found in codebase for Prometheus, Datadog, or Stackdriver custom metrics. Infrastructure-level GCP metrics (CPU, disk, network) are available through GCP Cloud Monitoring via the Ops Agent service account (`loc-sa-tableau-vm-ops-agent`).

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| GCP instance health check pass/fail | gauge | TCP health check on port 80 per instance | Failure removes instance from load balancer backend |
| Tableau process status (`/admin/systeminfo.xml`) | gauge | Any process with `status=Down` triggers email alert | Any process Down |

### Dashboards

> No evidence found in codebase. Monitoring dashboards are not defined in this repository.

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Tableau process Down | Any process `status=Down` in `systeminfo.xml` (checked every 5 min by `process_status_check_prod.py`) | warning | Email sent to `dnd-tools@groupon.com`; investigate via TSM or SSH to primary node |
| OpsGenie on-call | Service unavailable at `analytics.groupondev.com` or `tableau.groupondev.com` (checked every 15 min) | critical | OpsGenie on-call alerting; SSH to primary and run `tsm status` |

## Common Operations

### Restart Service

The daily automated restart runs at 04:00 GMT via the `restart.sh` cron script using `tableauadmin` user:

```bash
# On the primary VM as tableauadmin:
/path/to/tsm restart -u tableauadmin -p <password>
```

For a manual restart:
1. SSH to the primary VM as `tableaulogin`
2. Switch to `tableauadmin`
3. Run `tsm restart -u tableauadmin -p <password>`
4. Monitor `tsm status` until all processes report `Running`

### Scale Up / Down

Scaling requires a Terraform apply:

1. Edit `envs/<env>/us-central1/instance_group/cluster.json` — adjust `worker.instances` count
2. Run `make <env>/us-central1/instance_group/plan` and review the plan
3. Run `make <env>/us-central1/instance_group/apply`
4. After new worker VM starts, the startup script automatically joins the cluster using the bootstrap file from the primary node

### Backup Operations

Backups are created daily at 01:30 GMT by the `tableau_ENV_maintenance.sh` cron script and stored in the GCS bucket under `backups/`. To restore:

1. Identify the backup archive in `gs://grpn-tableau-<env>-bucket/backups/`
2. Download the archive to the primary VM
3. Use TSM to restore: `tsm maintenance restore --file <backup-file>`

### Apply Infrastructure Changes

```bash
cd envs
# Plan changes for a specific module
make prod/us-central1/instance_group/plan
# Apply
make prod/us-central1/instance_group/apply
```

## Troubleshooting

### Tableau Process Reported as Down
- **Symptoms**: Email alert from `process_status_check_prod.py`; `systeminfo.xml` shows `status=Down` for one or more processes
- **Cause**: Process crash, resource exhaustion, or configuration issue
- **Resolution**: SSH to primary VM; run `tsm status` to identify the failing process; run `tsm restart` or restart the individual service with `tsm services restart <process-name>`

### Worker Node Did Not Join Cluster
- **Symptoms**: Tableau cluster shows fewer worker nodes than expected; worker VM exists but processes are not running
- **Cause**: Worker startup script polls for `/home/tableaulogin/bootstrap_primary_node.json`; if the primary node has not finished initialisation the worker waits; SSH or bootstrap file copy may have failed
- **Resolution**: SSH to worker VM; check `/home/tableau/install.log`; verify `bootstrap_primary_node.json` is present at `/home/tableaulogin/`; if missing, SCP it from the primary node manually and re-run the `initialize_worker` function

### Terraform Apply Fails Due to Service Account Permission Error
- **Symptoms**: Terraform plan/apply exits with a GCP IAM permission denied error
- **Cause**: The Terraform service account (`grpn-sa-terraform-tableau`) is missing a required IAM role, or the operator's credentials cannot impersonate the service account
- **Resolution**: Verify GCP login with `gcloud auth list`; confirm the operator account is in the correct LDAP/Google group; contact CloudCore team to verify service account role bindings

### Startup Script Fails to Download Tableau RPM
- **Symptoms**: `/home/tableau/install.log` shows `curl` failure; Tableau Server is not installed
- **Cause**: Network connectivity issue from the VM to `downloads.tableau.com`, or the RPM URL has changed
- **Resolution**: Verify the VM can reach the internet via Cloud NAT; update the `tableau_server_url` in `modules/template/common.tf` if the version URL has changed; re-run the startup script or reprovision the VM

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Tableau Server completely unavailable (`analytics.groupondev.com` unreachable) | Immediate | `dnd-tools@groupon.com`, OpsGenie on-call |
| P2 | Some Tableau processes Down; degraded functionality | 30 min | `dnd-tools@groupon.com` |
| P3 | Minor issues (single worker unhealthy, non-critical process Down) | Next business day | `dnd-tools@groupon.com` |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| GCP Compute Engine | GCE instance status in GCP Console; `gcloud compute instances list` | No automatic fallback; manual Terraform reprovisioning required |
| GCS bucket | `gsutil ls gs://grpn-tableau-<env>-bucket` | No fallback; backups unavailable |
| LDAP / Active Directory (`use2-ldap-vip.group.on`) | `tsm user-identity-store verify-user-mappings -v svc_tableaubind` | No fallback; user authentication fails |
| Internal Load Balancer | GCP health check on port 80; `gcloud compute backend-services get-health` | No fallback; all traffic blocked |
