---
service: "voucher-inventory-jtier"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/status` (port 8080) | http | Default Dropwizard | Default |
| `GET /grpn/status` (port 8081 admin) | http | Default Dropwizard | Default |
| Kubernetes liveness/readiness | http | Default Conveyor | Default |

The status endpoint returns a JSON object including `commitId` (deployed git SHA) for deployment verification.

## Monitoring

### Metrics

Metrics are emitted via StatsD/UDP to the Telegraf sidecar (`continuumVoucherInventoryTelegraf`), which forwards them to Wavefront.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Request throughput | counter | Requests per minute served by the API | Alert if drops significantly below 800K RPM |
| p99 latency | histogram | 99th-percentile response latency for `GET /inventory/v1/products` | Alert if exceeds 20ms |
| p95 latency | histogram | 95th-percentile response latency | Alert if exceeds 15ms |
| Redis cache hit/miss | counter | Cache hit rate for inventory product lookups | Alert on sustained low hit rate |
| MessageBus consumer lag | gauge | Message processing backlog per topic | Alert on growing lag |
| JVM heap usage | gauge | JVM heap utilization percentage | Alert if sustained above `MAX_RAM_PERCENTAGE` (67%) |
| Pod count | gauge | Number of running API/worker pods | Alert if below `minReplicas` |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| SNC1 Production | Wavefront | https://groupon.wavefront.com/dashboard/voucher-inventory-jtier-snc1 |
| SAC1 Production | Wavefront | https://groupon.wavefront.com/dashboard/voucher-inventory-jtier-sac1 |
| DUB1 Production | Wavefront | https://groupon.wavefront.com/dashboard/voucher-inventory-jtier-dub1 |
| Cloud (Conveyor) | Wavefront | https://groupon.wavefront.com/dashboard/vis_jtier_conveyor_cloud |
| Conveyor Customer Metrics | Wavefront | https://groupon.wavefront.com/dashboard/Conveyor-Cloud-Customer-Metrics |
| Hybrid Boundary per Service | Wavefront | https://groupon.wavefront.com/dashboard/hybrid-boundary-per-service |
| VIS 2.0 Cloud Latency | Kibana | https://logging-us.groupondev.com/goto/6bf76c0adf613c8736b8d2893a04dddf |
| US Logs (Kibana) | Kibana | https://logging-us.groupondev.com/goto/053d8ad25d7550e07071b4f4dcd27700 |
| EU Logs (Kibana) | Kibana | https://logging-eu.groupondev.com/goto/bcd2e3f47de4ef428a2391ea08cdd592 |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High p99 latency | `GET /inventory/v1/products` p99 > 20ms | critical | Check recent deployments; check Pricing/Calendar service health; consider rollback |
| 503 spike | Elevated 503 error rate | critical | Check pod count vs maxReplicas; scale if needed; check Hybrid Boundary config |
| 403 spike | Elevated 403 error rate | warning | Verify client IDs in Hybrid Boundary UI; create PAR ticket if missing |
| Pod count below minimum | Running pods < minReplicas | critical | Check Kubernetes events; restart stuck pods; scale manually if needed |
| MessageBus consumer lag | Growing backlog on consumed topics | warning | Check worker pod health; increase worker replicas if needed |

Alerts are routed to: `voucher-inventory-urgent@groupon.com` and PagerDuty service `P815MP6`.

## Common Operations

### Restart Service

**Cloud (Kubernetes):**

Rolling restart of API pods:
```sh
kubectl rollout restart deployment/voucher-inventory-app -n voucher-inventory-production-sox --context <KUBE_CONTEXT>
```

**On-premises:**
```sh
sudo /usr/local/bin/sv start jtier
```

### Scale Up / Down

**Temporary (runtime) — Cloud:**

```sh
kubectl scale deployment/voucher-inventory-app --replicas=<N> \
  -n voucher-inventory-production-sox \
  --context <KUBE_CONTEXT>
