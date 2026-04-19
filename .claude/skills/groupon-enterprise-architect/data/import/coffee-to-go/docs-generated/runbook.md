---
service: "coffee-to-go"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /api/health` | http | On-demand | Database query <1s = healthy, >=1s = degraded, error = unhealthy |
| `GET /api/livez` | http | On-demand (orchestrator liveness probe) | Immediate |

The `/api/health` endpoint returns a JSON payload with:
- Overall status (`healthy`, `degraded`, `unhealthy`)
- Timestamp and uptime
- Application version and environment
- Per-service health (currently: database connectivity with response time)

## Monitoring

### Metrics

> No custom metrics instrumentation (Prometheus, StatsD, etc.) was found in the codebase. Operational metrics are derived from structured logs and Sentry error tracking.

### Logging

| Transport | Environment | Details |
|-----------|-------------|---------|
| stdout (pino) | All | Structured JSON logs via Pino |
| pino-roll | Docker/Production | Rolling file logs at `/var/groupon/logs/logfile.log` (100MB per file, max 2 files) |
| pino-sentry-transport | Non-Docker (staging/production) | Forwards `warn` and `error` level logs to Sentry |
| pino-pretty | Development | Human-readable colored console output |

Logs include: request ID, HTTP method, URL, user agent, user ID (when authenticated), and response status code.

### Dashboards

> No evidence found in codebase for Grafana, Datadog, or CloudWatch dashboards. Usage analytics are available via the built-in `/stats` page in the React application.

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Sentry errors | Error-level logs forwarded to Sentry | warning/critical | Investigate via Sentry dashboard, check application logs |
| Health check unhealthy | `/api/health` returns `unhealthy` | critical | Check database connectivity, verify `DB_URL` credentials and network |
| Health check degraded | `/api/health` returns `degraded` (DB response >1s) | warning | Check database load, connection pool exhaustion, network latency |

## Common Operations

### Restart Service

1. The container handles SIGTERM and SIGINT gracefully:
   - Stops accepting new HTTP connections
   - Destroys the Kysely database connection pool
   - Exits cleanly
2. Kubernetes/orchestrator will restart the container automatically
3. For manual restart, send SIGTERM to the process or restart the pod/container

### Scale Up / Down

> Scaling configuration is managed externally. Adjust replica count in the Kubernetes deployment or Helm values.

### Database Operations

**Run migrations:**
```bash
cd apps/coffee-api
npm run db:up        # Apply pending migrations
npm run db:down      # Rollback last migration
npm run db:status    # Check migration status
```

Migrations use dbmate with the `MIGRATION_TARGET_DATABASE_URL` environment variable.

**Refresh materialized view:**
The `refresh_deals_cache()` PostgreSQL function refreshes the `mv_deals_cache_v6` materialized view. This is typically triggered by n8n workflows after data ingestion.

**Generate database types:**
```bash
cd apps/coffee-api
npm run db:codegen   # Regenerate Kysely types from schema
```

**Dump schema:**
```bash
cd apps/coffee-api
npm run dump-schema
```

### API Key Management

API keys are managed via a CLI tool (not via the API -- endpoint is disabled):
```bash
cd apps/coffee-api
npm run api-key -- [options]
```

## Troubleshooting

### Users cannot sign in

- **Symptoms**: Google OAuth redirect fails or returns "Access denied: Only Groupon employees can access this application"
- **Cause**: User's email domain is not in the `ALLOWED_EMAIL_DOMAINS` list, or Google OAuth credentials are invalid/expired
- **Resolution**: Verify `GOOGLE_OAUTH_CLIENT_ID` and `GOOGLE_OAUTH_CLIENT_SECRET` are valid. Check that the user's email domain is in `ALLOWED_EMAIL_DOMAINS` (default: `groupon.com`).

### Deals not loading or stale data

- **Symptoms**: Empty deal results or outdated deal information displayed
- **Cause**: n8n workflow ingestion failed, materialized view not refreshed, or database connectivity issues
- **Resolution**: Check `job_metadata` table for recent workflow failures. Manually call `refresh_deals_cache()` if needed. Verify database connectivity via `/api/health`.

### Rate limit exceeded

- **Symptoms**: API returns 429 status with `RATE_LIMIT_EXCEEDED` or `TRACKING_RATE_LIMIT_EXCEEDED`
- **Cause**: Client exceeded 250 requests/15min (general) or 50 requests/min (tracking)
- **Resolution**: Wait for the rate limit window to expire. If legitimate traffic, consider adjusting limits in `middleware/rateLimiting.ts`.

### Database connection errors

- **Symptoms**: `/api/health` returns `unhealthy`, API returns 500 errors
- **Cause**: Database unreachable, credentials expired, connection pool exhausted, SSL certificate issues
- **Resolution**: Check `DB_URL` and `DB_URL_RO` values. Verify network connectivity. Check pool size (`APP_POOL_SIZE`). If SSL is enabled, verify `SSL_CA_CERTIFICATE` path and certificate validity.

### Map not rendering

- **Symptoms**: Map area shows blank or error in the React application
- **Cause**: Invalid or expired `GOOGLE_MAPS_API_KEY`, network issues, or Google Maps API quota exceeded
- **Resolution**: Verify the API key in the frontend config. Check Google Cloud Console for API key restrictions and quota usage.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down (API or DB unreachable) | Immediate | Coffee To Go Team |
| P2 | Degraded (slow queries, partial data, auth issues) | 30 min | Coffee To Go Team |
| P3 | Minor impact (stale competitor data, tracking failures) | Next business day | Coffee To Go Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| PostgreSQL | `GET /api/health` (SELECT 1 probe) | None -- service is degraded without database |
| Google OAuth | Observable via authentication failures in logs | Existing sessions remain valid |
| Google Maps API | Observable via client-side console errors | Deal data accessible via list view |
| Salesforce (via n8n) | Check `job_metadata` table | Existing data remains queryable; data becomes stale |
| EDW (via n8n) | Check `job_metadata` table | Review data becomes stale |
| DeepScout S3 (via n8n) | Check `job_metadata` table | Competitor data becomes stale |

> Operational procedures to be refined by service owner.
