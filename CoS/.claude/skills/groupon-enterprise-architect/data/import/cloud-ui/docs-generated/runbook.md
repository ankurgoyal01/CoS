---
service: "cloud-ui"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /api/health` (frontend) | HTTP | `10s` delay (readiness), `10s` delay (liveness) per Helm config | Not specified |
| `GET /cloud-backend/health` (backend) | HTTP | Not configured in discovered Helm values | Not specified |
| `GET /cloud-backend/ready` (backend) | HTTP | Not configured in discovered Helm values | Not specified |

Both the frontend's `/api/health` and the backend's `/cloud-backend/health` return `200 OK` with JSON `{ "status": "healthy" }` when the service is running. The Kubernetes readiness and liveness probes for the frontend container are configured to use `GET /api/health` on port `3000` with an initial delay of 10 seconds.

## Monitoring

### Metrics

> No evidence found in codebase. No custom metrics instrumentation (Prometheus, Datadog, etc.) was found in the Cloud UI or Cloud Backend source.

### Dashboards

> No evidence found in codebase. Operational procedures to be defined by service owner.

### Alerts

> No evidence found in codebase. Operational procedures to be defined by service owner.

## Common Operations

### Restart Service

To restart the Cloud UI frontend pod on Kubernetes:
1. Identify the deployment: `kubectl get deployments -n <namespace> | grep cloud-ui`
2. Trigger a rollout restart: `kubectl rollout restart deployment/cloud-ui -n <namespace>`
3. Verify pods are healthy: `kubectl get pods -n <namespace> -l app=cloud-ui`

### Scale Up / Down

Cloud UI uses a fixed replica count (`minReplicas: 2`, `maxReplicas: 2`) in the Helm values. To adjust:
1. Update `.meta/deployment/cloud/components/app/common.yml` with new `minReplicas`/`maxReplicas` values.
2. Commit and trigger the Jenkins pipeline to redeploy with updated Helm values.

### Database Operations

**Run migrations** (Encore manages this automatically on deployment):
- Encore applies migrations from `cloud-backend/api/migrations/` in numeric order on service startup.
- Migrations are idempotent (`IF NOT EXISTS` guards).

**Check sync lock state** (if a deployment appears stuck):
```sql
SELECT id, name, sync_in_progress, sync_started_at
FROM applications
WHERE sync_in_progress = TRUE;
```
To manually release a stale sync lock:
```sql
UPDATE applications
SET sync_in_progress = FALSE, sync_started_at = NULL
WHERE id = '<application_id>';
```

**Clear Helm caches** (if Helm operations are returning stale chart versions):
```
POST /cloud-backend/helm/clear-cache
```
This clears the in-memory index cache, the filesystem chart cache (`/tmp/helm-chart-cache`), and the Helm SDK cache.

## Troubleshooting

### Deployment Stuck in "synced" Phase

- **Symptoms**: `GET /cloud-backend/deployments/:id/status` returns `phase: synced` for more than 5 minutes; `status` transitions to `failed` after the 5-minute timeout
- **Cause**: The backend polled Jenkins but could not find a matching build for the commit hash (Jenkins job does not exist, or the build has not started yet)
- **Resolution**: Verify the Jenkins job exists at `https://cloud-jenkins.groupondev.com` for the organization/application name combination. Check Jenkins connectivity from the Cloud Backend pod. Retry the Git sync via `POST /cloud-backend/applications/:id/sync-to-git` once Jenkins is confirmed available.

### Git Sync Fails with Lock Error

- **Symptoms**: `POST /cloud-backend/applications/:id/sync-to-git` returns an error indicating sync is already in progress
- **Cause**: A previous sync operation left `sync_in_progress = TRUE` on the application record without releasing it (e.g., pod restart during sync)
- **Resolution**: Manually reset the sync lock in PostgreSQL (see Database Operations above), then retry the sync.

### Backend API URL Not Resolving (Frontend Shows No Data)

- **Symptoms**: Frontend loads but all API calls fail; `/api/config` returns the fallback `http://127.0.0.1:4000/cloud-backend`
- **Cause**: `API_URL` and `NEXT_PUBLIC_API_URL` environment variables are not set or not injected into the container
- **Resolution**: Verify the Helm values file for the environment (`staging-us-central1.yml` or `production-us-central1.yml`) has the correct `API_URL` in `envVars`. Re-deploy the frontend container with the corrected values.

### Helm Chart Version Not Found

- **Symptoms**: `POST /cloud-backend/helm/chart-for-workload` or `POST /cloud-backend/helm/validate-version` returns "not found" error
- **Cause**: The Artifactory index cache may be stale, or the chart version genuinely does not exist in the registry
- **Resolution**: Call `POST /cloud-backend/helm/clear-cache` to evict the index cache, then retry. If still failing, verify chart availability at `https://artifactory.groupondev.com/artifactory/list/helm-generic/`.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Cloud UI completely unavailable; no deployments can be triggered | Immediate | Cloud Platform Team |
| P2 | Deployment pipeline degraded (e.g., Jenkins integration down, Git sync failing) | 30 min | Cloud Platform Team |
| P3 | Helm preview or config diff not working; minor UI issues | Next business day | Cloud Platform Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| PostgreSQL | `GET /cloud-backend/ready` (reports `"database": "healthy"`) | No fallback; all write operations fail |
| Jenkins | `GET /cloud-backend/deployments/:id/status` — polling will log errors and surface failure in phase | Deployment marked failed after 5-minute timeout |
| Artifactory | `POST /cloud-backend/helm/clear-cache` + retry; check index cache TTL (6h) | In-memory and filesystem cache provide partial resilience up to 24h for known charts |
| Git repositories | `POST /cloud-backend/applications/:id/sync-to-git` error response | No fallback; sync fails and lock is released |
| Deploybot | URL construction only; no runtime call | Not applicable — URL is surfaced to engineer |
