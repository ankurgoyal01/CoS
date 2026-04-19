---
service: "suggest"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/healthcheck` | http | 10s (liveness/readiness probes) | 5s |
| `GET /grpn/versions` | http | on-demand | — |
| Kubernetes liveness probe (port 8080) | http | 20s | — |
| Kubernetes readiness probe (port 8080) | http | — | — |

The health check returns `{"status": "ok"}` when the application process is running. It does **not** validate BigQuery connectivity, division API reachability, or dictionary load completeness.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `http_requests_total` | counter | Total HTTP requests by method, status, handler | — |
| `http_request_duration_seconds` | histogram | End-to-end request latency with high-resolution buckets (5ms–1s) | Operator-defined |
| `http_request_size_bytes` | histogram | Incoming request size by handler | — |
| `query_preprocessing_feature_latency_seconds` | histogram | Per-feature latency for `typo_fix`, `locality_detection`, `radius_prediction`, `adult_detection` | Operator-defined |
| `python_gc_objects_collected_total` | counter | Python garbage collector activity | — |
| `process_virtual_memory_bytes` | gauge | Virtual memory usage | Operator-defined |
| `process_resident_memory_bytes` | gauge | Resident memory usage | Operator-defined |
| `process_cpu_seconds_total` | counter | CPU time consumed | — |
| `python_info` | gauge | Python runtime version info | — |

Prometheus recording rules are defined in `common.yml` under `prometheusRules`. Custom rules aggregate by `region`, `vpc`, `env`, `source`, `service`, and `component` labels.

### Dashboards

> Operational dashboard details are not discoverable from the codebase. Dashboards are expected to be available in the Groupon Grafana instance under the `search-next-suggest-app` source label.

### Alerts

> Alert rule definitions are not discoverable in the codebase. Operators should define alerts on the following key signals:
> - `http_request_duration_seconds` P99 exceeding acceptable thresholds
> - `http_requests_total{status=~"5.*"}` rate spike
> - `query_preprocessing_feature_latency_seconds` P95 for individual features
> - Dictionary refresh job failure (via job success/failure metrics from `JobMetricsCollector`)

## Common Operations

### Restart Service

1. Identify the pod: `kubectl get pods -n suggest-production -l groupon.com/service=suggest--app`
2. Perform a rolling restart: `kubectl rollout restart deployment/suggest -n suggest-production`
3. Monitor rollout: `kubectl rollout status deployment/suggest -n suggest-production`
4. Verify health: `curl http://<pod-ip>:8080/grpn/healthcheck`

On restart, the service reloads all dictionaries from BigQuery (30s initial delay before probes begin). Allow 30–120 seconds for startup depending on BigQuery query completion.

### Scale Up / Down

Scaling is managed through the Conveyor/Raptor platform. Production HPA is configured min: 2, max: 5 replicas with `hpaTargetUtilization: 50`. To adjust:

1. Update `minReplicas` / `maxReplicas` in `.meta/deployment/cloud/components/app/production-us-central1.yml`
2. Commit and trigger a deployment via Jenkins or Conveyor CLI

### Database Operations

The service performs no database writes. BigQuery tables (`product_analytics.query_by_division_index`, `product_analytics.suggestion_ranking_index`, `fs.suggest_prefix`) are owned and managed by the data platform team. Refresh jobs run automatically daily; to force an immediate refresh, restart the service.

## Troubleshooting

### Suggestions returning empty or stale results
- **Symptoms**: `GET /suggestions` returns `{"did_you_mean": "...", "suggestions": []}` or suggestions appear outdated
- **Cause**: Dictionary refresh job failed; BigQuery unreachable; `DictionaryManager.queries_dict` loaded from stale local fallback files
- **Resolution**: Check pod logs for `"Failed to load from BigQuery"` or `"Job ... failed"`. Verify BigQuery connectivity by checking service account key mount (`resources/service-account-key.json`). Restart the pod to force a fresh dictionary load.

### High suggestion latency
- **Symptoms**: `http_request_duration_seconds` P99 exceeds expected thresholds (target: sub-30ms)
- **Cause**: Large in-memory dictionary sizes causing slow iteration; BK-Tree matching under high query volume; Python GIL contention under concurrent requests
- **Resolution**: Check `process_resident_memory_bytes` for memory pressure. Verify `query_preprocessing_feature_latency_seconds` histogram per feature. Consider scaling out replicas or enabling async batching.

### Query preprocessing returning no locality
- **Symptoms**: `POST /query-preprocessing` returns `{"locality_detection": {"locality": null}}` for queries containing city names
- **Cause**: Locality dictionary failed to load (`cities.csv` parse error or empty file); BK-Tree for locality not initialized
- **Resolution**: Check pod logs for `"Error loading Localities Dictionary"`. Verify `data/cities.csv` is present in the image.

### Radius prediction unavailable
- **Symptoms**: `predicted_radius_km` is `null` in preprocessing responses
- **Cause**: ONNX model files (`onnx_encoder/model.int8.onnx`) or joblib model files (`data/radius_classifier.joblib`) missing or corrupt; `ModelRadiusProvider.is_available()` returned `false`
- **Resolution**: Check pod logs for `"CRITICAL ERROR: Failed to initialize OnnxSentenceEncoder"` or `"Model, categorical encoder or text encoder not loaded"`. Verify ONNX and joblib files are present in the Docker image.

### Division API failure at startup
- **Symptoms**: Pod starts but location-aware suggestions return single or no divisions; logs show `"Error fetching divisions"`
- **Cause**: `https://api.groupon.com/v2/divisions.json` was unreachable at pod startup; `DictionaryManager.gps_coordinates` is empty
- **Resolution**: Restart the pod during a window when the Division API is healthy. Verify network egress policies allow the pod to reach `api.groupon.com`.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down — no suggestions served to MBNXT users | Immediate | rapi@groupon.com / relevance-infra@groupon.com |
| P2 | Degraded suggestions — empty results or high latency affecting user experience | 30 min | rapi@groupon.com |
| P3 | Stale dictionaries / partial feature degradation (e.g., radius prediction disabled) | Next business day | acameramartinez |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Google BigQuery | Check pod logs for scheduler job success messages; query BQ directly via GCP console | Automatic fallback to local CSV files in `data/` |
| Groupon Division API | `curl "https://api.groupon.com/v2/divisions.json?client_id=<REDACTED>&show=all"` | No automatic fallback; GPS coordinates will be empty on startup failure |
| Elastic APM | Check APM server pod health in `logging-platform-elastic-stack-{env}` namespace | Non-critical; service continues without tracing |
| ONNX model files | Check pod startup logs for `"OnnxSentenceEncoder initialized successfully"` | `predicted_radius_km` returns `null`; other preprocessing features continue |
