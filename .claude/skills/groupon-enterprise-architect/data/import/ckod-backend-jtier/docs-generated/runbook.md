---
service: "ckod-backend-jtier"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET :8081/healthcheck` | http (Dropwizard admin) | Platform-managed | Platform-managed |
| `math` health check (registered in application startup) | Dropwizard HealthCheck | On request | On request |

The service registers a Dropwizard health check named `math` (`CkodBackendJtierHealthCheck`) accessible via the admin port 8081.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `http.in.total-time.count` | counter | Total incoming HTTP request count by endpoint | Baseline deviation |
| `http.in.*` (400 errors) | counter | Count of 4xx responses | Baseline deviation |
| `http.out.total-time.count` | counter | Outgoing HTTP request counts by endpoint | Baseline deviation |
| `db.out.time.total.count` | counter | Database operation counts | Baseline deviation |
| Keboola jobs request success/failure | counter | `KeboolaRequestMetrics` — successful and failed Keboola polling events | Drop in success rate |
| Keboola storage request success/failure | counter | `KeboolaRequestMetrics` — successful and failed storage API calls | Drop in success rate |
| Batch job update size | histogram | `KeboolaRequestMetrics` — number of jobs in each batch update | Anomalous spike |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| CKOD API Wavefront | Wavefront | `https://groupon.wavefront.com/dashboards/CKOD-API` |
| Conveyor Cloud Application Metrics | Wavefront | `https://groupon.wavefront.com/dashboards/Conveyor-Cloud-Application-Metrics` (filter `service: ckod-api`) |
| ELK Logs | Kibana (ELK) | `https://logging-stable-unified01.grpn-logging-stable.us-west-2.aws.groupondev.com/app/discover` (index: `filebeat-ckod-api-logging--*`) |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Drop in update job runs | Metric count drops below expected threshold | warning | Check `last_updated_timestamp` in `keboola_tables_metadata`; alert is often a lag in metric collection — wait for backfill before escalating |

## Common Operations

### Restart Service

Perform a rolling restart (zero downtime) with:

```
kubectl cloud-elevator auth
kubectx <kubernetes-context>
kubectl rollout restart deployment ckod-api--app--default
kubectl rollout restart deployment ckod-api--worker--default
```

Monitor pod health with `watch kubectl get pods`.

### Scale Up / Down

Scaling is managed by Kubernetes HPA. To manually override, update the deployment configuration in `.meta/deployment/cloud/components/app/{env}.yml` and redeploy. For emergency scaling, use `kubectl scale deployment ckod-api--app--default --replicas=<N>`.

### Database Operations

1. Authenticate with DBeaver using credentials from `github.groupondev.com/PRE/ckod-api-secrets`.
2. Use read-only credentials for all investigative queries.
3. Use read-write credentials only for data fixes — exercise caution in production.
4. Schema migrations run automatically at service startup via the JTier `MySQLMigrationBundle`.
5. To onboard a new Keboola project: insert a record into the `keboola_project` table with the project ID, name, and API token obtained from the Keboola connection page (see README for full procedure).

### View Pod Logs

```
kubectl cloud-elevator auth
kubectx ckod-api-staging-us-west-1
kubectl get pods
kubectl exec -c main <pod-name> -- cat /logs/jtier.steno.log
```

Logs are also available in ELK at the dashboard linked above.

## Troubleshooting

### Drop in Keboola update job run metrics
- **Symptoms**: Wavefront alert fires for drop in update job runs; `keboola_tables_metadata.last_updated_timestamp` appears stale
- **Cause**: Most likely a lag in metric collection (known false-alarm pattern); less likely: Keboola API outage, pod crash, or database connectivity issue
- **Resolution**: Check `last_updated_timestamp` in `keboola_tables_metadata` for the affected environment. If the timestamp is only as old as the update job interval, the alert is a false alarm. If significantly older, investigate pod logs for `IOException` from Keboola polling, check pod health, and verify MySQL connectivity.

### Deployment ticket not created
- **Symptoms**: Caller receives an error from `/deployments/create/keboola` or `/deployments/create/airflow`; no Jira ticket appears
- **Cause**: `JIRA_SERVER` or `JIRA_AUTH` environment variable is missing or invalid; Jira Cloud unreachable
- **Resolution**: Verify environment variables are set correctly. Check pod logs for `IOException` from `JiraTicketService`. Confirm Jira Cloud connectivity from the pod.

### GitHub diff link generation fails
- **Symptoms**: `/deployments/diff_link` or `/deployments/diff_authors` returns an error
- **Cause**: `GITHUB_API_TOKEN` missing, expired, or rate-limited; GitHub Enterprise unreachable
- **Resolution**: Verify `GITHUB_API_TOKEN` is set and valid. Check pod logs for `IOException` from `HttpClient.getGithubCompare()`.

### Service fails to start
- **Symptoms**: Pod enters `CrashLoopBackOff`; deployment does not become ready
- **Cause**: `GITHUB_API_TOKEN` not set (throws `IllegalStateException` at startup); database connection failure; JTier config file not found at `JTIER_RUN_CONFIG` path
- **Resolution**: Check pod logs for the startup exception. Verify all required environment variables and Kubernetes secrets are correctly mounted.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down (no API responses, worker stopped) | Immediate | PRE Team — dnd-pre@groupon.com |
| P2 | Degraded (Keboola polling stopped, deployment ticket creation failing) | 30 min | PRE Team — dnd-pre@groupon.com |
| P3 | Minor impact (metric collection lag, non-critical endpoint errors) | Next business day | PRE Team |

Full runbook: `https://docs.google.com/document/d/1pQE1NArL40TIlfukPxpfqVGGDbv5NLr5iDFwtQ-Lx4A/edit`

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| MySQL (read-only) | Connection validated at startup via Hibernate transaction probe | Service fails to start if unreachable |
| MySQL (read-write) | Connection validated at startup via Hibernate transaction probe | Service fails to start if unreachable |
| Keboola Cloud | `GET https://queue.groupon.keboola.cloud/search/jobs` — success/failure tracked by `KeboolaRequestMetrics` | Worker skips the current polling cycle; retries on next scheduled run |
| Jira Cloud | Checked implicitly during deployment ticket creation | Deployment ticket creation fails; error returned to caller |
| GitHub Enterprise | Checked implicitly during diff-link and author resolution | Endpoint returns error; deployment flow degrades gracefully |
| Google Chat | Checked implicitly during notification send | Notification failure does not block deployment ticket creation |
