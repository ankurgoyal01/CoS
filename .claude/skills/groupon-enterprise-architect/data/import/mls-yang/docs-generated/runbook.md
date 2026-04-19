---
service: "mls-yang"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/status` (port 8080) | HTTP | Kubernetes liveness/readiness probe cadence | Default jtier |
| Heartbeat file (`./heartbeat.txt`) | File-based (jtier health) | Configured via `jtier.health.heartbeatCheckIntervalSeconds` | N/A |
| Quartz admin (`/quartz`) | HTTP (admin port 8081) | On-demand | N/A |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Kafka consumer group lag (`mls_yang-prod-snc1`) | gauge | Message backlog per topic partition | Operator-defined; alert on sustained lag growth |
| Quartz job execution count | counter | Number of batch jobs fired per scheduler cycle | Alert on zero executions over expected window |
| Quartz job misfire count | counter | Jobs that missed their scheduled fire time (misfire threshold 300s) | Alert on repeated misfires |
| Deal metrics persistence time | histogram | Time (ms) per `DealMetricsService.update` call (logged via steno) | Alert if persistenceTimeInMillis exceeds SLA |
| Database connection pool utilisation | gauge | Pool saturation per named pool (`yang-rw`, `mls_lifecycle-rw`, `history-rw`, `mls_dealindex-ro`) | Alert at >80% utilisation |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| MLS Production (snc1) | Wavefront | https://groupon.wavefront.com/dashboard/snc1-mls-production |
| MLS Staging (snc1) | Wavefront | https://groupon.wavefront.com/dashboard/snc1-mls-staging |
| MLS Kafka (sac1/snc1) | Wavefront | https://groupon.wavefront.com/dashboard/sac1_snc1-mls-kafka |
| MLS Yang SMA | Wavefront | https://groupon.wavefront.com/dashboards/mls-yang--sma |
| Cloud resource monitoring | Wavefront | https://groupon.wavefront.com/dashboards/Conveyor-Cloud-Customer-Metrics-v2 |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Kafka consumer lag spike | Consumer group `mls_yang-prod-snc1` lag exceeds threshold on any topic | critical | Check consumer thread health; restart pods if consumers are stuck |
| Batch job failure | Quartz job reports exception; no feedback command published | warning | Check pod logs for job-specific exception; re-trigger job manually if needed |
| Database connection pool exhausted | Pool wait timeout for yangDb, rinDb, historyDb, or dealIndexDb | critical | Check for long-running queries; scale pod count or increase pool size |
| Pod OOM kill | Container killed by Kubernetes OOM | critical | Review `MALLOC_ARENA_MAX` setting; check for JVM heap leaks; increase memory limit |

- **PagerDuty**: https://groupon.pagerduty.com/services/PV2ZOZL
- **Alert email**: bmx-alert@groupon.com
- **Slack channel**: `#global-merchant-exper`

## Common Operations

### Restart Service

1. Identify the affected Kubernetes namespace (`mls-yang-production` or `mls-yang-staging`).
2. Perform a rolling restart: `kubectl rollout restart deployment/mls-yang -n mls-yang-production`.
3. Monitor pod startup via `kubectl rollout status deployment/mls-yang -n mls-yang-production`.
4. Confirm Kafka consumer group reconnects by checking consumer group lag on the Wavefront Kafka dashboard.
5. Confirm Quartz scheduler re-acquires cluster lock by checking `quartz.qrtz_scheduler_state` table in `yangDb`.

### Scale Up / Down

Scaling is controlled via `.meta/deployment/cloud/components/worker/production-us-central1.yml`. Adjust `minReplicas` and `maxReplicas`, then re-deploy via the Raptor pipeline. Because Quartz is clustered, adding more pods increases scheduler parallelism — verify that additional nodes do not cause job duplication for single-instance jobs.

### Database Operations

