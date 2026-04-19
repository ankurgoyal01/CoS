---
service: "emailsearch-dataloader"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/healthcheck` (port 9000) | http | 30s | Not specified (Kubernetes default) |

- **Readiness probe**: `/grpn/healthcheck` on port 9000, initial delay 30s, period 30s
- **Liveness probe**: `/grpn/healthcheck` on port 9000, initial delay 30s, period 30s

## Monitoring

### Metrics

The service emits custom metrics to Wavefront via the `wavefront_api` Retrofit client. Key operational counters and timers are instrumented in the Quartz job layer.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `custom.decision.start-count` | counter | Number of campaign decision tasks started per run | Not documented |
| `custom.decision.fail-count` | counter | Number of failed campaign decision tasks | Alert on sustained elevation |
| `custom.decision.no-decision-count` | counter | Number of campaigns where no treatment met rollout criteria | Informational |
| `custom.decision.missing-cp-count` | counter | Campaigns where Campaign Performance data was unavailable | Alert on elevation |
| `custom.decision.missing-im-count` | counter | Campaigns where Inbox Management data was unavailable (falls back to default threshold) | Informational |
| `custom.treatment.roll-out-count` | counter | Number of winning treatment rollouts executed | Informational |
| `custom.control.roll-out-count` | counter | Number of control rollouts executed (treatment did not win) | Informational |
| `custom.decision.roll-out-delay` | timer | Milliseconds between decision and exploit send time | Alert if consistently positive (late rollouts) |
| `custom.evaluation.start-count` | counter | Per-campaign evaluation starts | Informational |
| `custom.evaluation.fail-count` | counter | Per-campaign evaluation failures | Alert on elevation |
| `custom.evaluation.success-count` | counter | Successful treatment significance evaluations | Informational |
| `custom.evaluation.treatment-fail-count` | counter | Individual treatment evaluation failures | Alert on sustained elevation |
| `custom.engage-upload-job.process-time` | timer | Total wall-clock time for EngageUpload job | Alert on threshold |
| `custom.engage-upload-job.fail-count` | counter | EngageUpload job failures | Alert on any failure |
| `custom.engage-upload-job-campaign.count` | counter | Number of campaigns processed per EngageUpload run | Informational |
| Quartz job failure metrics (per job class) | counter | `failedJobCount` tracked per job type | Alert on elevation |
| Quartz job timer metrics (per job class) | timer | Wall-clock time per job execution | Alert on threshold |

### Dashboards

> Operational details managed externally. Check Wavefront for dashboards tagged to `emailsearch_dataloader`.

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High `custom.decision.fail-count` | Sustained increase | warning | Check Campaign Performance Service and Inbox Management Service connectivity; review logs for `Decision.execute` events |
| High `custom.decision.missing-cp-count` | More than expected | warning | Verify Campaign Performance Service health; check Retrofit client config and network |
| Late rollouts (`custom.decision.roll-out-delay` > 0) | Consistently positive delay | warning | DecisionJob may be running slower than campaign schedule; check job execution time and thread pool settings |
| EngageUpload failures (`custom.engage-upload-job.fail-count`) | Any failure | warning | Check Phrasee Service and Campaign Management Service connectivity |
| Health check failure | `/grpn/healthcheck` returns non-200 | critical | Pod is unhealthy; check container logs, database connectivity, and Kafka consumer status |

## Common Operations

### Restart Service

Operational procedures to be defined by service owner. For Kubernetes-managed deployments:
1. Identify the deployment in the appropriate namespace (e.g., `emailsearch-staging`, `emailsearch-production`)
2. Issue a rolling restart: `kubectl rollout restart deployment/<deployment-name> -n <namespace>`
3. Monitor pod readiness via `/grpn/healthcheck` probes (30s initial delay)
4. Confirm no increase in `custom.decision.fail-count` after restart

### Scale Up / Down

Scaling is primarily managed by the Raptor deploy bot and deployment YAML. For production us-central1 and us-west-1, replicas are fixed at 12. Manual scaling:
```sh
kubectl scale deployment/<deployment-name> -n <namespace> --replicas=<count>
```
Note: VPA is enabled on GCP environments; manual resource changes may be overridden.

### Database Operations

- **Schema migrations**: Run automatically by `jtier-migrations` on service startup for the Email Search Postgres (`postgresED`) and Decision Engine Postgres (`postgresDE`)
- **Quartz schema**: Managed by `jtier-quartz-postgres-migrations`; runs on startup
- **Hive table creation**: `MetricsExportJob` creates both temp and external tables if they do not exist (`CREATE TABLE IF NOT EXISTS`); no separate migration required
- **Backfill**: To re-export Hive metrics, truncate the Hive table and restart the service to allow `MetricsExportJob` to re-read from Postgres; coordinate with data engineering team

## Troubleshooting

### Decision Job Not Rolling Out Treatments

- **Symptoms**: `custom.decision.no-decision-count` elevated; no rollouts observed in Campaign Management Service; campaigns remain in EXPLORE state
- **Cause**: Statistical significance threshold not reached; `DecisionJob` is running in `dryRun=true` mode; or `autoRollout=false` on campaigns
- **Resolution**: Verify `DecisionConfig.dryRun` is `false` in runtime YAML; check significance threshold config in `DecisionConfig.decisionSettings`; confirm campaigns have `autoRollout: true`

### Campaign Performance Data Missing

- **Symptoms**: `custom.decision.missing-cp-count` elevated; decision tasks throw `IllegalStateException: Campaign Performance not retrieved`
- **Cause**: Campaign Performance Service is unavailable or returning errors
- **Resolution**: Check Campaign Performance Service health endpoint; verify `campaignPerformanceServiceClient` base URL and timeouts in runtime YAML; check network connectivity from pod

### Kafka Events Not Being Consumed

- **Symptoms**: Campaign performance data not updating; `emailSearchService` state stale
- **Cause**: Kafka connection issue (TLS cert expiry, wrong endpoint, broker unavailability)
- **Resolution**: Verify `KAFKA_ENDPOINT` env var; check TLS cert secret `emailsearch-dataloader-*-tls-identity` is valid and mounted; re-run `kafka-tls-v2.sh` logic by restarting the pod

### Hive Export Failing

- **Symptoms**: `MetricsExportJob` logs errors; `campaign_stat_sig_metrics` Hive table not updated
- **Cause**: Hive warehouse unavailable; JDBC URL or credentials incorrect; Hive schema mismatch
- **Resolution**: Check Hive JDBC URL in runtime YAML (`hive.jdbcUrl`); verify Hive cluster health; check for schema drift in `campaign_stat_sig_metrics` table definition

### OOM / Pod Killed

- **Symptoms**: Pods restarting; OOMKilled in pod events
- **Cause**: JVM heap or JVM metaspace exceeding limits; `MALLOC_ARENA_MAX` not set correctly
- **Resolution**: Verify `MALLOC_ARENA_MAX=4` is set; check `MAX_RAM_PERCENTAGE=80.0`; consider increasing memory limit (currently 6Gi) via deployment YAML; review thread pool sizing in `DecisionJob` and `EngageUploadJob` ForkJoinPool settings

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no campaign decisions being made; campaigns not rolling out | Immediate | Rocketman team (Owner's Manual: see `OWNERS_MANUAL.MD`) |
| P2 | Degraded — decisions running but with elevated failure rate or missing data | 30 min | Rocketman team |
| P3 | Minor impact — Hive export delayed; notification failures; ELK query failures | Next business day | Rocketman team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Campaign Performance Service | Query service health endpoint; check `custom.decision.missing-cp-count` | No fallback — decision task fails without CP data |
| Inbox Management Services | Check `custom.decision.missing-im-count` counter | Falls back to default 95% significance threshold |
| Campaign Management Service | Check if rollouts are being issued; verify service health endpoint | No fallback — rollout command cannot be sent |
| Kafka Cluster | Check consumer lag and pod logs for connection errors | No fallback — event consumption halts |
| Hive Warehouse | Check `MetricsExportJob` log entries | No fallback — export delayed until next run |
| PostgreSQL (ED, DE) | Check `/grpn/healthcheck` and JTier DaaS health indicators | Service cannot start without DB connectivity |
