---
service: "gcp-prometheus"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Component | Type | Interval | Timeout |
|---------------------|-----------|------|----------|---------|
| `/-/healthy` (port 10902) | Thanos Receive | http | 30s | 1s |
| `/-/ready` (port 10902) | Thanos Receive | http | 5s | 1s |
| `/-/healthy` (port 10902) | Thanos Query | http | 30s | 10s |
| `/-/ready` (port 10902) | Thanos Query | http | 5s | 10s |
| `/-/healthy` (port 10902) | Thanos Store Gateway | http | 30s | 30s |
| `/-/ready` (port 10902) | Thanos Store Gateway | http | 10s | 30s |
| `/-/healthy` (port 10902) | Thanos Compact | http | 30s | 1s |
| `/-/ready` (port 10902) | Thanos Compact | http | 5s | 1s |
| `/api/health` (port 3000, HTTPS) | Grafana | http | — | 30s |
| `pgrep filebeat` | Filebeat sidecar (all pods) | exec | 10s | 1s |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `thanos_receive_replication_factor` | gauge | Current replication factor for remote-write | < 1 |
| `thanos_store_series_total` | counter | Total series served by store gateway | — |
| `thanos_compact_blocks_cleaned_total` | counter | Blocks cleaned during compaction | — |
| `thanos_query_concurrent_requests` | gauge | Active concurrent queries | — |
| `prometheus_remote_storage_failed_samples_total` | counter | Failed remote-write samples to Thanos Receive | > 0 |
| `up` | gauge | Prometheus scrape target availability | == 0 for any critical target |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Logging Platform Elastic Stack (single cluster) | Wavefront | `https://groupon.wavefront.com/dashboard/logging_platform_elastic_stack_single_cluster` |
| Logging Platform Elasticsearch | Wavefront | `https://groupon.wavefront.com/dashboard/logging_platform_elasticsearch` |
| ELK Host Metrics | Wavefront | `https://groupon.wavefront.com/dashboard/elk_host_metrics` |
| Filebeat Status | Wavefront | `https://groupon.wavefront.com/dashboard/filebeat_status` |
| Filebeat Status by Cluster | Wavefront | `https://groupon.wavefront.com/dashboard/filebeat_status_by_cluster` |
| Kafka ELK | Wavefront | `https://groupon.wavefront.com/dashboard/kafka-elk` |
| Logging Platform Alerts | Wavefront | `https://groupon.wavefront.com/dashboard/logging_platform_alerts` |
| AWS Lambda Metrics | Wavefront | `https://groupon.wavefront.com/dashboard/aws-lambda-metrics` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Thanos Receive pod down | Pod not Ready for > 2 minutes | critical | Check pod logs; verify GCS connectivity and hashring config |
| Thanos Query timeout | Query latency exceeds 5m timeout | warning | Check Store Gateway health; consider `--query.partial-response` mode |
| GCS write failure | `prometheus_remote_storage_failed_samples_total` increasing | critical | Check `thanos-objectstorage` secret; verify GCS service account permissions |
| Grafana pod down | `/api/health` returns non-200 | warning | Check Grafana pod logs; verify database connectivity via `GF_DATABASE_URL` |
| Thanos Compact stalled | No blocks compacted in 24h | warning | Check Compact pod logs; verify GCS bucket consistency |

- PagerDuty service: `https://groupon.pagerduty.com/services/PPZ4I7E`
- On-call: `metrics-platform-team@groupon.pagerduty.com`
- Slack channel: `CFJGFTVRT`
- Support tickets: `https://logging-support.groupondev.com`

## Common Operations

### Restart Service

To restart a Thanos component (e.g., Thanos Receive):

```bash
kubectl rollout restart statefulset/thanos-receive -n telegraf-production
```

To restart Thanos Query:

```bash
kubectl rollout restart deployment/thanos-querier -n telegraf-production
```

To restart Grafana:

```bash
kubectl rollout restart deployment/grafana-ha -n <grafana-namespace>
```

