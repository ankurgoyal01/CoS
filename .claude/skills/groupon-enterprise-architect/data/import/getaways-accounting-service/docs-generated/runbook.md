---
service: "getaways-accounting-service"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/grpn/status` (port 8080) | http | Kubernetes liveness/readiness probe | Per cluster default |
| Dropwizard health checks (port 8081) | http | Continuous | — |
| Heartbeat file (`/var/groupon/jtier/heartbeat.txt`) | exec (file check) | 5 seconds | — |
| TIS PostgreSQL connection pool | jdbc | On startup and continuous | Per pool config |

**Admin health endpoint**: `http://{host}:8081/healthcheck`

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `financeResource.get` | timer | Timed metric for `GET /v1/finance` requests | Operational procedures to be defined by service owner. |
| `reservationsSearchResource.get` | timer | Timed metric for `GET /v1/reservations/search` requests | Operational procedures to be defined by service owner. |
| JVM heap / GC metrics | gauge/counter | Standard JVM metrics via Codahale Metrics | Operational procedures to be defined by service owner. |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| GAS SMA Dashboard | Wavefront | https://groupon.wavefront.com/dashboards/getaways-accounting-service--sma |
| GAS Custom Dashboard | Wavefront | https://groupon.wavefront.com/u/sqRBl1GWs4?t=groupon |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| PagerDuty service PN688R9 | On-call alert for critical failures | critical | Escalate to getaways-gas-alerts@groupon.com; check Wavefront dashboard and Splunk logs |
| CSV generation failure | CSV cron-job pod exits with non-zero code | critical | Check pod logs; verify TIS DB connectivity; verify SFTP server reachability; re-trigger `POST /tasks/createcsv` manually |
| SFTP upload failure | File upload or validation error in cron-job logs | critical | Verify SFTP credentials (`SFTP_*` secrets); check remote SFTP server; retry manually |

**Slack channel**: `CF9BSJ5GX`
**PagerDuty**: https://groupon.pagerduty.com/services/PN688R9

## Common Operations

### Restart Service
- The service is managed by Kubernetes. To restart a pod, use `kubectl rollout restart deployment/getaways-accounting-service -n getaways-accounting-service-production-sox`.
- Ensure the new pod passes its health check before the old one terminates.

### Scale Up / Down
- Scaling is managed via HPA. To manually override: `kubectl scale deployment getaways-accounting-service --replicas=N -n getaways-accounting-service-production-sox`.
- Production: configured min 2 / max 7; staging: min 1 / max 2.

### Manually Re-trigger CSV Generation
CSV generation is normally triggered by the daily cron-job at 00:20 UTC. To manually run:
1. Invoke the Dropwizard admin task on any active pod:
   ```
   curl -X POST "http://{pod-host}:8081/tasks/createcsv?type=all&date=YYYY-MM-DD&upload=true"
   ```
2. Monitor logs for CSV build, MD5 generation, SFTP upload, and validation steps.
3. Verify the generated file on the SFTP remote folder.

**Note**: The `csvJobScheduler.activeHost` config ensures only the pod whose hostname matches `activeHost` (set to `${HOSTNAME}`) actually executes the task. For the cron-job component, the pod hostname is used directly.

### Database Operations
The service does not own or migrate the TIS PostgreSQL database. All DDL changes are managed by the Travel Itinerary Service team. GAS only reads from the `reservations` and `reservations_id_to_iuid_mapping` tables.

## Troubleshooting

### CSV File Not Generated / Uploaded
- **Symptoms**: No CSV file on SFTP remote for expected date; cron-job pod logs show errors.
- **Cause**: TIS database connectivity failure, SFTP authentication failure, or `isActiveHost` check returning false (wrong hostname in config).
- **Resolution**: Check `TISPOSTGRES_*` secrets and database host reachability. Check `SFTP_*` secrets and SFTP server status. Verify `csvJobScheduler.activeHost` matches the pod hostname. Re-trigger manually via the admin task.

### CSV Missing `Inventory_Product_UUID` in Custom Data Column
- **Symptoms**: Log messages at `ERROR` level: `"DetailLine missing 'Inventory_Product_UUID' in customData"`. Accounting downstream reports data quality issues.
- **Cause**: Reservation records in TIS PostgreSQL are missing the inventory product UUID field in the JSON blob.
- **Resolution**: Identify booking numbers from the log message (`bookingNumber` field). Escalate to Getaways Engineering for investigation of the source reservation data.

### `GET /v1/finance` Returns Empty Results
- **Symptoms**: Caller receives empty map for known booking record locators.
- **Cause**: The record locators are either not yet committed in TIS (must have `commitsucceeded=true` and a non-null `commitupdatedat`), or the booking IDs passed in the query are incorrect.
- **Resolution**: Verify the record locators via direct TIS database query. Confirm booking commit status.

### `GET /v1/reservations/search` Returns Unexpected Count
- **Symptoms**: Fewer or more results than expected for a date range.
- **Cause**: The date-range query logic combines `cancelledat`, `commitupdatedat`, and `reservedat` columns. Results differ from Backpack because TIS updates `updated_at` on survey responses — GAS uses distinct date columns to avoid over-counting.
- **Resolution**: Review the SQL query in `ReservationDAO` for the expected date semantics. Confirm the date range and timezone of the request.

### SFTP File Integrity Failure (`FileIntegrityException`)
- **Symptoms**: CSV upload succeeds but validation throws `FileIntegrityException`.
- **Cause**: MD5 checksum of locally generated file does not match the file downloaded from SFTP remote after upload.
- **Resolution**: Check for network corruption or partial upload. Retry the upload. If the issue persists, check SFTP server disk and permissions.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down / CSV not delivered | Immediate | getaways-gas-alerts@groupon.com, PagerDuty PN688R9, Slack CF9BSJ5GX |
| P2 | API degraded / slow responses | 30 min | getaways-eng@groupon.com, Slack CF9BSJ5GX |
| P3 | Minor data quality issue | Next business day | getaways-eng@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| TIS PostgreSQL | Dropwizard health check registry (connection pool) | No fallback — API endpoints and CSV generation fail immediately |
| Content Service | Synchronous Retrofit HTTP call during CSV summary generation | No fallback — `HotelNotFound` exception thrown; CSV generation may partially fail |
| SFTP Accounting Server | Post-upload CSV Validator downloads and verifies file | No fallback — `FileIntegrityException` raised; alert fires |
