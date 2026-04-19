---
service: "travel-browse"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Kubernetes liveness probe | http | Platform default | Platform default |
| Kubernetes readiness probe | http | Platform default | Platform default |

> Specific health check endpoint paths and intervals are configured in the napistrano Helm chart. Operational procedures to be confirmed with Getaways Engineering (nranjanray@groupon.com).

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request rate | counter | Inbound requests per second to `/travel/:geo_slug/hotels`, `/hotels/:dealId/inventory`, `/getaways/tripadvisor` | Alert on sustained drop (possible pod crash) |
| HTTP error rate (5xx) | counter | Rate of 5xx responses from Express server | Alert on rate above baseline |
| SSR render duration | histogram | Time to server-side render a full browse or detail page | Alert on p99 exceeding SLA |
| Downstream API latency | histogram | Latency of calls to RAPI, Getaways API, MARIS | Alert on p99 spike |
| Memcache hit rate | gauge | Cache hit percentage for API response cache | Alert on sustained drop below threshold |
| Pod replica count | gauge | Active HPA-managed pod count | Alert if max replicas (64) sustained |

> Metric names and alert thresholds are managed in the monitoring platform. Specific dashboard links to be provided by Getaways Engineering.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Getaways Browse Service | Groupon internal monitoring platform | Operational procedures to be defined by service owner |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High 5xx rate | 5xx rate exceeds baseline for > 5 minutes | P1 | Check pod logs; inspect downstream API health; roll back if recent deploy |
| SSR latency spike | p99 render time exceeds SLA threshold | P2 | Check Memcache hit rate; check downstream API latency; consider cache warm-up |
| Memcache unavailable | Memcache connection failures from `travelBrowse_cacheAccess` | P2 | Verify `memcacheCluster` health; service degrades gracefully but latency increases |
| Pod crash-loop | Kubernetes reports CrashLoopBackOff on travel-browse pods | P1 | Inspect pod logs; check recent config changes; roll back deployment if needed |
| HPA at max replicas | HPA sustained at 64 replicas | P2 | Escalate to platform/infra; investigate traffic spike or upstream API slowness |

## Common Operations

### Restart Service

1. Identify the travel-browse deployment in the target Kubernetes cluster via napistrano or `kubectl`.
2. Perform a rolling restart: `kubectl rollout restart deployment/travel-browse -n <namespace>`.
3. Monitor pod status: `kubectl rollout status deployment/travel-browse -n <namespace>`.
4. Verify health checks pass and error rate returns to baseline in monitoring dashboard.

### Scale Up / Down

1. HPA manages scaling automatically between configured min and max (64) replicas.
2. For a manual scale override: `kubectl scale deployment/travel-browse --replicas=<N> -n <namespace>`.
3. Restore HPA control by removing the manual override after the incident.

### Database Operations

> Not applicable — travel-browse does not own a relational database. Memcache data is ephemeral; no migration or backfill procedures are required. To flush cached data, cycle the relevant Memcache keys or restart the `memcacheCluster` nodes (coordinate with platform team).

## Troubleshooting

### Browse Pages Returning Empty Results

- **Symptoms**: `/travel/:geo_slug/hotels` renders with no deal cards; no 5xx error
- **Cause**: RAPI (`rapiApi`) or Getaways API (`continuumGetawaysApi`) returning empty result set or timing out; Memcache stale data
- **Resolution**: Check RAPI and Getaways API health; inspect `apiClients` component logs for upstream error responses; flush Memcache keys for affected geo slug

### Hotel Inventory Page Shows No Pricing

- **Symptoms**: `/hotels/:dealId/inventory` loads but market-rate pricing is absent
- **Cause**: MARIS (`marisApi`) unavailable or returning empty availability response
- **Resolution**: Check MARIS service health; inspect `apiClients` logs for MARIS errors; confirm fallback pricing display is rendering

### SSR Rendering Fails

- **Symptoms**: Pages return 500 with HTML error page; React SSR exception in logs
- **Cause**: Rendering Engine component failure due to bad data from downstream API or a runtime exception in page module
- **Resolution**: Inspect pod logs for stack trace from `renderingEngine` component; check recent deployments; roll back if correlated with a deploy

### TripAdvisor Widget Not Loading

- **Symptoms**: `/getaways/tripadvisor` returns 500 or empty JSON
- **Cause**: Downstream TripAdvisor data unavailable via Getaways API or a rendering error in the widget module
- **Resolution**: Check `continuumGetawaysApi` health for TripAdvisor data path; inspect pod logs

### High Latency on Browse Pages

- **Symptoms**: p99 SSR render time elevated; users report slow page loads
- **Cause**: Memcache miss causing all requests to hit downstream APIs in parallel; one or more slow upstream API (RAPI, MARIS, Geodetails)
- **Resolution**: Check Memcache hit rate metric; identify which downstream API is slow; consider increasing cache TTL for unaffected data

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — all Getaways browse pages returning 5xx | Immediate | Getaways Engineering on-call (nranjanray@groupon.com) + Platform team |
| P2 | Degraded — partial data missing or elevated latency | 30 min | Getaways Engineering (nranjanray@groupon.com) |
| P3 | Minor impact — TripAdvisor widget unavailable or non-critical content missing | Next business day | Getaways Engineering |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumGetawaysApi` | Check service health endpoint in Getaways API runbook | Browse pages render without inventory data; error state shown |
| `rapiApi` | Check RAPI service status page | Browse pages render without deal results |
| `marisApi` | Check MARIS service status | Inventory page renders without market-rate pricing |
| `memcacheCluster` | Check Memcache cluster node connectivity | Service continues without cache; increased latency on all pages |
| `continuumMapProxyService` | Check Map Proxy health endpoint | Map component hidden; rest of page renders normally |
| `geodetailsV2Api` | Check Geodetails service status | Geo context unavailable; page may 404 for unknown geo slugs |
