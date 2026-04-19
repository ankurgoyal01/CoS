---
service: "tronicon-ui"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /` | http | No evidence found | No evidence found |

> No dedicated health check endpoint (e.g., `/health` or `/ping`) was identified in the service inventory. The main dashboard route `GET /` serves as a basic liveness indicator. Operational health check configuration to be confirmed by the Tronicon / Sparta team.

## Monitoring

### Metrics

> No evidence found in codebase for instrumented metrics (Prometheus, StatsD, Datadog agent). Operational metrics configuration to be defined by service owner.

### Dashboards

> No evidence found in codebase. Dashboard links to be provided by the Tronicon / Sparta team.

### Alerts

> No evidence found in codebase. Alert configuration to be defined by service owner.

## Common Operations

### Restart Service

1. Connect to the target host using the Fabric deployment tooling or direct SSH
2. Identify the running Gunicorn process: `ps aux | grep gunicorn`
3. Send SIGTERM to gracefully stop Gunicorn: `kill -TERM <pid>`
4. Restart the Docker container or re-run the Fabric deploy task to bring Gunicorn back up
5. Verify the service responds at `GET /`

> Operational procedures to be defined by service owner for environment-specific restart steps.

### Scale Up / Down

> Operational procedures to be defined by service owner. No Kubernetes HPA or ECS auto-scaling configuration was identified. Scaling is performed manually by adjusting Gunicorn worker count in the Docker run configuration or host provisioning.

### Database Operations

1. **Apply migrations**: Navigate to the `alembic/` directory and run `alembic upgrade head` against the target environment database (ensure `DB_*` environment variables are set)
2. **Rollback migrations**: Run `alembic downgrade -1` to revert the most recent migration
3. **Check migration status**: Run `alembic current` to confirm the active revision
4. **Manual backfills**: Connect directly to `continuumTroniconUiDatabase` MySQL instance with appropriate credentials and execute backfill SQL as needed

## Troubleshooting

### Service returns 500 errors on card or CMS operations
- **Symptoms**: Browser receives HTTP 500; card creation, CMS edit, or theme operations fail
- **Cause**: Most likely a database connectivity issue with `continuumTroniconUiDatabase` or a failed dependency call (Campaign Service, Taxonomy Service, Alligator)
- **Resolution**: Check Gunicorn logs for traceback. Verify MySQL connectivity. Check that `DB_HOST`, `DB_USER`, `DB_PASSWORD` environment variables are set correctly. Check downstream service availability.

### `/c/` proxy routes return errors
- **Symptoms**: Campaign operations via `/c/:path` fail with non-200 responses
- **Cause**: Campaign Service (`campaignService`) is unavailable or `CAMPAIGN_SERVICE_URL` is misconfigured
- **Resolution**: Verify `CAMPAIGN_SERVICE_URL` environment variable. Check Campaign Service health independently. Review proxy error response body for Campaign Service error details.

### Alembic migration fails on deploy
- **Symptoms**: Deployment completes but service fails to start or produces database errors
- **Cause**: Migration script error, schema conflict, or database permission issue
- **Resolution**: Run `alembic history` to identify the failing revision. Check migration SQL in `alembic/versions/`. Ensure the database user has DDL permissions. Roll back with `alembic downgrade -1` if needed.

### Frontend assets not loading
- **Symptoms**: Browser shows unstyled pages or JavaScript errors on asset load
- **Cause**: Grunt build step failed during deployment, or static asset paths are misconfigured
- **Resolution**: Re-run the Grunt build step manually. Check `deploy-config.js` for correct static asset path configuration. Verify the Docker image includes the compiled `dist/` or `static/` assets.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down — merchandising operations blocked | Immediate | Tronicon / Sparta team on-call |
| P2 | Degraded — specific features (e.g., CMS, geo-polygons) unavailable | 30 min | Tronicon / Sparta team |
| P3 | Minor impact — cosmetic or non-critical feature degraded | Next business day | Tronicon / Sparta team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumTroniconUiDatabase` | Attempt a lightweight query (e.g., `SELECT 1`) via SQLAlchemy connection | No fallback — service cannot operate without database |
| `continuumAlligatorService` | HTTP GET to Alligator health endpoint (URL from `ALLIGATOR_SERVICE_URL`) | Default experiment assignments applied; A/B data unavailable |
| `continuumGrouponApi` | HTTP GET to Groupon API health/ping endpoint (URL from `GROUPON_API_BASE_URL`) | Deal/offer association unavailable for campaign operators |
| `continuumTaxonomyService` | HTTP GET to Taxonomy Service health endpoint (URL from `TAXONOMY_SERVICE_URL`) | Taxonomy category selection unavailable |
| `campaignService` | HTTP GET to Campaign Service health endpoint (URL from `CAMPAIGN_SERVICE_URL`) | All `/c/` proxy routes unavailable |
