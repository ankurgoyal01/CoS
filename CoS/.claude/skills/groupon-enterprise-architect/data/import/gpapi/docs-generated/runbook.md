---
service: "gpapi"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /health` | http | 30s | 5s |
| `GET /healthz` | http | 30s | 5s |
| Kubernetes liveness probe | http | 30s | 5s |
| Kubernetes readiness probe | http | 10s | 3s |

> Specific health endpoint paths should be confirmed with the service owner. Rails convention typically uses `/health` or `/healthz`.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `gpapi.request.duration` | histogram | HTTP request latency by endpoint | p99 > 2000ms |
| `gpapi.request.count` | counter | Total HTTP requests by status code | — |
| `gpapi.request.error_rate` | gauge | Percentage of 5xx responses | > 1% over 5 min |
| `gpapi.db.query.duration` | histogram | PostgreSQL query latency | p99 > 500ms |
| `gpapi.downstream.duration` | histogram | Downstream service call latency by target | p99 > 3000ms |
| `gpapi.downstream.error_rate` | gauge | Downstream service error rate | > 5% over 5 min |

Metrics are emitted via `sonoma-metrics` (v0.9.0) using StatsD protocol. Distributed traces are collected by `elastic-apm` (v4.7.3).

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| gpapi Service Health | Elastic APM | Configured by platform team |
| gpapi Metrics | Grafana / Datadog | Configured by platform team |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High error rate | 5xx rate > 1% over 5 min | critical | Check logs, inspect downstream service health |
| High latency | p99 request duration > 2s | warning | Check downstream service latency, DB query performance |
| DB connection failure | PostgreSQL connection errors | critical | Verify `DATABASE_URL`, check DB pod/instance health |
| reCAPTCHA unavailable | Google reCAPTCHA API errors | warning | Vendor logins will fail; check Google Cloud status |
| S3 upload failures | S3 SDK errors on file upload | warning | Check AWS credentials and bucket permissions |

## Common Operations

### Restart Service

Operational procedures to be defined by service owner. For Kubernetes deployments:
1. Identify the deployment: `kubectl get deployments -n <namespace> | grep gpapi`
2. Perform a rolling restart: `kubectl rollout restart deployment/gpapi -n <namespace>`
3. Monitor rollout: `kubectl rollout status deployment/gpapi -n <namespace>`

### Scale Up / Down

Operational procedures to be defined by service owner. For Kubernetes deployments:
1. Scale replicas: `kubectl scale deployment/gpapi --replicas=<N> -n <namespace>`
2. Or update HPA min/max in the Kubernetes manifests managed by the platform team

### Database Operations

1. **Run migrations**: Execute `bundle exec rails db:migrate RAILS_ENV=production` within a pod or migration job
2. **Check migration status**: `bundle exec rails db:migrate:status RAILS_ENV=production`
3. **Rollback migration**: `bundle exec rails db:rollback RAILS_ENV=production` (use with caution in production)
4. Coordinate all production migrations with the Goods Platform team and follow Continuum migration runbook

## Troubleshooting

### Vendor Login Failures
- **Symptoms**: Vendors unable to log in; 401 or 422 responses from `POST /api/v1/sessions`
- **Cause**: reCAPTCHA Enterprise verification failure, invalid credentials, or Google Cloud API unavailability
- **Resolution**: Check `GOOGLE_RECAPTCHA_PROJECT_ID` and `GOOGLE_RECAPTCHA_SITE_KEY` env vars; verify Google Cloud reCAPTCHA Enterprise service status; inspect application logs for specific error messages

### Downstream Service Timeouts
- **Symptoms**: Slow responses or 504 errors from vendor portal; Elastic APM traces show long downstream spans
- **Cause**: One or more of the 13 internal service dependencies (Goods Product Catalog, DMAPI, Pricing Service, etc.) is slow or unavailable
- **Resolution**: Identify the slow dependency from Elastic APM traces; check health of the identified downstream service; escalate to the owning team if the dependency is degraded

### NetSuite Webhook Failures
- **Symptoms**: NetSuite reports failed webhook delivery; accounting events not processed
- **Cause**: gpapi is unavailable, or `NETSUITE_WEBHOOK_SECRET` mismatch causing 401 rejections
- **Resolution**: Verify gpapi is healthy and reachable; confirm `NETSUITE_WEBHOOK_SECRET` is correctly set; check `/webhooks/netsuite` endpoint logs for rejection reasons

### S3 File Upload Errors
- **Symptoms**: Vendors receive errors when uploading documents via `/api/v2/external_files`
- **Cause**: Expired or incorrect AWS credentials, S3 bucket permission changes, or bucket unavailability
- **Resolution**: Verify `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_S3_BUCKET` environment variables; check AWS IAM policy for the configured credentials; confirm S3 bucket exists and is accessible

### Database Connection Exhaustion
- **Symptoms**: `PG::ConnectionBad` errors in logs; service returns 500 for most requests
- **Cause**: Connection pool exhausted, database pod restarted, or `DATABASE_URL` misconfigured
- **Resolution**: Check database pod/instance health; verify `DATABASE_URL`; consider reducing `PUMA_WORKERS` or `PUMA_THREADS` to lower connection pressure; restart gpapi pods after database recovery

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Vendor Portal completely down; all vendor operations blocked | Immediate | Goods Platform on-call engineer |
| P2 | Partial degradation (specific flows failing, e.g., file upload or promotions) | 30 min | Goods Platform team |
| P3 | Minor impact (non-critical endpoint slow, non-blocking errors) | Next business day | Goods Platform team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumGpapiDb` | PostgreSQL connection test | None; service cannot operate without DB |
| Google reCAPTCHA Enterprise | Google Cloud status page | None; vendor logins blocked when unavailable |
| Goods Product Catalog | Internal health endpoint | Degrade gracefully; return cached or error response |
| Vendor Compliance Service | Internal health endpoint | Compliance onboarding flow unavailable |
| Goods Promotion Manager | Internal health endpoint | Promotion management flow unavailable |
| Amazon S3 | AWS health dashboard | File upload/download unavailable |
