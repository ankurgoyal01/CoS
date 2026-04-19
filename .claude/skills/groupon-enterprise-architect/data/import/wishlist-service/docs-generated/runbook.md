---
service: "wishlist-service"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/var/groupon/jtier/heartbeat.txt` (file-based) | exec | Kubernetes default | Kubernetes default |
| `GET /grpn/status` | http | — | — |
| `GET http://<host>:8081/healthcheck` (Dropwizard admin) | http | — | — |

Status check examples:

```
curl https://wishlist-service.production.service.us-west-1.aws.groupondev.com/grpn/status
curl https://wishlist-service.production.service.us-west-1.aws.groupondev.com/grpn/status/wishlists/v1/lists/query?consumerId=c70da834-0b5f-11e2-aa98-00259060adac&listName=default
```

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `user_dequeue` | counter | Number of user IDs dequeued per `UserDequeueJob` cycle | Alerting on drop |
| `user_dequeue_time` | histogram | Time taken to process each dequeued user | Alerting on spike |
| HTTP request rate | counter | Inbound request rate per endpoint | Alerting on drop |
| HTTP error rate (5xx) | counter | HTTP 5xx error rate | Alerting on spike |
| Redis memory usage | gauge | Redis cluster memory usage | Alerting on high watermark |

Metrics are published to Wavefront via JTier's SMA metrics integration (`doc/_dashboards/sma.js`).

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Wishlist Service SMA | Wavefront | https://groupon.wavefront.com/u/WHh0VcTwHB?t=groupon |
| Wishlist Service detailed | Wavefront | https://groupon.wavefront.com/dashboards/wishlist-service--sma |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High 5xx error rate | 5xx response rate exceeds threshold | critical | Check Kibana for bad API calls; ban bad `clientId` via GAPI if needed |
| Slow response speeds | P99 latency exceeds 40ms | critical | Check DaaS PostgreSQL health; add capacity if needed |
| Service won't start | Pod fails health check / CrashLoopBackOff | critical | Check `jtier.steno.log`; verify `production.yml` configuration is up to date |
| Deploy failure | Pod rollout fails for some hosts | warning | Check GDS firewall whitelist; verify DB migration completed; disable migration after first successful pod |
| Full disk | Pod disk usage high | warning | Remove old log files; tune logging configuration |

On-call: PagerDuty service P00HKZX; OpsGenie service `3a95281a-ad9b-48ae-8c2e-77539b1f0c91`

## Common Operations

### Restart Service

```bash
# Get the cluster context
kubectx wishlist-service-production-us-west-1

# Restart the app deployment
kubectl rollout restart deployment/wishlist-service-app -n wishlist-service-production

# Restart the worker deployment
kubectl rollout restart deployment/wishlist-service-worker -n wishlist-service-production

# Monitor rollout
kubectl rollout status deployment/wishlist-service-app -n wishlist-service-production
```

### Scale Up / Down

Scaling is managed via HPA (Horizontal Pod Autoscaler). To manually override:

```bash
kubectl scale deployment wishlist-service-app --replicas=<N> -n wishlist-service-production
```

Min/max bounds are 3–10 replicas per component as defined in `common.yml`.

### Database Operations

- **Migrations**: Applied automatically on service startup via `jtier-migrations` bundle (Flyway-style). To disable migration after one pod is rolled: update `backgroundProcessingConfig` or migration toggle in config.
- **DaaS failure / snapshot restore**: Contact GDS team and request hourly snapshot restoration. After restore, flush Redis to clear stale cached data.
- **Redis flush**: Connect to the Redis cluster and issue `FLUSHDB` to clear stale deal metadata cache after a DaaS restore.

### Accessing Kubernetes Pods

```bash
# List all pods
kubectl get pods -o wide -n wishlist-service-production

# Stream logs from a pod
kubectl logs -f <pod_name> -n wishlist-service-production

# Get an interactive shell in a container
kubectl exec --stdin --tty <pod_name> -c main -n wishlist-service-production -- /bin/sh
```

## Troubleshooting

### High 5xx Error Rate

- **Symptoms**: Error rate spike visible on Wavefront SMA dashboard; Kibana shows repeated 4xx/5xx from specific clients.
- **Cause**: Malformed requests from a bad `clientId`; downstream dependency (DaaS, Redis) failure; misconfiguration after deploy.
- **Resolution**: Check Kibana index `wishlist-service` for error patterns; if a specific `clientId` is misbehaving, coordinate with GAPI to ban it; if DB-related, engage DaaS team.

### Slow Response Speeds / Latency Above 40ms

- **Symptoms**: GAPI ignores responses; users see missing wishlist indicators; P99 latency exceeds 40ms.
- **Cause**: PostgreSQL replica overloaded; Redis unavailable; downstream service slowness (Deal Catalog, Pricing, etc.).
- **Resolution**: Check DaaS PostgreSQL health via DaaS team; check Redis memory and connection counts; provision additional app replicas if CPU-bound.

### Service Won't Start

- **Symptoms**: Pod enters CrashLoopBackOff state; logs show configuration errors.
- **Cause**: Missing or incorrect configuration in `production.yml`; database not reachable; migrations failing.
- **Resolution**: Check `jtier.steno.log` (located at `/var/groupon/jtier/logs/jtier.steno.log` on app host); verify all required env vars (`DAAS_APP_USER`, `DAAS_APP_PASSWORD`, etc.) are set.

### Deploy Fails for Some Hosts

- **Symptoms**: krane rollout fails; some pods stay on old version.
- **Cause**: Host not whitelisted on GDS firewall; DB migration connection limit exceeded.
- **Resolution**: Verify GDS firewall rules; check that DB migration completed on at least one pod; disable migration for subsequent pods if needed.

### Background Jobs Not Processing

- **Symptoms**: `user_dequeue` metric at zero; email/push notifications not sending.
- **Cause**: `ENABLE_JOBS` env var not set to `true` on worker; `backgroundProcessingConfig.enabled` is `false`; Redis queue empty.
- **Resolution**: Verify worker deployment has `ENABLE_JOBS=true` and `ENABLE_MBUS=true`; check Redis cluster connectivity; review `backgroundProcessingConfig` in the deployed config.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — wishlists unavailable across web/mobile | Immediate | UGC on-call via PagerDuty P00HKZX |
| P2 | Degraded — latency above 40ms; GAPI ignoring responses | 30 min | UGC team via ugc-alerts@groupon.com |
| P3 | Minor impact — background notifications not sending; no user-facing impact | Next business day | UGC team via ugc-dev@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| PostgreSQL (DaaS) | Query DaaS health endpoint; check Wavefront DB metrics | Cached data from Redis; degraded responses |
| Redis (RaaS) | Check Redis memory and connection metrics in Wavefront | Background processing halts; no price-drop cache |
| MBus | Check MBus consumer lag in Wavefront | Order purchase events not processed; notifications delayed |
| Deal Catalog Service | Check deal-catalog SMA dashboard | Wishlist responses returned without deal metadata enrichment |
| Mailman | Check Mailman health endpoint | Email notifications not sent; items remain unprocessed until retry |

## Log Locations

- Application logs: `/var/groupon/jtier/logs/jtier.steno.log` (Steno structured JSON format)
- Kibana index: `wishlist-service`
- Request logs: `requests.log`
