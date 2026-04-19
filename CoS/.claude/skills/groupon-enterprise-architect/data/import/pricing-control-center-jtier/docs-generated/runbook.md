---
service: "pricing-control-center-jtier"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /heartbeat.txt` on port 8080 | HTTP | Kubernetes liveness/readiness default | Default |
| `GET /grpn/healthcheck` on admin port 8081 | HTTP | On-demand | Default |
| ELK watchers on Kibana | Log-based alerts | Per watcher schedule (5 min – 30 min) | N/A |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| JVM heap usage | gauge | Heap consumed vs HEAP_SIZE; OOM risk if approaching limit | Alert via CloudSRE |
| Quartz trigger error state | gauge | Count of triggers in ERROR state; visible at `GET /quartz/error-state` | Any ERROR trigger |
| `custom_ils_sync_job_failure_error` | log-based | `CustomILSFluxModelSyncJob` consecutive failures over 4-hour window | 4+ hours without success |
| `pricing_control_center_jtier_customilsfetchdealoptions_error` | log-based | `CustomILSFetchDealOptionsJob` error log events | Any error within 5 minutes |
| `SelloutProgramCreatorJob` execution | log-based | Sellout flux file processing status | Failure triggers engineering alert |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| SMA / HTTP metrics | Wavefront | `https://groupon.wavefront.com/dashboards/pricing-control-center-jtier--sma` |
| Custom operational dashboard | Wavefront | `https://groupon.wavefront.com/u/MyNfhGwP9F?t=groupon` |
| Production Kibana logs | Kibana | `https://prod-kibana-unified.us-central1.logging.prod.gcp.groupondev.com/app/r/s/DC7E5` |
| Production application logs | Kibana | Index `us-*:filebeat-pricing_control_center_jtier--*` |
| Staging Kibana logs | Kibana | `https://stable-kibana-unified.us-central1.logging.stable.gcp.groupondev.com/app/r/s/A94md` |

Log retention in Kibana: 12 days. Logs are SOX-restricted — developers cannot access hosts directly.

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Custom ILS sync job failure | No successful `CustomILSFluxModelSyncJob` execution in 4 hours | warning | Check Kibana for transient errors; wait 1–2 hours for self-recovery; verify Hive table `grp_gdoop_local_ds_db.ils_flux_model_schedule_view` |
| CustomILSFetchDealOptionsJob error | Error log from `CustomILSFetchDealOptionsJob` within 5-minute window | critical | Investigate Kibana; if sale status is `FETCHING_DEAL_OPTIONS`, reset to `NEW` via `POST /sales/{id}/status/NEW` to allow retry |
| Quartz trigger in ERROR state | `GET /quartz/error-state` returns non-empty list | warning | Use `POST /quartz/{trigger}/state/WAITING` to resume; investigate root cause in Kibana |
| OOM / pod kill | Kubernetes OOM events | critical | Check `kubectl get events --sort-by=.metadata.creationTimestamp | grep <pod_name>`; consider increasing `HEAP_SIZE` or memory limit |

All application-level alerts are configured as ELK watchers in `github.groupondev.com/logging/watch-execution/tree/main/watches/pricing-control-center-jtier`. OpsGenie: `https://groupondev.app.opsgenie.com/service/4b1b4ff7-7e80-4634-b2a2-9b8498e5ffa5`. Emergency contact: `pricing-service@groupondev.opsgenie.net`.

## Common Operations

### Restart Service

```sh
# On-prem (legacy runit):
ssh <host>
sudo /usr/local/bin/sv stop jtier
sudo /usr/local/bin/sv start jtier

# Cloud (Kubernetes): redeploy via Deploybot or kubectl rollout restart
kubectl rollout restart deployment/pricing-control-center-jtier -n pricing-control-center-jtier-production-sox
```

### Scale Up / Down

Scaling is managed via Deploybot/Kubernetes. Adjust `minReplicas`/`maxReplicas` in `.meta/deployment/cloud/components/app/production-us-central1.yml` and redeploy. The HPA target is 100% CPU utilization.

### Take Instance Out-of-Rotation (OOR)

```sh
ssh <host>
sudo rm -f /var/groupon/jtier/heartbeat.txt
```

### Restore Instance to Rotation

```sh
ssh <host>
sudo touch /var/groupon/jtier/heartbeat.txt
```

### Interrupt All Running Tasks (Emergency Stop)

```sh
# Stops all currently executing Quartz sub-jobs by setting task status to PAUSE
POST http://<host>:8080/tasks/interrupt
```

### Manually Recover Stuck Sale

```sh
# Reset a stuck sale to NEW for re-processing
POST http://<host>:8080/sales/{sale_id}/status/NEW
Header: user-email: <your-email>
Header: authn-token: <your-token>

# Or trigger the built-in retry logic asynchronously
POST http://<host>:8080/sales/{sale_id}/retry
```

### Grant / Revoke User Access

