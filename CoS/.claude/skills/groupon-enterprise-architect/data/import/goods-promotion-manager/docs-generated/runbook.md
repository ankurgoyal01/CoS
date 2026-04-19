---
service: "goods-promotion-manager"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /status.json` | HTTP | JTier default | JTier default |
| `GET /grpn/status` | HTTP | JTier default | JTier default |

The `/status.json` endpoint returns `{"isHealthy": true}` when the service is operational. The JTier framework monitors this endpoint for liveness.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request processing time | histogram | P95 target: ~0.5s for reads, ~1s for writes (per OWNERS_MANUAL) | P95 > 1s (reads) or P95 > 2s (writes) |
| JVM memory usage | gauge | Heap and off-heap memory consumption | Container memory limit (6Gi staging / 30Gi production) |
| Database connection pool | gauge | Active and idle JDBI connections | Pool exhaustion |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Primary SMA dashboard | Wavefront | `https://groupon.wavefront.com/u/B8RGNSYZK7?t=groupon` |
| Secondary dashboard | Wavefront | `https://groupon.wavefront.com/u/8yF7Fyy1Tv?t=groupon` |
| snc1 Load Balancer | Wavefront | `https://groupon.wavefront.com/dashboard/lb_netscaler-vip_info` (snc1 VIP) |
| sac1 Load Balancer | Wavefront | `https://groupon.wavefront.com/dashboard/lb_netscaler-vip_info` (sac1 VIP) |
| Production logs | Kibana / Logging | `https://logging-us.groupondev.com/goto/e9076e77684e01a7240d95e3ddd23868` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Default infrastructure alerts | CPU, disk, or memory threshold breach | Warning / Critical | Investigate resource usage; scale pods if needed (see Scaling section) |
| PagerDuty service | Any critical alert | Critical | Page on-call via `https://groupon.pagerduty.com/services/PX8IU6S` |

No custom Opsgenie/PagerDuty alerts are configured beyond infrastructure defaults as of the last update to the OWNERS_MANUAL.

Full runbook: `https://groupondev.atlassian.net/wiki/spaces/GOOD/pages/25018545460/Goods+Intelligence+Runbook`

## Common Operations

### Restart Service

On legacy on-prem (snc1/sac1):
```bash
# Start
sudo /usr/local/bin/sv start jtier

# Stop
sudo /usr/local/bin/sv stop jtier
```

On cloud (Kubernetes), use standard `kubectl rollout restart` via Deploybot or via the cluster context `goods-promotion-manager-gcp-production-sox-us-central1`.

### Scale Up / Down

1. Edit `.meta/deployment/cloud/components/app/production-us-central1.yml`:
   - Increase `minReplicas` / `maxReplicas` for additional pod replicas
   - Increase `cpus.main.request` for more CPU per pod
   - Increase `memory.main.request` / `memory.main.limit` for more memory per pod
2. Merge to `master`, deploy through Deploybot to staging, then promote to production.
3. Verify with `kubectl describe pod <pod-name>` checking `Limits:` and `Requests:`, or `kubectl get pods` for replica count.

### Database Operations

- **Migrations**: Add a `.sql` file under `src/main/resources/db/migration` using Flyway naming convention (`Vx.x__description.sql`). Migrations run automatically on service startup via the `jtier-migrations` bundle (`jtier.plugin.flyway.baselineOnMigrate=true`).
- **Manual CSV extraction**: If the service is unavailable and a CSV is urgently needed, run the SQL query documented in the OWNERS_MANUAL against the production database, add the CSV header row, and send to the requesting team.

## Troubleshooting

### Deployment Smoke Test Failure (Quartz DB Connection Surge)

- **Symptoms**: Deploybot reports smoke test failure; service may roll back to the previous version
- **Cause**: Quartz scheduler acquires a large number of PostgreSQL connections on startup, which can overwhelm the connection pool during smoke test validation
- **Resolution**: Wait at least one hour after rollback, then retry the deployment from Deploybot. This is a known, non-critical Quartz behavior.

### CSV Download Returns "Failed - Forbidden"

- **Symptoms**: A buyer reports `Failed - Forbidden` when downloading a promotion CSV
- **Cause**: Authentication/authorization mismatch; the client-ID may lack the required role
- **Resolution**:
  1. Confirm the promotion name and retrieve its UUID: `SELECT name, uuid FROM promotion WHERE name ILIKE '%<promotion_name>%'`
  2. Use the `POST /v1/promotions/csv_data` endpoint directly via Postman with a valid `clientId` and the promotion UUID in the request body
  3. Save the response as a CSV and send to the requester
  4. See OWNERS_MANUAL for the full example curl command

### Service Down — Emergency CSV Extraction

If the service is completely unavailable, run the documented SQL query directly against the production database (see OWNERS_MANUAL `## Download CSV` section for the full query joining `promotion`, `promotion_deal`, `promotion_inventory_product`, `deal`, and `inventory_product` tables). Manually prepend the CSV header:
```
start_date,end_date,permalink,inventory_product_id,unit_price,unit_buy_price,offer_sell_price,offer_buy_price,currency_code,country_code,division
```

### High Processing Times

- **Symptoms**: P95 response time exceeds 0.5s for reads or 1s for writes
- **Cause**: Database query performance degradation, connection pool exhaustion, or insufficient pod resources
- **Resolution**: Check Wavefront dashboards for CPU/memory pressure; check PostgreSQL slow query logs; consider scaling pods or increasing resource requests

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down; promotions cannot be created or submitted | Immediate | goods-oncall@groupon.com via PagerDuty PX8IU6S |
| P2 | Degraded performance; slow responses; CSV downloads failing | 30 min | goods-eng-seattle@groupon.com |
| P3 | Minor impact; non-critical feature degradation | Next business day | goods-eng-seattle@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumGoodsPromotionManagerDb` (PostgreSQL) | JTier health check via JDBI connection probe | No fallback; service will fail health checks if database is unreachable |
| `continuumDealManagementApi` | No explicit health check; failure logged during Import Product Job | Service continues with previously imported deal/inventory data |
| `corePricingServiceSystem` | No explicit health check; failure logged during Update Established Price Job | Service continues with previously fetched established prices; CSV exports may have stale pricing |