- **Migrations**: Schema migrations are defined in the `mls-db-schemas` project (separate repo). Apply via the standard DaaS migration tooling.
- **Partition management**: The `PersistencePartitionsManagerJob` runs weekly (Mondays 09:00 UTC) to create new partitions in the `ext` schema of `yangDb`. To trigger manually: use the Quartz admin endpoint (`/quartz`) or directly insert a trigger via the Quartz tables.
- **CLO retention**: `CloRetentionManagerJob` runs daily at 05:00 UTC to purge old CLO records. To run manually, trigger the job via Quartz admin.
- **Batch job manual trigger**: Connect to the Quartz admin UI at `http://<host>:8081/quartz` and fire the desired job trigger manually, or insert a trigger record into `quartz.qrtz_triggers`.

### Re-run a Failed Batch Import

1. Identify the failing job name (e.g. `JanusDealSharesImportExecutorJob`) from pod logs.
2. Determine the failed processing date.
3. Use the `MANUAL` import strategy: trigger the job via Quartz admin with `import_strategy=MANUAL` and the target date.
4. Alternatively, the `RETRO_SCHEDULED` strategy with `days_in_past` can be adjusted to re-import historical data.

## Troubleshooting

### Kafka Consumer Not Processing

- **Symptoms**: Consumer group lag growing on Wavefront; no recent writes to yangDb for affected topic
- **Cause**: Consumer thread exception or SSL certificate expiry
- **Resolution**: Check pod logs for exception stack traces; verify SSL certificate validity at `/var/groupon/jtier/kafka.client.keystore.jks`; restart pod if needed

### Batch Import Producing No Metrics

- **Symptoms**: No new rows in `deal_metrics` after expected import window; no feedback command on `jms.queue.mls.batchCommands`
- **Cause**: Hive connection failure, Quartz job misfire, or Deal Catalog API unavailability
- **Resolution**: Verify Hive JDBC connectivity; check Quartz misfire log; confirm Deal Catalog is reachable; re-trigger job manually with `RETRO_SCHEDULED` strategy

### High Database Connection Pool Wait Times

- **Symptoms**: Slow API response times; JDBI timeout exceptions in logs
- **Cause**: Long-running batch queries holding connections; insufficient pool size for concurrent Quartz threads
- **Resolution**: Identify and kill long-running queries in the affected PostgreSQL database; reduce Quartz `threadCount` if batch and API are sharing pool; scale pods

### OOM Pod Kills

- **Symptoms**: Kubernetes evicts pods with OOMKill reason; memory limit (9Gi) exceeded
- **Cause**: JVM heap growth from large Hive result sets; native memory growth from glibc malloc arenas
- **Resolution**: Verify `MALLOC_ARENA_MAX=4` is set; review Hive `batchSize` (currently 10,000 rows); consider reducing Quartz `threadCount`

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | All Kafka consumers stopped; merchant data not being projected | Immediate | Merchant Experience team via PagerDuty (PV2ZOZL) |
| P2 | Single topic consumer degraded; batch imports failing | 30 min | bmx-alert@groupon.com; Slack `#global-merchant-exper` |
| P3 | Individual batch job failure; minor metric staleness | Next business day | merchant-experience-backend@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Kafka | Check consumer group lag via Wavefront Kafka dashboard | No fallback — consumers must be running; restart pods |
| yangDb (PostgreSQL) | `SELECT 1` via DaaS pool validation; check pool stats via JMX | No fallback; service writes fail and consumers error |
| rinDb / historyDb / dealIndexDb | DaaS pool validation on borrow | Specific handlers fail; other topics continue processing |
| Hive (Janus/Cerebro) | `SELECT 1` validation query (`validationQuery: "SELECT 1"`) | Batch import job fails for that run; next scheduled run retries |
| Deal Catalog | HTTP call with retry (6 attempts, 1s delay) | Permalink is skipped for that batch run; metric not persisted for that deal |
| Message Bus | Implicit — `FeedbackCommandEmitter` fails on send | Feedback command lost; downstream job tracking may show job as incomplete |
