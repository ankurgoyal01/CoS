---
service: "ghe-gcp-migration"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| GCP Load Balancer backend health check (Nginx) | HTTP (port 80) | Configured by GCP backend service defaults | 30 sec timeout per `google_compute_backend_service` |
| GCP Load Balancer backend health check (GHE SSH) | TCP (port 22/122) | Configured by GCP backend service defaults | 30 sec timeout per `google_compute_backend_service` |
| SSH connectivity to `nginx-core` | tcp | Manual | — |
| SSH connectivity to `github-core` | tcp | Manual | — |

> Operational procedures to be defined by service owner. No application-level health endpoint configuration is present in this Terraform repository.

## Monitoring

### Metrics

> No evidence found in codebase.

GCP native monitoring (Cloud Monitoring) applies to all provisioned GCE instances and load balancers by default. No custom metric definitions are configured in this repository.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| GCE Instance metrics (cpu, disk, network) | GCP Cloud Monitoring | GCP Console — project `prj-grp-general-sandbox-7f70` |
| Load Balancer metrics (requests, latency, error rate) | GCP Cloud Monitoring | GCP Console — Load Balancing section |

### Alerts

> No evidence found in codebase.

No alerting rules are configured in this Terraform repository. Alerts should be configured in GCP Cloud Monitoring or an external observability platform by the service owner.

## Common Operations

### Restart Service

To restart the GitHub Enterprise application:

1. SSH into the `github-core` instance using the provisioned SSH key: `ssh -i ~/.ssh/id_ed25519 <external-ip>`
2. Follow the GHE admin console or CLI procedures to restart GHE services
3. Alternatively, restart the GCE instance via GCP Console or `gcloud compute instances reset github-core --zone us-central1-b`

To restart the Nginx proxy:

1. SSH into the `nginx-core` instance: `ssh -i ~/.ssh/id_ed25519 <external-ip>`
2. Restart the Nginx service: `sudo systemctl restart nginx`

### Scale Up / Down

Scaling is managed by the GCP Autoscaler on the `github-core-manager` managed instance group.

- **Autoscaler bounds**: min 1, max 3 replicas; scales at 60% CPU utilization
- To manually adjust bounds, update `autoscaling_policy.min_replicas` or `autoscaling_policy.max_replicas` in `modules/compute/main.tf` and run `terraform apply`
- To scale Nginx (currently manual), add an instance group manager to `modules/compute/main.tf` (commented-out template exists)

### Database Operations

> No evidence found in codebase.

GitHub Enterprise manages its own internal database (MySQL). Database operations are performed through the GHE admin console or `ghe-dbconsole` CLI on the `github-core` instance. Terraform does not manage GHE application-level database operations.

## Troubleshooting

### Terraform Apply Fails — GCP Authentication Error
- **Symptoms**: `Error: google: could not find default credentials` or `Error 403: Access Not Configured`
- **Cause**: `GOOGLE_APPLICATION_CREDENTIALS` is not set, points to an invalid file, or the service account lacks required IAM roles
- **Resolution**: Set `GOOGLE_APPLICATION_CREDENTIALS` to a valid service account key JSON path; verify the service account has `Compute Admin`, `Service Account User`, and `Network Admin` roles on project `prj-grp-general-sandbox-7f70`

### GHE Instance Unreachable After Apply
- **Symptoms**: Cannot reach GitHub Enterprise web interface or SSH on the external IP
- **Cause**: Firewall rules may not include the client IP, the load balancer forwarding rules may not yet have propagated, or the GHE boot sequence is still in progress
- **Resolution**: Verify client IP is in the `allow-world-access` allowlist in `modules/firewall/main.tf`; check GCP Load Balancer backend health status in GCP Console; wait 2–5 minutes for GHE to complete initial boot

### External Disk Not Mounted
- **Symptoms**: GitHub Enterprise data unavailable; disk device `external-disk` not visible inside VM
- **Cause**: GCE attached disk may not be formatted or mounted by the GHE startup scripts
- **Resolution**: SSH into `github-core`; verify disk is attached with `lsblk`; follow GHE documentation to attach and configure the data volume

### Autoscaler Spinning Up Extra Replicas
- **Symptoms**: More than 1 GHE instance running unexpectedly; storage conflicts
- **Cause**: CPU utilization exceeded 60% threshold; autoscaler launched additional replicas
- **Cause note**: Multiple GHE replicas sharing a single persistent disk (`github-core-external-disk`) may cause data corruption
- **Resolution**: Investigate CPU load on the primary instance; consider raising CPU target or switching to a larger machine type; remove extra replicas manually if disk sharing is causing issues

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | GitHub Enterprise completely unreachable — no git push/pull, no web access | Immediate | github team / Platform on-call |
| P2 | GitHub Enterprise degraded — slow response, SSH unreachable but web accessible | 30 min | github team |
| P3 | Minor impact — Nginx proxy errors, individual feature unavailable | Next business day | github team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| GCP Compute API | `gcloud compute instances list --project prj-grp-general-sandbox-7f70` | No fallback — GCP is the sole provider |
| GCP Load Balancer | GCP Console → Load Balancing → Backend health | Route SSH directly to instance IP as emergency workaround |
| GitHub Enterprise image (`github-enterprise-public/github-enterprise-3-10-6`) | Verify image exists: `gcloud compute images list --project github-enterprise-public` | Pin to a known-good image version in `terraform.tfvars` |
