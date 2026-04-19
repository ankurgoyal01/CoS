---
service: "afl-3pgw"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/grpn/healthcheck` (port 8080) | HTTP GET | Readiness: 5s; Liveness: 15s | Readiness initial delay: 20s; Liveness initial delay: 30s |
| Heartbeat file (`heartbeat.txt`) | File presence (lifecycle hook) | On pod start/stop | Written at postStart; removed at preStop with 30s drain |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| CJ real-time order submissions | counter | Number of order events forwarded to CJ per time window | 0 events in 2h triggers severity-4 alert; 0 in 12h triggers severity-2 |
| Missing orders forwarded by CjSubmitNewOrdersJob | counter | New-sale orders submitted by the batch job | 0 submissions in 48h triggers severity-2 alert |
| CjCorrectionSubmissionJob execution | gauge | Whether the correction submission job has run | Not run in 48h triggers severity-2 alert |
| CjReportProcessingJob execution | gauge | Whether the report processing job has run | Not run in 24h triggers severity-2 alert |
| CjCommissionsJob execution | gauge | Whether the commissions job has run | Not run in 24h triggers severity-2 alert |
| SpotifySubmitOffersJob execution | gauge | Whether the Spotify offers job has run | Not run in 24h triggers severity-2 alert |
| Reconciliation discrepancy | ratio | Ratio of reconciliations vs. previous day | 400% more or fewer reconciliations triggers severity-2 alert |
| Service exception rate | counter | Rate of exceptions thrown by the service | Above threshold triggers `3PGW Exceptions Alert` |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| AFL-3PGW main dashboard | Wavefront | `https://groupon.wavefront.com/dashboard/afl-3pgw` |
| CJ integration dashboard | Wavefront | `https://groupon.wavefront.com/dashboards/cj-integration` |
| AFL-RTA attribution dashboard | Wavefront | `https://groupon.wavefront.com/u/8CYT1qsf0h?t=groupon` |

### Alerts

All alerts page `gpn-alerts@groupon.com` (triggers PagerDuty service `https://groupon.pagerduty.com/services/PP9FGY1`).

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| RealTime CJ Order Not being Sent for 2 Hrs | No CJ order events sent in last 2h | 4 | Check MBUS topic, AFL-RTA logs, ELK logs |
| AFL-3PGW RealTime CJ Order Not being Sent | No CJ orders consumed from MBUS in last 12h | 2 | Verify AFL-RTA attribution, check MBUS dashboard |
| Missing Orders not Forwarded to CJ in last 48 hours | `CjSubmitNewOrdersJob` has not forwarded new orders in 48h | 2 | Check corrections table, Optimus job status |
| CjSubmitNewOrdersJob Not run in last 48 hrs | Job has not executed in 48h | 2 | Check ELK for `CjSubmitNewOrdersJob*` events |
| Declined CJ orders not Forwarded to CJ | `CjCorrectionSubmissionJob` has not forwarded declined orders in 48h | 2 | Check corrections table, Optimus cancelled orders job |
| CjCorrectionSubmission Job Not run in last 48 hrs | Job has not executed in 48h | 2 | Check ELK for CjCorrectionSubmission job events |
| CJ Reconciliation discrepancy compared with previous day | Reconciliation count differs by 400%+ vs. previous day | 2 | Review ReconciliationJob logic, validate CorrectionDao queries |
| AFL-3pGW CJ Report Processing Job Failed | `CjReportProcessingJob` not run in last 24h | 2 | Check ELK for report job errors, check `jobs` table |
| CjCommissionsJob Job Not run in last 24 hrs | `CjCommissionsJob` not run in last 24h | 2 | Check ELK for commissions job errors |
| SpotifySubmitOffersJob Job Not run in last 24 hrs | `SpotifySubmitOffersJob` not run in last 24h | 2 | Investigate ELK and Mailman connectivity |
| AFL-3PGW-IMPORT-MA-ATTRIBUTIONS-ORDERS | Optimus Prime import job failed | 3 | Retrigger Optimus job; resolve within 3 days |

## Common Operations

### Restart Service

> Do not restart without a clear understanding of the underlying issue. Escalate to the next on-call level if unsure.

**Option A — Redeploy via DeployBot** (preferred):
1. Navigate to `https://deploybot.groupondev.com/AFL/afl-3pgw`
2. Select the current version and click redeploy, or select a previous version for rollback

**Option B — Restart pods via kubectl**:
```bash
# Authenticate
kubectl cloud-elevator auth

# Set context (example: production us-central1)
kubectx afl-3pgw-production-us-central1

# Stop pods
kubectl scale --replicas=0 deployment/3pgw--app--default

# Start pods
kubectl scale --replicas=1 deployment/3pgw--app--default
```

### Scale Up / Down

1. Update `minReplicas` and `maxReplicas` in `.meta/deployment/cloud/components/app/common.yml` (or the environment-specific override file)
2. Deploy via DeployBot to apply the updated HPA configuration
3. For immediate scaling without a deploy: `kubectl scale --replicas=N deployment/3pgw--app--default`

### Database Operations

- Flyway migrations run automatically on startup (`jtier-migrations` bundle)
- Migrations live in `src/main/resources/db/migration/` (V1__ through V63__)
- For manual DB access: use DaaS credentials (`DAAS_APP_USERNAME`/`DAAS_APP_PASSWORD`) against the appropriate cluster endpoint (see [Data Stores](data-stores.md) for endpoints)
- If disabling alerts before a backfill of `cj_report` or `cj_commission` tables, coordinate with the team to disable the `CjReportProcessingJob` and `CjCommissionsJob` alerts before starting

