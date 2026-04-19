---
service: "getaways-partner-integrator"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/healthcheck` (Dropwizard default) | http | Kubernetes liveness/readiness probe interval | Kubernetes probe timeout |
| `/ping` (Dropwizard admin) | http | — | — |
| Kafka consumer lag | metric | Continuous | — |
| MBus connection status | metric | Continuous | — |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| SOAP inbound request rate (per endpoint) | counter | Number of inbound SOAP requests received per channel manager endpoint | Drop to zero during partner active hours |
| SOAP outbound call latency | histogram | Latency of outbound SOAP calls to channel managers | P99 > partner SLA |
| SOAP outbound error rate | counter | Count of failed outbound SOAP calls to channel managers | Any sustained errors |
| Kafka consumer lag | gauge | Lag on partner inbound Kafka consumer | Sustained lag above threshold |
| MBus message processing rate | counter | Rate of InventoryWorkerMessage events consumed and produced | Drop to zero |
| REST API request rate | counter | Requests to `/getaways/v2/channel_manager_integrator/mapping` and `/reservation/data` | Abnormal spike or drop |
| DB connection pool utilization | gauge | MySQL connection pool usage | Near pool limit |

### Dashboards

> Operational procedures to be defined by service owner. Contact the Travel team for current dashboard links.

| Dashboard | Tool | Link |
|-----------|------|------|
| Getaways Partner Integrator — per variant | Groupon internal monitoring | Contact Travel team |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| SOAP inbound endpoint down | No requests received during partner active window | P2 | Check pod health, partner connectivity, and WS-Security config |
| Outbound SOAP call failure | Error rate on `partnerSoapClient` exceeds threshold | P2 | Check partner endpoint availability; review MySQL SOAP logs for payload details |
| Kafka consumer lag growing | Partition lag exceeds threshold for partner inbound topic | P2 | Check consumer pod health; scale up if needed |
| MBus disconnection | MBus worker not processing messages | P2 | Check MBus broker health; restart pod if needed |
| DB connection pool exhausted | All MySQL connections in use | P1 | Scale service replicas; investigate slow queries |

## Common Operations

### Restart Service

1. Identify the affected variant deployment: `kubectl get deployments -n <namespace> | grep getaways-partner-integrator`
2. Perform a rolling restart: `kubectl rollout restart deployment/<variant-deployment-name> -n <namespace>`
3. Monitor rollout: `kubectl rollout status deployment/<variant-deployment-name> -n <namespace>`
4. Verify health check passes: `kubectl get pods -n <namespace>` and check `/healthcheck` endpoint

### Scale Up / Down

1. Identify the target variant deployment name.
2. Scale replicas: `kubectl scale deployment/<variant-deployment-name> --replicas=<N> -n <namespace>`
3. Monitor pod readiness: `kubectl get pods -n <namespace> -w`

### Database Operations

- Schema migrations: Not discoverable from architecture inventory — contact the Travel team for migration tooling and procedures.
- Manual reservation data queries: Connect to `continuumGetawaysPartnerIntegratorDb` MySQL instance using approved DBA credentials via JTier DaaS tooling.
- SOAP log review: Query the SOAP request/response log table directly to inspect historical partner interaction payloads for debugging.

## Troubleshooting

### SOAP Inbound Not Receiving Partner Messages
- **Symptoms**: No ARI or reservation records being created; partner reports delivery failures
- **Cause**: Service pod unhealthy, WS-Security credential mismatch, or network policy blocking inbound SOAP traffic
- **Resolution**: Check pod health; verify WS-Security credentials match partner configuration; check Kubernetes service and ingress routing for the affected variant

### Outbound SOAP Calls Failing
- **Symptoms**: Reservation confirmations not reaching channel manager; SOAP error logs in MySQL
- **Cause**: Partner endpoint unavailable, WS-Security auth rejected, or payload serialization error
- **Resolution**: Review MySQL SOAP request/response logs for error details; verify partner endpoint URL and WS-Security credentials; check partner system status

### Kafka Consumer Not Processing Messages
- **Symptoms**: Growing lag on partner inbound Kafka topic; no mapping updates
- **Cause**: Consumer pod crashed, Kafka connectivity issue, or deserialization error on message format
- **Resolution**: Check pod logs for consumer exceptions; verify Kafka bootstrap server connectivity; inspect message format for schema changes

### MBus Worker Stalled
- **Symptoms**: InventoryWorkerMessage events not being consumed or produced; downstream inventory not updating
- **Cause**: MBus broker connectivity loss, credential expiry, or JMS session error
- **Resolution**: Check MBus broker health; verify `MBUS_BROKER_URL` and credentials; restart the affected pod

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | All partner integrations down; no ARI or reservation processing | Immediate | Travel team on-call |
| P2 | Single partner variant down or degraded; other variants unaffected | 30 min | Travel team |
| P3 | Non-critical degradation (e.g., delayed Kafka processing) | Next business day | Travel team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumGetawaysPartnerIntegratorDb` (MySQL) | Dropwizard DB health check at `/healthcheck` | Service will fail health check; no graceful degradation |
| `grouponKafkaCluster_2c7f` (Kafka) | Kafka consumer connectivity check | Messages queue in Kafka; processing resumes on reconnect |
| `grouponMessageBus_7a2d` (MBus) | MBus connection liveness | Messages queue in MBus; processing resumes on reconnect |
| `getawaysInventoryService_5e8a` | REST call success/failure | Mapping workflows that require inventory hierarchy will fail; no local fallback |
| SiteMinder / TravelgateX / APS | Outbound SOAP call success | Failed calls are logged to MySQL; no automatic retry evidenced |
