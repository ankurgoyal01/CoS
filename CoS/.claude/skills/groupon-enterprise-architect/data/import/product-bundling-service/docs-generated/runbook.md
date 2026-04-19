---
service: "product-bundling-service"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/grpn/status` (port 8080) | HTTP | Kubernetes liveness/readiness probe interval | Per cluster defaults |
| `heartbeat.txt` | File | Checked by JTier health bundle (`jtier.health.heartbeatPath`) | Per JTier defaults |
| Admin connector (port 8081) | HTTP | Internal Dropwizard admin metrics/healthcheck | On demand |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP inbound request rate | counter/histogram | Requests per second to PBS API endpoints | SMA dashboard |
| HTTP outbound request rate | counter/histogram | Requests per second to DCS, VIS, GIS, Flux | SMA dashboard |
| JVM heap usage | gauge | JVM memory utilization | Wavefront unified dashboard |
| Quartz job execution time | histogram | Duration of WarrantyBundlesRefreshJob and RecommendationsRefreshJob | Wavefront |
| PostgreSQL connection pool utilization | gauge | Active/idle connections for read and write pools | Wavefront |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| PBS Unified Dashboard | Wavefront | `https://groupon.wavefront.com/dashboards/product-bundling-service-unified-dashboard` |
| PBS SNC1 Dashboard | Wavefront | `https://groupon.wavefront.com/dashboard/snc1-product-bundling-service` |
| PBS JTier SNC1 Dashboard | Wavefront | `https://groupon.wavefront.com/dashboard/snc1-pbs_jtier-snc1` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Service unavailable | `/grpn/status` returns non-200 | P1 | Restart service pods; check logs for startup errors |
| High error rate | HTTP 5xx rate above baseline | P2 | Check Deal Catalog Service and PostgreSQL connectivity |
| Quartz job failure | Job execution exception logged | P2 | Check downstream dependencies (DCS, VIS, GIS, Flux, HDFS); trigger manual refresh |
| PagerDuty | See PagerDuty service page | P1/P2 | `https://groupon.pagerduty.com/services/PDONLHN` |

## Common Operations

### Restart Service

Operational procedures to be defined by service owner. For Kubernetes environments:
1. Identify the pod(s) in the relevant namespace (`product-bundling-service-production` or `product-bundling-service-staging`)
2. Use `kubectl rollout restart deployment/product-bundling-service -n <namespace>`
3. Verify new pods reach `Running` state and `/grpn/status` returns 200

### Scale Up / Down

For Kubernetes (GCP):
1. HPA automatically scales between `minReplicas` and `maxReplicas` based on CPU utilization
2. For manual override: `kubectl scale deployment/product-bundling-service --replicas=<N> -n <namespace>`
3. Production HPA: min 2 / max 50 replicas

### Manual Refresh Trigger

To trigger a bundle refresh job without waiting for the scheduled cron:
```
POST http://product-bundling-service-vip.snc1/v1/bundles/refresh/{refreshType}?requester=<your-name>&message=<reason>
```
Where `refreshType` is one of: `warranty`, `customer_also_bought`, `customer_also_bought_2`, `customer_also_viewed`, `sponsored_similar_item`

### Database Operations

- Schema migrations are run via `jtier-migrations` on service startup
- Database: `pbs_development` (dev), environment-specific database name in production/staging configs
- Read replica: `readPostgres` config block; Write primary: `writePostgres` config block
- For backfills or manual SQL operations, use the `pbs_dev_dba` role credentials (managed externally)

## Troubleshooting

### Bundles Not Appearing in DC Response

- **Symptoms**: Deal Catalog response does not include `bundles` data for a deal that has bundles in PBS
- **Cause**: PBS successfully wrote bundles to Postgres but the Deal Catalog node upsert failed (DCS unavailable or returned error)
- **Resolution**: Check DCS availability; manually trigger `POST /v1/bundles/{dealUuid}/{bundleType}` to re-attempt the bundle create and DCS node sync

### Recommendations Refresh Job Not Completing

- **Symptoms**: `RecommendationsRefreshJob` logs show exception; Watson KV Kafka not receiving recommendation events
- **Cause**: Flux API unavailable, HDFS input file missing (Cerebro pipeline not run), or HDFS output not available after Flux run
- **Resolution**: Check Flux API health; verify Cerebro HDFS input files exist for the expected path; verify Flux run status via Flux API; trigger manually with `POST /v1/bundles/refresh/{refreshType}` after dependencies are healthy

### Warranty Refresh Job Not Completing

- **Symptoms**: `WarrantyBundlesRefreshJob` logs show exception; warranty bundles not updated in PBS
- **Cause**: Voucher Inventory Service or Goods Inventory Service unavailable; Deal Catalog Service unavailable for deal lookups
- **Resolution**: Check VIS and GIS health; check DCS health; retry the job manually via `POST /v1/bundles/refresh/warranty`

### Bundle Create Returns 403

- **Symptoms**: `POST /v1/bundles/{dealUuid}/{bundleType}` returns HTTP 403
- **Cause**: No config found in `bundles_config` table for the requested `bundleType`, or no creative contents found in DCS for the provided `bundledProductId`
- **Resolution**: Verify the `bundleType` exists in the `bundles_config` table; verify the `bundledProductId` has creative contents registered in Deal Catalog Service

### Bundle Create Returns 400

- **Symptoms**: `POST /v1/bundles/{dealUuid}/{bundleType}` returns HTTP 400
- **Cause**: `bundleType` is not in the `allowedBundleTypes` list, or `bundledProductId` format is invalid, or product UUIDs are invalid
- **Resolution**: Confirm `bundleType` is one of the configured allowed types; validate UUIDs in the request body

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down — bundles unavailable for DC responses | Immediate | deal-platform-urgent@groupon.com; PagerDuty PDONLHN |
| P2 | Degraded — refresh jobs failing or high error rate | 30 min | deal-platform-urgent@groupon.com; Slack CFPDDNHNW |
| P3 | Minor impact — single job run failure, individual deal bundles stale | Next business day | deal-catalog-dev@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Deal Catalog Service | `GET http://deal-catalog-staging.snc1/grpn/status` | Bundle CRUD still persists to PBS Postgres; DCS node sync will fail silently |
| Voucher Inventory Service | `GET http://voucher-inventory-ht-staging.snc1/grpn/status` | Warranty refresh job fails for affected options; existing bundles remain in place |
| Goods Inventory Service | `GET http://goods-inventory-service-vip-staging.snc1/grpn/status` | Warranty refresh job fails for affected options; existing bundles remain in place |
| PostgreSQL (read/write) | JDBI connection pool health (Dropwizard admin health check) | Service cannot read or write bundles; all endpoints will return 500 |
| Flux API | Check Flux API status endpoint | Recommendations refresh job fails; existing recommendation bundles remain |
| HDFS (Cerebro/Gdoop) | Check Hadoop cluster status | Recommendations refresh job fails; no new recommendations published to Kafka |
