---
service: "marketing-and-editorial-content-service"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Details |
|---------------------|------|---------|
| `GET /healthcheck` | HTTP (Dropwizard admin) | Returns status of the registered `math` health check (always passes: `2 + 2 == 4`) |
| Kubernetes readiness probe | HTTP | 90-second initial delay; pod receives traffic only after readiness passes |
| Kubernetes liveness probe | HTTP | 100-second initial delay; pod is restarted if liveness fails |

> Note: The database connectivity health check is intentionally disabled in cloud deployments. A PostgreSQL outage will cause the API to return 5xx responses rather than triggering pod restarts.

## Monitoring

### Metrics

| Metric | Type | Description | Notes |
|--------|------|-------------|-------|
| `custom.imageservice.client` | counter | Count of Global Image Service upload attempts with `operation_id=uploadImage` and `status=success` or `status=failed` tags | Emitted by `HttpGlobalImageService` |
| Dropwizard / Codahale metrics | various | Standard JVM, thread pool, and HTTP request metrics emitted by Dropwizard | Flushed to Telegraf every 60 seconds (`metrics.yml`) |
| Elastic APM traces | trace | Request traces sent to Elastic APM agent in production | Enabled via `apm.enabled: true` in deployment config |

### Dashboards

> Operational procedures to be defined by service owner. Dashboard links are not stored in the codebase.

### Alerts

> Operational procedures to be defined by service owner. Alert thresholds are not configured in the codebase.

## Common Operations

### Restart Service

1. Access the Kubernetes cluster for the target environment (context names are in `.deploy_bot.yml`, e.g., `marketing-and-editorial-content-service-gcp-production-us-central1`).
2. Perform a rolling restart: `kubectl rollout restart deployment marketing-and-editorial-content-service -n marketing-and-editorial-content-service-production`
3. Monitor rollout status: `kubectl rollout status deployment marketing-and-editorial-content-service -n marketing-and-editorial-content-service-production`
4. Verify pod health via `kubectl get pods -n marketing-and-editorial-content-service-production`.

### Scale Up / Down

- Autoscaling (production): VPA and HPA manage replicas automatically between 1 and 6. Manual scaling is not the preferred approach.
- Manual override (if needed): `kubectl scale deployment marketing-and-editorial-content-service --replicas=<N> -n marketing-and-editorial-content-service-production`
- Staging is fixed at 3 replicas; changes require a deployment config update.

### Database Operations

- **Schema migrations**: Flyway migrations run automatically at service startup via `PostgresMigrationBundle`. Migration files are in `src/main/resources/db/migration/`. New migrations should follow the naming pattern `V<YYYYMMDD>.<seq>__<description>.sql`.
- **Manual DB access**: Connect using DBA credentials (`DAAS_DBA_USERNAME` / `DAAS_DBA_PASSWORD`) to the appropriate host. Production write host: `marketing-and-editorial-content-service-rw-na-production-db.gds.prod.gcp.groupondev.com`, database: `editorial_content_prod`.
- **Audit table inspection**: Query `images_audit` or `text_audit` to review the history of mutations on a specific content record by UUID.

## Troubleshooting

### 422 Unprocessable Entity on text create/update

- **Symptoms**: `POST /mecs/text` or `PUT /mecs/text` returns 422 with a profanity error message.
- **Cause**: The `GrouponProfanityService` detected profane terms in the submitted text content. Profanity lists are refreshed daily from gconfig (86400000 ms interval).
- **Resolution**: Review the submitted text content and remove flagged terms. Check the profanity list in the `groupon/essence/profanity` library repository if the detection appears incorrect.

### Image upload failure (500 from GIMS)

- **Symptoms**: `POST /mecs/image` returns 500; logs contain `HTTP_GLOBAL_IMAGE_SERVICE_CLIENT` event with `status=failed`.
- **Cause**: The Global Image Service at `https://img.grouponcdn.com/v1/upload` returned a non-success response, or a network/timeout error occurred.
- **Resolution**: Check GIMS availability independently. Verify `GISC_CLIENT_ID` and `GISC_API_KEY` secrets are current. Confirm network connectivity from the pod to `img.grouponcdn.com`. Retry the request after GIMS recovers.

### High memory usage / OOM

- **Symptoms**: Pod is OOMKilled; `kubectl describe pod` shows memory limit exceeded.
- **Cause**: JVM heap growth, possibly from large image upload streams buffered in memory (`IOUtils.toByteArray`).
- **Resolution**: Check current memory request/limit in `common.yml` (1.6Gi request, 4Gi limit). Review VPA recommendations. If OOM is consistent, increase memory limit in the deployment config and redeploy.

### 404 Not Found for known UUID

- **Symptoms**: `GET /mecs/image/{uuid}` or `GET /mecs/text/{uuid}` returns 404 for a UUID that exists.
- **Cause**: Possible read replica lag — the record was recently created but the read replica has not yet replicated the row.
- **Resolution**: Wait a few seconds and retry. If the problem persists, check replication lag on the PostgreSQL read replica.

### Service not receiving traffic after deployment

- **Symptoms**: New pods are up but no requests are routed to them.
- **Cause**: Readiness probe initial delay is 90 seconds. JVM startup and connection pool initialization may take up to this duration.
- **Resolution**: Wait at least 90–100 seconds after pod start before diagnosing traffic issues. Check `kubectl describe pod` for readiness probe failures.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down — all editorial content APIs unavailable | Immediate | MARS team on-call |
| P2 | Degraded — image uploads failing or high error rate on a subset of endpoints | 30 min | MARS team on-call |
| P3 | Minor impact — single endpoint slow, non-critical functionality degraded | Next business day | MARS team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| MECS PostgreSQL (Write) | No automated health check (intentionally disabled in cloud); check `pg_isready` manually | API returns 5xx; no fallback |
| MECS PostgreSQL (Read) | Same as above | API returns 5xx; no fallback |
| Global Image Service (GIMS) | No circuit breaker; check `https://img.grouponcdn.com` independently | Image uploads fail with 500; existing image records with URLs already stored are unaffected |
