---
service: "invoice_management"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /health` | http | > No evidence found in codebase. | > No evidence found in codebase. |
| `GET /status` | http | > No evidence found in codebase. | > No evidence found in codebase. |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request latency | histogram | End-to-end request duration via Play framework instrumentation | > No evidence found in codebase. |
| HTTP error rate (5xx) | counter | Count of 5xx responses from Play controllers | > No evidence found in codebase. |
| Invoice creation rate | counter | Number of invoices created per time window | Drop to 0 during business hours may indicate mbus disconnection |
| NetSuite transmission errors | counter | Failures sending invoices to NetSuite | > No evidence found in codebase. |
| Payment reconciliation lag | gauge | Age of oldest unreconciled invoice | > No evidence found in codebase. |
| Quartz job failure count | counter | Number of Quartz scheduler job execution failures | Any sustained failures warrant investigation |
| DB connection pool usage | gauge | PostgreSQL connection pool saturation | > No evidence found in codebase. |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Invoice Management Service Health | > No evidence found in codebase. | > No evidence found in codebase. |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Service health check failing | `/health` returns non-200 | critical | Restart pod; check logs for startup errors; verify DB connectivity |
| NetSuite transmission failing | Invoices not transmitted for >1 Quartz cycle | critical | Verify NetSuite credentials; check NetSuite service status; check IAS logs |
| mbus consumer lag | Events not being consumed | critical | Check mbus broker connectivity; verify consumer group offsets; restart consumer |
| PostgreSQL connection failing | DB queries timing out or rejecting connections | critical | Verify DB host; check connection pool config; contact DB team |
| Quartz job not running | Scheduled job has not run within expected window | warning | Check Quartz cron_tracking table; verify service is running; inspect logs |
| S3 upload failing | Remittance report upload errors | warning | Check AWS credentials; verify bucket name and permissions |

## Common Operations

### Restart Service

1. Identify the running pod: `kubectl get pods -l app=invoice-management -n <namespace>`
2. Delete the pod to trigger a rolling restart: `kubectl delete pod <pod-name> -n <namespace>`
3. Monitor new pod startup: `kubectl logs -f <new-pod-name> -n <namespace>`
4. Verify health: `curl https://<host>/health`
5. Confirm Quartz scheduler has resumed: check `cron_tracking` table for recent job executions.

### Scale Up / Down

1. `kubectl scale deployment invoice-management --replicas=<N> -n <namespace>`
2. **Important**: Quartz scheduler is configured for single-node execution to prevent duplicate invoice transmissions. Scaling beyond 1 replica requires Quartz clustering to be configured. Contact Goods Engineering before scaling above 1 replica.

### Database Operations

- **View pending invoices**: `SELECT * FROM invoices WHERE status = 'PENDING' ORDER BY created_at;`
- **Check payment reconciliation**: `SELECT * FROM payments WHERE status = 'UNRECONCILED';`
- **View Quartz job history**: `SELECT * FROM cron_tracking ORDER BY last_run DESC LIMIT 20;`
- **Database migrations**: > No evidence found in codebase. Migration tooling not confirmed. Contact Goods Engineering for migration procedures.

## Troubleshooting

### Invoices not being created from PO events
- **Symptoms**: New POs are created but no corresponding invoices appear in the database
- **Cause**: mbus consumer is disconnected, PO event topic has changed, or event consumer is throwing unhandled exceptions
- **Resolution**: Check mbus consumer logs; verify `MBUS_BROKER_URL` and `MBUS_CLIENT_ID`; confirm PO event topic subscription; inspect consumer exception logs

### NetSuite transmission failures
- **Symptoms**: Invoices remain in PENDING or QUEUED state; NetSuite shows no new invoices
- **Cause**: NetSuite OAuth credentials expired or invalid; NetSuite API endpoint unreachable; rate limiting
- **Resolution**: Verify `NETSUITE_CONSUMER_KEY`, `NETSUITE_TOKEN`, and related OAuth env vars; confirm NetSuite service status; check for 401/403 errors in IAS logs; rotate credentials if expired

### Payment pull not reconciling
- **Symptoms**: Invoices remain unpaid despite payments existing in NetSuite
- **Cause**: `/pull_payments` Quartz job not running; NetSuite API returning empty results; mismatched invoice IDs
- **Resolution**: Check Quartz `cron_tracking` table for job status; trigger manual `/pull_payments`; compare invoice IDs in IAS vs NetSuite

### NetSuite callback not received
- **Symptoms**: Payment status updates not reflected in IAS after NetSuite processes payment
- **Cause**: `/ns_callback` endpoint unreachable from NetSuite; OAuth signature verification failing; network routing issue
- **Resolution**: Verify IAS is accessible from NetSuite network; check `Authorization` header signature validation; review callback handler logs for signature errors

### Remittance report not uploaded to S3
- **Symptoms**: Vendors report missing remittance files; no new objects in S3 bucket
- **Cause**: AWS credentials invalid or expired; S3 bucket permissions misconfigured; report generation failure (Apache POI error)
- **Resolution**: Verify `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`; check S3 bucket ACL; inspect POI report generation logs for Excel errors

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down or invoices not being processed; financial operations blocked | Immediate | Goods Engineering + Finance + Platform/SRE |
| P2 | NetSuite transmission failing; payment reconciliation halted | 30 min | Goods Engineering + Finance |
| P3 | Remittance reports delayed; non-critical Quartz jobs failing | Next business day | Goods Engineering |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| PostgreSQL (`continuumInvoiceManagementPostgres`) | Check connection pool status in logs; query `SELECT 1` | Service cannot function; all operations fail |
| NetSuite | Check `/send_invoices` endpoint response; verify OAuth token validity | Invoice transmission and payment pull halt; Quartz retries on next cycle |
| Message Bus (mbus) | Check consumer group lag via mbus tooling | Event-driven invoice creation halts; events queue up and replay on reconnection |
| AWS S3 | Attempt a test S3 list operation; verify IAM credentials | Remittance uploads fail; reports can be regenerated and uploaded manually |
| Rocketman | Check Rocketman service health endpoint | Email notifications fail; invoice processing continues unaffected |

> Operational procedures to be defined by service owner where marked above.