```sh
# Grant access (SUPER role required)
POST http://<host>:8080/user
Content-Type: application/json
authn-token: <token>
Body: { "email": "user@groupon.com", "role": "IM", "channel": ["LOCAL_ILS"] }

# Add role via v1.0 API
POST http://<host>:8080/v1.0/roles
Content-Type: application/json
authn-token: <token>
Body: { "userEmail": "user@groupon.com", "role": "IMTL", "channel": ["GOODS"] }
```

SOX requirement: Screenshot `control_center_users` table before and after; attach to JIRA ticket; CC `dp-engg@groupon.com`.

### Database Operations

Schema migrations run automatically on startup via JTier migration bundle (Flyway). For manual investigation:
- Database is GDS-managed PostgreSQL in GCP; no direct host SSH access for developers.
- Use Kibana logs for query-level debugging.
- Backup and replication per GDS default policy.

### Changing Teradata Password

1. Ensure no analytics upload job is running (shut down the service or pause the `AnalyticsUploadJobTrigger`).
2. Update the password in Teradata via `https://grit.groupondev.com/tsst/ResetPasswordV2.jsp`.
3. Update the secret in the deployment configuration and redeploy.
4. Update the Optimus Teradata profile for group `Pricing_Operations` at `https://optimus.groupondev.com/#/groups/Pricing_Operations`.

## Troubleshooting

### CustomILSFetchDealOptionsJob stuck / Custom ILS sale not progressing

- **Symptoms**: Custom ILS sale has status `FETCHING_DEAL_OPTIONS` for more than 1 hour; `CustomILSFetchDealOptionsJob` error logs in Kibana
- **Cause**: Hive read timeout or no model output found for the sale's target date
- **Resolution**: Search Kibana for `CustomILSFetchDealOptionsJob.salePicked` to identify the affected sale ID. Check log lines for `targetStartDate could not be computed` or `Not able to get model output tables even after`. If transient, reset sale status to `NEW` via `POST /sales/{id}/status/NEW` so the next job run picks it up.

### CustomILSFluxModelSyncJob failure

- **Symptoms**: OpsGenie alert; `custom_ils_sync_job_failure_error` watcher fires
- **Cause**: Hive table `grp_gdoop_local_ds_db.ils_flux_model_schedule_view` is temporarily empty or read times out
- **Resolution**: Wait 1–2 hours for the hourly job to self-recover. If persisting, verify Hive table contents and compare with `custom_ils_flux_model` PostgreSQL table. Alert is idempotent; the job can be safely re-run.

### Quartz trigger in ERROR state

- **Symptoms**: `GET /quartz/error-state` returns one or more triggers
- **Cause**: Job threw an unhandled exception; Quartz marked the trigger as ERROR
- **Resolution**: Investigate root cause in Kibana. Use `POST /quartz/{trigger}/state/WAITING` to reset the trigger to the waiting state and allow the next scheduled fire.

### Sale stuck in SCHEDULING_STARTED or SCHEDULING_FAILED

- **Symptoms**: Sale does not progress to `SALE_SETUP_COMPLETE`; `CheckForPendingSalesJob` manages retry
- **Cause**: Sub-jobs hung or failed; network connectivity to Pricing Service or VIS lost
- **Resolution**: Check Kibana for `ILSSchedulingSubJob` errors. Use `POST /sales/{id}/retry` to trigger the `manageStuckSale` logic, or manually override status via `POST /sales/{id}/status/{status}`. Check Pricing Service health.

### OOM / Container killed

- **Symptoms**: Pod disappears; Kubernetes events show OOM kill
- **Cause**: JVM heap growth exceeds memory limit; typically during large ILS scheduling batches
- **Resolution**: `kubectl get events --sort-by=.metadata.creationTimestamp | grep <pod_name>`. Check Wavefront dashboard for heap trend. Increase `HEAP_SIZE` env var or memory limit via deployment config update.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no sales can be scheduled | Immediate | Dynamic Pricing Engineering (`dp-engg@groupon.com`) + OpsGenie `pricing-service@groupondev.opsgenie.net` |
| P2 | Degraded — Custom ILS or Sellout job failures | 30 min | Dynamic Pricing Engineering |
| P3 | Minor — single sale stuck, analytics upload delayed | Next business day | Dynamic Pricing Engineering |

The service is Criticality Tier 4 (T4). SOX compliance applies to production; all production changes require GPROD logbook ticket and team member approval.

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumPricingService` | Call `GET /pricehistory` with a known product; expect 200 | Scheduling jobs fail with `SCHEDULING_FAILED`; retry via `CheckForPendingSalesJob` |
| `continuumVoucherInventoryService` | Monitor sub-job logs for VIS call errors | Products set to `SCHEDULING_FAILED`; exclusion reason recorded |
| `continuumUsersService` | Monitor auth filter errors in Kibana | All authenticated requests return 401 |
| Hive Warehouse | Job logs; query `SELECT 1` via Hive CLI | Jobs fail with retry (up to 7 attempts); email alert sent |
| GCS bucket | `gcp.enabled` flag; check `RetailPriceOptimizationJob` logs | RPO job skips current cycle; version record set to error |
| PostgreSQL | `/grpn/healthcheck` endpoint | Service unable to serve any requests |
