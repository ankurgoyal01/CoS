---
service: "sem-blacklist-service"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/grpn/status` on port 8080 | HTTP | Configured by JTier framework | JTier default |
| Dropwizard admin health check on port 8081 | HTTP | On demand / external probe | JTier default |
| `SemBlacklistServiceHealthCheck` | exec (Dropwizard) | Per health-check invocation | JTier default |

The service registers a custom Dropwizard `HealthCheck` (`SemBlacklistServiceHealthCheck`). The current implementation always returns healthy. The primary health check endpoint is `/grpn/status` at port 8080 (`sha_key: commitId`).

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| JVM memory / GC | gauge / histogram | JVM heap and GC metrics collected by JTier and shipped via filebeat | Container OOM |
| HTTP request latency | histogram | Dropwizard metrics for REST endpoints | Not configured in codebase |
| Asana task processing count | counter | Logged as `AsanaTasksRetrieved` with `add_tasks` and `delete_tasks` counts | No automated alert |
| Blacklist DB errors | counter | Logged as `TransientDatabaseError` on IOException from DAO | No automated alert |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| SEM Blacklist Service | Grafana | `https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/d/de7hslbsubif4n/sem-blacklist-service` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| OpsGenie alert | As configured in OpsGenie at `sem-analytics-service@groupondev.opsgenie.net` | Configurable | Engage SEM on-call; review Grafana dashboard |
| `AsanaTaskProcessingFatalError` log event | Unhandled exception in Asana task processing batch | warning | Check Asana API connectivity; verify `asanaApiKey` and `asanaSectionGid` config values |
| `BlacklistRefreshError` log event | GDoc Quartz job failed (IOException or scheduler error) | warning | Check Google Sheets API connectivity; verify OAuth2 credentials at `credentialLocation` |

## Common Operations

### Restart Service

1. Identify the Kubernetes deployment in the target namespace (e.g., `sem-blacklist-service-production`).
2. Issue a rolling restart: the DeployBot or platform team can trigger a re-deploy via the Jenkins pipeline or `kubectl rollout restart deployment/<deployment-name> -n sem-blacklist-service-production`.
3. Monitor pod status with `kubectl get pods -n sem-blacklist-service-production` until all pods are Running.
4. Verify health via `/grpn/status` on port 8080.

### Scale Up / Down

Scaling is configured statically in `.meta/deployment/cloud/components/api/production-us-central1.yml` (min 2 / max 2). To adjust, update the manifest and redeploy via DeployBot. VPA is enabled and may adjust resource allocations automatically.

### Trigger Asana Task Processing Manually

Send an HTTP POST request to the admin trigger endpoint:

```
POST /denylist/process-asana-tasks
```

This bypasses the Quartz schedule and immediately polls the configured Asana section for open tasks and processes any `ADD_REQUEST` or `DELETE_REQUEST` tasks.

### Database Operations

- **Schema migrations**: Managed automatically by `jtier-migrations` during service startup via Flyway.
- **Query denylist entries**: Use `GET /denylist?client=<client>&country=<country>` for live queries, or connect to the DaaS PostgreSQL instance and query `SELECT * FROM sem_raw_blacklist WHERE client = '<client>' AND country_code = '<country>' AND active = TRUE`.
- **Manual entry deletion**: Issue `DELETE /denylist` with a JSON body identifying the entry, or soft-delete via direct SQL: `UPDATE sem_raw_blacklist SET active = FALSE, deleted_by = '<user>', deleted_at = NOW() WHERE ...`.

## Troubleshooting

### Asana tasks not being processed
- **Symptoms**: Denylist entries expected from Asana tasks are not appearing; log event `AsanaTaskProcessingFatalError` or `AsanaTaskProcessingError` visible in Grafana/logs.
- **Cause**: Invalid or expired `asanaApiKey`; wrong `asanaSectionGid`; Asana API unavailable; task `Service Status` custom field not set to `ADD_REQUEST` or `DELETE_REQUEST`.
- **Resolution**: Verify `asanaApiKey` secret is current and the Asana API is reachable. Confirm `asanaSectionGid` matches the correct Asana section. Use `POST /denylist/process-asana-tasks` to trigger a manual run and observe logs. Update task custom field values in Asana if needed.

### Google Sheets blacklist not refreshing
- **Symptoms**: PLA denylist entries stale; `BlacklistRefreshError` log event visible; `GDocRefreshBlacklistJob` not completing.
- **Cause**: Expired OAuth2 stored credential at `credentialLocation`; `plaGdoc` sheet ID changed; Google Sheets API rate limit hit.
- **Resolution**: Check that `credLocation/StoredCredential` is valid and not expired. Verify the `plaGdoc`, `plaUsGDocDealSheet`, and `plaUsGDocDealOptionSheet` config values point to accessible sheets. Regenerate the OAuth2 credential if needed (see `GoogleDocsClient.createSheetsServiceRefreshCred()` notes in source).

### High memory / OOM container restarts
- **Symptoms**: Pods are killed with OOM; JVM heap or vmem usage is high.
- **Cause**: Insufficient memory limits; `MALLOC_ARENA_MAX` not tuned; JVM heap growth.
- **Resolution**: Verify `MALLOC_ARENA_MAX` is set to `4` in the Kubernetes deployment (`common.yml`). Review Grafana JVM memory dashboard. Adjust memory `request` / `limit` in `.meta/deployment/cloud/components/api/production-us-central1.yml` and redeploy.

### Denylist entries not appearing after REST API write
- **Symptoms**: `POST /denylist` returns success but entry not visible in subsequent `GET`.
- **Cause**: Duplicate entry guard (`WHERE NOT EXISTS`) blocked re-insert; entry exists but `active = FALSE`.
- **Resolution**: Query `sem_raw_blacklist` directly filtering on the key fields including `active = FALSE`. If the entry is soft-deleted, the `addEntity` API will call `updatePrev` to reactivate it. Verify the correct combination of `entityId`, `entityOptionId`, `client`, `countryCode`, `searchEngine`, and `brandMerchantId` was provided.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down — no denylist reads or writes possible | Immediate | SEM team (`sem-devs@groupon.com`); OpsGenie `sem-analytics-service@groupondev.opsgenie.net` |
| P2 | Degraded — Asana or GDoc sync failing; REST API still functional | 30 min | SEM on-call via OpsGenie |
| P3 | Minor impact — individual task processing errors; metrics anomaly | Next business day | SEM team Slack / email |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| PostgreSQL (DaaS) | JTier connection pool; Dropwizard admin health check (port 8081) | Service fails writes; reads return errors |
| Asana REST API | Implicit — checked on each job run; `AsanaApiRequest` log event | Quartz job logs error and retries on next schedule |
| Google Sheets API | Implicit — checked on each job run; `BlacklistRefreshError` log event | Quartz job logs error; existing DB entries remain unchanged |