```

**Permanent — Cloud:**

Update `maxReplicas` in the relevant `.meta/deployment/cloud/components/app/<cluster>.yml` and redeploy the same image via Deploybot.

**On-premises:**

Follow the capacity addition process in `doc/owners_manual.md` (procure servers, whitelist for DaaS/RaaS, add to load balancer).

### Database Operations

- **Migrations**: Managed by `jtier-migrations` (Flyway); run automatically on deployment startup via JTier migration bundle
- **Backfills**: No standard backfill procedure documented; coordinate with DaaS team for large-scale operations
- **Read-only vs read-write**: `vis_mysql` and `vis_units_mysql` are read-only replicas; `vis_rw_mysql` is the writable endpoint. Enable RW mode only on designated hosts via `ENABLE_RW_DATABASE` env var

## Troubleshooting

### High 503 Error Rate

- **Symptoms**: Elevated 503 responses from Hybrid Boundary or Nginx; clients reporting timeouts
- **Cause**: Pod count has reached `maxReplicas`; Jetty thread pool exhausted (`maxQueuedRequests: 50` reached); or Hybrid Boundary load balancer misconfiguration
- **Resolution**:
  1. Check current pod count: `kubectl get pods -n voucher-inventory-production-sox`
  2. If at maxReplicas, temporarily increase via `kubectl scale` or update `maxReplicas` config
  3. Check Hybrid Boundary UI for correct load balancer IP configuration
  4. Open GPROD Logbook ticket for capacity change

### High 403 Error Rate

- **Symptoms**: Clients receiving 403 Forbidden responses
- **Cause**: Client ID not registered in Hybrid Boundary UI
- **Resolution**:
  1. Verify client ID in Hybrid Boundary UI
  2. If missing, create a PAR ticket with client ID and required permissions
  3. Coordinate in `#hybrid-boundary` Slack channel for urgent fixes

### High p99 Latency

- **Symptoms**: p99 latency exceeds 20ms on `GET /inventory/v1/products`
- **Cause**: Possible load test; slow Pricing or Calendar Service response; slow Redis or MySQL
- **Resolution**:
  1. Check `#production` channel for active load tests
  2. Review VIS 2.0 Cloud Dashboard for latency breakdown (app vs nginx vs HB layers)
  3. Check Pricing Service and Calendar Service latency dashboards
  4. If caused by recent deployment, roll back via Deploybot (redeploy previous SHA)

### MessageBus Consumer Not Processing

- **Symptoms**: Inventory data in Redis is stale; MessageBus consumer lag growing
- **Cause**: Worker pods restarted; `ENABLE_MBUS=false` set on worker pods; MessageBus connectivity issue
- **Resolution**:
  1. Verify worker pods have `ENABLE_MBUS=true`
  2. Restart worker deployment: `kubectl rollout restart deployment/voucher-inventory-worker -n voucher-inventory-production-sox`
  3. Check MessageBus host connectivity from worker pods

### Replenishment Job Not Running

- **Symptoms**: Inventory replenishment schedules stale; Ouroboros job not firing
- **Cause**: `ENABLE_OUROBOROS=false`; Legacy VIS unreachable; Quartz scheduler issue
- **Resolution**:
  1. Check `ENABLE_OUROBOROS` env var on `ouroboros-jtier` component pods
  2. Verify Legacy VIS endpoint reachability from worker pod
  3. Access Quartz admin endpoint at `/quartz` for job status

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down or >10% error rate | Immediate | voucher-inventory-urgent@groupon.com; PagerDuty P815MP6 |
| P2 | Degraded latency (p99 > 20ms sustained) or partial region outage | 30 min | voucher-inventory-dev@groupon.com; Slack #voucher-inventory |
| P3 | Minor impact (single feature degraded, e.g., dynamic pricing off) | Next business day | Slack #voucher-inventory; JIRA ticket |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Pricing Service | Wavefront pricing-service dashboards; direct health endpoint at base URL | Falls back to contracted price if response not received within TP99 (7ms) |
| Calendar Service | Monitor enableCalendarService feature flag; Calendar Service health endpoint | Controlled via `enableCalendarService` flag; disable flag to bypass |
| Redis (RaaS) | RaaS Wavefront graphs (`cache.snc1.raas-voucher-inventory-prod.grpn` etc.) | Cache miss falls through to MySQL; increased DB load |
| MySQL (Product/Units/RW) | DaaS MySQL Wavefront graphs per VIP | Service continues with stale cache if DB is temporarily unavailable |
| MessageBus | Check subscription lag via `vis_jtier_conveyor_cloud` Wavefront dashboard | Durable subscriptions preserve messages; catch up after recovery |
| Legacy VIS | Check reachability from worker pod | Replenishment and unit redeem jobs fail for that cycle; no real-time fallback |
