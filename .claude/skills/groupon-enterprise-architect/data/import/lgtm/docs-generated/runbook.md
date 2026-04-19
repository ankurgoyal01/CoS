---
service: "lgtm"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Kubernetes pod readiness probe (Tempo components) | http | Defined by Helm chart defaults | Defined by Helm chart defaults |
| Kubernetes pod liveness probe (OTel Collector) | http | Defined by Helm chart defaults | Defined by Helm chart defaults |
| Grafana Tempo Gateway availability | tcp / http | Cluster-level | — |

> Operational procedures to be defined by service owner. Specific probe paths and intervals are inherited from the upstream Helm chart defaults for `tempo-distributed` v1.32.0 and `opentelemetry-collector` v0.115.0.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| OTel Collector received spans | counter | Total spans received by the OTLP receivers (gRPC + HTTP) | Operational procedures to be defined by service owner |
| OTel Collector exported spans | counter | Total spans successfully exported to Tempo and Elastic APM | Operational procedures to be defined by service owner |
| Tempo ingester flush latency | histogram | Time taken to flush trace blocks from memory to GCS | Operational procedures to be defined by service owner |
| Tempo querier query duration | histogram | Latency for trace query requests from Grafana | Operational procedures to be defined by service owner |
| HPA replica count (OTel Collector) | gauge | Current replica count — min 1, max 10 | Operational procedures to be defined by service owner |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Trace Search | Grafana (Tempo datasource) | `/d/` (internal Grafana instance; see `grafana/dashboards/traces.json`) |
| Trace Detail | Grafana (Tempo datasource) | `/d/cdjp318r07nr4c/03-trace-detail` (linked from Trace Search dashboard) |

The Grafana trace dashboards are defined in `grafana/dashboards/traces.json` (trace list) and `grafana/dashboards/trace_details.json` (trace detail). The trace detail dashboard links are parameterised by `var-job` and `var-traceId`.

### Alerts

> Operational procedures to be defined by service owner. No alert rules are defined in this repository. Alerting is expected to be configured in the metrics stack (Thanos/Alertmanager) or Grafana alerting.

## Common Operations

### Restart Service

To restart the OTel Collector or a Tempo component, perform a rolling restart of the relevant Kubernetes Deployment or StatefulSet in the target namespace (`tempo-staging` or `tempo-production`):

```
kubectl rollout restart deployment/otel-collector -n tempo-staging
kubectl rollout restart deployment/tempo-distributor -n tempo-staging
```

For a full re-deploy via the pipeline, trigger the Jenkins job on the appropriate branch, or use DeployBot to promote staging to production.

### Scale Up / Down

Scaling is managed by HPA. To manually override:

1. Adjust `minReplicas` / `maxReplicas` in the relevant Helm values file (`common.yml` or environment override)
2. Re-run the deploy script: `bash .meta/deployment/cloud/scripts/deploy.sh <env> <namespace>`

Alternatively, use `kubectl scale` for a temporary override (will be reconciled on next deploy).

### Database Operations

GCS buckets are managed by GCP and require no schema migrations. Tempo compaction is automatic — the `compactor` component handles block merging. Manual compaction is not typically required.

To verify GCS bucket contents:
- Use `gsutil ls gs://<bucket-name>/` with the appropriate GCP service account credentials.

## Troubleshooting

### Traces not appearing in Grafana

- **Symptoms**: Grafana trace search returns no results or stale data
- **Cause**: OTel Collector may not be receiving spans, Tempo Gateway may be down, or the Grafana data source configuration is incorrect
- **Resolution**: Check OTel Collector pod logs for export errors; verify Tempo Gateway pod is running and the service endpoint matches the OTel Collector's `otlphttp/tempo` exporter URL; confirm Grafana data source is pointed to the correct Tempo query endpoint

### OTel Collector crashing or restarting

- **Symptoms**: Pods in CrashLoopBackOff; traces and metrics not being forwarded
- **Cause**: Invalid Helm values configuration, downstream exporter unreachable, or OOM
- **Resolution**: Check `kubectl logs` for the OTel Collector pod; verify exporter endpoints in the environment-specific values file; check HPA status for resource pressure

### GCS write failures (Tempo ingester)

- **Symptoms**: Tempo ingester logs show GCS write errors; traces ingested but not queryable
- **Cause**: Workload Identity misconfiguration, GCS bucket permissions, or GCS bucket does not exist
- **Resolution**: Verify the GCP service account annotation on the Tempo service account (`iam.gke.io/gcp-service-account`); confirm the bucket name matches the environment values file; check GCP IAM permissions for the service account

### Metrics not arriving in Thanos

- **Symptoms**: Metrics dashboards show gaps; Thanos remote write endpoint returning errors
- **Cause**: `prometheusremotewrite` exporter endpoint misconfigured or Thanos receive is unavailable
- **Resolution**: Check the `prometheusremotewrite.endpoint` in the relevant environment values file; verify Thanos receive pod is running in the `telegraf-staging` or `telegraf-production` namespace

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Trace ingestion completely stopped — no traces reaching Tempo | Immediate | Platform Engineering |
| P2 | Partial loss — one region or one pipeline degraded | 30 min | Platform Engineering |
| P3 | Grafana dashboard slowness or stale data | Next business day | Platform Engineering |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| GCS (Tempo storage) | Check Tempo ingester logs for flush errors; `gsutil ls` on the bucket | No fallback — trace data not persisted if GCS is down |
| Elastic APM (Oxygen pipeline) | Check OTel Collector logs for `otlp/elastic` exporter errors | Traces still flow to Tempo; only Oxygen-specific APM routing is affected |
| Thanos (metrics) | Check OTel Collector logs for `prometheusremotewrite` exporter errors | Metrics are dropped; no persistent buffer |
| Tempo Gateway | `kubectl get pods -n tempo-staging` or `tempo-production` | OTel Collector will queue and retry up to its buffer limits |