## Troubleshooting

### No CJ orders received from MBUS

- **Symptoms**: Alert fires: `AFL-3PGW No MBUS Orders Received` or `RealTime CJ Order Not being Sent for 2 Hrs`
- **Cause**: Upstream `afl-rta` is not publishing events, or MBUS topic is backed up; or AFL-3PGW is not consuming due to a configuration/connection issue
- **Resolution**:
  1. Check `afl-rta` attribution on the Wavefront dashboard (`https://groupon.wavefront.com/u/8CYT1qsf0h?t=groupon`)
  2. Check the MBUS dashboard (`https://mbus-dashboard.groupondev.com/`) for topic `jms.topic.afl_rta.attribution.orders`
  3. Search ELK index `filebeat-afl-3pgw_app--*` for exceptions/errors
  4. If ELK is inconclusive, check pod logs: `kubectl logs pod/<pod-name> -c main`

### Missing `topCategory` on order events causing processing failures

- **Symptoms**: `3PGW Exceptions Alert` fires; ELK shows exceptions in `OrdersMessageHandler`
- **Cause**: `afl-rta` could not fetch `topCategory` from MDS and published events without it; AFL-3PGW will not acknowledge these messages and they will expire
- **Resolution**: Contact the MDS team (`marketing-deal-service`) with the deal UUIDs missing `topCategory`; no AFL-3PGW action needed — events will expire from the topic

### Reconciliation discrepancy alert

- **Symptoms**: Alert fires: `CJ Reconciliation discrepancy compared with previous day`
- **Cause**: ReconciliationJob produced 400%+ more or fewer records compared to the previous day; may indicate a logic bug or upstream data anomaly
- **Resolution**:
  1. Check ELK for `ReconciliationJob` or `Exception` in `filebeat-afl-3pgw_app--*`
  2. Identify the failing query in `CorrectionDao`
  3. Review reconciliation logic at `ReconciliationJob.java:54`
  4. Do not assume this is expected — a similar logic error has occurred previously

### CjSubmitNewOrdersJob or CjCorrectionSubmissionJob not forwarding orders

- **Symptoms**: `Missing Orders not Forwarded to CJ in last 48 hours` or `Declined CJ orders not Forwarded to CJ` alert fires
- **Cause**: Corrections table has no new entries since the last checkpoint; Optimus import job may have failed
- **Resolution**:
  1. Check the `jobs` table for the relevant job's last-run checkpoint
  2. Check the `corrections` table for entries after the checkpoint
  3. Retrigger the relevant Optimus job (`AFL-3PGW-IMPORT-CJ-COMMISSIONS` or `AFL-3PGW-IMPORT-MA-CANCELLED-ORDERS`) at `https://optimus.groupondev.com/#/groups/Affiliate`
  4. Check ELK for errors in `CjSubmitNewOrdersJob` or `CjCorrectionSubmissionJob` classes

### SpotifySubmitOffersJob failure

- **Symptoms**: Alert fires: `SpotifySubmitOffersJob Job Not run in last 24 hrs`
- **Cause**: Connectivity issue between AFL-3PGW and Mailman service, or a configuration/code issue in the Spotify workflow
- **Resolution**:
  1. Check ELK logs for errors in the Spotify integration classes
  2. Verify Mailman service availability
  3. Review recent deployments or configuration changes
  4. Escalate per the [Spotify integration runbook](https://groupondev.atlassian.net/wiki/spaces/AM/pages/80775807090/Spotify)

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down / no orders reaching CJ for 12h | Immediate | gpn-alerts@groupon.com → PagerDuty PP9FGY1 |
| P2 | Degraded — batch jobs not running / corrections not submitted | 30 min | gpn-alerts@groupon.com |
| P3 | Minor impact — single job missed, non-critical alert | Next business day | gpn-dev@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| MBUS topic `jms.topic.afl_rta.attribution.orders` | MBUS dashboard at `mbus-dashboard.groupondev.com`; Wavefront alert on 0 events in 2h | No automatic fallback; batch reconciliation jobs provide eventual consistency for missed events |
| Commission Junction API | Wavefront CJ integration dashboard; 0-submission alerts | Retry via scheduled `CjSubmitNewOrdersJob` and `CjCorrectionSubmissionJob` |
| Awin API | Wavefront alerts for Awin job execution | Retry via scheduled Awin jobs |
| Orders Service | ELK exception monitoring | Event processing fails; MBUS message expires and may be recovered via reconciliation |
| Marketing Deal Service (MDS) | ELK exception monitoring; `3PGW Exceptions Alert` | Event processing fails; contact MDS team for missing `topCategory` values |
| MySQL (`afl_3pgw_production`) | Pod readiness/liveness probe implicitly validates DB connectivity | Service will not start if DB is unreachable at boot |

## Log Access

| Environment | ELK Index | Kibana URL |
|-------------|----------|------------|
| Staging / Pre-production | `filebeat-afl-3pgw_app--*` | `https://stable-kibana-unified.us-central1.logging.stable.gcp.groupondev.com/` |
| Production US | `filebeat-afl-3pgw_app--*` | `https://prod-kibana-unified.us-central1.logging.prod.gcp.groupondev.com/` |
| Production INT (EMEA) | `filebeat-afl-3pgw_app--*` | `https://prod-kibana-unified-eu.logging.prod.gcp.groupondev.com/` |

Filter hints:
- Use `groupon.region` to filter US vs. EMEA
- Use `groupon.source` to filter staging vs. production
- Search `exception or error` to find issues
- Use `data.name` field to filter by structured event name
