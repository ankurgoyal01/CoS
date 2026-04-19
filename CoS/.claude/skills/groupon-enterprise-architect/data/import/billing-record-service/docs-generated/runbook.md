---
service: "billing-record-service"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/grpn/healthcheck` | http | 5s (readiness), 15s (liveness) | 5s |
| `/heartbeat.txt` | http | Kubernetes probe | Not specified |

Readiness probe has an initial delay of 180s to allow Tomcat and application context to initialize. Liveness probe has an initial delay of 200s.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Hystrix error rate | gauge | Percentage of circuit-breaker-wrapped calls returning errors | Alert severity 2 when elevated |
| JVM Heap Old Gen usage | gauge | Old generation heap usage as a percentage | Alert severity 2 (pager to BRS dev) |
| JVM thread count | gauge | Total active JVM threads | Alert severity 2 when excessive |
| PCI breach search failure rate | counter | Failed PCI breach search operations | Alert severity 2 (pager to BRS dev) |
| BFM monitor | gauge | Standard Groupon BFM (Black Friday Monitor) baseline alert | Alert severity 2 (pager to SOC) |
| 5-minute load average | gauge | Host CPU load (legacy VM metric) | Alert severity 3 |
| Disk space | gauge | Available disk on log volume | Alert severity 3 |
| IO wait | gauge | Host IO wait percentage | Alert severity 3 |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Billing Record Service EMEA | Wavefront | https://groupon.wavefront.com/dashboards/Billing-Record-Service-EMEA-ELK |
| Billing Record Service NA | Wavefront | https://groupon.wavefront.com/dashboards/Billing-Record-Service-NA-ELK |
| BRS additional dashboard 1 | Wavefront | https://groupon.wavefront.com/u/nR7V82BhTq?t=groupon |
| BRS additional dashboard 2 | Wavefront | https://groupon.wavefront.com/u/PZJwyM7qYv?t=groupon |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Hystrix Errors | Services returning circuit-breaker errors | 2 (warning) | Restart Tomcat on affected hosts; if unresolved, page billing-record-service@ |
| JVM Heap Old Gen | JVM Old Gen heap above threshold | 2 (warning) | Restart Tomcat; if unresolved, page billing-record-service@ |
| JVM Threading | JVM thread count above threshold | 2 (warning) | Restart Tomcat; if unresolved, page billing-record-service@ |
| PCI Breach Search | PCI breach search failures | 2 (warning) | Page BRS dev immediately; if unresolved, page billing-record-service@ |
| BFM Monitor | Standard BFM baseline alert | 2 (warning) | SOC to investigate; if unresolved, page billing-record-service@ |
| 5-minute load average | Host overloaded | 3 (info) | Restart service on hot host; if fleet-wide, page billing-record-service@ |
| Disk Space | Running out of disk | 3 (info) | Remove old log backups from `/var/groupon/apache-tomcat/logs/` |
| IO Wait | IO system overloaded | 3 (info) | Restart service on hot host; if fleet-wide, page billing-record-service@ |
| Memory Low | Free memory critically low | 3 (info) | Restart Tomcat service |

## Common Operations

### Restart Service

For Kubernetes-managed deployments, restart by triggering a new rollout:
```
kubectl rollout restart deployment/billing-record-service -n billing-record-service-production
```

For legacy VM deployments (pre-Kubernetes):
```
bundle exec cap <ENV> deploy:restart
```

Monitor logs during restart:
- Kubernetes: check pod logs via `kubectl logs`
- Legacy: `/var/groupon/apache-tomcat/logs/brs.log` and ELK

### Scale Up / Down

Scaling is managed via Kubernetes HPA (min/max replicas defined in `.meta/deployment/cloud/components/app/`). To add capacity:

1. Procure additional nodes via the ops request system
2. Update `minReplicas` / `maxReplicas` in the relevant environment YAML under `.meta/deployment/cloud/components/app/`
3. Re-deploy to apply changes
4. Add new host IPs to DaaS PostgreSQL whitelist (create a GDS Jira ticket)

### Database Operations

**Check migration status**:
```
export BRS_ENV=<env>:<region>
export BRS_VERSION=<version>
bundle exec cap -f Capfile.liquibase $BRS_ENV:status deploy:all VERSION=$BRS_VERSION TYPE=RELEASE
```

**Apply migration**:
```
bundle exec cap -f Capfile.liquibase $BRS_ENV:update deploy:all VERSION=$BRS_VERSION TYPE=RELEASE
```

After running, check `/var/groupon/artifacts/billing-record-service/liquibase/target/liquibase/` for `migrate.sql` and `rollback.sql`. For production, attach scripts to a GDS ticket instead of applying directly.

**Verify a user's billing records** (for smoke testing after deployment):
```sql
SELECT br_p_id AS user_UUID, COUNT(id) AS "billing records size"
FROM billingrecord.billing_record
WHERE br_status IN ('INITIATED', 'AUTHORIZED') AND created_at >= '2018-01-01'
GROUP BY br_p_id
HAVING COUNT(id) > 1
LIMIT 1;
```
Then call:
```
curl -X GET http://<vip-of-BRS_ENV>/v3/users/<user_UUID>/billing_records
```

## Troubleshooting

### Hystrix Circuit Breaker Open
- **Symptoms**: Calls to PCI-API or Braintree fail with circuit-open errors; associated billing record operations return errors
- **Cause**: Downstream dependency (PCI-API or Braintree) is slow or unavailable
- **Resolution**: Restart Tomcat to reset Hystrix state; confirm downstream dependency health; if persistent, escalate to billing-record-service@

### JVM Memory Pressure
- **Symptoms**: JVM Old Gen heap alert; service becomes slow or unresponsive; OutOfMemoryError in logs
- **Cause**: Memory leak or excessive heap usage under load
- **Resolution**: Restart Tomcat on the affected host; monitor heap after restart; if recurring, engage BRS dev team for heap dump analysis

### Message Bus Consumer Not Processing
- **Symptoms**: GDPR erasure or token-deletion events are not being handled; backlog grows on mbus
- **Cause**: `messagebus.enabled=false` in config, or mbus connectivity failure
- **Resolution**: Verify `messagebus.enabled` is `true` in the active properties; verify mbus connectivity; restart service to re-initialize consumers

### Database Connectivity Failure
- **Symptoms**: All API calls return 500 errors; JDBC connection pool exhausted in logs
- **Cause**: PostgreSQL unreachable or DaaS issue
- **Resolution**: Verify database availability with DaaS team; check `/var/groupon/apache-tomcat/logs/brs.log` for JDBC errors; restart Tomcat if connection pool is exhausted

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service fully down; checkout payments blocked | Immediate | Page billing-record-service@ via PagerDuty (https://groupon.pagerduty.com/services/PL181L3) |
| P2 | Degraded — high error rate or latency; GDPR processing delayed | 30 min | Notify cap-payments@groupon.com; engage BRS dev on-call |
| P3 | Minor impact — single host issue, non-critical alert | Next business day | Post in Slack #billing-record-servic; notify cap-payments@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| PostgreSQL | JDBC connectivity check on app startup; visible in `/grpn/healthcheck` | No fallback — all billing record reads/writes require DB |
| Redis | Redis connection on startup; cache failures degrade to DB-only reads | Cache miss falls through to PostgreSQL query |
| PCI-API | Hystrix health stream | Circuit opens; token deletion deferred; billing record status update still commits |
| Braintree | Hystrix health stream | Circuit opens; one-time token endpoint returns error |
| Groupon Message Bus | mbus consumer status check | Messages unacknowledged; redelivered on reconnection |
