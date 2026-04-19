---
service: "place-service"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/placereadservice/v2.0/status` | http | 5s (readiness) / 15s (liveness) | — |
| US production: `https://m3-placeread.production.service.us-central1.gcp.groupondev.com/placereadservice/v2.0/status?client_id=demo` | http | manual verify | — |
| EU production: `http://m3-placeread.production.service.eu-west-1.aws.groupondev.com/placereadservice/v2.0/status?client_id=demo` | http | manual verify | — |

## Monitoring

### Metrics

Metrics are emitted via `metrics-sma` (SMA — Service Monitoring Architecture) to Wavefront/InfluxDB. Key metric dimensions include HTTP in/out by status code and endpoint, and DB-out latency.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Incoming request latency (US) | histogram | p99 latency of incoming requests — US region | > 30ms |
| Incoming request latency (EU) | histogram | p99 latency of incoming requests — EU region | > 30ms |
| Incoming 5xx error rate (US) | gauge | Percentage of incoming requests returning 5xx — US | > 2% |
| Incoming 5xx error rate (EU) | gauge | Percentage of incoming requests returning 5xx — EU | > 2% |
| Hybrid Boundary 503 errors (US) | counter | 503 errors at Hybrid Boundary — US | > 100 |
| Hybrid Boundary 503 errors (EU) | counter | 503 errors at Hybrid Boundary — EU | > 100 |
| Pod restarts (US) | counter | Number of pod restarts in production — US | > 5 |
| Pod restarts (EU) | counter | Number of pod restarts in production — EU | > 5 |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| ELK App Logs (US) | Kibana | https://prod-kibana-unified.us-central1.logging.prod.gcp.groupondev.com/app/r/s/cPauW |
| ELK App Logs (EU) | Kibana | https://logging-prod-eu-unified1.grpn-logging-prod.eu-west-1.aws.groupondev.com/goto/44a8b7a64c72fe19a9257dd1aec13052 |
| ELK Access Logs (US) | Kibana | https://prod-kibana-unified.us-central1.logging.prod.gcp.groupondev.com/app/r/s/j8djB |
| ELK Access Logs (EU) | Kibana | https://logging-prod-eu-unified1.grpn-logging-prod.eu-west-1.aws.groupondev.com/goto/40dd8e705fc2742c75cdbfa23c81188d |
| Grafana (main) | Grafana | https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/dashboards/f/ce7z8fe7j4hdsf/ |
| Grafana Alerts | Grafana | https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/alerting/list?search=m3%20place&view=grouped |
| Conveyor Cloud Metrics | Grafana | https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/goto/B_scvckDg?orgId=1 |
| Hybrid Boundary (US) | HBU | https://hybrid-boundary-ui.prod.us-central1.gcp.groupondev.com/services/m3-placeread/m3-placeread |
| RaaS (Redis) NA | Grafana | https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/d/bea2rbflxq4u8a/redis-clusters |
| DaaS (Postgres) NA | Grafana | https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/d/decnv92o2pczkf/postgres-dashboard |
| Wavefront SMA | Wavefront | https://groupon.wavefront.com/dashboards/m3-placeread--sma# |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Incoming request latency Alert US | p99 latency > 30ms US | warning | Check endpoint latency in Grafana; if downstream (DaaS/RaaS), contact respective team |
| Incoming request latency Alert EU | p99 latency > 30ms EU | warning | Check endpoint latency in Grafana; if downstream, contact respective team |
| Incoming 5xx Error Rate Alert US | Error rate > 2% US | critical | Check ELK logs for exception type; fix in application or escalate to dev team |
| Incoming 5xx Error Rate Alert EU | Error rate > 2% EU | critical | Check ELK logs; escalate to dev team |
| HB 503 Errors US | HB 503 errors > 100 US | critical | Check Grafana dashboard; contact dev/cloud team |
| HB 503 Errors EU | HB 503 errors > 100 EU | critical | Check Grafana dashboard; contact dev/cloud team |
| POD Restart Alert US | Pod restarts > 5 US | warning | Check Grafana for restart reason; if OOM, increase memory limit |
| POD Restart Alert EU | Pod restarts > 5 EU | warning | Check Grafana for restart reason; if OOM, increase memory limit |
| POD Not Running Alert US | Running pods < 2 US | critical | Check Grafana for cause; contact dev/cloud team |
| POD Not Running Alert EU | Running pods < 2 EU | critical | Check Grafana for cause; contact dev/cloud team |
| POD Termination Alert US | Terminations > 2 US | warning | Check Grafana for termination reason; contact dev/cloud team |
| POD Termination Alert EU | Terminations > 2 EU | warning | Check Grafana for termination reason; contact dev/cloud team |

## SLA

