---
service: "mx-merchant-access"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /ping` | HTTP (Kubernetes readiness probe) | 15 s | — |
| `GET /ping` | HTTP (Kubernetes liveness probe) | 18 s | — |
| `GET /health?invoker=service-portal` | HTTP (service-portal status) | on demand | — |

Both probes start after an initial delay of 120 seconds to allow Tomcat and the Spring context to fully initialize.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Incoming request latency | histogram | P99 latency of inbound HTTP requests | > 30 ms (US and EU regions) |
| Outgoing request latency | histogram | P99 latency of outbound HTTP calls to dependencies | > 30 ms (US and EU regions) |
| Incoming 5xx error rate | counter/rate | Rate of HTTP 5xx errors on inbound requests | > 2% (US and EU regions) |
| Outgoing 5xx error rate | counter/rate | Rate of HTTP 5xx errors on outbound requests | > 2% (US and EU regions) |
| HB 503 errors | counter | HTTP 503 errors at the Hybrid Boundary sidecar | > 100 (US and EU regions) |
| Pod restart count | counter | Number of pod restarts in the deployment | > 5 (US and EU regions) |
| Pod not running count | gauge | Number of pods not in Running state | > 2 (US and EU regions) |

Metrics are emitted via the `metrics-sma` / `metrics-sma-influxdb` libraries and visualized in Wavefront.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| SMA Dashboard | Wavefront | https://groupon.wavefront.com/dashboard/mx-merchant-access--sma |
| EMEA Merchant Access | Wavefront | https://groupon.wavefront.com/dashboard/dub1-merchantaccess-emea |
| USA Merchant Access | Wavefront | https://groupon.wavefront.com/dashboard/snc1-merchantaccess-usa |
| SMA Preview | Wavefront | https://groupon.wavefront.com/dashboards/mx-merchant-access--sma--preview |
| Conveyor Cloud Customer Metrics | Wavefront | https://groupon.wavefront.com/dashboards/Conveyor-Cloud-Customer-Metrics |
| ELK App Logs (US) | Elasticsearch/Kibana | https://logging-prod-us-unified1.grpn-logging-prod.us-west-2.aws.groupondev.com/goto/7ca618b34688708e6929e4e2136af981 |
| ELK App Logs (EU) | Elasticsearch/Kibana | https://logging-prod-eu-unified1.grpn-logging-prod.eu-west-1.aws.groupondev.com/goto/1c0baca200445818d32392b5e37ac564 |
| Production Hybrid Boundary | Hybrid Boundary UI | https://hybrid-boundary-ui.prod.eu-west-1.aws.groupondev.com/services/mx-merchant-access/mx-merchant-access |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Incoming Request Latency US | Latency > 30 ms in US region | warning | Check endpoint logs; escalate to DaaS/RaaS teams if downstream-caused |
| Outgoing Request Latency US | Latency > 30 ms in US region | warning | Identify slow downstream; escalate to respective team |
| Incoming Request Latency EU | Latency > 30 ms in EU region | warning | Check endpoint logs in ELK EU dashboard |
| Outgoing Request Latency EU | Latency > 30 ms in EU region | warning | Identify slow downstream; escalate to respective team |
| Incoming 5xx Error Rate US | Error rate > 2% | critical | Check ELK logs for exception; delete impacted pod if single-pod issue |
| Incoming 5xx Error Rate EU | Error rate > 2% | critical | Check ELK logs EU; contact dev team if app bug |
| Outgoing 5xx Error Rate US | Error rate > 2% | critical | Check outgoing endpoint errors; escalate to downstream team |
| Outgoing 5xx Error Rate EU | Error rate > 2% | critical | Check outgoing endpoint errors EU |
| HB 503 Errors US | > 100 HB 503 errors | critical | Check Wavefront; contact dev/cloud team |
| HB 503 Errors EU | > 100 HB 503 errors | critical | Check Wavefront EU; contact dev/cloud team |
| Pod Restart US | Pod restarts > 5 | critical | Check pod describe for OOM/crash reason; increase memory if OOM |
| Pod Restart EU | Pod restarts > 5 | critical | Same as US |
| Pod Not Running US | < 2 pods running | critical | Investigate restart reason; scale deployment if needed |
| Pod Not Running EU | < 2 pods running | critical | Same as US |

## Common Operations

### Restart Service

```bash
# Restart the entire deployment (triggers rolling restart)
kubectl rollout restart deploy mx-merchant-access--app--default

# Log into a specific pod for debugging
kubectl -n {name_space} exec -it pod/{pod_name} -c main -- /bin/sh

# Delete a single impacted pod (Kubernetes will recreate it)
kubectl delete pod {pod_name}
```

### Scale Up / Down

```bash
# Check current deployment state
kubectl get deployment
kubectl get pods

# Scale manually (if HPA is not handling it)
kubectl scale deployment mx-merchant-access--app--default --replicas={N}
```

### Database Operations

Schema migrations are managed with Liquibase:

```bash
# Apply schema changes to production
cd access-infrastructure
mvn process-resources liquibase:update -Dprofile=prod -Dliquibase.password={password}

# Apply schema changes to staging
mvn process-resources liquibase:update -Dprofile=stg-us
mvn process-resources liquibase:update -Dprofile=stg-emea
```

### Port-forward to production pod

```bash
kubectl port-forward {pod_name} 8080:8080
# Service is then available at http://localhost:8080/
```

## Troubleshooting

### High incoming request latency
- **Symptoms**: Wavefront latency alerts firing; response times > 30 ms
- **Cause**: Slow database queries (DaaS) or slow upstream callers overloading the service
- **Resolution**: Check ELK logs for slow query indicators; inspect Wavefront outgoing latency to identify if DaaS is the bottleneck; escalate to DaaS team if database-caused; escalate to dev team if application-caused

### High 5xx error rate
- **Symptoms**: Wavefront error rate alerts; 500-series responses to callers
- **Cause**: Application exception (bug, DB connectivity, MBus connectivity)
- **Resolution**: Open ELK App Dashboard; filter for ERROR-level log entries; identify exception stack trace; if single pod, delete the pod and let Kubernetes recreate it; if all pods affected, escalate to dev team

### Pod OOM crash / Pod restart loop
- **Symptoms**: Pod restart alert; `kubectl describe pod` shows OOMKilled exit code
- **Cause**: Insufficient memory limit for current workload
- **Resolution**: Increase `memory.main.limit` in the relevant environment Helm YAML file; redeploy; monitor `MALLOC_ARENA_MAX` tuning

### MBus consumer not processing events
- **Symptoms**: Account cleanup not occurring after account deactivation/merge/erase events
- **Cause**: `mbus.enabled=false` in properties file, or MBus connectivity lost
- **Resolution**: Verify `mbus.enabled` property is true; check MBus host configuration; check service health endpoint for MBus status

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service fully down (no pods running) | Immediate | bmx-alert@groupon.com, PagerDuty PV2ZOZL, Slack #global-merchant-exper |
| P2 | Degraded (high error rate or latency) | 30 min | bmx-alert@groupon.com, Slack #global-merchant-exper |
| P3 | Minor impact (single pod restarting) | Next business day | Slack #global-merchant-exper |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| PostgreSQL (DaaS) | `accessSvc_healthAndMetrics` runs scheduled DB health checks; visible in `/health` response | No fallback — DB is required for all operations |
| MBus | MBus consumer connectivity visible in service health; `mbus.enabled` can be set to `false` to disable consumers | Disabling MBus consumers stops account cleanup; access data may become stale |
