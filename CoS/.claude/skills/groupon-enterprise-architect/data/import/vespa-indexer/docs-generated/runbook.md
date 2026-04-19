---
service: "vespa-indexer"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/healthcheck` | http | Kubernetes probe interval (default) | Kubernetes probe timeout |
| `GET /grpn/health` | http | On demand | On demand |

- `/grpn/healthcheck` is used by Kubernetes readiness and liveness probes (configured on port 8080 in `common.yml`).
- `/grpn/health` returns Vespa connectivity status, active thread count, and process info; useful for operator investigations.

## Monitoring

### Metrics

Prometheus metrics are exposed at `/metrics` via `prometheus_fastapi_instrumentator` 7.0.0 and scraped every 60 seconds by a Prometheus sidecar. Metrics are remote-written to Thanos (`thanos-receive.telegraf-<env>.svc:19291`).

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `http_requests_total` | counter | Total HTTP requests by method, status, handler | Operational |
| `http_request_size_bytes` | histogram | Request sizes | Operational |
| `process_cpu_seconds_total` | counter | CPU usage | Operational |
| `process_resident_memory_bytes` | gauge | Resident memory usage | Operational |
| `python_gc_objects_collected_total` | counter | Python GC collected objects | Operational |
| MessageBus messages received | counter | Messages received from `jms.topic.mars.mds.genericchange` | To be defined by service owner |
| MessageBus messages processed | counter | Successfully processed messages | To be defined by service owner |
| MessageBus messages acked | counter | ACKed messages | To be defined by service owner |
| MessageBus messages nacked | counter | NACKed (failed) messages | To be defined by service owner |
| Vespa indexing duration | histogram | Time taken to write documents to Vespa | To be defined by service owner |
| MDS REST API calls | counter | Calls to MDS REST API | To be defined by service owner |
| Scheduler job duration (`deal_refresh`, `feature_refresh`) | histogram | CronJob-triggered job duration tracked by `SchedulerJobMetricsTracker` | To be defined by service owner |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Vespa Indexer | Prometheus / Grafana | Operational procedures to be defined by service owner |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High NACK rate | MessageBus nacked messages rising | warning | Check logs for parsing errors; verify MessageBus connectivity |
| Vespa unhealthy | `/grpn/health` returns `vespa: unhealthy` | critical | Verify Vespa cluster health; check `VESPA_URL` configuration |
| CronJob missed schedule | CronJob not completed within `startingDeadlineSeconds` (3600 s) | warning | Check Kubernetes CronJob events; re-trigger manually if needed |
| CronJob backoff exhausted | `backoffLimit` (2) exceeded | critical | Inspect job pod logs; fix root cause; delete failed job and re-trigger |

> Specific alert thresholds and Grafana/PagerDuty routing are to be defined by the service owner (relevance-infra@groupon.com).

## Common Operations

### Restart Service

```bash
kubectl rollout restart deployment/vespa-indexer-app -n vespa-indexer-<env>
kubectl rollout status deployment/vespa-indexer-app -n vespa-indexer-<env>
```

### Scale Up / Down

Production scaling is controlled by HPA (minReplicas=6, maxReplicas=10). To temporarily override:
```bash
kubectl scale deployment/vespa-indexer-app --replicas=<N> -n vespa-indexer-production
```
Update `production-us-central1.yml` and re-deploy for permanent changes.

### Trigger Deal Refresh Manually

```bash
curl -X POST http://<service-url>/scheduler/refresh-deals
```

### Trigger Feature Refresh Manually

```bash
curl -X POST http://<service-url>/scheduler/refresh-features
```

### Index Specific Deals On Demand

```bash
curl -X POST http://<service-url>/indexing/index-deals \
  -H "Content-Type: application/json" \
  -d '{"deal_uuids": ["<uuid1>", "<uuid2>"]}'
```
Maximum 50 UUIDs per request.

### Database Operations

This service does not own any database. Vespa document management (schema changes, content cluster operations) is handled by the Vespa platform team.

## Troubleshooting

### MessageBus Consumer Not Processing Messages

- **Symptoms**: No new Vespa documents created or updated after deal changes; NACK metric rising
- **Cause**: MessageBus connection dropped, authentication failure, or malformed message payload
- **Resolution**: Check pod logs for `stomp.py` connection errors; verify `MBUS_HOST`, `MBUS_PORT`, `MBUS_USERNAME`, `MBUS_PASSWORD` are correct; restart the pod to re-establish the STOMP connection

### Deal Refresh CronJob Failing

- **Symptoms**: CronJob pod in `Error` or `OOMKilled` state; Vespa index stale
- **Cause**: GCS feed file not available; MDS REST API unavailable; Vespa write errors; memory pressure during large feed processing
- **Resolution**: Check pod logs from the CronJob pod and from the main service pod (background job logs); verify GCS bucket (`GCP_BUCKET_NAME`) contains the feed file; verify MDS REST API reachability; re-trigger manually via `POST /scheduler/refresh-deals`

### Feature Refresh CronJob Failing

- **Symptoms**: Vespa documents have stale `fs_*` feature values; BigQuery query errors in logs
- **Cause**: BigQuery table unavailable or schema change; credentials expired
- **Resolution**: Verify `DEAL_FEATURE_TABLE`, `DEAL_OPTION_FEATURE_TABLE`, `DEAL_DISTANCE_BUCKET_TABLE` are correct and accessible; check GCP service account permissions; re-trigger manually via `POST /scheduler/refresh-features`

### Vespa Writes Failing (Unicode Errors)

- **Symptoms**: Vespa HTTP API returning 400 errors; log messages about Unicode or parsing errors
- **Cause**: Control characters in deal text fields bypassing the `clean_unicode_string()` sanitiser
- **Resolution**: Check which deal UUID caused the failure in logs; the `SearchIndexAdapter._transform_option_to_vespa_document()` method applies unicode cleaning — verify the cleaning logic handles the offending character class

### High Memory Usage

- **Symptoms**: Pod OOMKilled or approaching memory limit (3 Gi in production)
- **Cause**: Large GCS feed file held in memory; or excessive concurrent feature refresh tasks
- **Resolution**: Reduce `FEATURE_REFRESH_MAX_WORKERS`; verify the GCS streaming uses 8 MB chunk downloads (not full file load); scale the deployment if needed

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Vespa index not updating — search results stale for all users | Immediate | relevance-infra@groupon.com |
| P2 | CronJob failing — scheduled refresh not completing | 30 min | relevance-infra@groupon.com |
| P3 | Feature refresh delayed — ML signals temporarily stale | Next business day | relevance-infra@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Vespa Cluster | `GET /grpn/health` → `services.vespa` field | No automatic fallback; indexing will fail silently until Vespa recovers |
| GCS (MDS feed) | Inspect CronJob pod logs for GCS download errors | Re-trigger deal refresh manually after GCS recovers |
| BigQuery | Inspect feature refresh job logs | Re-trigger feature refresh manually after BigQuery recovers |
| MessageBus | Monitor NACK rate and STOMP connection log messages | Real-time updates paused until connection restored; restart pod to reconnect |
| MDS REST API | Inspect deal refresh job logs for HTTP errors | Re-trigger deal refresh manually after MDS REST recovers |
