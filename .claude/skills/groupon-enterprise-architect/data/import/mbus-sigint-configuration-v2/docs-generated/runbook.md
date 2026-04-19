---
service: "mbus-sigint-configuration-v2"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET http://<host>:8081/healthcheck` | HTTP (Dropwizard admin) | On demand / external probe | Default Dropwizard timeout |
| `GET http://<host>:8080/grpn/status` | HTTP (status endpoint) | External monitoring probe | — |
| DB connectivity check (`mbsc_healthChecks`) | Dropwizard HealthCheck (JDBC ping) | Per health poll | — |
| Heartbeat file (`jtier.health.heartbeatPath: ./heartbeat.txt`) | File existence check | JTier managed | — |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| JVM heap usage | gauge | Memory usage relative to 4Gi limit | Operational threshold to be defined by service owner |
| HTTP request rate / response time | histogram | Tracked via Dropwizard metrics flushed to Telegraf at `localhost:8186` every 60s | Operational threshold to be defined by service owner |
| Quartz job execution count / failure | counter | Tracks job runs and misfire/failure events | Operational threshold to be defined by service owner |
| PostgreSQL connection pool | gauge | Active vs. max pool connections | Operational threshold to be defined by service owner |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| MBus CheckMk v1 | CheckMk | `https://checkmk-lvl3.groupondev.com/ber1_prod/check_mk/` (v1 hosts; mbus-config-sigint[1-2]) |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Service down | Health endpoint unresponsive | P1 | Page mbus@groupon.pagerduty.com (PagerDuty: PGG3KB5); escalate to GMB team |
| Deployment job failure | `DeployConfigJob` sets request status to `FAILED_TEST` or `FAILED_PROD` | P2 | Check Ansible host reachability; inspect Quartz job log; retry via `POST /admin/deploy/{clusterId}/{env}` |
| Jira integration failure | `JiraCreateJob` or transition job fails repeatedly | P3 | Check Jira API token expiry (`JIRA_API_PASSWORD`); verify Jira API URL reachability |
| PostgreSQL unavailable | DB health check fails | P1 | Check DaaS status for `mbus-sigint-config-rw-na-*-db`; restart service pod after DB recovery |

## Common Operations

### Restart Service

1. Identify the Kubernetes namespace: `mbus-sigint-config-<environment>`
2. Rolling restart: `kubectl rollout restart deployment/mbus-sigint-config -n mbus-sigint-config-<environment>`
3. Verify health: `kubectl rollout status deployment/mbus-sigint-config -n mbus-sigint-config-<environment>`
4. Confirm via `GET http://<pod-ip>:8081/healthcheck`

### Scale Up / Down

1. Edit Helm values or update `minReplicas`/`maxReplicas` in `.meta/deployment/cloud/components/app/<env>.yml`
2. Re-deploy via DeployBot or `kubectl scale deployment/mbus-sigint-config --replicas=<N> -n mbus-sigint-config-<environment>`
3. HPA (target utilization 100%) will manage replicas within configured min/max bounds

### Database Operations

- **Schema migrations**: Flyway runs automatically at startup. Monitor startup logs for migration errors.
- **Quartz schema**: Managed by `jtier-quartz-postgres-migrations`; runs on first startup.
- **Manual DB connection**: Use `PGHOST`, `PGDATABASE`, `PGPORT`, `PGUSER`, `PGPASSWORD` from `.envrc` for local development.
- **Production DB host**: `mbus-sigint-config-rw-na-production-db.gds.prod.gcp.groupondev.com:5432`, database `mbus_sigint_cnf_prod`

### Trigger On-Demand Deployment

To manually trigger an Artemis configuration deployment outside of the Quartz schedule:
1. Call `POST /admin/deploy/{clusterId}/{environmentType}` with `admin` role header (`x-grpn-username`)
2. Monitor response and check Quartz job execution log
3. Verify deployment outcome in the request/config status

### Refresh Deploy Schedules

If Quartz triggers are out of sync with the database schedule:
1. Call `PUT /deploy-schedule/refreshAll` with `admin` role header
2. All Quartz jobs are re-scheduled from the current `deploy_schedule` table data

## Troubleshooting

### Change request stuck in DEPLOYING_TEST or DEPLOYING_PROD

- **Symptoms**: Request status does not advance after deployment trigger; no further state transition
- **Cause**: Ansible SSH command timed out or returned an error; Quartz job may have lost its trigger
- **Resolution**: Check Ansible host connectivity; inspect `DeployConfigJob` logs; retry via `POST /admin/deploy/{clusterId}/{environmentType}`; if Quartz triggers are missing, call `PUT /deploy-schedule/refreshAll`

### Jira ticket not created for change request

- **Symptoms**: Change request exists but `jiraTicket` field is empty after several minutes
- **Cause**: `JiraCreateJob` failed or was not triggered; Jira API token may be expired
- **Resolution**: Check Jira API token at `JIRA_API_PASSWORD`; verify Jira API URL is reachable; inspect Quartz `JiraJobScheduler` logs; tokens managed at `https://id.atlassian.com/manage-profile/security/api-tokens` for `mbus-jira@groupon.com`

### Service OOM killed

- **Symptoms**: Pod restarts with OOM; kubectl describe shows memory exceeded 4Gi limit
- **Cause**: Memory arena growth under load; `MALLOC_ARENA_MAX` not effective enough
- **Resolution**: Increase memory limit in Helm values; verify `MALLOC_ARENA_MAX: 4` is applied; check for runaway Quartz threads

### PostgreSQL connection failures at startup

- **Symptoms**: Service fails to start; logs show JDBC connection refused or timeout
- **Cause**: DaaS database not reachable; incorrect credentials; Flyway migration blocked
- **Resolution**: Verify database host reachability; check `DAAS_APP_USERNAME`/`DAAS_APP_PASSWORD` k8s secrets; check DaaS console for cluster health

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — MBus configuration unreadable by Artemis brokers | Immediate | PagerDuty mbus@groupon.pagerduty.com (PGG3KB5); Slack #global-message-bus (CF7HYM0KS) |
| P2 | Degraded — deployments failing or Jira integration broken | 30 min | GMB team (messagebus-team@groupon.com); Slack #mbus-deployments (GE052NNDC) |
| P3 | Minor impact — non-critical job failures, UI unavailable | Next business day | GMB team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| PostgreSQL (DaaS) | Dropwizard DB health check on admin port 8081 | No fallback — service is fully database-dependent |
| Jira API | No built-in health check — failures surfaced via Quartz job errors | Change requests continue without Jira linkage; `jiraTicket` field remains empty |
| ProdCat API | No built-in health check | Production promotion is blocked until ProdCat is reachable |
| Ansible (SSH) | No built-in health check — deployment commands log success/failure | `DeployConfigJob` marks request as `FAILED_*`; admin can retry manually |
