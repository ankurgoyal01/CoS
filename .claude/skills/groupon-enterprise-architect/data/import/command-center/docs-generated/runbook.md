---
service: "command-center"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Rails HTTP health endpoint (path not enumerated) | http | Not enumerated | Not enumerated |
| MySQL connectivity (ActiveRecord connection check) | db | Not enumerated | Not enumerated |
| Delayed Job worker process (process liveness) | exec | Not enumerated | Not enumerated |

> Operational procedures to be defined by service owner. Specific health endpoint paths, intervals, and timeouts are not enumerated in the architecture inventory.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Delayed Job queue depth | gauge | Number of jobs queued but not yet started in `continuumCommandCenterMysql` | To be defined by service owner |
| Delayed Job failed count | counter | Number of jobs that have exceeded retry attempts | To be defined by service owner |
| Tool execution latency | histogram | Time from job scheduling to job completion | To be defined by service owner |
| Downstream API error rate | counter | HTTP errors calling Deal Management API, Orders Service, Voucher Inventory Service, M3 Places Service, and Salesforce | To be defined by service owner |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Command Center Operations | Not enumerated | Not enumerated |

> Operational procedures to be defined by service owner.

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Delayed Job queue spike | Queue depth exceeds threshold | warning | Investigate worker process health; scale worker replicas if needed |
| Delayed Job failed jobs | Failed job count increases | warning | Inspect failed job records in `continuumCommandCenterMysql`; review error logs |
| Web process down | HTTP health check fails | critical | Restart web pod/process; check Rails logs |
| Worker process down | Worker heartbeat absent | critical | Restart worker pod/process; verify Delayed Job table connectivity |
| Downstream API degraded | Error rate from Deal Management API, Orders Service, or other dependencies exceeds threshold | warning | Check dependency health; notify dependency team |

## Common Operations

### Restart Service

1. Identify the web (`continuumCommandCenterWeb`) and/or worker (`continuumCommandCenterWorker`) deployment in the cluster.
2. Perform a rolling restart of the web deployment to apply config changes without downtime.
3. Restart worker deployment; in-progress Delayed Job records will be re-queued on next poll cycle (locked jobs will be released after lock timeout).
4. Verify health check passes after restart.

> Operational procedures to be defined by service owner. Specific kubectl commands or deployment tooling details are not enumerated in the architecture inventory.

### Scale Up / Down

1. Adjust worker replica count or `DELAYED_JOB_WORKERS` environment variable to increase or decrease parallel job execution capacity.
2. Monitor queue depth metric after scaling to verify throughput improves.
3. Scale web replicas independently based on operator traffic load.

> Operational procedures to be defined by service owner.

### Database Operations

- **Migrations**: Rails database migrations are applied via `bundle exec rails db:migrate` against `continuumCommandCenterMysql`. Run migrations before deploying new application versions.
- **Delayed Job cleanup**: Completed and failed Delayed Job records accumulate in the `delayed_jobs` table. Periodic cleanup jobs or manual deletion of old records prevents unbounded table growth.
- **Report artifact references**: Stale report artifact references in the database may be cleaned up after confirming S3 artifacts are no longer needed.

## Troubleshooting

### Jobs Not Processing

- **Symptoms**: Delayed Job queue depth grows; no jobs completing; worker metrics flat.
- **Cause**: Worker process (`continuumCommandCenterWorker`) is down, unhealthy, or unable to connect to `continuumCommandCenterMysql`.
- **Resolution**: Check worker process health. Verify `continuumCommandCenterMysql` connectivity. Restart worker if needed. Inspect `delayed_jobs` table for locked records with stale lock timestamps — release locks manually if workers have crashed.

### Tool Workflow Failures

- **Symptoms**: Tool executions fail immediately or jobs complete with error status; users receive failure notification emails via `cmdCenter_webMailer`.
- **Cause**: Downstream API (`continuumDealManagementApi`, `continuumOrdersService`, `continuumVoucherInventoryService`, `continuumM3PlacesService`, or `salesForce`) is unavailable or returning errors.
- **Resolution**: Check failed job records in `continuumCommandCenterMysql` for error messages. Verify downstream dependency health. Re-queue failed jobs after dependency is restored.

### S3 Artifact Retrieval Failures

- **Symptoms**: Report downloads fail; artifact references exist in database but files are inaccessible.
- **Cause**: `cloudPlatform` (S3) connectivity issue, expired credentials, or missing bucket permissions.
- **Resolution**: Verify S3 credentials and bucket configuration. Check `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` environment variables. Confirm bucket policy allows the Command Center service role.

### Message Bus Event Consumption Lag

- **Symptoms**: Erasure or support workflows are delayed; MBus consumer offset lagging.
- **Cause**: `continuumCommandCenterWorker` is not consuming events from `messageBus` at expected rate, or worker is down.
- **Resolution**: Check worker process health. Verify message bus connectivity. Restart worker if needed.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — operations team unable to use any tools | Immediate | Continuum Platform Team |
| P2 | Degraded — some tools failing or job processing severely delayed | 30 min | Continuum Platform Team |
| P3 | Minor impact — isolated tool failure or slow job processing | Next business day | Continuum Platform Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumCommandCenterMysql` | ActiveRecord connection check; query latency | No fallback — both web and worker are fully dependent on MySQL |
| `continuumDealManagementApi` | HTTP GET health endpoint (path not enumerated) | Delayed Job will retry failed worker jobs |
| `continuumDealCatalogService` | HTTP GET health endpoint (path not enumerated) | Tool workflows requiring deal metadata will fail to schedule |
| `continuumVoucherInventoryService` | HTTP GET health endpoint (path not enumerated) | Voucher workflows will fail; worker will retry |
| `continuumOrdersService` | HTTP GET health endpoint (path not enumerated) | Order support workflows will fail; worker will retry |
| `continuumM3PlacesService` | HTTP GET health endpoint (path not enumerated) | Place management tools will be unavailable |
| `salesForce` | REST API availability | Salesforce-dependent tools will fail; worker will retry async calls |
| `messageBus` | MBus connection health | Event publishing and consumption will be unavailable |
| `cloudPlatform` (S3) | S3 connectivity check | Report artifact storage and retrieval will fail |
