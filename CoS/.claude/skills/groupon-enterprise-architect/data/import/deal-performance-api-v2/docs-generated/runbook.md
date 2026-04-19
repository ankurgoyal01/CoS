---
service: "deal-performance-api-v2"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/grpn/healthcheck` | HTTP GET | JTier default | JTier default |
| `/grpn/status` | HTTP GET (status JSON) | — | — |
| `heartbeat.txt` | File-based heartbeat | JTier default | — |

Production health check URL: `https://deal-performance-service-v2.production.service.us-central1.gcp.groupondev.com/grpn/healthcheck/grpn/status`

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `http.in.total-time` | histogram | Incoming request latency per operation | p95 > threshold triggers `[DPS V2 NA] - [10m] - tp95` alert |
| `http.in.total-time.count` | counter | Incoming request throughput | Drop triggers `[DPS V2 NA] - [1h] - Http throughput` alert |
| HTTP non-200 status rate | counter | Rate of 4xx/5xx responses | Triggers `[DPS V2 NA] - [60s] - API non 200 status` and `[DPS V2 NA] - [1h] - API non 200 status` alerts |
| `db.out.time.total.count` | counter | Database query throughput and latency | High DB latency visible in Conveyor Cloud Application Metrics dashboard |

Metrics are flushed via Telegraf/Codahale to `http://localhost:8186/` every 10 seconds (`src/main/resources/metrics.yml`).

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| DPS V2 SMA | Wavefront | `https://groupon.wavefront.com/dashboards/deal-performance-api-v2--sma` |
| Deal Performance Service V2 | Wavefront | `https://groupon.wavefront.com/dashboards/deal-performance-service-v2` |
| Conveyor Cloud Customer Metrics | Wavefront | `https://groupon.wavefront.com/dashboards/Conveyor-Cloud-Customer-Metrics` |
| Conveyor Cloud Application Metrics | Wavefront | `https://groupon.wavefront.com/dashboards/Conveyor-Cloud-Application-Metrics` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| `[DPS V2 NA] - [10m] - tp95` | p95 latency exceeds threshold | warning | Check DB latency, pod restarts; see [High p95](#high-p95) |
| `[DPS V2 NA] - [1h] - Http throughput` | Throughput drops below threshold | warning | Check p95, non-200 rate, reach out to client team if RPM is low |
| `[DPS V2 NA] - [60s] - API non 200 status` | Non-200 rate exceeds threshold (60s window) | critical | Check ELK logs for exceptions; see [Non-200 HTTP Status](#non-200-http-status) |
| `[DPS V2 NA] - [1h] - API non 200 status` | Non-200 rate exceeds threshold (1h window) | warning | Same resolution as 60s alert |

Notification channel: `mds-alerts@groupondev.opsgenie.net` / PagerDuty: `https://groupon.pagerduty.com/services/deal-performance-api-v2`

## Common Operations

### Restart Service

```bash
kubectl cloud-elevator auth
kubectx deal-performance-service-v2-production-us-central1
kubectl rollout restart deployment/<deployment-name> -n deal-performance-service-v2-production
kubectl get pods -o wide  # verify pods come up in Running status
```

### Scale Up / Down

Edit `.meta/deployment/cloud/components/app/production-us-central1.yml` and redeploy, or adjust at runtime:
```bash
kubectl edit hpa -n deal-performance-service-v2-production
kubectl edit deployment -n deal-performance-service-v2-production
```

Key fields: `maxReplicas`, `hpaTargetUtilization`, `cpu.main.request`, `memory.main.request/limit`.

### Database Operations

- This service performs no writes; all DB operations are reads.
- If connection limits are exhausted, contact the GDS team (`#gds-daas` Slack) to increase connection limits.
- Database backups are managed by the GDS team.

## Troubleshooting

### Non-200 HTTP Status

#### 5xx Errors
- **Symptoms**: Elevated 5xx rate in Wavefront alerts
- **Cause**: Database connectivity failure, OOMKilled pods, or Hybrid Boundary issues
- **Resolution**:
  1. Check ELK logs: `*:filebeat-deal-performance-api-v2-app--*` (production)
  2. Search for exceptions or errors in logs
  3. If pod restarts are occurring, check [Pod Issues](#pod-issues) section
  4. If Hybrid Boundary returns 5xx, reach out to `#hybrid-boundary` Slack

#### 4xx Errors
- **Symptoms**: Elevated 4xx rate in Wavefront
- **Cause**: Invalid request parameters (bad UUID format, missing required fields, unsupported enum values)
- **Resolution**: Check ELK logs for request details and validate client request format against the swagger spec

### High p95 Latency
- **Symptoms**: p95 alert fires in Wavefront
- **Cause**: Database query slowness, high RPM, or pod resource pressure
- **Resolution**:
  1. Check application metrics for DB-out latency — if high, contact `#gds-daas`
  2. Check RPM — if high, consider scaling up (add replicas)
  3. Check pod restart rate — if pods are restarting, see [Pod Issues](#pod-issues)

### Low Throughput
- **Symptoms**: Throughput alert fires
- **Cause**: High p95 causing queuing, high non-200 rate, or reduced client traffic
- **Resolution**:
  1. Check if p95 is elevated
  2. Check non-200 rate
  3. If RPM is genuinely low from client side, reach out to the consuming team

### Pod Issues

```bash
kubectl cloud-elevator auth
kubectx deal-performance-service-v2-production-us-central1
kubectl get pods -o wide
kubectl get pod -o go-template='{{range.status.containerStatuses}}{{"Container Name: "}}{{.name}}{{"\r\nLastState: "}}{{.lastState}}{{end}}' <pod-name>
```

#### OOMKilled
1. Check for request spike: ELK logs `http.in.start count`
2. If spike: contact client team
3. If unknown: increase memory limit in `production-us-central1.yml`, get reviewed, and redeploy

#### Non-OOM Crash
```bash
kubectl logs <pod-name> -c <container-name> --previous
```
Check ELK logs and debug application errors.

### Access Issues

- `RBAC: Access Denied` — contact `#hybrid-boundary` Slack
- `Unable to connect to the server: No valid id-token` — run `kubectl cloud-elevator auth`

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down | Immediate | Marketing Services team, `#gds-daas` for DB issues |
| P2 | Degraded (high latency / partial errors) | 30 min | Marketing Services team |
| P3 | Minor impact (isolated 4xx, low throughput) | Next business day | Marketing Services team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Deal Performance PostgreSQL | Check DB-out latency in Wavefront; run test query via `kubectl exec` into pod | No fallback — service returns errors if DB is unreachable |

## Logs

### ELK Index Patterns

| Environment | Index Pattern |
|-------------|--------------|
| Production | `*:filebeat-deal-performance-api-v2-app--*` |
| Staging | `filebeat-deal-performance-api-v2-app--*` |

### Container Logs

```bash
# Get pod names
kubectl get pods -n deal-performance-service-v2-production

# Tail logs for a specific pod
kubectl logs pod/<pod-name> main -n deal-performance-service-v2-production

# All pods (staging)
kubectl logs -n deal-performance-service-v2-staging \
  -l groupon.com/service=deal-performance-service-v2--app \
  -c main --prefix=true --tail=100
```
