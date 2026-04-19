---
service: "ugc-async"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `http://<host>:9001/healthcheck` | http | Per Kubernetes liveness probe schedule | Not specified in source |
| `/grpn/status` (port 9000) | http | Disabled in `.service.yml` | Not applicable |
| `/var/groupon/jtier/heartbeat.txt` | file (exec) | Kubernetes heartbeat check | Not specified |

> `UgcAsyncHealthCheck` always returns healthy (arithmetic sanity check `2 + 2 == 4`). Real health signal comes from Wavefront metrics and MBus consumer lag, not the health endpoint.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Survey creation rate | counter | Number of surveys created per job execution | Alert on sustained zero rate |
| Survey sending rate | counter | Number of survey notifications dispatched | Alert on sustained zero rate |
| MBus consumer lag | gauge | Queue depth for each enabled MBus consumer | Threshold configured in Wavefront |
| S3 image migration count | counter | Images transferred per S3ImageMoverJob run | Alert on sustained zero |
| JVM memory usage | gauge | Heap and non-heap usage | Alert at 90% of 25Gi limit |
| Quartz job failure | counter | Number of Quartz job execution failures | Alert on any P1 job failure |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| UGC Async main dashboard | Wavefront | https://groupon.wavefront.com/dashboard/ugc-async |
| UGC Async secondary | Wavefront | https://groupon.wavefront.com/u/0hWWzdM5NW?t=groupon |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| PagerDuty service P057HSW | Configured alert conditions fire | P1/P2 | Page on-call UGC engineer; check Wavefront dashboards |
| Slack alert | ugc-alerts@groupon.com | P2/P3 | Review dashboard, check Kubernetes pod status |

Slack channel: `ugc` (ID in `.service.yml`)

## Common Operations

### Restart Service

1. Identify the failing pod: `kubectl get pods -n ugc-async-production`
2. Delete the pod to trigger a rolling restart: `kubectl delete pod <pod-name> -n ugc-async-production`
3. Kubernetes will reschedule the pod automatically using the existing deployment spec
4. Verify new pod reaches `Running` state and health check passes on port 9001
5. Check Wavefront dashboard to confirm metric emission resumes

### Scale Up / Down

1. Patch the HPA: `kubectl patch hpa ugc-async-worker -n ugc-async-production -p '{"spec":{"minReplicas":<N>}}'`
2. Alternatively, update `.meta/deployment/cloud/components/worker/production-us-central1.yml` and redeploy
3. HPA target utilization is 50% CPU; production min 2 / max 3 replicas (increase max before traffic surge)

### Database Operations

- **Schema migrations**: Managed by `jtier-migrations` and run at service startup; ensure new pod starts successfully before decommissioning old pods
- **Quartz metadata**: Quartz tables are stored in `continuumUgcPostgresDb`; do not manually modify Quartz tables while jobs are running
- **Redis checkpoint reset**: To reprocess Goods survey creation from an earlier timestamp, update the `berlinGoodsRedemptionImport` key in Redis: `SET berlinGoodsRedemptionImport <epoch-millis>`
- **Duplicate survey cleanup**: `DuplicateSurveyRemovalJob` runs on a Quartz schedule; manual trigger not supported (restart pod to force Quartz re-evaluation)

## Troubleshooting

### Surveys Not Being Created

- **Symptoms**: Survey creation metrics flat; no new surveys in `surveys` table
- **Cause**: MBus consumer disabled (config flag false), Quartz job not scheduled, Teradata connection failure, or eligibility checks filtering all candidates
- **Resolution**: Verify `MessageConsumerConfig` flags in active YAML; check Quartz trigger state in Postgres; check Teradata connectivity; review Steno logs for eligibility rejection reasons

### Survey Notifications Not Being Sent

- **Symptoms**: Surveys in `pending` status not transitioning; dispatch records not being written
- **Cause**: `SurveySendingJob` eligibility checkers rejecting candidates (opted-out users, blacklisted merchants, wait time not elapsed, notification already sent, missing deal title/image)
- **Resolution**: Query `dispatch_records` for outcome field; check Rocketman/CRM service availability; review `SurveySendingEnabledConfig` and `SurveySendingLocalesConfig`

### S3 Image Migration Stalled

- **Symptoms**: Images accumulating in S3 bucket; no new image records in Postgres
- **Cause**: AWS S3 connectivity failure, Image Service returning 5xx errors, rate limit (100 calls/minute throttle in `S3ImageMoverHelper`)
- **Resolution**: Check AWS credentials and S3 bucket access; verify Image Service health; review `S3ImageMoverJob` Quartz schedule; check Steno logs for `S3ImageMoverJob` event

### MBus Consumer Lag Growing

- **Symptoms**: Wavefront shows increasing queue depth for a consumer topic
- **Cause**: Processing bottleneck in message handler (slow downstream calls, DB contention), or pod restart disrupting consumer connection
- **Resolution**: Check downstream dependency health (Postgres, Redis, external REST services); consider scaling up replicas if CPU-bound; review thread pool utilisation in Steno logs

### High Memory Usage / OOM

- **Symptoms**: Pod OOM-killed; Kubernetes reports OOMKilled exit code
- **Cause**: Quartz job loading large result sets from Teradata or Postgres without pagination; or MBus consumer backlog processing large batches
- **Resolution**: Verify production memory limit is 25Gi; check if `updatedGoodsSurveyCreationQuery` flag is active (reduces Teradata result set size); reduce batch sizes if configurable; scale to more replicas to distribute load

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no surveys created or sent | Immediate | PagerDuty P057HSW; ugc-alerts@groupon.com |
| P2 | Degraded — specific consumer or job failing | 30 min | UGC Slack channel; ugc-dev@groupon.com |
| P3 | Minor impact — non-critical job delayed | Next business day | ugc-dev@groupon.com |

Owner's manual: https://github.groupondev.com/UserGeneratedContent/ugc-async/wiki/Owner's-manual
Runbook (Confluence): https://confluence.groupondev.com/display/UGC/UGC+Jtier+Runbook

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumUgcPostgresDb` | JDBI connection validation at startup; query failures logged | No fallback; job execution halts on DB errors |
| `continuumUgcRedisCache` | Jedis connection pool validation | Job coordination falls back to uncoordinated execution (risk of concurrent Quartz runs) |
| `mbusPlatform_9b1a` | MBus client heartbeat | Quartz-scheduled jobs continue operating independently |
| `ugcTeradataWarehouse_6b9d` | JDBC connection at job start | Job skips execution until connectivity restored; Redis checkpoint not advanced |
| AWS S3 | SDK exception handling in `S3ImageMoverHelper` | Migration job skips failing objects; retried on next scheduled run |
| Rocketman / CRM | HTTP response code in `SurveySendingProcessor` | Dispatch record written with error outcome; survey not re-queued automatically |
