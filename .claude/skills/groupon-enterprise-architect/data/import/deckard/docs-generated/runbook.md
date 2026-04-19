---
service: "deckard"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/healthcheck` (returns `OK`) | http | 10–15 s (Kubernetes probe) | 6 s (SLA timeout) |
| `GET http://localhost:9090/v1/inventory_units` (port-forward) | http | on-demand | — |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Endpoint error rate | counter | HTTP 5xx responses on `/v1/inventory_units` | Elevated error rate signals deckard or downstream issue |
| Cache miss rate | gauge | Proportion of requests that bypass Redis and fetch from inventory services | High miss rate = cache cold or Redis unavailable |
| Downstream service error rate | counter | Per-client HTTP errors to inventory services | Any single service failing = partial results; all failing = full outage |
| CPU usage | gauge | JVM CPU utilization | High CPU = heavy sorting/filtering load; consider rollback |
| Memory usage | gauge | JVM heap utilization | Growing memory = potential memory leak; consider rollback |
| Redis connection errors | counter | Redis client connection failures | Triggers cache miss storm and elevated latency |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Deckard main dashboard | Grafana | `https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/d/fe8krowf802dcf/deckard` |
| Deckard system metrics | Grafana | `https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/goto/CIOdkazDR?orgId=1` |
| Deckard logs (US) | Kibana | `https://logging-us.groupondev.com/app/kibana` (index: `filebeat-deckard--*`) |
| Deckard logs (EU) | Kibana | `https://logging-eu.groupondev.com/app/kibana` (index: `filebeat-deckard--*`) |
| Envoy sidecar logs | Kibana | index: `filebeat-mtls-sidecar-access-json--*` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High endpoint error rate (all) | Many endpoints returning errors simultaneously | critical | Deckard itself is failing; check host health, consider rollback |
| Single endpoint error rate | One endpoint returning elevated errors | warning | Single downstream inventory service failing; check downstream service health |
| Cache/uncached error rate discrepancy | Uncached endpoint errors elevated vs cached | warning | Redis cluster problem; check RAAS Elastic Cache health |
| Memory growing over time | Memory usage increasing without bound | critical | Memory leak; roll back immediately |
| mbus events not received | Deckard cache becoming outdated; no event logs in ELK | warning | Check mbus health; verify host mbus subscription is active |

## Common Operations

### Authenticate to Kubernetes

```sh
kubectl cloud-elevator auth
kubectl config get-contexts
kubectl config use-context deckard-production-us-central1
```

### Restart Service (Rolling Restart)

```sh
kubectl rollout restart deployment/<deployment_name>
```
For legacy on-prem environments (if applicable):
```sh
fab -f deckard_deploy.py prod_snc1 service.rolling_restart
```

### View Logs

```sh
kubectl logs <pod-name> main
kubectl logs <pod-name> main-log-tail
```

Or in Kibana with source `us-*:filebeat-deckard--*`.

### Port Forward to Service (for local debugging)

```sh
kubectl cloud-elevator auth
kubectl config use-context deckard-production-us-central1
kubectl port-forward -n deckard-production service/deckard--app--default 9090:80
# Now hit: http://localhost:9090/v1/inventory_units?consumer_id=...
```

### Scale Up / Down

Scaling is controlled by Kubernetes HPA. To manually adjust replicas:
```sh
kubectl scale deployment/<deployment_name> --replicas=<N>
```
Production replica bounds: min 4, max 20 (us-central1); min 2, max 20 (europe-west1).

### Database Operations

Deckard has no relational database and no schema migrations. Redis data can be inspected by following the RAAS Redis access documentation at `https://confluence.groupondev.com/pages/viewpage.action?spaceKey=RED&title=Cloud+FAQ`.

## Troubleshooting

### mbus Events Not Being Received

- **Symptoms**: Deckard cache becoming stale; inventory units not reflecting recent status changes
- **Cause**: mbus not delivering messages, or Deckard pods not processing incoming messages
- **Resolution**:
  1. Check ELK: set filter `data.eventSource:"eventBusHandler"` to confirm event receipt
  2. If no events in ELK, the issue is with mbus — engage the mbus/DSE team
  3. If events arrive but are not processed, check pod health and restart if needed

### Redis Connection Failures