| Metric | Target |
|--------|--------|
| Uptime | 99.95% |
| p99 latency GET /v3.0/places/{id} | 40ms |
| p99 latency GET /v3.0/places/count | 100ms |
| p99 latency GET /v3.0/places | 150ms |
| Throughput GET /v3.0/places/{id} | 1M RPM |

## Common Operations

### Restart Service

```
kubectl rollout restart deploy m3-placeread--app--default
```

### Scale Up / Down

List current HPA:
```
kubectl get hpa
kubectl describe hpa m3-placeread--app--default
```

Edit replica count:
```
kubectl edit hpa m3-placeread--app--default
```

Alternatively, update `minReplicas` / `maxReplicas` in the appropriate `.meta/deployment/cloud/components/app/<env>.yml` and redeploy via DeployBot.

### Port-Forward to Production Pod

```
kubectl port-forward <pod_name> 8080:8080
```

Then access: `http://localhost:8080/placereadservice/v2.0/status?client_id=demo`

### Log into a Pod

```
kubectl -n <namespace> exec -it pod/<pod_name> -c main -- /bin/sh
```

### Database Operations

- **Postgres migrations**: Managed externally by the GDS team. DB connection config is in the `place-service-secrets` repository.
- **Postgres read replica**: EMEA read replica is managed by GDS; do not attempt write operations against EMEA.
- **OpenSearch index updates**: Index documents are updated by the `placeSvc_writePipeline` on place writes. Manual re-indexing must be coordinated with the Merchant Data team.

## Troubleshooting

### High Latency on Place Read Endpoints

- **Symptoms**: p99 latency > 30ms on `/v3.0/places/{id}` or `/v2.0/places/`; Grafana latency alert fires
- **Cause**: Cache misses causing Postgres or OpenSearch lookups; slow downstream dependency (DaaS/RaaS); insufficient replicas under load
- **Resolution**: Check ELK app logs for slow queries. Check RaaS dashboard for Redis latency/availability. Check DaaS dashboard for Postgres latency. If downstream: contact DaaS or RaaS team. If application-level: contact Merchant Data dev team.

### High 5xx Error Rate

- **Symptoms**: Error rate > 2% on incoming requests; Grafana 5xx alert fires
- **Cause**: Application bug, misconfiguration, or failing dependency (Postgres, OpenSearch, Redis, Merchant Service)
- **Resolution**: Open Grafana to identify which endpoint is failing. Check ELK logs for exception stack traces. If single pod impacted: `kubectl delete pod <pod_name>` (new pod is created automatically). If all pods impacted: check ELK logs and escalate to dev team.

### Pod Restart / OOM

- **Symptoms**: Pod restart alert fires; `kubectl describe pod` shows `OOMKilled`
- **Cause**: JVM heap or native memory exceeding container limit
- **Resolution**: Increase memory limit in `production-us-central1.yml` or `production-eu-west-1.yml`. Also check for memory leaks via APM (APM enabled in EU production). Restart the deployment: `kubectl rollout restart deploy m3-placeread--app--default`.

### Place Not Found (404)

- **Symptoms**: Callers receive 404 for a known place ID
- **Cause**: Place record missing from both Postgres and OpenSearch index; or incorrect `client_id` / `view_type` combination returning empty result
- **Resolution**: Verify place record existence in Postgres via DaaS tools. Check OpenSearch index for the document. Ensure `client_id` is registered. Check `visibility` and `view_type` parameters.

### Google Places Lookup Failure

- **Symptoms**: `InternalServerException` in logs for `GoogleClient`; Google place controller returns 500
- **Cause**: Invalid or expired `google_places_api_key`; Google API rate limit or outage
- **Resolution**: Verify `google_places_api_key` in config-central. Check Google Cloud Console for API quota. The Redis cache reduces Google API call frequency; a cache hit bypasses the issue.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down / all pods not running | Immediate | Merchant Data on-call via PagerDuty (PTIR99Q) |
| P2 | Degraded (high latency or error rate) | 30 min | Merchant Data on-call via PagerDuty |
| P3 | Minor impact (partial region degradation) | Next business day | Merchant Data team (merchantdata@groupon.com) |

PagerDuty: `https://groupon.pagerduty.com/services/PTIR99Q`
Slack: `CFPA9QH8B`

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Place Postgres | DaaS Dashboard; `kubectl port-forward` and query | Read from OpenSearch index (partial fallback) |
| Place OpenSearch | ELK/Grafana dashboards; direct ES HTTP health endpoint | No direct fallback; search/count capabilities degrade |
| Place Redis | RaaS Dashboard; Redis `PING` via port-forward | Cache misses; all requests hit Postgres/OpenSearch |
| M3 Merchant Service | ELK logs for `M3MerchantClient` errors | Place response returned without merchant enrichment |
| Google Maps API | `GoogleClient` error logs; Google Cloud Console | Redis-cached candidates served; new lookups fail with 500 |
