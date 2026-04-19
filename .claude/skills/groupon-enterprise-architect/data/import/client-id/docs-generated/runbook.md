---
service: "client-id"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/var/groupon/jtier/heartbeat.txt` | File-based heartbeat (Kubernetes readiness probe) | Kubernetes default | Kubernetes default |
| Dropwizard admin healthcheck (`/healthcheck` on port `9001`) | HTTP | — | — |
| `ClientIdHealthCheck` (internal Dropwizard health check) | In-process | Per Dropwizard admin poll | — |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP endpoint response times | histogram | Per-endpoint latency tracked by Telegraf/InfluxDB | Configured in Grafana |
| HTTP error rates | counter | 4xx / 5xx response counts per endpoint | Configured in Grafana |
| JVM heap usage | gauge | Heap used vs configured `HEAP_SIZE` (1843m) | Configured in Grafana |
| HikariCP pool metrics | gauge | Active, idle, pending connection counts for primary (pool=5) and read-replica (pool=30) | Configurable via JMX / Telegraf |
| Pod CPU / memory | gauge | Kubernetes HPA / VPA source metrics | HPA target utilisation |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Client ID Telegraf | Grafana | `https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/d/ae8rsgn1yfldsd/client-id-telegraf` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Pod CrashLoopBackOff | Pod restarts repeatedly | critical | Check `kubectl logs`, inspect startup errors, verify `JTIER_RUN_CONFIG` resolves to a valid file |
| High 5xx rate | Spike in 5xx HTTP responses | critical | Check Grafana dashboard; inspect pod logs for exceptions; verify MySQL connectivity |
| MySQL connection pool exhaustion | HikariCP pool timeout errors in logs | warning | Check replica and primary pool sizes; scale pods or increase `poolSize` in config |
| Deployment unavailable | `kubectl get deployments` shows replicas < desired | critical | Check pod events with `kubectl describe`; initiate rollback via Deploybot if required |

> Application-level alert thresholds are defined in Grafana. See the dashboard link above.

## Common Operations

### Restart Service

```bash
# Rolling restart (zero downtime)
kubectl rollout restart deployment/client-id--app--default -n <namespace>

# Alternatively, redeploy current version via Deploybot
# https://deploybot.groupondev.com/groupon-api/client-id
```

### Scale Up / Down

```bash
# Scale to desired replica count
kubectl scale deployment client-id--app--default -n <namespace> --replicas=<count>

# View current HPA status
kubectl get hpa -n <namespace>
```

### Stop Service (DANGEROUS)

```bash
# Scale to zero — will remove all pods and stop serving traffic
kubectl scale deployment client-id--app--default -n <namespace> --replicas=0

# Restart by scaling back up
kubectl scale deployment client-id--app--default -n <namespace> --replicas=<count>
```

### Database Operations

```bash
# Connect to production MySQL (US GCP primary)
mysql -h client-id-rw-na-production-db.gds.prod.gcp.groupondev.com \
      -u <DAAS_APP_USER> -p -D client_id_production

# Credentials are stored in Kubernetes secrets (client-id-secrets repo)
# Decode base64 secret: echo <encoded-value> | base64 --decode
```

Schema migrations follow the `jtier-daas` conventions. File a ticket with GDS to sync databases between environments.

## Troubleshooting

### Client ID exists in PROD but not in UAT/Staging

- **Symptoms**: Token lookup in staging returns 404 or empty; API Proxy in staging rejects a valid prod client ID
- **Cause**: GDS cross-environment DB sync preserves the original `updated_at` timestamp from production. If any change was made in staging after the PROD token was created, API Proxy's sync timestamp will skip the PROD-imported token
- **Resolution**:
  1. File a GDS ticket to sync the staging/UAT DBs with production (reference: `jira.groupondev.com/browse/GDS-16186`)
  2. If API Proxy is still rejecting the token after a GDS sync, force API Proxy to re-fetch all tokens:
     ```
     fab -f api_proxy_deploy.py staging_snc1 reset_clients
     fab -f api_proxy_deploy.py staging_snc1 service.rolling_restart
     ```

### API Proxy Rejecting Client ID After GDS Sync

- **Symptoms**: Valid token still rejected by API Proxy in staging/UAT after GDS sync
- **Cause**: Timestamp drift — API Proxy's stored `updated_at` cursor is newer than the imported token's `updated_at`
- **Resolution**: Run the `reset_clients` fabric command for API Proxy staging (see above)

### Service Returns Error / Invalid Response

For GCP environments — search Cloud Logging:
```
resource.type="k8s_container"
resource.labels.cluster_name="<cluster-name>"
resource.labels.namespace_name="<namespace>"
resource.labels.container_name="client-id"
"<error message>"
```

For AWS EMEA environments — search CloudWatch:
```
log-group: /aws/eks/<cluster-name>/<namespace>
"<error message>"
```

### Jira Self-Service Ticket Creation Fails

- **Symptoms**: `/self-service/newClientToken` POST returns a 400 or 5xx error
- **Cause**: `jiraServiceClientHost` is misconfigured or the Jira API service is unreachable
- **Resolution**: Verify the `jiraServiceClientHost` value in the active config file; check network connectivity to the Jira host from within the pod

### MySQL Connection Pool Exhaustion

- **Symptoms**: `HikariPool-1 - Connection is not available, request timed out after 40000ms` in logs
- **Cause**: Insufficient connection pool size or a connection leak
- **Resolution**: Check active connections; restart pods for a clean pool state; consider increasing `poolSize` in the config (requires redeploy)

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service fully down — API Proxy cannot sync; active rate limit enforcement may degrade | Immediate | groupon-api on-call |
| P2 | Elevated error rate or partial availability; token sync slow | 30 min | groupon-api team |
| P3 | Non-critical UI errors or self-service failures | Next business day | groupon-api team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| MySQL primary | HikariCP pool metrics; `connectionTimeout: 40000ms` | No automatic fallback; writes will fail |
| MySQL read replica | HikariCP pool metrics; `connectionTimeout: 40000ms` | No automatic fallback to primary for reads — read paths will return errors |
| Jira REST API | No circuit breaker; `connectTimeout: 2s`, `readTimeout: 1s` | Self-service flow fails; client/token management UI is unaffected |
