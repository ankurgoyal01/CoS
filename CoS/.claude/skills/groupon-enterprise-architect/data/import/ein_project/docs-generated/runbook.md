---
service: "ein_project"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /api/heartbeat/` | http | Kubernetes liveness probe interval (configured in manifests) | Kubernetes liveness probe timeout |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Change request approval rate | gauge | Proportion of change requests approved vs. rejected | Operational alert threshold to be defined by service owner |
| Change request rejection rate | gauge | Rate of rejected change requests (by reason) | Operational alert threshold to be defined by service owner |
| Region lock active | gauge | Whether one or more regions are currently locked | Any region locked for > configured threshold |
| Background job queue depth | gauge | Number of pending RQ jobs in Redis | Operational alert threshold to be defined by service owner |
| JIRA API error rate | counter | Errors returned from JIRA Cloud during validation | Sustained errors indicate JIRA connectivity issue |
| JSM/PagerDuty API error rate | counter | Errors returned from JSM/PagerDuty during incident checks | Sustained errors indicate incident monitor degradation |
| Heartbeat response | gauge | `/api/heartbeat/` HTTP status (emitted via Wavefront) | Non-200 response |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| ProdCat compliance metrics | Wavefront | Link to be provided by service owner |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Heartbeat failing | `/api/heartbeat/` returns non-200 for > 2 consecutive checks | critical | Investigate web app pod logs; check PostgreSQL and Redis connectivity |
| Worker queue stuck | RQ job queue depth growing without reduction | warning | Check worker pod logs; verify Redis connectivity; restart worker pod if needed |
| Region lock not lifting | Region remains locked after incident resolved in PagerDuty/JSM | warning | Manually clear the region lock via admin UI or database; verify `incidentMonitor` job is running |
| JIRA validation errors | Sustained JIRA API errors causing change request rejections | critical | Check JIRA API token validity; verify JIRA Cloud availability; contact JIRA admin |

## Common Operations

### Restart Service

1. Identify the affected pod(s) via `kubectl get pods -n <namespace>`.
2. For the web app: `kubectl rollout restart deployment/prodcat-web -n <namespace>`.
3. For the worker: `kubectl rollout restart deployment/prodcat-worker -n <namespace>`.
4. Verify `/api/heartbeat/` returns healthy after restart.

### Scale Up / Down

1. Adjust the Kubernetes HPA target or deployment replica count in the external manifests.
2. For immediate scaling: `kubectl scale deployment/prodcat-web --replicas=<N> -n <namespace>`.
3. Worker replicas should match the expected job throughput; adjust via `kubectl scale deployment/prodcat-worker --replicas=<N>`.

### Database Operations

1. Django database migrations are applied via `python manage.py migrate` as part of the deployment pipeline before new pods are started.
2. Manual migration: exec into a web app pod and run `python manage.py migrate`.
3. Database backups are managed by Cloud SQL automatic backup policies; restore via GCP Console or `gcloud sql backups restore`.

## Troubleshooting

### Change requests are being rejected with no clear reason

- **Symptoms**: Deployment tooling reports rejection; `/api/change_log/` shows rejection but reason is unclear.
- **Cause**: One or more of the following: JIRA ticket not in approved state, active region lock, change window freeze, Service Portal validation failure.
- **Resolution**: Check the rejection detail in the change log response. Verify JIRA ticket status. Check `/api/scheduled_locks/` and `/api/regions/` for active locks. Check `/api/change_windows/` for freeze windows. Check Service Portal for service registration issues.

### Region is locked and cannot be unlocked

- **Symptoms**: All deployments to a region are blocked; incident is resolved but lock persists.
- **Cause**: `incidentMonitor` background job has not yet run or failed to connect to PagerDuty/JSM.
- **Resolution**: Check worker pod logs for `incidentMonitor` errors. Verify `PAGERDUTY_API_TOKEN` and `JSM_API_TOKEN` are valid. Manually release the lock via the Django admin or database if the incident is confirmed resolved.

### Background jobs are not running

- **Symptoms**: Tickets are not being auto-closed; incident monitor is not updating region locks.
- **Cause**: Worker pod is down or Redis is unreachable.
- **Resolution**: Check worker pod status with `kubectl get pods`. Verify Redis connectivity from the worker pod. Check `REDIS_URL` environment variable. Restart worker pod if needed.

### JIRA integration returning 401 / 403

- **Symptoms**: Change requests fail validation with JIRA authentication errors in logs.
- **Cause**: `JIRA_API_TOKEN` has expired or been revoked.
- **Resolution**: Rotate the JIRA API token in JIRA Cloud settings. Update the Kubernetes secret. Restart web app pods to pick up the new token.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | ProdCat is down — all deployments blocked | Immediate | Jarvis team (deployment@groupon.com) + Production Change Management |
| P2 | Partial degradation — specific regions blocked or JIRA integration failing | 30 min | Jarvis team (deployment@groupon.com) |
| P3 | Minor impact — notifications failing, metrics not emitting | Next business day | Jarvis team (deployment@groupon.com) |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumProdcatPostgres` (Cloud SQL) | Django database connectivity at startup; ORM query failures surface in logs | No fallback — service cannot operate without the database |
| `continuumProdcatRedis` (Memorystore) | RQ connection at worker startup; cache miss on Redis failure | Cache miss degrades to direct external API calls; RQ jobs cannot be processed without Redis |
| JIRA Cloud | API call success/failure during validation | No fallback — validation fails closed if JIRA is unreachable |
| JSM / PagerDuty | API call success/failure during incident monitor | Last known region lock state preserved |
| Service Portal | API call success/failure during validation | No fallback — validation fails closed if Service Portal is unreachable |
| Google Chat | Notification delivery success/failure | Failure is non-blocking; change request outcome unaffected |
