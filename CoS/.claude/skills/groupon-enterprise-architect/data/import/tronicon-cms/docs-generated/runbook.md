---
service: "tronicon-cms"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/grpn/status` (port 8080) | http | Kubernetes managed | Kubernetes managed |
| Kubernetes pod liveness/readiness | exec | Kubernetes managed | Kubernetes managed |

> The status endpoint path is `/grpn/status`; the environment poller is disabled in `.service.yml` (`status_endpoint.disabled: true`).

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP 5xx error rate (US) | counter | All 5xx responses in production us-central1 | Alerting configured in Grafana (SEV 4) |
| HTTP 5xx error rate (EU) | counter | All 5xx responses in production eu-west-1 | Alerting configured in Grafana (SEV 4) |
| Pod restarts (US) | gauge | Pod restart count in tronicon-cms-production namespace (us-central1) | Alerting configured in Grafana |
| Pod restarts (EU) | gauge | Pod restart count in tronicon-cms-production namespace (eu-west-1) | Alerting configured in Grafana |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Tronicon CMS | Grafana | https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/d/ce9zdyn4j6x34d/tronicon-cms |
| Conveyor Cloud Customer Metrics | Grafana | https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/d/fe7dii805648wc/conveyor-cloud-customer-metrics (namespace: tronicon-ui-production) |
| Arrowhead | Internal | https://arrowhead.groupondev.com/ |
| Production Alerts List | Grafana | https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/alerting/list?search=tronicon-cms |

### Log Access (Kibana)

| Environment | Link |
|-------------|------|
| Staging US | https://stable-kibana-unified.us-central1.logging.stable.gcp.groupondev.com/app/r/s/QUFxu |
| Staging EMEA | https://stable-kibana-unified-eu.logging.stable.gcp.groupondev.com (see monitoring runbook for full URL) |
| Production US | https://prod-kibana-unified.us-central1.logging.prod.gcp.groupondev.com/app/r/s/88pVp |
| Production EMEA | https://logging-prod-eu-unified1.grpn-logging-prod.eu-west-1.aws.groupondev.com/goto/b5666b6558a4895edd45e2bf97fd3fc9 |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| [Production] [Cloud] [EU] All 5xx Errors | 5xx error rate threshold exceeded (eu-west-1) | SEV 4 | Check API via Kibana; review exceptions |
| [Production] [Cloud] [US] All 5xx Errors | 5xx error rate threshold exceeded (us-central1) | SEV 4 | Check API via Kibana; review exceptions |
| [Production] [Cloud] [US] Pod Restarts | Pod restart count exceeded (us-central1) | — | Check pod state via kubectl |
| [Production] [Cloud] [EU] Pod Restarts | Pod restart count exceeded (eu-west-1) | — | Check pod state via kubectl |

## Common Operations

### Restart Service

```bash
# Determine affected region and authenticate
kubectl cloud-elevator auth browser
kubectl config use-context <context>   # e.g., tronicon-cms-gcp-production-us-central1
kubens tronicon-cms-production
kubectl get pods -o wide
kubectl delete pod <pod_name>          # pod will be rescheduled automatically
```

### Scale Up / Down

Edit `.meta/deployment/cloud/components/app/<environment>.yml` and update `minReplicas` / `maxReplicas`, then redeploy via DeployBot. HPA target utilization is set via `hpaTargetUtilization: 50` in `common.yml`.

```yaml
# Example scaling configuration (common.yml)
minReplicas: 3
maxReplicas: 3
hpaTargetUtilization: 50
```

### Database Operations

**Run migrations** — Flyway migrations run automatically on application startup. To add a new migration:
1. Create `src/main/resources/db/migration/V<latest+1>__<description>.sql`
2. Start the application locally; verify migration via local DB inspection
3. Flyway history table: `schema_version`

**Connect to database** — See the [postgres commands runbook](https://github.groupondev.com/tronicon/tronicon-cms/blob/main/docs/runbooks/commands/postgres.md) and contact the GDS team via `#gds-daas` for managed access.

## Troubleshooting

### API Issue (5xx Errors)

- **Symptoms**: Grafana 5xx alert fires; elevated error rate in Kibana
- **Cause**: Application exception, database connectivity failure, or bad request handling
- **Resolution**:
  1. Query Kibana for failing requests (filter by `status >= 500`)
  2. Query Kibana for exceptions thrown in the same period
  3. Group requests by status code to identify error pattern
  4. If database related, contact GDS team (`#gds-daas`)
  5. If application related, review recent deployments and consider rollback via DeployBot

### Pod Issue (Pod Restarts / Not Running)

- **Symptoms**: Grafana pod restart alert fires; pods in CrashLoopBackOff or Pending state
- **Cause**: OOM kill, startup failure, misconfiguration, or bad deployment
- **Resolution**:
  ```bash
  kubectl config use-context <context>
  kubens tronicon-cms-production
  kubectl get pods -o wide
  kubectl logs pod/<pod_name> -c main           # startup issues
  kubectl logs <pod_name> -p -c main            # previous container logs (OOM/terminated)
  kubectl get <pod_name> --output=yaml          # check lastState for exit code
  ```
  For stuck deployments: `kubectl delete deployment <deployment_name>` or `kubectl delete pod <pod_name>`

### Memory Issue

- **Symptoms**: OOM kills, high memory usage in Grafana
- **Cause**: Memory leak or insufficient limit configuration
- **Resolution**: Consider increasing `memory.main.limit` in the environment-specific deployment YAML and redeploying, or scale out via HPA settings. See [adding_capacity runbook](https://github.groupondev.com/tronicon/tronicon-cms/blob/main/docs/runbooks/adding_capacity.md).

### VIP Issue

- **Symptoms**: VIP status unhealthy; requests not reaching pods
- **Cause**: Pod unavailability causing VIP health check failures
- **Resolution**: Follow Pod Issue resolution steps to restore healthy pods

### Database Issue

- **Symptoms**: 500 errors with database connection or query failures in logs
- **Cause**: DaaS outage, connectivity issue, or schema mismatch
- **Resolution**:
  1. Run postgres diagnostic commands (see `docs/runbooks/commands/postgres.md`)
  2. Escalate to GDS team via `#gds-daas` Slack channel

### Disk Space Issue

- **Symptoms**: Disk full errors in logs
- **Cause**: Log accumulation in `/tmp` or other filesystem
- **Resolution**: `sudo du -a / | sort -n -r | head -n 10` to identify consumers; contact prod ops (`#production`)

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down (all regions) | Immediate | wolfhound-apps@groupon.pagerduty.com — PD service P13VDUS |
| P2 | Degraded performance or single-region outage | 30 min | wolfhound-dev@groupon.com |
| P3 | Minor impact / non-production | Next business day | wolfhound-dev@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| MySQL DaaS | Query the [GDS catalog](https://pages.github.groupondev.com/ops/paver/catalog/cloud.html); contact `#gds-daas` | None — service returns 500 if DB is unreachable |
| Elastic APM | Check APM endpoint availability in cluster | Non-blocking — service continues if APM is down |
| ELK / Filebeat | Check Kibana dashboards for log ingestion | Non-blocking — service continues if log shipping fails |

## SLA

| Metric | Target |
|--------|--------|
| Uptime | 99% |
| Latency | 250ms at 99.5th percentile |
| Throughput | 500 RPM |
