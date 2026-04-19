---
service: "coupons-itier-global"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| I-Tier platform health endpoint (standard `/health` or `/status`) | HTTP | Not documented | Not documented |

> Specific health check configuration is not captured in the architecture inventory. Operational procedures to be defined by service owner (coupons-eng@groupon.com).

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Request latency | histogram | End-to-end latency for page and redirect requests | Not documented |
| Redis cache hit rate | gauge | Ratio of cache hits vs misses for `continuumCouponsRedisCache` | Not documented |
| Vouchercloud API error rate | counter | Count of failed requests to Vouchercloud API | Not documented |
| GAPI error rate | counter | Count of failed GraphQL requests to GAPI | Not documented |
| Redirect cache refresh success | counter | Successful executions of `redirectCacheCron` | Not documented |

Metrics are reported via `influx` v5.10.0 to InfluxDB.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Coupons I-Tier metrics | InfluxDB / Grafana (inferred from `influx` library) | Not documented |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High Vouchercloud API error rate | Sustained upstream failures causing cache miss degradation | critical | Check Vouchercloud API availability; verify credentials; inspect Redis cache fill status |
| Redis unavailable | `continuumCouponsRedisCache` unreachable | critical | Check Redis connection; restart if needed; all requests will fall through to live upstream APIs |
| Redirect cache refresh failure | `redirectCacheCron` not completing successfully | warning | Check cron logs; verify Vouchercloud API connectivity; manually trigger cache refresh if needed |

## Common Operations

### Restart Service

> Operational procedures to be defined by service owner. Follow Continuum I-Tier standard restart procedures for the Kubernetes deployment.

### Scale Up / Down

> Adjust Kubernetes HPA min/max replica configuration. Contact coupons-eng@groupon.com for scaling thresholds.

### Database Operations

Redis is used as a cache only. There are no schema migrations. To flush stale cache entries:

1. Identify the affected key pattern (offer payloads, redirect rules, or render payloads)
2. Use Redis CLI or an admin tool to delete the affected keys
3. The service will repopulate the cache on the next request or on the next `redirectCacheCron` execution

## Troubleshooting

### Coupon pages rendering stale or missing data
- **Symptoms**: Pages show outdated coupon offers or blank content sections
- **Cause**: Stale Redis cache entries or upstream Vouchercloud/GAPI API failure
- **Resolution**: Check Redis cache TTLs; verify Vouchercloud and GAPI API availability; flush affected cache keys to force a fresh fetch

### Affiliate redirects failing or looping
- **Symptoms**: `/redirect/merchant/{id}` or `/redirect/offers/{id}` return errors or unexpected destinations
- **Cause**: Stale or missing redirect rules in `continuumCouponsRedisCache`; `redirectCacheCron` not running
- **Resolution**: Verify `redirectCacheCron` is executing on schedule; manually refresh redirect cache entries; check Vouchercloud API for current redirect rule data

### Redirect cache refresh not running
- **Symptoms**: Redirect rules in Redis are stale; `redirectCacheCron` execution logs absent
- **Cause**: `node-schedule` cron misconfiguration or Node.js process crash
- **Resolution**: Restart the service; verify cron expression in application configuration; check process logs for scheduler errors

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no coupons pages or redirects served | Immediate | coupons-eng@groupon.com |
| P2 | Degraded — pages serving stale data or partial content | 30 min | coupons-eng@groupon.com |
| P3 | Minor — single country or category affected | Next business day | coupons-eng@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumCouponsRedisCache` | Check Redis connectivity via `ioredis` connection status | Requests fall through to live Vouchercloud/GAPI API calls (higher latency, increased upstream load) |
| Vouchercloud API | HTTP request to Vouchercloud health or probe endpoint | Serve cached data from Redis if available; degrade gracefully if cache is also empty |
| GAPI | GraphQL health check or probe query | Serve page with available data; omit deal content sections if unavailable |
