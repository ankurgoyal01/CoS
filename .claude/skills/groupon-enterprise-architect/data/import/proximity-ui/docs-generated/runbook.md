---
service: "proximity-ui"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `http://{host}:8080/#!/summary` | http (curl) | Deploy-time only (no continuous health check configured) | Up to 10 retries x 2s backoff via `fabfile.py` `verify()` |

> No evidence found in codebase of a dedicated `/health` or `/ping` endpoint. The Fabric deploy script verifies liveness by curling the summary UI route post-deployment.

## Monitoring

### Metrics

> No evidence found in codebase. No metrics instrumentation (StatsD, Datadog agent, Prometheus, etc.) is present.

### Dashboards

> No evidence found in codebase.

### Alerts

> No evidence found in codebase.

## Common Operations

### Restart Service

```bash
# SSH to the affected host
ssh proximity-ui-app1.snc1

# Navigate to the application directory
cd /var/groupon/proximity-ui

# Stop the forever process and restart with current NODE_ENV
NODE_ENV=production npm run build
# This runs: forever stopall && NODE_ENV=$NODE_ENV forever start build/build.js
```

### Deploy to Staging

```bash
# From local repo root (SNC1 staging only via shortcut)
fab deploy_staging

# For any environment including EMEA and regional production targets
fab deploy:staging_emea
fab deploy:production_dub1
fab deploy:production_sac1
```

### Deploy to Production

```bash
# SNC1 production only via shortcut
fab deploy_prod

# Regional overrides
fab deploy:production_dub1
fab deploy:production_sac1
```

### Manual Deploy (without Fabric)

```bash
# SSH to the remote host
ssh proximity-ui-app1.snc1

cd /var/groupon/proximity-ui
git pull origin master
npm install
NODE_ENV=production npm run build
```

### Scale Up / Down

Operational procedures to be defined by service owner. Scaling is achieved by adding or removing hosts from the `hosts` dict in `fabfile.py` and re-deploying.

### Database Operations

Not applicable. This service is stateless and owns no database.

## Troubleshooting

### Service Not Responding After Deploy

- **Symptoms**: `curl http://{host}:8080/#!/summary` returns connection refused or non-200
- **Cause**: `forever` process did not start, or Node.js build failed
- **Resolution**: SSH to host, run `forever list` to check process status. If not running, inspect `forever` logs in `/var/groupon/proximity-ui`, then re-run `NODE_ENV=<env> npm run build` manually.

### "Permission" Screen Shown to All Users

- **Symptoms**: Every user sees the `/permission` Vue view regardless of their identity
- **Cause**: `X-Remote-User` header is not being injected by Nginx, or the user's username is not present in the Hotzone API user allowlist returned by `/v1/proximity/location/hotzone/users?client_id=ec-team`
- **Resolution**: Verify Nginx is setting `X-Remote-User`. Check that the user is listed in `continuumProximityHotzoneApi` user management.

### Hotzone API Calls Failing

- **Symptoms**: Browser shows alert banners with error messages from API operations (create, browse, delete)
- **Cause**: The upstream `continuumProximityHotzoneApi` VIP is unreachable, or the `NODE_ENV` config file points to the wrong endpoint
- **Resolution**: Verify `NODE_ENV` is set correctly for the environment. Curl the configured `hotzoneApiEndpoint` directly from the host to confirm reachability. Check that the host is connected to the appropriate internal network / VPN.

### Duplicate Hotzone Confirmation Dialog Appears

- **Symptoms**: User sees a bootbox confirmation dialog warning about a previously submitted hotzone
- **Cause**: The Vue `Create` view detects that the current form payload matches the last-submitted payload (stored in component state as `previousHotzonesObject`)
- **Resolution**: This is expected behavior. If the user intends to create an identical hotzone, they should confirm the dialog. The check is client-side only and resets on page reload.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down — administrators cannot manage hotzones | Immediate | EC Team on-call |
| P2 | Degraded — some operations failing (e.g., delete works but create does not) | 30 min | EC Team |
| P3 | Minor — UI cosmetic issues or non-critical feature broken | Next business day | EC Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumProximityHotzoneApi` | Curl `http://<hotzoneApiEndpoint>/users?client_id=ec-team` directly from the host | No automatic fallback; all data operations will fail if this dependency is down |
