---
service: "janus-web-cloud"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/healthcheck` (Dropwizard standard) | http | Platform default | Platform default |
| MySQL connectivity check (Dropwizard healthcheck) | http | Platform default | Platform default |

> Operational procedures to be defined by service owner for exact intervals and timeouts.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| JVM heap usage | gauge | JVM memory utilisation for the service process | No evidence found |
| HTTP request rate | counter | Requests per second across all API endpoints | No evidence found |
| HTTP error rate | counter | 5xx responses across all API endpoints | No evidence found |
| MySQL connection pool utilisation | gauge | Active JDBI/JDBC connections vs pool capacity | No evidence found |
| Quartz job execution latency | histogram | Time taken for scheduled alert evaluation and replay jobs | No evidence found |
| Alert evaluation failures | counter | Alert threshold evaluation jobs that errored | No evidence found |
| Replay job queue depth | gauge | Number of pending replay jobs in MySQL | No evidence found |

> Specific metric names and alert thresholds are not discoverable from the architecture model. The `metricsStack` integration emits and consumes operational metrics. Service owner should define thresholds.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Janus Web Cloud Operational | metricsStack / Grafana (inferred) | No evidence found |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| MySQL connectivity failure | Health check fails for `continuumJanusMetadataMySql` | critical | Verify MySQL host reachability; check connection pool config; escalate to dnd-ingestion |
| Alert evaluation job failure | Quartz alert job fails repeatedly | warning | Check Elasticsearch connectivity; review alert threshold expressions in `/janus/api/v1/alert/`; check logs |
| SMTP delivery failure | Alert email dispatch fails | warning | Verify `smtpRelay` connectivity and credentials; check email recipient configuration |
| Replay job stalled | Replay job status stuck in-progress for extended period | warning | Check replay job status via `/replay/{id}`; verify GDOOP resource manager connectivity; escalate if needed |
| High 5xx error rate | HTTP 5xx rate above threshold on any endpoint group | critical | Check service logs via `loggingStack`; verify downstream dependency health; restart if needed |

## Common Operations

### Restart Service

> Operational procedures to be defined by service owner. Follow JTier/Kubernetes rolling restart procedures. Quartz clustered mode ensures in-flight jobs are picked up by remaining instances during restart.

### Scale Up / Down

1. Adjust replica count via the platform orchestration tool (Kubernetes HPA or manual scaling).
2. Ensure all new instances share the same `MYSQL_HOST`, `MYSQL_DATABASE`, and `QUARTZ_CLUSTER_ID` configuration so Quartz clustering operates correctly.
3. Verify new instances pass the `/healthcheck` endpoint before receiving traffic.

### Database Operations

- **Schema migrations**: Run against `continuumJanusMetadataMySql` during a maintenance window; follow the migration scripts in the source repository.
- **Quartz table maintenance**: Stale Quartz trigger records can be cleaned up via the `quartzSchedulerTables` using Quartz administrative tooling.
- **Alert definition management**: Use `/janus/api/v1/alert/` CRUD endpoints to manage alert rules without direct DB access.
- **Replay backfills**: Submit replay jobs via `POST /replay/` and monitor status via `GET /replay/{id}`.

## Troubleshooting

### Alert emails not being sent
- **Symptoms**: Alert definitions exist; evaluation runs (logs show job execution); no emails received
- **Cause**: `smtpRelay` connectivity or authentication failure; or recipient list misconfigured in alert definition
- **Resolution**: Check SMTP credentials and host config; verify recipient addresses via `GET /janus/api/v1/alert/{id}`; check `loggingStack` for SMTP error traces

### Replay jobs not progressing
- **Symptoms**: Replay job status stuck; `GET /replay/{id}` shows in-progress indefinitely
- **Cause**: Quartz trigger misfired; GDOOP resource-manager unreachable; replay split too large
- **Resolution**: Check `quartzSchedulerTables` for misfired triggers; verify GDOOP connectivity; review replay configuration and split parameters; check `loggingStack` for errors

### GDPR report generation failing
- **Symptoms**: `POST /gdpr/` returns error; GDPR report not generated
- **Cause**: Bigtable/HBase connectivity failure; GCP credentials invalid or expired
- **Resolution**: Verify `bigtableRealtimeStore` connectivity; check GCP service account credentials; review `loggingStack` for HBase connection errors

### High MySQL connection pool exhaustion
- **Symptoms**: API endpoints timing out; health check reports MySQL unhealthy
- **Cause**: Too many open JDBI connections; long-running Quartz jobs holding connections
- **Resolution**: Review JDBI connection pool configuration; check for long-running queries in MySQL; consider increasing pool size or optimising slow queries

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — all Janus metadata management and replay operations unavailable | Immediate | dnd-ingestion (aabdulwakeel) |
| P2 | Degraded — alert emails not delivering or replay jobs stalled | 30 min | dnd-ingestion (aabdulwakeel) |
| P3 | Minor impact — GDPR reports or analytics metrics unavailable | Next business day | dnd-ingestion |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumJanusMetadataMySql` | Dropwizard MySQL healthcheck on `/healthcheck` | No fallback — service degrades completely without MySQL |
| `elasticSearch` | Query a known index; check HTTP response | Alert evaluation and metrics API fail gracefully with error responses |
| `bigtableRealtimeStore` | HBase connection ping | GDPR report generation fails; other API groups unaffected |
| `bigQuery` | BigQuery SDK connectivity | Analytical reporting calls fail; other API groups unaffected |
| `smtpRelay` | SMTP connection test | Alert emails not sent; alert outcome still written to MySQL |
