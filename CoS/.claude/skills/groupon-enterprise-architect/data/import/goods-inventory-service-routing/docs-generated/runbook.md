---
service: "goods-inventory-service-routing"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/status` | HTTP | Per-request (Dropwizard JTier) | Default JTier |
| Heartbeat file `./heartbeat.txt` | file-existence | JTier-managed (`heartbeatCheckIntervalSeconds` default) | JTier-managed |
| Dropwizard admin health at `:8081/healthcheck` | HTTP | Kubernetes liveness/readiness probe | Platform-managed |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| JVM heap usage | gauge | JVM memory consumption | To be defined by service owner |
| HTTP request rate (in) | counter | Inbound requests to `/inventory/v1/products` | To be defined by service owner |
| HTTP error rate (in) | counter | 4xx/5xx responses returned to callers | To be defined by service owner |
| HTTP request rate (out) | counter | Outbound calls to GIS | To be defined by service owner |
| HTTP error rate (out) | counter | Non-2xx responses from GIS | To be defined by service owner |
| DB query duration | histogram | JDBI query latency against `inventory_product_shipping_regions` | To be defined by service owner |

Metrics are published via Codahale Metrics to a Telegraf agent at `http://localhost:8186/` (flush every 10 seconds), as configured in `src/main/resources/metrics.yml`.

Dashboards are defined in `doc/_dashboards/` using JTier SMA dashboard components covering HTTP in/out, JVM, cloud, and service health.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| SMA Service Health | JTier SMA (`doc/_dashboards/sma.js`) | Configured in `doc/_dashboards/components/sma/service-health.js` |
| HTTP In | JTier SMA | `doc/_dashboards/components/sma/http-in.js` |
| HTTP Out | JTier SMA | `doc/_dashboards/components/sma/http-out.js` |
| JVM | JTier SMA | `doc/_dashboards/components/jvm.js` |
| Cloud | JTier SMA | `doc/_dashboards/components/cloud.js` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| GIS unreachable | `UNABLE_TO_REACH_GIS` error rate elevated | critical | Check GIS health; check network connectivity between routing pods and GIS; inspect logs |
| DB connection failure | JDBI errors / connection pool exhaustion | critical | Check PostgreSQL host reachability; check `DAAS_APP_USERNAME`/`DAAS_APP_PASSWORD` secrets; inspect connection pool settings |
| High 4xx rate | Elevated `MIXED_SHIPPING_REGIONS` or `MISSING_SHIPPING_REGIONS` errors | warning | Investigate caller payloads; check if new shipping regions need to be added to `gisRegions` config |
| Pagerduty | Any P1 incident | critical | `https://groupon.pagerduty.com/services/P7VSOA6` |

## Common Operations

### Restart Service

Operational procedures to be defined by service owner. In Kubernetes: scale down and scale up the deployment in namespace `goods-inventory-service-production` or `goods-inventory-service-staging`. Use DeploybotV2 for controlled restarts to preserve deployment history.

### Scale Up / Down

Use DeploybotV2 or update the Raptor deployment manifest in `.meta/deployment/cloud/components/routing/` and redeploy. Production HPA range: 3–15 replicas. Staging HPA range: 1–15 replicas.

### Database Operations

- **Migrations**: Applied automatically by JTier DaaS during deployment via the scripts in `src/main/resources/db/migration/`. Do not run migrations manually against production.
- **Backfill shipping regions**: If the `inventory_product_shipping_regions` table is missing entries for existing products, perform a backfill by driving upsert requests through the routing service for each affected product UUID (GIS write will trigger the persistence path).
- **Inspect routing data**: Connect to the production PostgreSQL host `goods-inventory-service-routing-rw-na-production-db.gds.prod.gcp.groupondev.com`, database `goods_inv_serv_routing_prod`, and query `inventory_product_shipping_regions` by `inventory_product_uuid`.

## Troubleshooting

### UNABLE_TO_REACH_GIS errors (HTTP 500)

- **Symptoms**: Callers receive `{"httpCode":500,"errors":[{"code":"UNABLE_TO_REACH_GIS","message":"UNABLE_TO_REACH_GIS"}]}`
- **Cause**: The OkHttp call from `gisClient` to the regional GIS endpoint threw an `IOException` — network partition, GIS pod restart, or DNS resolution failure
- **Resolution**: Check GIS service health; check Kubernetes DNS for `goods-inventory-service.production.service`; check Hybrid Boundary sidecar logs; review routing pod logs (steno-trace format)

### MIXED_SHIPPING_REGIONS errors (HTTP 400)

- **Symptoms**: Callers receive `{"httpCode":400,"errors":[{"code":"MIXED_SHIPPING_REGIONS",...}]}`
- **Cause**: A request batch contains products whose shipping regions span more than one configured GIS region (e.g., mixing US and GB products in a single POST)
- **Resolution**: Callers must split multi-region batches into separate requests, one per geographic region

### NO_GIS_REGION_FOUND errors (HTTP 400)

- **Symptoms**: Callers receive `{"httpCode":400,"errors":[{"code":"NO_GIS_REGION_FOUND",...}]}`
- **Cause**: A shipping region country code in the request does not match any entry in the configured `gisRegions[*].shippingRegions` list
- **Resolution**: Add the new country code to the appropriate `gisRegions` entry in the environment config file and redeploy; or the caller is sending an invalid country code

### Inventory product not found (empty response on GET)

- **Symptoms**: GET returns an empty `inventoryProducts` list even though products exist in GIS
- **Cause**: The `inventory_product_shipping_regions` table has no row for the requested UUID(s) — the product was created directly in GIS without going through the routing service
- **Resolution**: Drive an upsert for the missing product UUID through the routing service to populate the shipping-region record

### DB connection pool exhaustion

- **Symptoms**: JDBI errors in logs; slow or failing requests with database-related stack traces
- **Cause**: `maxThreads` (500) threads could all hold DB connections if all requests hit the DB simultaneously
- **Resolution**: Check PostgreSQL connection limits and DaaS pool sizing; scale up pods or reduce `maxThreads` if needed

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — all inventory routing requests failing | Immediate | RAPT team via PagerDuty (P7VSOA6); Slack `#goods-eng-seattle` |
| P2 | Degraded — elevated error rate, partial routing failures | 30 min | RAPT team Slack `#goods-eng-seattle` |
| P3 | Minor impact — individual product routing failures or stale shipping-region data | Next business day | RAPT team email `inventory@groupon.com` |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumGoodsInventoryService` | Verify `GET /inventory/v1/products?ids=<known-uuid>` succeeds end-to-end; check GIS service dashboards | No automatic fallback — routing requests will fail with `UNABLE_TO_REACH_GIS` |
| `continuumGoodsInventoryServiceRoutingDb` | Query `SELECT 1` on production PostgreSQL host; check DaaS connection pool metrics | No fallback — service cannot route reads (GET) without DB; writes will also fail during routing-lookup step |
