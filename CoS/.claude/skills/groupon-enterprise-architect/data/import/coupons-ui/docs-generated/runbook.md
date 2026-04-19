---
service: "coupons-ui"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/healthcheck` | HTTP | Kubernetes default (configurable via Raptor) | Kubernetes default |

The healthcheck responds `200 OK` with plain-text body `OK` and `Cache-Control: no-store`. It requires no dependencies (Redis, VoucherCloud API) to succeed, making it a pure liveness indicator.

## Monitoring

### Metrics

Metrics are emitted via Telegraf/InfluxDB using the `influx` library. Measurements are prefixed `coupons.metrics.` and tagged with `az`, `env`, `source`, `atom`, and `service`.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `coupons.metrics.*` | varies | Application-level metrics emitted per measurement name | See Grafana dashboard |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Affiliates and Coupons Dashboard | Grafana | https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/d/de77tssfsyghsc/affiliates-and-coupons-dashboard?orgId=1&refresh=5m |
| Overall Count / Error Rate | Grafana | https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/goto/B7LzUsbNR?orgId=1 |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Vouchercloud-api 503s | VoucherCloud API returning 503 errors | Warning → Critical | See VoucherCloud 503 troubleshooting below |
| Service unhealthy | Health probe failures | Warning | Check pod logs; verify Redis connectivity |
| High error rate | Elevated 5xx response rate | Critical | Check Grafana Overall Count dashboard; inspect logs in Kibana/ELK |

Alert notifications:
- Warning: `coupons-eng@groupon.com`
- Critical: `coupons-alerts@groupon.com`
- Google Chat space ID: `AAAALVmO7ak`

## Common Operations

### Restart Service

Kubernetes manages restarts automatically. To force a rolling restart:

```bash
kubectl rollout restart deployment/coupons-ui--app--default \
  --context <environment>-<region> \
  --namespace coupons-ui-<environment>
```

### Scale Up / Down

**During incidents — emergency scale via kubectl:**

```bash
EDITOR=nano kubectl edit hpa \
  --context production-us-central1 \
  --namespace coupons-ui-production
```

Edit `spec.maxReplicas` (and `spec.minReplicas` if needed). Changes take effect within a few minutes.

**Permanent scaling changes** — update `.meta/deployment/cloud/components/app/{environment}-{region}.yml`:

```yaml
minReplicas: 4
maxReplicas: 20
```

Changes apply on the next deployment via DeployBot.

### Database Operations

Coupons UI does not own a database and does not run migrations. Redis data is managed by the upstream coupon worker pipeline.

## Troubleshooting

### VoucherCloud API 503 Errors

- **Symptoms**: Redemption and redirect API routes return 500 errors; elevated error rates on Grafana dashboard; `voucherCloudApi.getRedemptionData.failed` or `voucherCloudApi.getOfferRedirect.failed` log entries
- **Cause**: Network connectivity issues between Coupons UI and VoucherCloud API, or VoucherCloud platform outage
- **Resolution**:
  1. Verify issue scope: check if all calls are affected or specific endpoints only
  2. Test direct connectivity to VoucherCloud public endpoint:
     ```bash
     curl -k --location 'https://restfulapi.vouchercloud.com/merchants/157965?countryCode=US&domainIds=19' \
       --header 'X-ApiKey: <API_KEY>'
     ```
  3. Test via hybrid-boundary service:
     ```bash
     curl -k --location 'http://vouchercloud-idl.production.service/merchants/157965?countryCode=US&domainIds=19' \
       --header 'X-ApiKey: <API_KEY>'
     ```
  4. If network issue: escalate to network team
  5. If VoucherCloud platform issue: contact VoucherCloud support

### Redis Connectivity Failure

- **Symptoms**: Merchant pages fail to render; `vouchercloud.getMerchantData.failed` or `vouchercloud.getSiteWideData.redisFailed` log entries
- **Cause**: Redis Memorystore instance unreachable or overloaded
- **Resolution**:
  1. Check ioredis connection errors in application logs (Kibana/ELK)
  2. Verify Redis Memorystore instance health in GCP/AWS console
  3. Confirm Redis host configuration matches the correct environment in config file
  4. Increase `maxRetries` as a temporary mitigation if transient errors persist

### High Memory Usage

- **Symptoms**: OOM kills; pod restarts; memory limit exceeded in Kubernetes events
- **Cause**: In-memory NodeCache growing beyond `cache.maxSize` (default 1 GiB); or Redis connection pool accumulation
- **Resolution**:
  1. Check pod memory metrics in Grafana
  2. Verify `UV_THREADPOOL_SIZE` is set to `75` (prevents thread pool exhaustion contributing to memory pressure)
  3. Consider reducing `cache.maxSize` in configuration if NodeCache is growing too large
  4. Rolling restart to clear process-local cache state

### Configuration Fails to Load

- **Symptoms**: Service starts but returns `500 Configuration not available` for all requests
- **Cause**: `DEPLOY_ENV` or `DEPLOY_REGION` not set; or referenced environment variable placeholder (e.g., `${VCAPI_US_API_KEY}`) not defined
- **Resolution**:
  1. Verify environment variables `DEPLOY_ENV` and `DEPLOY_REGION` are set in the pod spec
  2. Check that all secret references (`VCAPI_US_API_KEY`, `ALGOLIA_API_ID`, `ALGOLIA_API_KEY`) are populated as Kubernetes secrets
  3. Review startup logs for `Failed to load config file` or `Environment variable X is not defined` messages

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down — no coupon pages rendering | Immediate | Coupons team on-call; coupons-alerts@groupon.com |
| P2 | Redemption or redirect flow degraded — offers visible but cannot be redeemed | 30 min | coupons-eng@groupon.com |
| P3 | Search widget unavailable (Algolia); GTM not loading | Next business day | coupons-eng@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| VoucherCloud API | `curl https://restfulapi.vouchercloud.com/merchants/{id}?countryCode=US&domainIds=19 -H 'X-ApiKey: ...'` | Returns `null`; API routes respond with 500 JSON error |
| Redis (Memorystore) | Check pod logs for ioredis connection errors; check GCP/AWS console | Returns `null`; merchant page renders fail (no cached data fallback) |
| Algolia | Client-side only; check browser network tab | Search widget becomes non-functional; page still renders |
| GTM | Browser network tab or GTM preview mode | Analytics events lost; no functional impact |
