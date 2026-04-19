---
service: "groupon-monorepo"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Encore Cloud health (automatic) | Platform-managed | Continuous | Platform default |
| `GET /healthz` (Cloud Run frontends) | HTTP | 10s | 5s |
| Docker health check (Python services) | exec | 30s | 10s |
| Encore developer dashboard (`localhost:9400`) | HTTP (local only) | On-demand | -- |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Request latency (per service) | histogram | Encore-managed per-endpoint latency | Platform default |
| Error rate (per service) | counter | Encore-managed 4xx/5xx error counts | Platform default |
| `vespa_reader_vespa_duration_ms` | gauge | Vespa HTTP request latency (Go backend) | > 500ms |
| `vespa_reader_vespa_requests` | counter | Vespa requests by HTTP status code (Go backend) | Status "err" or "5xx" spike |
| Langfuse trace metrics | histogram | AI/LLM call latency and token usage | Per-model thresholds |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Encore Cloud Dashboard | Encore Cloud | https://app.encore.cloud |
| Encore Local Dev Dashboard | Encore CLI | http://localhost:9400 (local) |
| Langfuse AI Observability | Langfuse | Configured per tribe (B2B, AI, Test projects) |
| Cloud Run Console | Google Cloud Console | GCP project dashboard |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Service crash/restart | Service exits unexpectedly | critical | Encore Cloud auto-restarts; check logs in Encore dashboard |
| Database migration failure | Migration script errors on deploy | critical | Roll back deployment; fix migration; redeploy |
| Salesforce sync failure | jsforce API errors or timeout | warning | Check Salesforce API status; verify OAuth tokens; retry sync manually |
| Kafka consumer lag | Consumer offset falls behind | warning | Check kafka service logs; verify Kafka cluster health |
| Frontend build failure | Cloud Run deploy fails | critical | Check GitHub Actions workflow logs; fix build errors; re-trigger deploy |
| Python service unhealthy | Docker health check fails | critical | SSH to DigitalOcean droplet; check supervisor logs; restart containers |

## Common Operations

### Restart Service
Encore Cloud services automatically restart on crash. For manual restart:
1. Navigate to Encore Cloud Dashboard (https://app.encore.cloud)
2. Select the environment (staging/production)
3. Find the target service
4. Trigger redeployment from the dashboard or merge a no-op commit to the target branch

### Scale Up / Down
- **Encore backend**: Managed automatically by Encore Cloud. No manual scaling required.
- **Cloud Run frontends**: Adjust min/max instances in the Cloud Run console or deployment workflow.
- **Python services**: Resize the DigitalOcean droplet or adjust supervisor process count in `supervisord.conf`.

### Database Operations
- **Run migrations**: Migrations run automatically on deployment via Encore's `SQLDatabase` migration system.
- **Access database shell**: `cd apps/encore-ts && encore db shell <db-name> --env=<env>`
- **Get connection string**: `cd apps/encore-ts && encore db conn-uri <db-name> --env=<env>`
- **Database proxy**: `cd apps/encore-ts && encore db proxy --env=<env>` (for local tools like Drizzle Studio)
- **Reset database**: `cd apps/encore-ts && encore db reset <service-name>` (local only)
- **Drizzle Studio**: `cd apps/encore-ts && pnpm drizzle:studio` (visual DB explorer)
- **Import data from remote**: `cd apps/encore-ts && pnpm db:import -- --from-env staging-us-central1`

## Troubleshooting

### Docker not running
- **Symptoms**: `pnpm backend` fails, `docker info` errors
- **Cause**: Docker Desktop or OrbStack not started
- **Resolution**: Start Docker Desktop or OrbStack. Verify with `docker info`.

### Wrong Node.js version
- **Symptoms**: Build errors, package install failures, runtime crashes
- **Cause**: Node.js version below 22
- **Resolution**: `nvm use 22` or `nvm install 22`. Verify with `node -v`.

### Encore client out of sync
- **Symptoms**: Type errors in frontend code, missing API endpoints
- **Cause**: Backend API changed without regenerating client
- **Resolution**: Run `pnpm gen` from monorepo root. This regenerates the TypeScript client from Encore API definitions.

### Build failures after pulling changes
- **Symptoms**: Various build or type errors after git pull
- **Cause**: Dependencies or generated code out of date
- **Resolution**: Run `pnpm clean:node_modules && pnpm install && pnpm run init` from monorepo root.

### Temporal workflow not executing
- **Symptoms**: Workflow tasks not being picked up
- **Cause**: Temporal workers not enabled or not running
- **Resolution**: Start with `pnpm dev:workflow <worker-name>` or set `TEMPORAL_WORKERS_ENABLED=1` before running backend.

### Salesforce sync failing
- **Symptoms**: Account data stale, sync errors in logs
- **Cause**: Salesforce OAuth token expired or API limits exceeded
- **Resolution**: Check Encore secrets for Salesforce credentials. Verify Salesforce API status. Trigger manual sync from admin UI.

### Python AI services not responding
- **Symptoms**: AIDG inference calls failing, timeouts
- **Cause**: Python services container crashed or unreachable
- **Resolution**: Check DigitalOcean droplet status. SSH and check `supervisord` logs. Restart with `docker-compose -f docker-compose.dev.yml up --build` (local) or redeploy (production).

### Database migration errors
- **Symptoms**: Service fails to start after deployment
- **Cause**: SQL migration script has errors or conflicts
- **Resolution**: Check Encore Cloud logs for migration error details. Fix migration file. Redeploy. For local: `encore db reset <service-name>`.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Platform down, all services affected | Immediate | Encore Core Team |
| P2 | Single service degraded, partial functionality | 30 min | Owning tribe team |
| P3 | Minor feature impact, workaround available | Next business day | Owning tribe team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Salesforce | jsforce connection test | Local cache; manual sync later |
| BigQuery | Query execution test | Stale dashboard data; no immediate fallback |
| Mux | API ping | Video upload queued; text/image content unaffected |
| Twilio | API status page | SMS delivery delayed; notification service logs failure |
| Vespa.ai | HTTP health endpoint | Search returns empty results; Booster adapter fallback (Go) |
| Booster API | HMAC-signed test request | Vespa adapter fallback (Go) |
| Continuum DMAPI | HTTP health check | Deal sync queued; manual retry from admin UI |
| Continuum Lazlo | HTTP health check | Redis cache serves stale data; Lazlo retry on next request |
| Kafka | Consumer lag monitoring | Messages buffered in Kafka; consumer reconnects automatically |
| Redis | Connection ping | Services degrade to direct DB queries; cache miss path |
