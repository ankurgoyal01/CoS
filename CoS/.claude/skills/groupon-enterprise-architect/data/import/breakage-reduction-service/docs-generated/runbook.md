---
service: "breakage-reduction-service"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `:8000/status` (I-Tier default health endpoint) | http | Kubernetes default | Kubernetes default |

## Monitoring

### Metrics

Metrics are emitted via Telegraf/InfluxDB/Wavefront using the Standard Measurement Architecture (SMA). Key Wavefront metric names used in alerting:

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `http.in.message` | counter | Inbound requests to `/message/v1/content` | Alert if rate drops unexpectedly |
| `http.in.remind_me_later` | counter | Inbound requests to remind-me-later endpoints | Alert if rate drops unexpectedly |
| `http.in.voucher_next_actions` | counter | Inbound requests to `/voucher/v1/next_actions` | Alert if rate drops unexpectedly |
| `http.in.error` | counter | Total inbound HTTP error responses | Alert on sustained elevation |
| `http.out.schedule` | counter | Outbound calls to RISE scheduler | Alert on elevated error rate |
| `http.out.lookupDealById` | counter | Outbound calls to deal-catalog | Alert on elevated error rate |
| `http.out.showV2Deal` | counter | Outbound calls to deal-catalog v2 | Alert on elevated error rate |
| `http.out.getBookingDetails` | counter | Outbound calls to epods | Alert on elevated error rate |
| `http.out.getOrderInventoryUnit` | counter | Outbound calls to orders | Alert on elevated error rate |
| `http.out.getMerchant` | counter | Outbound calls to m3-merchant-service | Alert on elevated error rate |
| `http.out.unitsShow` | counter | Outbound calls to voucher-inventory | Alert on elevated error rate |
| Cloud CPU | gauge | Pod CPU utilization | Alert on sustained high usage |
| Cloud Memory | gauge | Pod memory utilization | Alert if approaching 3072Mi limit |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| BRS VEX General Dashboard | Grafana | https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/d/beoi0m2hkj3eob/general-dashboard |
| BRS VEX Wavefront Dashboard | Wavefront | https://groupon.wavefront.com/dashboards/vex |
| BRS SNC1 Wavefront Dashboard | Wavefront | https://groupon.wavefront.com/dashboard/snc1-brs-vex |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| HB 503 Errors | Service returning 503s | critical | Check Kibana for `name:'app.error'` and `name:'http.in.error'`; if near deploy time, rollback; else group by message and fix in descending frequency |
| Cloud CPU high | CPU spike after deploy | warning | Check Wavefront for spike post-deploy; if correlated, rollback; else increase capacity |
| Cloud Memory Usage | Memory approaching limit | warning | Check Wavefront for post-deploy increase; rollback if correlated (fix memory leak separately); else increase capacity |
| `http.in.message#` elevated errors | Message endpoint error rate rising | warning | Check `http.out` errors; contact relevant downstream team |
| `http.in.remind_me_later#` elevated errors | Reminder endpoint error rate rising | warning | Check `http.out` errors; contact relevant downstream team |
| `http.in.voucher_next_actions#` elevated errors | Next-actions endpoint error rate rising | warning | Check `http.out` errors; contact relevant downstream team |

PagerDuty service: https://groupon.pagerduty.com/services/PDBQKO8

## Common Operations

### Restart Service

Deploybot rollback triggers a clean Kubernetes rolling restart. For a manual restart:

```sh
kubectl get pods -n breakage-reduction-service-production
kubectl rollout restart deployment/breakage-reduction-service--itier--default -n breakage-reduction-service-production
```

### Scale Up / Down

Edit `minReplicas` / `maxReplicas` in `package.json` under `napistrano.environment.{env}.{region}`, then run:

```sh
npx nap --cloud deploy:configs
```

Commit and push to trigger a deploy. Production: min 3, max 12. Staging: min 3, max 5.

### Database Operations

BRS has no relational database migrations. Redis keys are managed by the workflow engine logic. No manual migration steps are required for Redis.

## Troubleshooting

### Service returns 503 / Not Available

- **Symptoms**: `name:'app.error'` or `name:'http.in.error'` in Kibana logs
- **Cause**: Application crash, OOM, or unhealthy pods
- **Resolution**: Check pod status (`kubectl get pods`); check logs (`kubectl logs <pod> -c main`); if after a deploy, rollback via Deploybot; else identify error group and fix

### Downstream service failure (e.g., deal-catalog, voucher-inventory)

- **Symptoms**: Elevated `http.out.{operation}` error metrics in Wavefront; 5xx responses to callers
- **Cause**: Downstream service degradation
- **Resolution**: See `README.md` alert table for owning team per `http.out` operation name; escalate to that team; BRS does not have circuit breakers — callers will receive errors until the downstream recovers

### Memory leak / OOM

- **Symptoms**: Cloud Memory Usage alert; pods restarting
- **Cause**: Node.js heap growth (check `--max-old-space-size=1024`)
- **Resolution**: Rollback last deploy first; investigate heap snapshots if needed; increase memory limit as short-term mitigation

### Redis connection failure

- **Symptoms**: Workflow helper state unavailable; errors in logs from Redis client
- **Cause**: Redis cluster unavailability or misconfigured host
- **Resolution**: Check Redis host configuration in `config/stage/production.cson`; `enable_offline_queue: true` means requests will queue up; check `max_attempts: 10`

### Pod not starting

- **Symptoms**: Pods in CrashLoopBackOff
- **Cause**: Config error, missing secrets, or Node.js startup failure
- **Resolution**: `kubectl logs <pod_name> -c main`; check env vars (`KELDOR_CONFIG_SOURCE`, `PORT`, `NODE_OPTIONS`)

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no voucher next-actions or reminders served | Immediate | Post Purchase team (brs-vex@groupon.pagerduty.com) |
| P2 | Degraded — elevated error rates on one or more endpoints | 30 min | Post Purchase team (ppeng@groupon.com) |
| P3 | Minor impact — isolated errors or degraded downstream | Next business day | Post Purchase team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Voucher Inventory Service (VIS) | `http.out.unitsShow` metric; Wavefront alert | No fallback — voucher data is required for next-actions |
| Deal Catalog | `http.out.lookupDealById` / `showDeals` metrics | No fallback — deal data is required |
| Orders | `http.out.getOrderInventoryUnit` metric | `orderSummary` defaults to `{totalOrders: 0, totalResigned: 0, nonPaidOrders: 0}` |
| RISE Scheduler | `http.out.schedule` metric | No fallback — scheduling failure returns an error |
| Users Service | `http.out.loadUserDetails` metric | No fallback — user data required for personalization |
| AMS | AMS client metric | Falls back to `{}` (empty attributes) when feature flag `customer_authority_attributes` is on but AMS is unavailable |
| Redis | Redis client connection error | Workflow state reads/writes may fail; `enable_offline_queue: true` queues up to `max_attempts: 10` |

## Log Access

| Environment | Log System | Link |
|-------------|-----------|------|
| Staging | Kibana (ELK) | https://logging-stable-unified01.grpn-logging-stable.us-west-2.aws.groupondev.com/goto/c7743a9d9b4b992b101950b9278e54c7 |
| Production US | Kibana (ELK) | https://logging-prod-us-unified1.grpn-logging-prod.us-west-2.aws.groupondev.com/goto/c7743a9d9b4b992b101950b9278e54c7 |
| Production EMEA | Kibana (ELK) | https://logging-prod-eu-unified1.grpn-logging-prod.eu-west-1.aws.groupondev.com/goto/7955af9118662e1e69cfe2d85bd80ded |
