---
service: "file-sharing-service"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/healthcheck` | http (returns HTTP 200 with `{}`) | Readiness: 5s, Liveness: 15s | Not configured (Kubernetes default) |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `custom.file-sharing-service.general.server_error` | counter | HTTP server errors; tagged with `uri`, `request_method`, `remote_ip`, `exception_type`, `env`, `region` | Operational procedures to be defined by service owner |

Metrics are written to InfluxDB/Telegraf via `TELEGRAF_URL`. Global metric tags are populated from `DEPLOY_AZ`, `DEPLOY_ENV`, `DEPLOY_COMPONENT`, `DEPLOY_SERVICE`, `DEPLOY_INSTANCE`, `DEPLOY_MONITORING_GROUP`, `DEPLOY_NAMESPACE`, `DEPLOY_REGION`, `TELEGRAF_METRICS_ATOM`.

### Dashboards

> Operational procedures to be defined by service owner. Kibana logs are accessible via index `us-*:filebeat-file-sharing-service_api` at the Groupon logging platform endpoints.

### Alerts

> Operational procedures to be defined by service owner.

## Common Operations

### Restart Service

1. Authenticate: `./bin/auth` (calls `kubectl cloud-elevator auth`)
2. Set context: `./bin/production-context` or `./bin/staging-context`
3. View pods: `./bin/pods`
4. Restart by deleting a pod (Kubernetes will recreate it): `kubectl delete pod <pod-name>`
5. Check logs: `./bin/pod-logs` or `kubectl logs <pod-name> -c main`

### Scale Up / Down

Scaling is managed through the Conveyor Cloud deployment YAML (`min/maxReplicas`). To manually scale in an emergency:

```shell
kubectl scale deployment file-sharing-service --replicas=<N>
```

### Database Operations

**Staging migrations** (run inside pod):

1. `./bin/bash` — drop into a pod shell
2. `lein lobos migrate` — apply pending migrations
3. `lein lobos rollback` — roll back last migration

**Production migrations** — raise a GDS ticket at `https://jira.groupondev.com/browse/GDS` including:
- SQL `ALTER TABLE` statement (migrate)
- `INSERT INTO lobos_migrations(name) VALUES('<migration-name>')` (migrate)
- `ALTER TABLE ... DROP COLUMN` (rollback)
- `DELETE FROM lobos_migrations WHERE name = '<migration-name>'` (rollback)

**Connect to staging database**:
```shell
./bin/staging-database
```

### Port Forwarding (Local → Pod)

```shell
./bin/port-forward
# forwards local port 9000 → pod port 5001
```

### Token Refresh for a User

Open a REPL and call:
```clojure
(replace-user-oauth-tokens <user-id> <auth-code>)
```
Obtain a fresh `auth-code` via the Google Developers OAuth 2.0 Playground using the FSS `client_id` and `client_secret`.

## Troubleshooting

### File upload fails with authentication error

- **Symptoms**: Upload returns 500 with "All authentication methods failed" or Google Drive exception in logs
- **Cause**: Service account JSON key is missing, expired, or the path `GOOGLE_SERVICE_ACCOUNT_JSON_PATH` is incorrect; or `GOOGLE_DELEGATED_USER_EMAIL` is not set up for domain-wide delegation in Google Workspace; or user's OAuth tokens are expired and cannot be refreshed
- **Resolution**: Verify the service account JSON key is mounted at the expected path; check `GOOGLE_AUTH_MODE` env var; verify delegation is enabled in Google Workspace admin console; refresh user OAuth tokens via REPL `replace-user-oauth-tokens`

### Token was previously used or invalid (400)

- **Symptoms**: `POST /users/register` returns HTTP 400 `{"error": "Token was previously used or invalid."}`
- **Cause**: The Google OAuth2 authorization code has already been exchanged or has expired (codes are single-use)
- **Resolution**: Generate a new authorization code via the Google Developers OAuth 2.0 Playground and retry registration

### User already exists (400)

- **Symptoms**: `POST /users/register` returns HTTP 400 `{"error": "User already exists."}`
- **Cause**: A user record with the same email already exists in the `users` table (`SQLIntegrityConstraintViolationException`)
- **Resolution**: Update the user's OAuth tokens via REPL instead of re-registering

### File content gone (410)

- **Symptoms**: `GET /files/<uuid>` returns HTTP 410 `{"error": "File content is gone."}`
- **Cause**: The `file_contents` blob has been cleared by the daily scheduled task (the `delete-at` timestamp passed)
- **Resolution**: The file cannot be retrieved from MySQL. If it was previously uploaded to Google Drive (`external-file-id` is set), the caller can use the Google Drive ID to access it directly. This is expected behavior.

### Scheduled tasks not running

- **Symptoms**: Expired file contents are not being cleared; `/tasks/status` shows `running: false`
- **Cause**: The cronj scheduler was not started or was stopped
- **Resolution**: `GET /tasks/start` to restart the scheduler; verify `/tasks/status` shows `running: true`

### Metrics not appearing in InfluxDB

- **Symptoms**: No data in `custom.file-sharing-service.general.*` measurements
- **Cause**: `TELEGRAF_URL` env var not set or Telegraf sidecar not reachable at the configured host/port
- **Resolution**: Verify `TELEGRAF_URL` is set correctly; check Telegraf sidecar is healthy; metric write failures are logged as `:write-points-failure` events in the application log

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — file upload/sharing unavailable | Immediate | finance-engineering team |
| P2 | Degraded — Google Drive auth failing, falling back to OAuth only | 30 min | finance-engineering team |
| P3 | Minor — metrics not shipping, non-critical endpoint degraded | Next business day | finance-engineering team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| MySQL (`continuumFileSharingMySql`) | JDBC connection on startup; queries fail fast if DB is down | No fallback — service cannot operate without DB |
| Google Drive API | Upload request; 5-retry logic per upload attempt | Three-tier auth fallback: service account → delegation → OAuth |
| Google OAuth2 API | Token exchange/refresh on `/users/register` and token use | No fallback — if OAuth is unavailable, registration fails |
| InfluxDB / Telegraf | Metrics write on each error event | Metrics failures are caught and logged; service continues normally |
