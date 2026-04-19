---
service: "subscription-programs-itier"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /programs/select` | http | Kubernetes liveness/readiness probe | No evidence found in codebase |

> Specific health check endpoint and probe configuration are managed in Kubernetes manifests externally.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request rate | counter | Requests per second across all `/programs/select` routes | No evidence found in codebase |
| HTTP error rate (5xx) | counter | Rate of 5xx responses from the service | No evidence found in codebase |
| Enrollment success rate | counter | Rate of successful `POST /programs/select/subscribe` completions | No evidence found in codebase |
| Enrollment failure rate | counter | Rate of failed enrollment POST attempts | No evidence found in codebase |
| Poll response latency | histogram | Latency of `GET /programs/select/poll` responses | No evidence found in codebase |
| Memcached hit rate | gauge | Cache hit ratio for membership status cache entries | No evidence found in codebase |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Select I-Tier Service Health | No evidence found in codebase | No evidence found in codebase |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High 5xx rate | Error rate exceeds threshold | critical | Check Subscriptions API and V2 API health; inspect service logs |
| Enrollment failure spike | Enrollment POST failure rate increases sharply | critical | Check Groupon Subscriptions API availability; review error logs |
| Poll endpoint errors | `GET /programs/select/poll` returning errors | warning | Check Subscriptions API; verify Memcached connectivity |
| Subscriptions API unavailable | Repeated connection failures to Subscriptions API | critical | Alert Select/Subscriptions team; enrollment is blocked |
| Memcached unavailable | Cannot connect to Memcached | warning | All membership lookups hit live Subscriptions API; elevated load risk |

## Common Operations

### Restart Service
Operational procedures to be defined by service owner. Standard Kubernetes rolling restart: `kubectl rollout restart deployment/subscription-programs-itier -n <namespace>`

### Scale Up / Down
Operational procedures to be defined by service owner. Adjust HPA min/max replica counts in Kubernetes infrastructure manifests or use `kubectl scale deployment/subscription-programs-itier --replicas=<N> -n <namespace>` for immediate manual scaling.

### Database Operations
subscription-programs-itier owns no relational database. Cache operations:
- **Flush Memcached**: No dedicated cache control endpoint; flush via Memcached admin interface or by restarting the service (which clears in-process state)
- **Verify Memcached connectivity**: Check `MEMCACHED_HOSTS` env var; test from pod with `telnet <host> <port>`

## Troubleshooting

### Enrollment fails after submit
- **Symptoms**: `POST /programs/select/subscribe` returns an error page or error JSON; users cannot complete enrollment
- **Cause**: Groupon Subscriptions API is unavailable or returning errors; or user session is invalid
- **Resolution**: Check Subscriptions API health and error logs; verify `SUBSCRIPTIONS_API_URL` env var; confirm user is authenticated (`itier-user-auth`); review service logs for upstream error details

### Select landing page shows wrong variant
- **Symptoms**: Users see incorrect purchase variant (`purchg1`, `purchgg`, or `purchge`) relative to expected A/B test assignment
- **Cause**: Birdcage feature flag evaluation returning incorrect or default assignment; stale cached flag in Memcached
- **Resolution**: Check Birdcage flag configuration for Select enrollment variants; flush Memcached feature flag entries; verify `BIRDCAGE_URL` env var

### Poll endpoint returns stale or incorrect membership status
- **Symptoms**: `GET /programs/select/poll` returns outdated membership state (e.g., "pending" after enrollment completes)
- **Cause**: Memcached membership status cache entry has not expired; Subscriptions API returning stale data
- **Resolution**: Flush Memcached membership cache entries for the affected user; retry poll; if Subscriptions API is the source of stale data, escalate to Subscriptions team

### Benefits page inaccessible after enrollment
- **Symptoms**: Authenticated member receives error or empty state on `GET /programs/select/benefits`
- **Cause**: Groupon V2 API (Select Membership) not returning correct membership state; or Memcached returning stale non-member state
- **Resolution**: Check V2 API health; flush Memcached entry for the user's membership state; verify `GROUPON_V2_API_URL` env var

### Tracking events missing
- **Symptoms**: Enrollment events not appearing in analytics dashboards
- **Cause**: Tracking Hub unavailable or `tracking-hub-node` misconfigured; `TRACKING_HUB_URL` env var incorrect
- **Resolution**: Check Tracking Hub availability; verify `TRACKING_HUB_URL`; review service logs for Tracking Hub emit errors; enrollment flow itself is not affected

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — Select enrollment not loading | Immediate | Select / Subscriptions team + SRE |
| P2 | Degraded — enrollment submissions failing or poll broken | 30 min | Select / Subscriptions team |
| P3 | Minor impact — tracking missing or variant mismatch | Next business day | Select team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Groupon Subscriptions API | Check platform status; inspect service error logs | No fallback; enrollment is blocked if unavailable |
| Groupon V2 API (Select Membership) | Check platform status | Landing page shows default non-member view |
| Birdcage | Check platform status | Default feature flag values; default enrollment variant shown |
| GeoDetails API | Check platform status | Fall back to default division/region |
| Tracking Hub | Check platform status; review tracking-hub-node logs | Tracking events lost; enrollment flow unaffected |
| Memcached | `kubectl get pods -n <namespace>`; test connectivity | All membership lookups hit Subscriptions API directly |