### Scale Up / Down

Thanos Query (Deployment) supports horizontal scaling. Update replicas in `common.yml` and redeploy via `deploy-gcp.sh`. HPA is configured for staging (min: 5, max: 10 replicas).

Thanos Receive and Store Gateway are StatefulSets; scaling requires a Helm values update and redeployment to avoid hashring inconsistencies.

### Redeployment

```bash
# Staging US-Central1
bash .meta/deployment/cloud/scripts/deploy-gcp.sh staging-us-central1 staging

# Production US-Central1
bash .meta/deployment/cloud/scripts/deploy-gcp.sh production-us-central1 production
```

Krane applies the full rendered manifest with `--no-prune` (existing unmatched resources are not deleted). Timeout is 300 seconds.

### Database Operations

Grafana database migrations run automatically on startup. No manual migration steps are required. If migration fails, check `GF_DATABASE_URL` and `GF_DATABASE_MIGRATION_LOCKING=false`.

## Troubleshooting

### Thanos Receive pods not Ready

- **Symptoms**: `/-/ready` returns non-200; remote-write from Prometheus fails
- **Cause**: Hashring misconfiguration, GCS secret missing, or OOMKill
- **Resolution**: Check pod logs (`kubectl logs <pod> -c thanos-receive -n telegraf-production`); verify `thanos-objectstorage` secret exists; check PVC usage; verify `hashring-config` ConfigMap lists correct pod endpoints

### Thanos Query returning partial results

- **Symptoms**: Grafana dashboards show gaps or `partial response` warnings
- **Cause**: One or more Store Gateway shards or Thanos Receive pods unavailable
- **Resolution**: Identify unhealthy store endpoints in Thanos Query UI (`/stores`); check Store Gateway pod health and GCS connectivity; `--query.partial-response` allows query to succeed with partial data

### Grafana login failure (Okta)

- **Symptoms**: Users cannot log in; redirect to Okta fails or returns error
- **Cause**: Expired or incorrect `GF_AUTH_OKTA_CLIENT_ID` / `GF_AUTH_OKTA_CLIENT_SECRET`; redirect URL mismatch
- **Resolution**: Rotate Okta credentials in the `grafana` Kubernetes secret and redeploy. Verify `GF_AUTH_OKTA_REDIRECT_URL` matches the configured Okta application callback URL.

### Thanos Compact stuck or crashing

- **Symptoms**: Compact pod in CrashLoopBackOff; no recent compaction activity
- **Cause**: Malformed block index (mitigated by `--debug.accept-malformed-index`); GCS permission issue; conflicting time windows with another Compact instance
- **Resolution**: Check Compact logs; ensure only one Compact instance runs per time window; verify `thanos-objectstorage` secret is valid.

### GCS block writes failing

- **Symptoms**: `prometheus_remote_storage_failed_samples_total` increasing; Thanos Receive logs show GCS errors
- **Cause**: Expired GCS service account credentials; GCS bucket permissions changed
- **Resolution**: Rotate the GCS service account key in `thanos-objectstorage` secret; verify bucket IAM policy grants `roles/storage.objectAdmin` to the service account.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Metrics ingestion or query fully unavailable | Immediate | Metrics Team PagerDuty (`PPZ4I7E`) |
| P2 | Partial metric data loss or degraded queries | 30 min | Metrics Team (`CFJGFTVRT` Slack) |
| P3 | Single dashboard broken, non-critical store shard down | Next business day | Metrics Team email |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| GCS | GCP Console / `gsutil ls gs://<bucket>` | Thanos Receive buffers to local TSDB (1d retention); Store Gateway becomes read-only from cache |
| Okta | Okta status page | Grafana login unavailable; existing sessions may persist |
| Kafka (Filebeat) | `kubectl logs <pod> -c filebeat-metrics` | Log shipping stops; metrics collection unaffected |
| Kubernetes API | `kubectl get nodes` | Pod scheduling and service discovery fail; existing pods continue running |