- **Symptoms**: 5xx errors on all endpoints; cache miss storm; elevated latency
- **Cause**: Redis cluster or standalone Redis instance unavailable
- **Resolution**:
  1. Check RAAS Elastic Cache health in Grafana
  2. Verify Redis DNS resolution from within pods
  3. Follow [Redis connections monitoring in deckard](https://groupondev.atlassian.net/wiki/spaces/GA/pages/80778100831/Redis+connections+monitoring+in+deckard)
  4. Contact RaaS team to restore cache instances if infrastructure failure

### Single Inventory Service Failing

- **Symptoms**: Specific unit types missing from responses; `errors.inventoryServices` contains the service name in API responses
- **Cause**: One downstream inventory service is down or timing out
- **Resolution**:
  1. Identify failing service from ELK: set filter `data.clientName:"<clientName>"` (e.g., `getawaysInventoryClient`)
  2. Check the failing service's own runbook
  3. Deckard continues returning partial results; no Deckard action needed unless all services fail

### Cold Start (Empty Cache)

- **Symptoms**: All requests are cache misses; elevated latency; increased load on inventory services
- **Cause**: Cache cluster restart, pod scale-up, or Redis flush
- **Resolution**:
  1. Limit concurrent connections to Deckard during warm-up
  2. Use exponential backoff on retries from API Lazlo
  3. If latency is unacceptable, engage inventory service owners to improve throughput

### API Lazlo Calls Returning 5xx

- **Symptoms**: Lazlo clients seeing 5xx from Deckard
- **Cause**: Likely Redis unavailable (only cache-dependent errors cause 5xx)
- **Resolution**: Verify Redis cache cluster status (see Redis Connection Failures above)

### Overload / High RPS

- **Symptoms**: Queue size exceeded errors; increased latency
- **Resolution**:
  1. Add replicas via Kubernetes HPA or manual scale
  2. Increase Redis cache retention (`referenceConsumerCacheStaleAge`) in config
  3. Increase cache staleness threshold (`servingStaleData: true` temporarily)

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Deckard fully down; My Groupons page unavailable | Immediate | Groupon API Team on-call |
| P2 | Degraded responses; partial inventory missing | 30 min | Groupon API Team on-call |
| P3 | Single inventory service failing; partial results | Next business day | Groupon API Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Redis Cache Cluster | Grafana RAAS Elastic Cache dashboard | Serve stale data (if `servingStaleData: true`); all requests become cache misses |
| Redis Async Update Queue | Grafana RAAS Elastic Cache dashboard | mbus events cannot be processed; cache becomes stale |
| Getaways Inventory Service | ELK filter `data.clientName:"getawaysInventoryClient"` | Partial results without getaways units |
| Goods Inventory Service | ELK filter `data.clientName:"goodsInventoryClient"` | Partial results without goods units |
| VIS Inventory Service | ELK filter `data.clientName:"voucherV2Inventory"` | Partial results without voucher units |
| Groupon Message Bus | ELK filter `data.eventSource:"eventBusHandler"` | Cache becomes stale; TTL-based expiry still applies |

## RAAS Elastic Cache Instances

| Cluster | Region | Environment | DNS |
|---------|--------|-------------|-----|
| deckard-async-staging | us-central1 | staging | `deckard-async-memorystore.us-central1.caches.stable.gcp.groupondev.com` |
| deckard-cache-staging | us-central1 | staging | `deckard-cache-memorystore.us-central1.caches.stable.gcp.groupondev.com` |
| deckard-async-staging | europe-west1 | staging | `deckard-async-memorystore.europe-west1.caches.stable.gcp.groupondev.com` |
| deckard-cache-staging | europe-west1 | staging | `deckard-cache-memorystore.europe-west1.caches.stable.gcp.groupondev.com` |
| deckard-async-prod | europe-west1 | prod | `deckard-async-memorystore.europe-west1.caches.prod.gcp.groupondev.com` |
| deckard-async-prod | us-central1 | prod | `deckard-async-memorystore.us-central1.caches.prod.gcp.groupondev.com` |
| deckard-cache-prod | europe-west1 | prod | `deckard-cache-memorystore.europe-west1.caches.prod.gcp.groupondev.com` |
| deckard-cache-prod | us-central1 | prod | `deckard-cache-memorystore.us-central1.caches.prod.gcp.groupondev.com` |
