---
service: "ultron-api"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/health` | http | Inferred from Kubernetes liveness probe | Inferred |
| `/evolutions` | http | Manual / on-deploy check | — |

> Specific health check intervals and timeouts are not defined in the architecture module. Verify in the service source repository and Kubernetes probe configuration.

## Monitoring

### Metrics

> No evidence found in codebase. Metrics collection follows standard Continuum JVM service patterns. Operational procedures to be defined by service owner.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request rate | counter | Requests per second to Ultron API endpoints | To be defined |
| HTTP error rate (5xx) | counter | Server-side errors on API and UI endpoints | To be defined |
| HTTP response latency | histogram | P99 latency for API responses | To be defined |
| JVM heap usage | gauge | JVM heap utilization percentage | To be defined |
| Database connection pool usage | gauge | Active connections to `continuumUltronDatabase` | To be defined |
| Quartz scheduler missed fires | counter | Watchdog triggers that did not fire on time | To be defined |
| Watchdog alerts sent | counter | Email alerts dispatched by the Email Manager | To be defined |

### Dashboards

> No evidence found in codebase. Operational procedures to be defined by service owner.

| Dashboard | Tool | Link |
|-----------|------|------|
| Ultron API Service Dashboard | Datadog / Grafana (inferred) | To be defined by service owner |

### Alerts

> No evidence found in codebase. Operational procedures to be defined by service owner.

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High 5xx Error Rate | >1% error rate over 5 min | critical | Check database connectivity; review Play application logs |
| Database Connection Pool Exhausted | Pool at 100% utilization | critical | Check for slow queries; consider scaling or pool size increase |
| Quartz Scheduler Not Firing | No watchdog triggers in expected window | critical | Check Quartz DB connectivity; restart service if needed |
| JVM Heap at Limit | Heap usage >90% | warning | Check for memory leaks; restart pod; review JAVA_OPTS heap settings |

## Common Operations

### Restart Service

For Kubernetes-managed deployments:
1. Identify the deployment: `kubectl get deployment ultron-api -n <namespace>`
2. Perform a rolling restart: `kubectl rollout restart deployment/ultron-api -n <namespace>`
3. Monitor rollout: `kubectl rollout status deployment/ultron-api -n <namespace>`
4. Verify Quartz scheduler reinitializes: check logs for Quartz startup messages

### Scale Up / Down

For Kubernetes deployments:
1. Check current scale: `kubectl get deployment ultron-api -n <namespace>`
2. Scale manually if HPA is not active: `kubectl scale deployment/ultron-api --replicas=<N> -n <namespace>`

### Database Operations

1. **Run Play Evolutions**: Navigate to `/evolutions` in a browser (or via API) on a freshly deployed instance to apply pending schema migrations
2. **Check pending evolutions**: The `appController` exposes evolution status at the evolution endpoint
3. **Database backups**: Managed by the infrastructure team; verify against Continuum DB backup policies
4. **Manual schema inspection**: Connect to `continuumUltronDatabase` via approved DB access tooling with read-only credentials

## Troubleshooting

### Watchdog Alerts Not Sending

- **Symptoms**: Overdue jobs not generating alert emails; `emailManager` not dispatching
- **Cause**: SMTP email service unavailable, incorrect SMTP credentials, or Quartz scheduler not running
- **Resolution**: Check `SMTP_HOST` and `SMTP_PORT` configuration; verify `smtpEmailService_2d1e` is reachable; check Quartz scheduler logs for trigger firing

### Job Instance Registration Failures

- **Symptoms**: Job runner clients receive 5xx errors when POSTing to `/job-instances`
- **Cause**: `continuumUltronDatabase` connectivity failure or schema mismatch
- **Resolution**: Check database connection pool logs; verify `ULTRON_DB_URL` and credentials; check for unapplied evolutions via `/evolutions`

### Quartz Scheduler Not Starting

- **Symptoms**: Service starts but watchdog jobs do not fire; Quartz initialization errors in logs
- **Cause**: `continuumQuartzSchedulerDb` unreachable or schema not initialized
- **Resolution**: Verify `QUARTZ_DB_URL` and credentials; run Quartz DDL scripts against the database if schema is missing

### Slow API Responses

- **Symptoms**: High P99 latency on job or resource queries
- **Cause**: Slow database queries; missing indexes; high connection pool contention
- **Resolution**: Check active queries on `continuumUltronDatabase`; review Slick query plans; check connection pool metrics

### UI Not Loading

- **Symptoms**: HTML views return 500 errors or blank pages
- **Cause**: Play template rendering failure; database query error within controller action
- **Resolution**: Check application logs for Play template exceptions; verify database connectivity

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Ultron API fully down (job runner clients cannot register runs) | Immediate | Continuum Platform Team |
| P2 | Watchdog alerts not sending; UI degraded | 30 min | Continuum Platform Team |
| P3 | Specific endpoint slow or erroring; lineage UI broken | Next business day | Continuum Platform Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumUltronDatabase` | `/health` endpoint; JDBC connectivity test on startup | Service unavailable; all API and UI operations fail |
| `continuumQuartzSchedulerDb` | Quartz startup connectivity check | Scheduler does not start; watchdog jobs do not fire |
| `smtpEmailService_2d1e` | No explicit check; SMTP connection attempt on first alert | Watchdog alert not delivered; state still recorded in DB |
