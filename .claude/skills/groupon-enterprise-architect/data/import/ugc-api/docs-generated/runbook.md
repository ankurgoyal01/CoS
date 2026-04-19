---
service: "ugc-api"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Notes |
|---------------------|------|-------|
| `GET /health` | HTTP | Returns service health status; used by Kubernetes liveness/readiness probes |
| `GET /heartbeat.txt` | HTTP | Static file response; used by load balancer health checks |
| `GET /ping` | HTTP | Liveness ping |
| `GET /grpn/status` (port 8080) | HTTP | JTier status endpoint; returns commit ID via `commitId` key |
| Kubernetes liveness probe | HTTP | Configured via JTier Helm chart; checks `/health` |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request rate | counter | Requests per second across all endpoints | Wavefront dashboard |
| HTTP error rate (5xx) | counter | Server error rate across all endpoints | Wavefront alert |
| HTTP latency (p99) | histogram | Request latency at 99th percentile | Wavefront alert |
| JVM heap usage | gauge | JVM heap utilization as percentage of max | Wavefront dashboard |
| DB connection pool saturation | gauge | JDBI connection pool exhaustion | Wavefront alert |
| Redis connection health | gauge | Redis client connectivity status | Wavefront alert |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| UGC API JTier | Wavefront | https://groupon.wavefront.com/dashboard/ugc-api-jtier |
| UGC API (custom 1) | Wavefront | https://groupon.wavefront.com/u/fmGCtGwBGL?t=groupon |
| UGC API (custom 2) | Wavefront | https://groupon.wavefront.com/u/HbXM1Zx1sz?t=groupon |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High 5xx rate | HTTP 5xx rate exceeds threshold | critical | Check logs, DB connectivity, downstream service health |
| High latency | p99 latency exceeds SLO | warning | Check DB query performance, connection pool saturation, Redis availability |
| PagerDuty service | ugc-alerts@groupon.com / P057HSW | critical | Escalate to UGC on-call via Slack `#ugc` and PagerDuty |

## Common Operations

### Restart Service

1. Identify the target Kubernetes namespace: `ugc-api-jtier-{environment}` (e.g., `ugc-api-jtier-production`)
2. Use kubectl or deploy-bot to trigger a rolling restart:
   ```
   kubectl rollout restart deployment/ugc-api-jtier -n ugc-api-jtier-production
   ```
3. Monitor rollout: `kubectl rollout status deployment/ugc-api-jtier -n ugc-api-jtier-production`
4. Verify health: `GET /health` returns 200

### Scale Up / Down

1. Scale via deploy-bot (preferred) by adjusting `minReplicas`/`maxReplicas` in the environment YAML and redeploying
2. Emergency scale via kubectl:
   ```
   kubectl scale deployment/ugc-api-jtier --replicas=N -n ugc-api-jtier-production
   ```
3. Production scaling range: 3–50 replicas (HPA target: 40% CPU utilization)

### Database Operations

- **Schema migrations**: Managed by `jtier-migrations` (Flyway). Migrations in `db/migration/` run automatically on service startup. No manual migration steps are required for standard deployments.
- **Read replica**: If read replica is unavailable, review read traffic will fail. Check PostgreSQL DaaS status and failover procedures.
- **Connection pool**: Default JDBI connection pool is configured in the JTier runtime YAML. Pool exhaustion manifests as `504` errors on read endpoints.

## Troubleshooting

### Review reads returning 500
- **Symptoms**: GET requests to `/ugc/v1.0/merchants/{merchantId}/reviews` return HTTP 500
- **Cause**: PostgreSQL read replica unavailable, or JDBI connection pool exhausted
- **Resolution**: Check DB connectivity; verify read replica health in Wavefront; check connection pool saturation metric; if pool exhausted, scale up replicas

### Survey eligibility returning empty results
- **Symptoms**: `GET /v1.0/surveys` returns 200 with empty survey list unexpectedly
- **Cause**: Survey eligibility depends on `continuumOrdersService` for voucher validation; if orders service is degraded, surveys may not be returned
- **Resolution**: Check `continuumOrdersService` health; verify survey records exist in PostgreSQL for the requested `grouponCode` or `voucherId`

### S3 upload URLs not generating
- **Symptoms**: `GET /v1.0/surveys/{surveyId}/uploadUrls` returns error
- **Cause**: AWS credentials expired or IAM role misconfigured; secret-service-v2 unreachable
- **Resolution**: Verify IAM credentials via secret-service-v2; check AWS SDK error logs; confirm S3 bucket exists and is accessible

### High latency on merchant summary endpoints
- **Symptoms**: p99 latency spike on `/ugc/v1.0/merchants/{merchantId}/summary`
- **Cause**: Redis cache miss causing full DB aggregation query; or downstream enrichment calls (merchant API, taxonomy) timing out
- **Resolution**: Check Redis cache hit rate in Wavefront; inspect DB query explain plans; check `continuumMerchantApi` and `continuumTaxonomyService` latency

### JMS event publishing failures
- **Symptoms**: Log entries showing JMS publish errors; downstream consumers not receiving UGC events
- **Cause**: `mbus` (ActiveMQ broker) unavailable or connection lost
- **Resolution**: Check mbus service health; restart JMS connection pool; events are not retried automatically — a backfill job may be needed for missed events

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down — all review reads/writes failing | Immediate | PagerDuty P057HSW; Slack `#ugc`; ugc-alerts@groupon.com |
| P2 | Degraded — partial failures (e.g., survey endpoints down, images unavailable) | 30 min | Slack `#ugc`; ugc-dev@groupon.com |
| P3 | Minor impact — admin endpoints slow, non-critical features degraded | Next business day | Slack `#ugc` |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumUgcPostgresPrimary` | Check Wavefront DB connection metrics; test write query | No fallback for writes — service will return 500 |
| `continuumUgcPostgresReadReplica` | Check Wavefront DB connection metrics; test read query | Fall back to primary (if configured); otherwise 500 on reads |
| `continuumUgcRedis` | Check Redis connectivity in logs | Rate limiting disabled; requests proceed without rate control |
| `continuumUgcRedisCache` | Check Redis connectivity in logs | Cache miss — fall back to DB queries; increased DB load |
| `continuumUgcMessageBus` | Check mbus service status | Events not published; downstream consumers will not receive UGC updates |
| `continuumMerchantApi` | Check HTTP client error logs | Review enrichment degrades — merchant names/details may be missing |
| `continuumOrdersService` | Check HTTP client error logs | Survey eligibility checks fail — surveys not returned |
| `continuumTaxonomyService` | Check HTTP client error logs | Aspect classification unavailable — aspect-filtered queries may fail |

> Operational procedures are managed by the UGC team. See the full runbook at: https://confluence.groupondev.com/display/UGC/UGC+runbook
