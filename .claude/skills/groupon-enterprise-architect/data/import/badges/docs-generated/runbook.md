---
service: "badges-service"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /heartbeat` (port 8080) | HTTP | Kubernetes liveness/readiness probe interval | Kubernetes default |
| `GET /grpn/status` (port 8070) | HTTP | On demand | — |

The `/grpn/status` endpoint returns the service commit SHA (key: `commitId`) and is used by the Conveyor deployment platform to verify rollout health.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `DealStatsClientJanusImpl.janusExceptionMeter` | counter (meter) | Rate of exceptions from Janus deal-stats HTTP calls | Elevated rate indicates Janus connectivity issues |
| `DealStatsClientJanusImpl.janusTimeoutExceptionMeter` | counter (meter) | Rate of timeout exceptions from Janus calls | Elevated rate indicates Janus latency degradation |
| `DealStatsClientJanusImpl.janusGetEventsTimer` | histogram (timer) | Latency of Janus `/v1/getEvents` calls | Alert on p99 exceeding configured hard timeout |
| `DealStatsClientJanusImpl.janusLastPurchaseTimeTimer` | histogram (timer) | Latency of Janus `/v1/deal_last_purchase_time` calls | Alert on p99 exceeding configured hard timeout |
| `janusLast24hours` cache hit/miss | counter (MetricsCacheDecorator) | Redis cache hit rate for 24-hour deal stats | Low hit rate indicates Redis issues |
| `janusLast7days` cache hit/miss | counter (MetricsCacheDecorator) | Redis cache hit rate for 7-day deal stats | Low hit rate indicates Redis issues |
| `janusLastPurchaseTime` cache hit/miss | counter (MetricsCacheDecorator) | Redis cache hit rate for last-purchase-time data | Low hit rate indicates Redis issues |
| `janusLast5min` cache hit/miss | counter (MetricsCacheDecorator) | Redis cache hit rate for 5-minute view data | Low hit rate indicates Redis issues |
| `get_watson_recently_viewed` | histogram (timer) | Latency of Watson KV recently-viewed HTTP calls | Alert on elevated p99 |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Badges Service SMA | Wavefront | https://groupon.wavefront.com/dashboards/badges-service--sma |
| Badges Unified Dashboard | Wavefront | https://groupon.wavefront.com/dashboards/badges-unified-dashboard |

Dashboard source files for local development are in `doc/_dashboards/` (cloud, custom, JVM, on-prem, SMA variants).

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Service down / pod crash loop | `/heartbeat` failing or pod not ready | P1 | Check pod logs, verify Redis connectivity, check Janus availability |
| High Janus exception rate | `janusExceptionMeter` above baseline | P2 | Verify Janus service health; Badges Service will return zero-value badge signals until Janus recovers |
| High Janus timeout rate | `janusTimeoutExceptionMeter` above baseline | P2 | Review Janus `requestHardTimeout` configuration; consider increasing timeouts or caching TTLs |
| Redis unavailable | Redis connection errors in logs | P1 | Badge reads return empty; writes fail; escalate to STaaS team |
| MerchandisingBadgeJob failure | `Error while fetching deals in MerchandisingBadgeJob` in logs | P2 | Verify DCS connectivity; stale Redis entries will remain until next successful job run |

On-call contact: badges-service@groupon.pagerduty.com (PagerDuty service PDONLHN)

## Common Operations

### Restart Service

1. Identify the affected pod: `kubectl get pods -n badges-service-production`
2. Delete the pod to trigger a rolling restart: `kubectl delete pod <pod-name> -n badges-service-production`
3. Kubernetes will reschedule a new pod; monitor readiness via `/heartbeat`
4. For a full rolling restart: update the deployment via Conveyor deploy tooling

### Scale Up / Down

API component scaling is handled by the HPA (target 60% CPU, min 3 / max 20 replicas in production). To manually intervene:
1. Update `minReplicas`/`maxReplicas` in `.meta/deployment/cloud/components/api/production-us-central1.yml` (or europe-west1)
2. Redeploy via Conveyor pipeline

The `jobs` component is intentionally fixed at 1 replica (`minReplicas: 1`, `maxReplicas: 1`). Do not scale the jobs component horizontally — badge writes are not idempotent across concurrent job runners.

### Background Job Operations

- `MerchandisingBadgeJob`: Toggled by `ENABLE_JOBS=true` on the `jobs` deployment component. If badges are stale, verify the job is running in the `jobs` pod and that DCS is reachable.
- `LocalizationJob`: Fetches and refreshes in-memory localization cache. If badge display text appears untranslated, check Localization API connectivity and job logs.
- Both jobs are scheduled via Quartz; schedules are defined in the YAML run config under the `quartz` key.

### Database Operations

Redis entries have TTLs; no manual migrations are required. To force a badge cache refresh:
1. Trigger a manual run of `MerchandisingBadgeJob` via the `jobs` pod (or wait for the next scheduled run)
2. Redis key expiry is 21,600 seconds (6 hours) for merchandising badges

## Troubleshooting

### Badges missing or empty on deal grid

- **Symptoms**: Badge data absent from RAPI badge responses; `itemBadges` array empty
- **Cause**: Redis unavailable, Janus returning errors, or MerchandisingBadgeJob has not run recently
- **Resolution**: Check Redis connectivity; verify Janus is responding; review `badges-unified-dashboard` for anomalies; check `jobs` pod logs for `MerchandisingBadgeJob` failures

### Urgency messages not showing timer or quantity

- **Symptoms**: `/api/v3/urgency_messages` returns empty `urgencyMessages` or missing `showTimer`/`showQuantity` fields
- **Cause**: Janus `deal_last_purchase_time` or 5-minute view data missing/timed out; misconfigured `appConfig` thresholds
- **Resolution**: Verify Janus last-purchase-time endpoint is responsive; review `appConfig.timerThreshold` and `appConfig.dailyViewsThreshold` values in the run config

### Localized badge text showing keys instead of strings

- **Symptoms**: Badge `displayText` contains raw message keys rather than translated strings
- **Cause**: `LocalizationJob` failed or Localization API unreachable; in-memory cache empty or stale
- **Resolution**: Check `jobs` pod logs for `LocalizationClient` errors; verify Localization API health; restart `jobs` pod to force cache re-population on startup

### High latency on badge lookup requests

- **Symptoms**: `GET /badges/v1/badgesByItems` p99 latency elevated
- **Cause**: Slow Janus calls (async HTTP with hard timeout), slow Watson KV calls, or Redis latency
- **Resolution**: Check `janusGetEventsTimer` and `get_watson_recently_viewed` metrics on Wavefront; review Redis cluster health via STaaS dashboard; verify `janusConfig` hard-timeout values are appropriate

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no badges served | Immediate | badges-service@groupon.pagerduty.com (PDONLHN) → deal-platform team |
| P2 | Degraded — some badge types missing or stale | 30 min | deal-catalog-dev@groupon.com → PagerDuty PDONLHN |
| P3 | Minor — localization issues or single badge type failure | Next business day | deal-catalog-dev@groupon.com |

Runbook wiki: https://github.groupondev.com/deal-platform/badges/wiki/Runbook

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Redis (STaaS) | Redis `PING` via Lettuce/Jedis connection pool | Badge reads return empty; writes fail silently |
| Janus | `janusExceptionMeter` / `janusTimeoutExceptionMeter` metrics; call Janus status endpoint | Returns `DealStats.getAllZerosInstance()` — all badge signals based on stats evaluate to zero/false |
| Watson KV (recently viewed) | `get_watson_recently_viewed` timer metric | Returns empty recently-viewed list; RV-based badges are suppressed |
| Deal Catalog Service | `MerchandisingBadgeJob` logs | Stale Redis entries remain until next successful job run (up to 6-hour TTL) |
| Localization API | `LocalizationJob` logs | In-memory cache retains last successful fetch; badge text may be stale |
| Taxonomy API | Taxonomy client logs | Falls back to previously loaded taxonomy cache |
