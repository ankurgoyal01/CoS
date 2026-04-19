---
service: "alligator"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/heartbeat` (port 8080) | http | 30s (readiness), 30s (liveness) | — |
| `/status.json` (port 8080) | http | On-demand (service discovery) | — |

Kubernetes readiness probe: `GET /heartbeat` with `delaySeconds: 300`, `periodSeconds: 30`.
Kubernetes liveness probe: `GET /heartbeat` with `delaySeconds: 1200`, `periodSeconds: 30`.

## Monitoring

### Metrics

Alligator exports metrics via Micrometer to InfluxDB/Telegraf (registry: `micrometer-registry-influx`) and exposes JMX metrics (`micrometer-registry-jmx`). The Spring Boot Actuator endpoints are also available.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| JVM heap usage | gauge | JVM heap memory consumed | Operational procedures to be defined by service owner |
| HTTP request rate | counter | Requests per second to card endpoints | Operational procedures to be defined by service owner |
| HTTP error rate | counter | 4xx/5xx responses from card endpoints | Operational procedures to be defined by service owner |
| Hystrix circuit state | gauge | Circuit breaker open/closed/half-open per upstream | Operational procedures to be defined by service owner |
| Cache hit/miss rate | counter | Redis cache hits vs misses for deck/card/template lookups | Operational procedures to be defined by service owner |
| Cache reload duration | histogram | Time taken by `cacheReloadWorker` to refresh all catalog entries | Operational procedures to be defined by service owner |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Alligator SMA Dashboard (NA) | Arrowhead (internal) | https://arrowhead.groupondev.com/ |
| Alligator SMA Dashboard (EMEA dub1) | Arrowhead (internal) | https://arrowhead-dub1.groupondev.com/ |
| Wavefront Dashboard | Wavefront | https://groupon.wavefront.com/u/sFbSdssKjR?t=groupon |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Service down / unhealthy | `/heartbeat` fails to return 200 | P1 | Restart service; check Redis connectivity; check upstream services |
| Cache reload failure | `cacheReloadWorker` fails repeatedly; stale or empty cache | P2 | Investigate Cardatron Campaign Service health; check logs for errors |
| Hystrix circuit open | One or more Hystrix circuits are in open state | P2 | Identify failing upstream; check its health; monitor for recovery |
| High error rate | Elevated 5xx/4xx response rate | P2 | Check logs; identify failing upstream via Hystrix dashboard |

Slack: `#rapi` (channel ID CF9BTGACX)
PagerDuty notify: darwin-alerts@groupon.pagerduty.com
Ticket creation: https://groupondev.atlassian.net/secure/CreateIssue.jspa?pid=21440&issuetype=1

## Common Operations

### Restart Service

**Kubernetes (GCP):**
1. Identify the relevant Kubernetes context (e.g., `alligator-service-production-us-central1`).
2. Use `kubectl rollout restart deployment/alligator-service -n alligator-service-production` or trigger a new deployment via DeployBot.
3. Monitor readiness probe (`/heartbeat`) to confirm pods come back in rotation (readiness delay is 300s).

**On-premises (JTier):**
1. SSH to the target host (e.g., `alligator-app1.snc1`).
2. Ensure host is out of rotation first.
3. Run `sv restart jtier`.
4. Verify service is responding on port 8080.

### Scale Up / Down

1. Update `minReplicas` / `maxReplicas` in the appropriate `.meta/deployment/cloud/components/app/<env>.yml` file.
2. Commit and redeploy via the CI/CD pipeline or directly via `kubectl` for emergency scaling.
3. HPA target CPU utilization is set to 50% (common.yml); automatic scaling occurs between configured min/max bounds.

### Database Operations

Redis is a cache; there are no schema migrations. If Redis data needs to be cleared:
1. Connect to the Redis instance for the affected environment.
2. Run `FLUSHDB` or selectively delete keys.
3. The cache reload worker will repopulate data on its next scheduled run.
4. Monitor for elevated latency until the cache is warm again.

