---
service: "wh-users-api"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/grpn/status` (port 8080) | http | (Kubernetes default) | (Kubernetes default) |
| Dropwizard admin port 8081 | http | (Kubernetes default) | (Kubernetes default) |

> Note: Database connectivity health checks are intentionally disabled. A database outage causes the service to return HTTP 5xx responses rather than failing health probes (which would cause pod restarts). This is a deliberate operational design choice in `WhUsersApiConfiguration`.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP 5xx error rate (US) | counter | Overall 5xx errors in production US region | Alert fires to wolfhound-alerts@groupon.com |
| HTTP 5xx error rate (EMEA) | counter | Overall 5xx errors in production EMEA region | Alert fires to wolfhound-alerts@groupon.com |
| Pod restarts (US) | counter | Number of pod restarts in production US region | Alert fires to wolfhound-alerts@groupon.com |
| Pod restarts (EMEA) | counter | Number of pod restarts in production EMEA region | Alert fires to wolfhound-alerts@groupon.com |

Metrics are collected via Codahale MetricRegistry and forwarded to Telegraf / `tsd_aggregator`.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| WH Users API (Production) | Grafana | https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/d/de9zd3dgveubkc/wh-users-api?orgId=1 |
| Conveyor Cloud Customer Metrics | Grafana | https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/d/fe7dii805648wc/conveyor-cloud-customer-metrics |
| WH Users API (Staging) | Grafana | https://stable-grafana.us-central1.logging.stable.gcp.groupondev.com/d/de9zd3dgveubkc/wh-users-api?orgId=1 |
| Kibana Logs (Production NA) | Kibana | https://prod-kibana-unified.us-central1.logging.prod.gcp.groupondev.com/app/dashboards#/view/dc462810-0584-11ec-a801-11a7c12df8e3 |
| Kibana Logs (Production EMEA GCP) | Kibana | https://prod-kibana-unified-eu.logging.prod.gcp.groupondev.com/app/r/s/MElCW |
| Kibana Logs (Staging NA) | Kibana | https://stable-kibana-unified.us-central1.logging.stable.gcp.groupondev.com/app/r/s/pZA2k |
| Hybrid Boundary (Production US) | Hybrid Boundary UI | https://hybrid-boundary-ui.prod.us-central1.gcp.groupondev.com/services/wh-users-api/wh-users-api |
| Hybrid Boundary (Production EMEA) | Hybrid Boundary UI | https://hybrid-boundary-ui.prod.eu-west-1.aws.groupondev.com/services/wh-users-api/wh-users-api |
| GDS Database Instances | GDS Catalog | https://pages.github.groupondev.com/gds/catalog/ |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| WH Users API - Overall 5xx Errors [Production][US] | HTTP 5xx rate exceeds threshold | critical | Investigate via Kibana 5xx logs; use `transactionId` to trace individual errors |
| WH Users API - Overall 5xx Errors [Production][EMEA] | HTTP 5xx rate exceeds threshold | critical | Investigate via Kibana EMEA logs |
| WH Users API - Pod Restarts [Production][US] | Pod restart count exceeds threshold | critical | Check pod logs via `kubectl logs pod/<pod_name> -c main` |
| WH Users API - Pod Restarts [Production][EMEA] | Pod restart count exceeds threshold | critical | Check pod logs; verify OOM or startup failure |

Alert notifications go to: `wolfhound-alerts@groupon.com`
PagerDuty service: https://groupon.pagerduty.com/services/P13VDUS

## Common Operations

### Restart Service

wh-users-api runs on Kubernetes. To restart pods:

```bash
# Authenticate
kubectl cloud-elevator auth browser

# Switch to the affected cluster context
kubectl config use-context wh-users-api-production-us-central1  # or eu-west-1 / europe-west1

# Switch namespace
kubens wh-users-api-production

# Delete a specific pod (Kubernetes will reschedule it)
kubectl get pods -o wide
kubectl delete pod <pod_name>

# Or delete the deployment to recreate all pods
kubectl get deployments
kubectl delete deployment <deployment_name>
```

For legacy on-host Runit-managed instances (non-Kubernetes):
```bash
sudo sv start jtier
sudo sv stop jtier
sudo sv status jtier
```

### Scale Up / Down

Adjust `minReplicas`/`maxReplicas` in the environment-specific deployment config under `.meta/deployment/cloud/components/api/<env>-<region>.yml` and redeploy. Production currently runs min 1 / max 3 replicas per region.

### Database Operations

- Database credentials are stored in the `wh-users-api-secrets` private repository.
- Database migrations run automatically via Flyway on service startup using the DBA user.
- To connect to the DaaS PostgreSQL database, set up an SSH tunnel (see `docs/runbooks/How_to_connect_to_database.md`).
- For database debugging commands, see the PostgreSQL commands runbook at `docs/runbooks/commands/postgres.md`.
- For database issues, contact the GDS team in Slack: `#gds-daas`.

## Troubleshooting

### High 5xx Error Rate

- **Symptoms**: Grafana alert fires; elevated 5xx count in Kibana logs
- **Cause**: Database unavailability, memory pressure, or application bugs
- **Resolution**:
  1. Open Kibana (production NA or EMEA) and filter for 5xx responses on `/wh/v2/*`
  2. Use the `transactionId` field in logs to trace a specific failing request
  3. Check database connectivity via the GDS Instances dashboard
  4. If database is healthy, check pod logs for application exceptions

### Pod Restarts

- **Symptoms**: Grafana pod restart alert fires; pods cycling
- **Cause**: OOM kill (memory limit exceeded), application startup failure, or liveness probe failure
- **Resolution**:
  1. `kubectl get pods -o wide` — identify the restarting pod
  2. `kubectl get pod <pod_name> --output=yaml` — review `lastState` for exit code and reason
  3. `kubectl logs <pod_name> -p -c main` — review logs from the previous container instance
  4. If OOM: increase `memory.main.limit` in the relevant deployment config (currently 2.5Gi)

### Memory Issue

- **Symptoms**: Container OOM-killed; pod restarts with exit code 137
- **Cause**: JVM heap or native memory exceeds limit
- **Resolution**: Increase `memory.main.limit` in `.meta/deployment/cloud/components/api/common.yml` or per-environment override; consider tuning `MALLOC_ARENA_MAX`

### CPU Issue

- **Symptoms**: High CPU throttling; slow request latency
- **Resolution**: Increase `cpus.main.request` in the relevant deployment config

### Database Issue

- **Symptoms**: HTTP 500 responses; database connection errors in logs
- **Resolution**: Check the PostgreSQL commands runbook; contact `#gds-daas` in Slack

### Disk Space Issue

- **Symptoms**: Pod filesystem full; log write failures
- **Resolution**: `sudo du -a / | sort -n -r | head -n 10` on the affected host; check for large files in `/tmp`; contact `#production`

### Network / IO Issue

- **Resolution**: Contact the prod ops team in Slack: `#production`

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down | Immediate | wolfhound-alerts@groupon.com, PagerDuty P13VDUS |
| P2 | Degraded (elevated errors) | 30 min | wolfhound-alerts@groupon.com |
| P3 | Minor impact | Next business day | wolfhound-dev@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| DaaS PostgreSQL RW | GDS Instances catalog; check connection from app logs | Service returns HTTP 5xx; no automatic fallback |
| DaaS PostgreSQL RO | GDS Instances catalog; check connection from app logs | Falls back to RW config if `readOnlyPostgres` is not configured; otherwise HTTP 5xx |
