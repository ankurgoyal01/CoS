---
service: "coupons-astro-demo"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Kubernetes liveness/readiness probes | http | Managed by Kubernetes via `cmf-generic-api` Helm chart | Per Helm defaults |
| Admin port `8081` | tcp | Declared in `.meta/deployment/cloud/components/app/common.yml` | Not configured in codebase |

> Specific health check endpoint paths and intervals are not visible in the repository; they are defined by the `cmf-generic-api` Helm chart version `3.72.1`. Operational procedures to be defined by service owner.

## Monitoring

### Metrics

> No evidence found in codebase. Metrics configuration is expected to be provided by the `cmf-generic-api` Helm chart infrastructure layer.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| coupons-astro service | Not documented in codebase | Operational procedures to be defined by service owner |

### Alerts

> Operational procedures to be defined by service owner.

## Common Operations

### Restart Service

1. Identify the running pods: `kubectl get pods -n coupons-astro-staging`
2. Perform a rolling restart: `kubectl rollout restart deployment/coupons-astro -n coupons-astro-staging`
3. Monitor rollout: `kubectl rollout status deployment/coupons-astro -n coupons-astro-staging`

### Scale Up / Down

Scaling is governed by the HPA configured via Helm values. To temporarily override:
```
kubectl scale deployment/coupons-astro --replicas=<N> -n coupons-astro-staging
```
For permanent changes, update `minReplicas` / `maxReplicas` in `.meta/deployment/cloud/components/app/common.yml` (or the per-environment override file) and re-deploy.

### Database Operations

This service owns no database. Redis is external and read-only from this service's perspective. Cache key versioning (`:v3`, `:v4` suffixes) is the mechanism for migrating to new data formats without breaking running instances. To flush stale cache entries, coordinate with the VoucherCloud pipeline team.

## Troubleshooting

### Merchant page returns 404

- **Symptoms**: `GET /coupons/[merchantPermalink]` redirects to `/404`
- **Cause**: The Redis cache key `getMerchantDetails:{permalink}:v4` returned null — either the key does not exist, the cache is empty, or Redis is unreachable
- **Resolution**: Verify Redis connectivity (`REDIS_HOST`, `REDIS_PORT`); confirm the merchant permalink is valid and that VoucherCloud has populated the cache; check pod logs for `"Redis connection error:"` messages

### Page renders with no offers

- **Symptoms**: The merchant page loads but the offers list is empty
- **Cause**: Redis cache key `VC_merchantOffers:{permalink}:v3` returned null or an empty `Offers` array
- **Resolution**: Confirm VoucherCloud has populated offers data for this merchant; check Redis key existence directly on the cache host

### Redis connection errors in logs

- **Symptoms**: Log lines matching `"Redis connection error:"` appear in pod stdout
- **Cause**: Network connectivity to Redis host (`REDIS_HOST`) is broken, or credentials are incorrect
- **Resolution**: Verify the `REDIS_HOST` env var matches the Memorystore hostname; verify `REDIS_PASSWORD` secret is correctly mounted; check GCP VPC peering between the cluster and Memorystore

### High latency on merchant pages

- **Symptoms**: `/coupons/[merchantPermalink]` response times are elevated
- **Cause**: The route handler issues 6 concurrent Redis GET operations; if Redis latency spikes, all 6 calls are affected. The `commandTimeout` is 5 seconds per command.
- **Resolution**: Monitor Redis latency metrics on the Memorystore instance; consider increasing pod replicas to reduce per-pod request load; review HPA utilization target (currently 50%)

### Advert carousel not rendering

- **Symptoms**: The sidebar advert carousel is absent on the merchant page
- **Cause**: `getAdverts('Carousel', 32)` returned null or an empty array from Redis (cache key `getAdvertData:32768:32`)
- **Resolution**: Confirm VoucherCloud advert cache is populated for the `Carousel` type (mapped to value `32768`)

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | All merchant coupon pages returning errors | Immediate | Coupons Engineering (Slack: #coupons) |
| P2 | Specific merchants failing or degraded data | 30 min | Coupons Engineering |
| P3 | Minor visual issues (e.g., missing adverts, empty sidebar) | Next business day | Coupons Engineering |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| VoucherCloud Redis Cache | `ioredis` connection event (`connect` / `error` logged to stdout); check pod logs for `"Redis connection error:"` | Most null responses degrade gracefully to empty arrays; missing merchant data results in redirect to `/404` |
