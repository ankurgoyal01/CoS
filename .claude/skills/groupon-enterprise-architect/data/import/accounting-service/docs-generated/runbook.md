---
service: "accounting-service"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /api/v3/health` | http | Configured by Kubernetes liveness/readiness probe | Configured by Kubernetes |
| `GET /status` | http | Kubernetes probe | Configured by Kubernetes |
| `GET /heartbeat` | http | Load balancer probe | Configured by platform |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP response codes (5xx rate) | counter | Rate of server errors on API endpoints | To be defined by service owner |
| Resque queue depth | gauge | Number of pending jobs in `continuumAccountingRedis` Resque queues | To be defined by service owner |
| Resque failed queue depth | gauge | Number of failed jobs requiring investigation | Any increase above baseline |
| MySQL connection pool utilization | gauge | ActiveRecord connection pool usage for `continuumAccountingMysql` | To be defined by service owner |
| Rails request latency | histogram | Response time distribution for all API endpoints (logged via lograge) | To be defined by service owner |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Accounting Service Overview | Groupon internal monitoring platform | Link managed by Finance Engineering team |

> Dashboard and alerting configuration details are not discoverable from this repository inventory. Contact fed@groupon.com for links.

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Health check failing | `/api/v3/health` returns non-200 | critical | Check application logs; verify MySQL and Redis connectivity; escalate to Finance Engineering |
| Resque failed queue growing | Failed job count increases unexpectedly | warning | Inspect failed jobs via Resque web UI; investigate root cause; re-enqueue or discard after analysis |
| Payment job failure | Merchant payment Resque job fails | critical | Investigate job arguments and error; verify Orders Service and Voucher Inventory Service are reachable; escalate to Finance Engineering with GPROD notification if SOX data affected |
| Contract import failure | Salesforce contract import job fails repeatedly | warning | Check Salesforce API connectivity and credentials; review import job logs; escalate to Finance Engineering |

## Common Operations

### Restart Service

1. Identify the service deployment in the cloud-elevator Kubernetes namespace for the target environment
2. For non-production: use cloud-elevator tooling to rolling-restart the Rails web deployment
3. For production: open a GPROD-approved change; execute rolling restart via cloud-elevator; verify `/api/v3/health` returns 200 after restart
4. Monitor Resque worker processes to confirm they reconnect to `continuumAccountingRedis` and resume processing

### Scale Up / Down

1. Determine current replica count via cloud-elevator or Kubernetes CLI
2. For non-production: adjust replica count in cloud-elevator configuration and apply
3. For production: open a GPROD-approved change; apply scaling adjustment; monitor pod startup and health endpoints

### Database Operations

- **Migrations**: Run `bundle exec rake db:migrate` in a one-off container or pre-deploy hook; migrations are SOX-controlled in production and require GPROD approval
- **Backfills**: Execute via Rails runner or Resque jobs; avoid long-running queries during peak traffic; coordinate with Finance Engineering
- **ar-octopus sharding**: If read/write splitting is configured, ensure migrations run against the primary shard; consult service owner for shard topology

## Troubleshooting

### Resque Workers Stuck or Not Processing

- **Symptoms**: Resque queue depth grows; jobs not completing; no recent job activity in logs
- **Cause**: Worker processes may have crashed, lost Redis connectivity, or stalled on a long-running job
- **Resolution**: Check worker pod logs; verify `continuumAccountingRedis` connectivity; restart worker pods via cloud-elevator if safe; inspect the Resque failed queue for errors

### Contract Import Not Reflecting Latest Salesforce Data

- **Symptoms**: Vendor contracts in the accounting API show stale data; recently updated Salesforce contracts not appearing
- **Cause**: Contract import job may have failed, Salesforce API credentials may be expired, or the import Resque job may be stuck
- **Resolution**: Check import job logs; verify `SALESFORCE_CLIENT_ID` and `SALESFORCE_CLIENT_SECRET` are valid; manually trigger an import job if needed; escalate to Finance Engineering

### Invoice Workflow Stuck in Pending State

- **Symptoms**: Invoices remain in pending status; approve/reject API calls return errors or do not update state
- **Cause**: Payment and invoicing engine job failure; database write error; upstream dependency (Orders Service or Voucher Inventory Service) unreachable
- **Resolution**: Check `acctSvc_paymentAndInvoicing` component logs; verify downstream service health; inspect Resque failed queue for related jobs; escalate to Finance Engineering if SOX-relevant data is affected

### High MySQL Connection Pool Utilization

- **Symptoms**: ActiveRecord connection pool exhaustion errors in logs; slow API responses
- **Cause**: Too many concurrent requests or long-running queries holding connections; ar-octopus shard misconfiguration
- **Resolution**: Check slow query logs on `continuumAccountingMysql`; review active connections; consider scaling web pods or tuning pool size via database.yml configuration

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no health check response; merchant payments not processing | Immediate | Finance Engineering on-call (fed@groupon.com); GPROD notification required for SOX-inscope incidents |
| P2 | Degraded — elevated error rate; specific workflows failing (e.g., contract import or invoice approval) | 30 min | Finance Engineering on-call |
| P3 | Minor impact — non-critical background jobs failing; reporting jobs delayed | Next business day | Finance Engineering via standard ticket |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumAccountingMysql` | Checked via `/api/v3/health`; ActiveRecord connection test | Service cannot operate without MySQL; no fallback |
| `continuumAccountingRedis` | Checked via Resque connectivity; `/api/v3/health` | Resque workers cannot process without Redis; no fallback |
| `salesForce` | Verify Salesforce API responds with valid auth token | Contract import halts; existing contract data remains available for invoicing |
| `continuumDealCatalogService` | HTTP GET to service health endpoint | Deal metadata unavailable; contract processing may use cached data |
| `continuumOrdersService` | HTTP GET to service health endpoint | Order and refund data unavailable; TPS/ASL flows may fail |
| `continuumVoucherInventoryService` | HTTP GET to service health endpoint | Voucher state unavailable; ingestion workers will retry via Resque |
| `messageBus` | Message Bus client connectivity check | Published events not delivered; consumed events not received; Resque queues drain without new work |
