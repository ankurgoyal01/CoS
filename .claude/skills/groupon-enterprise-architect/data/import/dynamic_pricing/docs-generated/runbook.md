---
service: "dynamic_pricing"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/heartbeat.txt` | http | Kubernetes default | Kubernetes default |

> The `/heartbeat.txt` endpoint is served by `continuumDynamicPricingNginx_healthEndpoint` and is used for Kubernetes liveness and readiness probes on the NGINX proxy container. Application-level health endpoints are served by `continuumPricingService_configHeartbeatController`.

## Monitoring

### Metrics

> No evidence found for specific metric names in the available architecture inventory. Operational procedures to be defined by service owner.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Price update latency | histogram | End-to-end latency of the price update workflow | No evidence found |
| Redis cache hit rate | gauge | Ratio of cache hits to total current price requests | No evidence found |
| MBus publish failures | counter | Count of failed event publications to `continuumMbusBroker` | No evidence found |
| DB connection errors | counter | JDBC connection failures to `continuumPricingDb` or `continuumPwaDb` | No evidence found |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Dynamic Pricing Service | No evidence found | No evidence found |

> Dashboard configuration is managed externally. Contact the Dynamic Pricing team (hijain) for dashboard links.

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Price update failure spike | High rate of failed writes to `continuumPricingDb` | critical | Check DB connectivity; review `continuumPricingService_priceUpdateWorkflow` logs |
| Redis cache unavailable | Redis connection errors from `continuumPricingService_redisCacheClient` | critical | Verify `continuumRedisCache` health; price reads will fall back to DB |
| MBus publish failure | Event publication errors from `continuumPricingService_mbusPublishers` | critical | Verify `continuumMbusBroker` connectivity; downstream consumers will not receive price events |
| VIS integration failure | HTTP errors from `continuumPricingService_visHttpClient` | warning | Check `continuumVoucherInventoryService` health; program price creation will be blocked |
| Deal Catalog failure | HTTP errors from `continuumPricingService_dealCatalogClient` | warning | Check `continuumDealCatalogService` health; program price validation will be blocked |

## Common Operations

### Restart Service

> Operational procedures to be defined by service owner. Restarting the Pricing Service pod via Kubernetes will reconnect all JMS consumers and Redis clients on startup. Quartz jobs will resume from persisted state in `continuumPricingDb`.

### Scale Up / Down

> Operational procedures to be defined by service owner. Scale the Pricing Service deployment via Kubernetes. The `continuumDynamicPricingNginx` upstream configuration defines separate read and write pod pools — coordinate NGINX config updates when pod counts change significantly.

### Database Operations

> Operational procedures to be defined by service owner. Schema migrations for `continuumPricingDb` should be applied with the service quiesced or in a maintenance window, given the Quartz job store tables. The `continuumPwaDb` is a shared database — coordinate changes with other consumers.

## Troubleshooting

### Current price returning stale data

- **Symptoms**: Price reads from `/pricing_service/v2.0/product/{id}/current_price` return prices that do not reflect a recent update
- **Cause**: Redis PriceSummary cache entry not expired after a price write; or cache expiry failed silently
- **Resolution**: Verify `continuumPricingService_redisCacheClient` is successfully expiring cache keys after writes; check Redis connectivity and error logs

### Program price creation failing

- **Symptoms**: POST to `/pricing_service/v2.0/program_price` returns error or times out
- **Cause**: Dependency failure on `continuumVoucherInventoryService` (VIS) or `continuumDealCatalogService` during validation; or transactional write failure to `continuumPricingDb`
- **Resolution**: Check VIS and Deal Catalog service health; review `continuumPricingService_programPriceService` logs for validation errors; check DB connectivity

### Price events not reaching downstream consumers

- **Symptoms**: Downstream services report stale prices; MBus consumer lag increasing
- **Cause**: `continuumPricingService_mbusPublishers` failing to connect or publish to `continuumMbusBroker`
- **Resolution**: Verify MBus broker health; check JMS connection configuration; review publisher error logs in `continuumPricingService`

### Scheduled price updates not firing

- **Symptoms**: Expected price changes at scheduled times are not applied
- **Cause**: Quartz job runner (`continuumPricingService_quartzJobRunner`) or scheduled update worker (`continuumPricingService_scheduledUpdateWorker`) not running; Quartz table corruption in `continuumPricingDb`
- **Resolution**: Check Quartz job and trigger status in `continuumPricingDb`; verify `continuumPricingService_scheduledUpdateWorker` thread health; restart service if worker threads have died

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no pricing reads or writes available | Immediate | Dynamic Pricing team (hijain) |
| P2 | Degraded — price writes succeeding but events not publishing; or cache down | 30 min | Dynamic Pricing team (hijain) |
| P3 | Minor impact — scheduled jobs delayed; history queries slow | Next business day | Dynamic Pricing team (hijain) |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumPricingDb` | JDBC connection test | No fallback — price reads and writes will fail |
| `continuumPwaDb` | JDBC connection test | Price updates can partially succeed but PWA parity will be broken |
| `continuumRedisCache` | Redis PING | Falls back to direct DB reads for current price lookups (higher latency) |
| `continuumMbusBroker` | JMS connection test | Price writes succeed locally but downstream consumers receive no events |
| `continuumVoucherInventoryService` | HTTP GET health endpoint | Program price creation and validation blocked |
| `continuumDealCatalogService` | HTTP GET health endpoint | Program price validation blocked |