### Manual Cache Reload

The cache reload worker runs on a schedule. To inspect current cache state:
- Use `/cache/cachevalues?cacheName=cardDecks` (or `cards`, `templates`, `clients`, `polygons`, `permalinks`) to view in-memory cache contents.
- Use `/debug/card/{uuid}/alligator` to view a specific card's state in the Alligator cache.
- Use `/debug/card/{uuid}/cardatron` to compare against the live Cardatron response.

## Troubleshooting

### Empty or stale card responses

- **Symptoms**: API returns empty card arrays or outdated card content; no errors.
- **Cause**: Cache reload worker has failed or is delayed; Redis may be empty or stale.
- **Resolution**: Check `cacheReloadWorker` logs for errors. Verify Cardatron Campaign Service is accessible. Inspect Redis keys. If Redis is empty, check for connectivity issues between Alligator and Redis.

### Hystrix circuit breakers open

- **Symptoms**: Partial card responses; upstream service calls returning defaults/empty; Hystrix metrics show open circuits.
- **Cause**: One or more upstream services (Cardatron, GAPI, RAPI, Finch, etc.) are slow or returning errors.
- **Resolution**: Identify the failing upstream from Hystrix command names in logs. Check the health of that service. Circuits will half-open automatically after a cooldown window; if the upstream recovers, traffic will resume.

### OOM / container killed

- **Symptoms**: Kubernetes pod restarting with OOMKilled status; high memory usage.
- **Cause**: JVM heap or native memory growth exceeding the 10.5Gi container limit.
- **Resolution**: Check `MALLOC_ARENA_MAX` is set to `4` (common.yml). Review heap dumps if available. Consider adjusting JVM heap flags in the application config. Redis Lettuce connection pool may also contribute to off-heap usage.

### Service not coming into rotation after deploy

- **Symptoms**: Readiness probe failing; deployment stuck rolling out.
- **Cause**: Application taking longer than `delaySeconds: 300` to start (cache reload on startup), or a downstream dependency is unavailable.
- **Resolution**: Check startup logs for cache reload completion. Verify Redis is accessible. If downstream services are down, the NoOp fallbacks should still allow startup to complete.

### 406 Invalid parameters

- **Symptoms**: Clients receive HTTP 406 responses.
- **Cause**: Required parameters (`locale`, `deck_client_id`, `card_uuid`, `template_uuid`, `visitor_id`, `x-brand`) are missing or invalid.
- **Resolution**: Ensure calling clients pass all required fields per the OpenAPI spec at `doc/swagger/openapi.yaml`.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down; no cards returned | Immediate | Relevance team via darwin-alerts@groupon.pagerduty.com |
| P2 | Degraded; partial card responses or elevated errors | 30 min | Relevance team via `#rapi` Slack + PagerDuty |
| P3 | Minor impact; single upstream degraded with fallbacks active | Next business day | Relevance team via Jira (pid=21440) |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumAlligatorRedis` | Spring Data Redis connection; `/heartbeat` checks Redis health | Service degrades; cards assembled from live upstream calls only |
| Cardatron Campaign Service | HTTP call during cache reload | Stale cache data served until next successful reload |
| Finch Service | HTTP call per request | `NoOp` executor; default template bucketing used |
| Audience Management Service | HTTP call per request | `NoOpAudienceServiceExecutor`; eligibility filtering skipped |
| Deal Decoration Service | HTTP call per request | `NoOpDealDecorationServiceExecutor`; undecorated cards returned |
| Deal Recommendation Service | HTTP call per request | `NoOpDealRecommendationServiceExecutor`; cross-sell cards omitted |
| GAPI / API Proxy | HTTP call per request | `NoOpGapiServiceExecutor`; GAPI-sourced cards omitted |
| RAPI / Relevance API | HTTP call per request | NoOp fallback; RAPI-sourced cards omitted |
