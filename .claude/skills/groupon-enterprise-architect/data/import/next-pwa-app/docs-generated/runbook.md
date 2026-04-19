---
service: "next-pwa-app"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/api/grpn/healthcheck` | HTTP GET | Infrastructure-managed | Infrastructure-managed |
| `/readiness-watt` (port 9090) | HTTP GET (wattpm) | Kubernetes probe | Configurable |
| `/liveness-watt` (port 9090) | HTTP GET (wattpm) | Kubernetes probe | Configurable |

The wattpm process manager exposes readiness and liveness endpoints on the metrics port (9090) as configured in `watt.json`. The `/api/grpn/healthcheck` endpoint is the application-level health check available on the main port (8000).

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Event loop lag | gauge | Node.js event loop delay (via `instrumentation/event-loop/`) | Service-owner defined |
| OpenTelemetry HTTP spans | histogram | HTTP request duration and status codes | Service-owner defined |
| Sentry error rate | counter | Client and server error events | Sample rate: 1% events, 0.1% traces |
| wattpm worker metrics | gauge | Worker process health (port 9090) | Infrastructure-managed |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Elastic APM | Elastic APM | `https://prod-apm.us-central1.logging.prod.gcp.groupondev.com/` (production) |
| Elastic APM (staging) | Elastic APM | `https://stable-apm.us-central1.logging.stable.gcp.groupondev.com/` (staging) |
| Sentry | Sentry | `https://o4509586704826368.ingest.us.sentry.io/` (project dashboard) |
| SonarQube | SonarQube | `https://sonarqube.groupondev.com` (project: mbnxt-web-local-test) |
| Elasticsearch Production Logs | Elasticsearch | Index pattern: `us-*:filebeat-next-pwa-app_itier--*` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High error rate (Sentry) | Spike in error events above baseline | warning | Check Sentry dashboard for error patterns, identify root cause |
| Pod restart loop | Kubernetes pod restarting repeatedly | critical | Check pod logs, verify health endpoints, check memory usage |
| Elevated response latency | P95 latency exceeds threshold | warning | Check APM traces, identify slow data sources or resolvers |

## Common Operations

### Restart Service
1. Service is managed by Kubernetes. Pods will be automatically restarted by the orchestrator.
2. For a manual restart, use the deployment platform (Napistrano/Conveyor) to trigger a rolling restart.
3. Alternatively, scale down and back up via Kubernetes: pods will be replaced with fresh instances.

### Scale Up / Down
1. Scaling is managed via Napistrano/Conveyor and Kubernetes HPA.
2. The `WATT_WORKERS` environment variable controls the number of Node.js worker processes per pod (default: 1).
3. For horizontal scaling, adjust pod replicas through the deployment platform.

### Cache Operations
1. Redis cache can be flushed by clearing the Redis instance referenced by `REDIS_CONNECTION_URL`.
2. Next.js ISR cache is stored per-pod and cleared on pod restart.
3. If `REDIS_CONNECTION_URL` is empty, caching falls back to in-memory (cleared on restart).

### Build and Deploy
1. Merge PR to `main` branch to trigger automatic staging deployment.
2. For production deployment, use the `/deploy` slash command on the PR or trigger via Napistrano.
3. Docker build process: install deps -> codegen -> build standalone -> post-build assets -> Docker image.

## Troubleshooting

### High memory usage during build
- **Symptoms**: Build OOM kills, Docker build failures
- **Cause**: Large number of locales/pages consuming memory during static generation
- **Resolution**: Use `CI_BUILD_LOCALES` to limit locale count in CI. Ensure `--max-old-space-size=12000` is set. For Docker builds, `NX_PARALLEL=1` limits parallelism.

### MaxMind GeoIP database missing
- **Symptoms**: Geo-details degraded, log warning "GeoIP2-City.mmdb not found"
- **Cause**: `pull-maxmind-db` script failed during build (expected in local builds without credentials)
- **Resolution**: Verify MaxMind credentials are available in the build environment. For local development, this is expected and the app falls back gracefully.

### GraphQL resolver errors
- **Symptoms**: GraphQL errors in response, data not loading on pages
- **Cause**: Upstream data source (Continuum service) returning errors or timing out
- **Resolution**: Check Sentry for error details, verify upstream service health. Each data source client logs errors via OpenTelemetry. Check APM traces for the failing service call.

### SSR page render failures
- **Symptoms**: 500 errors on server-rendered pages, elevated error rate
- **Cause**: getServerSideProps or React Server Component rendering failure
- **Resolution**: Check server logs (Elasticsearch index: `us-*:filebeat-next-pwa-app_itier--*`). Common causes: upstream API timeout, serialization error, or missing configuration.

### Stale ISR pages
- **Symptoms**: Pages showing outdated content after data changes
- **Cause**: ISR cache not yet revalidated
- **Resolution**: Pages revalidate on their configured interval. For immediate updates, restart pods to clear file-system cache, or flush Redis cache if configured.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down, consumers cannot access Groupon | Immediate | MBNXT Team (i-tier-devs@groupon.com) |
| P2 | Degraded experience (slow pages, partial failures) | 30 min | MBNXT Team |
| P3 | Minor impact (cosmetic issues, non-critical features) | Next business day | MBNXT Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| API Proxy (Lazlo) | ITier health check | GraphQL errors returned to client, UI shows error state |
| Continuum Relevance API | ITier health check | Feed/search results unavailable |
| Redis Cache | Connection check on `REDIS_CONNECTION_URL` | Falls back to in-memory cache (or no cache if empty URL) |
| Sentry | DSN reachability | Errors silently dropped, no impact on functionality |
| Elastic APM | OTLP endpoint reachability | Traces silently dropped, no impact on functionality |
| MaxMind GeoIP | File existence check | Falls back to default locale/division |

> Operational procedures to be refined by the MBNXT service owner team.
