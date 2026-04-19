---
service: "gcp-aiaas-terraform"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /v1/healthCheck` | HTTP (via API Gateway) | Platform heartbeat — monitored via Wavefront | N/A |
| Airflow Scheduler Heartbeat | Wavefront metric | Continuous (Wavefront polling) | Alert fires when heartbeat stops |
| GCP CPU / Memory / Disk stats | Wavefront metrics (pre-configured DAG) | Continuous | Per alert thresholds below |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Airflow Scheduler Heartbeat | gauge | Ping success of GCP Airflow instance; forwarded to Wavefront | Any heartbeat gap (alert: `1592332282787`) |
| Airflow Disk Space | gauge | Disk usage on Airflow host (10 GB total storage limit) | 80% full (alert: `1646674970684`) |
| Airflow CPU Usage | gauge | CPU utilisation on Airflow host | Sustained high CPU (alert: `1646673557191`) |
| Airflow Memory Usage | gauge | Memory utilisation on Airflow host | Sustained high memory (alert: `1646673764895`) |
| Ephemeral Dataproc Deploy | counter | Success/failure of Dataproc bootstrapping | Any failure (severity 2) |
| Ephemeral Dataproc Query | counter | Success/failure of Dataproc Spark queries | Any failure (severity 2) |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| DSSI ML Toolkit | Wavefront | https://groupon.wavefront.com/dashboards/dssi-ml-toolkit |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Airflow - No Disk Space | Disk usage >= 80% on Airflow host | 5 (critical) | See [Airflow - No Disk Space](#airflow---no-disk-space) |
| Airflow - No Scheduler Heartbeats | Scheduler has stopped sending heartbeats | 5 (critical) | See [Airflow - No Scheduler Heartbeats](#airflow---no-scheduler-heartbeats) |
| Airflow - High CPU Usage | Sustained high CPU on Airflow host | 5 (critical) | See [Airflow - High CPU / Memory Usage](#airflow---high-cpu--memory-usage) |
| Airflow - High Memory Usage | Sustained high memory on Airflow host | 5 (critical) | See [Airflow - High CPU / Memory Usage](#airflow---high-cpu--memory-usage) |
| Ephemeral Dataproc - Failed to deploy | Dataproc bootstrapping failed | 2 (warning) | See [Ephemeral Dataproc - Failed to Deploy](#ephemeral-dataproc---failed-to-deploy) |
| Ephemeral Dataproc - Query Failed | Spark query failed on Dataproc cluster | 2 (warning) | See [Ephemeral Dataproc - Query Failed](#ephemeral-dataproc---query-failed) |

## Common Operations

### Restart Service

To restart the full platform or individual GCP resources:

1. Navigate to `envs/` directory
2. Authenticate: `make <env>/us-central1/<module>/gcp-login`
3. Destroy the target resource: `make <env>/us-central1/<module>/destroy`
   - If destroy fails mid-way, run the destroy command again
4. Re-apply the resource: `make <env>/us-central1/<module>/apply`
5. Requires `grpn-dnd-dssi-af` role; contact `@cloudcore` in Slack for access

For a full platform restart, run `DESTROY ALL` then `APPLY` following `gcp-terraform-base` instructions.

### Scale Up / Down

- **Cloud Composer workers**: Edit `min_count` / `max_count` in `envs/<env>/account.hcl` and apply via `make <env>/us-central1/gcp-composer/apply`
- **Vertex AI endpoints**: Update the autoscaling policy in the service's ADM and apply the `gcp-vertex-ai` module; GCP recommender suggests optimal instance types
- **Cloud Run**: Update `image_extraction_max_instances` / `image_extraction_min_instances` in `envs/<env>/us-central1/gcp-cloud-run/terragrunt.hcl` and apply
- **Dataproc**: Up to 25 workers can be configured per cluster (default 10); update the worker count in the DAG definition (not Terraform)

### Database Operations

- BigQuery datasets and tables are managed entirely via Terraform (`gcp-big-query` module)
- To add tables: update the `gcp-big-query` Terraform module and apply
- Schema changes are performed within the module; no separate migration tooling is used
- `delete_contents_on_destroy = false` is set in prod to prevent accidental data loss

## Troubleshooting

### Airflow - No Disk Space

- **Symptoms**: Wavefront alert `1646674970684` fires; disk usage >= 80% on Airflow host
- **Cause**: Task logs or large files filling the 10 GB GCP-managed Airflow storage
- **Resolution**:
  1. Use `df` (via Bash Operator DAG) to identify full disk
  2. Use `du -sh ./*` to locate large directories
  3. Remove confirmed-unnecessary large files
  4. If logs are the source, investigate the operator producing excessive logs
  5. For persistent issues: contact GCP Support (log maintenance is GCP-managed)

### Airflow - No Scheduler Heartbeats

- **Symptoms**: Wavefront alert `1592332282787` fires; DAGs not scheduling
- **Cause**: Airflow scheduler process crashed or host is unreachable
- **Resolution**:
  1. Check `#production` Slack channel for broader outage
  2. If host is running, trigger an environment update via Terraform
  3. If host is not running, destroy and redeploy Dataproc via Terraform
  4. If metrics are missing but service is healthy, investigate Wavefront metric pipeline
  5. Escalate to GCP Support if above steps fail

### Airflow - High CPU / Memory Usage

- **Symptoms**: Wavefront alerts `1646673557191` / `1646673764895` fire; DAGs slow or failing
- **Cause**: CPU/memory-intensive DAGs (`PythonOperator`, `BashOperator`), too many concurrent DAGs, or runaway process
- **Resolution**:
  1. Check Wavefront for which metrics are elevated
  2. Temporarily disable non-critical DAGs in the Airflow UI
  3. Run `airflow list_dags -r` (via BashOperator) to check DAG read times
  4. Identify high-resource DAG or task and notify the DAG owner
  5. Trigger a dummy environment update via Terraform to restart MWAA if needed

### Ephemeral Dataproc - Failed to Deploy

- **Symptoms**: Dataproc cluster fails to bootstrap; Airflow task marked failed
- **Cause**: Invalid bootstrap script, disallowed instance types, insufficient spot instances, or SCP violation
- **Resolution**:
  1. Compare configuration against the environment template in `envs/.environment-template/`
  2. Check with CloudCore that instance types are allowed by SCPs
  3. Ensure a fallover policy exists if spot instances are used
  4. Inspect the bootstrap script for invalid shell syntax
  5. Contact GCP Support if none of the above applies

### Ephemeral Dataproc - Query Failed

- **Symptoms**: Spark SQL query fails on Dataproc cluster
- **Cause**: Spark container too small for the SQL operation; out-of-memory error
- **Resolution**:
  1. Increase Dataproc instance count in the DAG configuration
  2. Check Dataproc logs in the Kibana cluster (Filebeat forwards logs from Dataproc bootstrap)
  3. Review GCP logs at `console.cloud.google.com/storage/browser/dataproc-staging-us-central1-364685817243-joxbkjlz/`

### Cloud Run Endpoint Failures

| Error | Cause | Resolution |
|-------|-------|-----------|
| HTTP 400 Bad Request | Missing or malformed request parameters | Verify caller is sending all required JSON fields |
| HTTP 403 Forbidden | Missing or invalid API key | Check API Gateway API key configuration and caller headers |
| HTTP 415 Unsupported Media Type | Request body not sent as `application/json` | Ensure `Content-Type: application/json` header is present |
| HTTP 424 Gateway Model Error | Application error inside Cloud Run container | Check Cloud Run application logs; debug and redeploy |
| HTTP 503 Service Unavailable | Application unavailable or capacity limit reached | Check API Gateway throttle settings; if no outage, delete and redeploy the endpoint via Terraform |

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Platform fully down (all endpoints returning 5xx, Airflow scheduler dead) | Immediate | DSSI team (cs_ds@groupon.com), PagerDuty `PREMYX7`, Slack `C0258LWGX44` |
| P2 | Degraded (individual endpoint or DAG failures, high resource utilisation) | 30 min | DSSI on-call via PagerDuty |
| P3 | Minor impact (non-critical endpoint failure, Dataproc query failure) | Next business day | DSSI team via Slack `C0258LWGX44` |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| GCP Vertex AI | GCP status page / Cloud Monitoring | Inference fails; retry per caller implementation |
| GCP BigQuery | GCP status page / Airflow task retries | DAG tasks fail and retry per Airflow retry config |
| GCP Cloud Composer | Wavefront Scheduler Heartbeat alert | Restart via Terraform destroy + apply |
| DAAS PostgreSQL | N/A (no health check configured) | Cloud Functions dependent on DAAS fail; investigate DB host connectivity |
| Wavefront | N/A | Monitoring blind spot; no functional impact on platform |

> For production deployment, always create a GPROD logbook ticket in JIRA before applying changes.
