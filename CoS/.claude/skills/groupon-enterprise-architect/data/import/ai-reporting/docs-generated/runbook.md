---
service: "ai-reporting"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/healthcheck` (Dropwizard standard) | http | 30s | 5s |
| `/ping` (Dropwizard standard) | http | 30s | 2s |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `ai_reporting.campaigns.created` | counter | Number of Sponsored Listing campaigns created | — |
| `ai_reporting.wallet.topup.count` | counter | Number of wallet top-up transactions processed | — |
| `ai_reporting.citrusad.sync.failures` | counter | CitrusAd campaign sync failures per cycle | > 0 triggers Slack alert |
| `ai_reporting.report.reconciliation.delta` | gauge | Billing delta (expected vs actual) from CitrusAd report reconciliation | Configurable threshold |
| `ai_reporting.feed.upload.duration` | histogram | Time to generate and upload CitrusAd feeds to GCS | — |
| `ai_reporting.mbus.consumer.lag` | gauge | JTier MessageBus consumer lag for Salesforce and deal pause topics | — |

> Metric names are inferred from component responsibilities in the DSL. Verify actual metric names with the service owner.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| AI Reporting Operations | Grafana / Datadog | > Link managed externally — contact ads-eng@groupon.com |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| CitrusAd sync failure | `ai_reporting.citrusad.sync.failures` > 0 for 2 consecutive cycles | warning | Check CitrusAd API availability; inspect scheduler logs; retry manually if needed |
| Reconciliation billing delta | CitrusAd billing delta exceeds configured threshold | critical | Review reconciliation records in MySQL; escalate to Finance and CitrusAd account team |
| MessageBus consumer lag | JMS consumer falling behind on Salesforce or deal pause topics | warning | Check MBus broker health; inspect consumer thread status; restart service if stuck |
| Feed upload failure | GCS feed upload job fails | warning | Check GCS bucket access; verify service account credentials; re-run feed job |
| Wallet balance sync error | Wallet top-up or refund fails to sync to CitrusAd | critical | Check CitrusAd wallet API; verify wallet ledger state in MySQL; notify Finance |

## Common Operations

### Restart Service

Operational procedures to be defined by service owner. Standard JTier/Kubernetes rolling restart:
1. Verify no active CitrusAd sync or reconciliation jobs are in progress (check Quartz job state in MySQL or logs)
2. Issue rolling restart via Kubernetes deployment rollout
3. Monitor healthcheck endpoint until all pods report healthy
4. Verify Quartz scheduler resumes and MBus consumers reconnect

### Scale Up / Down

Operational procedures to be defined by service owner. Adjust Kubernetes replica count via deployment manifest. Note: Quartz scheduler uses cluster-aware locking to prevent duplicate job execution across replicas.

### Database Operations

Operational procedures to be defined by service owner. Key operations:
- Schema migrations: run via the service's migration tooling before deployment
- Wallet ledger backfill: requires Finance sign-off; run as a one-off Quartz job or direct SQL with audit trail
- Audience table cleanup: managed by the scheduled audience refresh job; manual cleanup requires Hive access

## Troubleshooting

### CitrusAd Campaigns Out of Sync

- **Symptoms**: Merchant dashboard shows campaign state mismatch; CitrusAd reports different status than MySQL
- **Cause**: CitrusAd API timeout or authentication failure during sync job; manual changes made directly in CitrusAd portal
- **Resolution**: Identify affected campaigns via MySQL `citrusad_campaign` table; trigger manual sync via admin endpoint or Quartz job; check CitrusAd OAuth token expiry

### Wallet Balance Discrepancy

- **Symptoms**: Merchant reports wallet balance different from expected after top-up; CitrusAd wallet diverges from MySQL ledger
- **Cause**: Partial failure during top-up flow (MySQL write succeeded but CitrusAd wallet update failed, or vice versa)
- **Resolution**: Compare MySQL ledger with CitrusAd wallet API balance; identify unreconciled transactions; apply correction via `continuumAiReportingService_merchantPaymentsService` admin operation; notify Finance

### Feed Upload Stale

- **Symptoms**: CitrusAd reports stale customer/order data; feed timestamps in MySQL are old
- **Cause**: GCS upload failure; Quartz scheduler job not firing; GCS authentication issue
- **Resolution**: Check Quartz job state in MySQL scheduler tables; verify GCS bucket accessibility and service account credentials; manually trigger feed generation job

### MBus Consumer Not Processing

- **Symptoms**: Salesforce wallet updates not reflected in MySQL; deal pauses not cascading to campaigns
- **Cause**: JTier MessageBus broker connection dropped; consumer thread blocked or crashed
- **Resolution**: Check MBus broker health; restart service to force consumer reconnection; verify no unprocessed messages on dead letter queue

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — merchants cannot manage campaigns or view wallet | Immediate | Ads Engineering on-call (ads-eng@groupon.com) |
| P2 | Degraded — CitrusAd sync failing or wallet reconciliation errors | 30 min | Ads Engineering on-call |
| P3 | Minor impact — reporting data stale or single vendor unavailable | Next business day | Ads Engineering team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumAiReportingMySql` | MySQL connection pool health via Dropwizard healthcheck | Service cannot operate without MySQL — escalate immediately |
| `citrusAd` | CitrusAd API ping / OAuth token refresh | Campaign sync deferred to next Quartz cycle; Slack alert fires |
| `salesForce` | Salesforce OAuth token refresh success | Sync deferred; JMS events continue to queue |
| `continuumAiReportingGcs` | GCS bucket accessibility check | Feed uploads queued; reconciliation jobs paused until GCS recoverable |
| `continuumAiReportingMessageBus` | JTier MBus consumer heartbeat | Deal pause and Salesforce events delayed until broker reconnects |
| `notsService` | HTTPS /health endpoint | Notifications dropped (non-blocking); campaigns continue |
