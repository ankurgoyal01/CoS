---
service: "raas"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /clusters` (Info Service liveness) | http | > No evidence found | > No evidence found |
| Nagios check plugins (`continuumRaasChecksRunnerService`) | exec | Scheduled per check run | > No evidence found |
| K8s Config Updater reconciliation loop | internal | Continuous polling loop | > No evidence found |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Info Service request metrics | counter/histogram | HTTP request counts and latencies from `continuumRaasInfoService` to `metricsStack` | > No evidence found |
| Monitoring job metrics | gauge | Job run success/failure rates from `continuumRaasMonitoringService` | > No evidence found |
| Check execution metrics | counter | Nagios check pass/fail counts from `continuumRaasChecksRunnerService` | > No evidence found |
| Config updater metrics | counter | Server-set change detections and config map update counts from `continuumRaasConfigUpdaterService` | > No evidence found |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| RaaS Platform | > No evidence found | > No evidence found |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Stale API cache | API Cache Collector has not written new snapshots for an extended period | warning | Verify `continuumRaasApiCachingService` is running; check Redislabs API connectivity and GitHub Secrets bootstrap |
| Monitoring DB sync failure | `continuumRaasMonitoringService_raasMonDbSyncJob` fails to swap tables | critical | Check MySQL/PostgreSQL connectivity; review job logs via `loggingStack` |
| Config map update failure | `continuumRaasConfigUpdaterService` cannot apply Kubernetes config maps | critical | Verify Kubernetes API connectivity and service account permissions |
| Checks runner failure | `continuumRaasChecksRunnerService` check plugins report cluster health issues | warning/critical | Inspect cached rladmin state; correlate with Redislabs Control Plane |

## Common Operations

### Restart Service

1. Identify the failing container: Info Service, API Caching Service, Monitoring Service, Checks Runner, or Config Updater.
2. For Kubernetes-deployed components (`continuumRaasConfigUpdaterService`): use `kubectl rollout restart deployment/<name>` in the appropriate namespace.
3. For daemon-style services: restart the scheduled job or daemon process via the appropriate orchestration mechanism.
4. Verify health by checking `/clusters` endpoint (Info Service) or reviewing `loggingStack` output.

### Scale Up / Down

> Operational procedures to be defined by service owner (raas-team@groupon.com). The K8s Config Updater scales via Kubernetes HPA or manual replica adjustment.

### Database Operations

- **MySQL migrations**: Managed by Rails ActiveRecord migrations in `continuumRaasInfoService`. Run `rails db:migrate` in the appropriate environment.
- **PostgreSQL sync**: The `continuumRaasMonitoringService_raasMonDbSyncJob` uses a temporary table-swap pattern — do not interrupt a running sync job.
- **Cache reset**: Delete files under the `api_cache/` and `raas_info/` directories to force a full re-fetch on the next collection run.

## Troubleshooting

### Stale cluster metadata in Info Service
- **Symptoms**: `/clusters`, `/dbs`, `/nodes`, `/endpoints`, or `/shards` return outdated data; last-modified timestamps are old
- **Cause**: The API Cache Collector (`continuumRaasApiCachingService`) has not run recently, or the Info Updater Job (`continuumRaasInfoService_raasInfoUpdaterJob`) has not executed
- **Resolution**: Check `continuumRaasApiCachingService` logs in `loggingStack`; verify Redislabs API connectivity; manually trigger `/update/run` to force a sync from existing cache

### Kubernetes config maps not updating
- **Symptoms**: Telegraf deployments have outdated ElastiCache endpoint lists; monitoring data collection is incomplete
- **Cause**: `continuumRaasConfigUpdaterService` reconciliation loop is failing or cannot reach the Kubernetes API or AWS ElastiCache API
- **Resolution**: Check `continuumRaasConfigUpdaterService` logs in `loggingStack`; verify AWS IAM permissions for ElastiCache discovery; verify Kubernetes service account has config map write permissions

### Ansible playbook failures during database provisioning
- **Symptoms**: Redis database creation or cloning fails; operator reports playbook errors
- **Cause**: `continuumRaasAnsibleAdminService_raasCreateDbPlaybook` cannot reach the Redislabs API, or `continuumRaasAnsibleAdminService_raasDbSpecPruner` fails to normalize fetched DB specs
- **Resolution**: Verify Redislabs API credentials via GitHub Secrets bootstrap; review pruner output for malformed DB spec payloads

### Monitoring DB sync failures
- **Symptoms**: MySQL or PostgreSQL metadata is not refreshed; monitoring dashboards show stale data
- **Cause**: `continuumRaasMonitoringService_raasMonDbSyncJob` table-swap failed due to database connectivity or schema issues
- **Resolution**: Check database connectivity; verify temporary table state; review sync job logs in `loggingStack`

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | RaaS Info Service completely unavailable; no cluster metadata accessible | Immediate | raas-team@groupon.com |
| P2 | Telemetry collection stopped; metadata is stale but service responds | 30 min | raas-team@groupon.com |
| P3 | Individual check failures or config map update delays | Next business day | raas-team@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumRaasRedislabsApi` | Verify API Cache Collector can authenticate and fetch a cluster payload | Serve last cached snapshot from filesystem |
| `continuumRaasElastiCacheApi` | Verify AWS SDK can list ElastiCache clusters | Config Updater holds last-applied config map state |
| `continuumRaasKubernetesApi` | Check Config Updater logs for API server connectivity | Telegraf deployments remain at last-applied state |
| `continuumRaasMetadataMysql` | Rails Info Service health check; verify DB connection in logs | Info Service returns 5xx; no metadata update possible |
| `continuumRaasMetadataPostgres` | Monitor DB Sync Job logs for PostgreSQL connection errors | MySQL remains authoritative; PostgreSQL mirror is stale |
