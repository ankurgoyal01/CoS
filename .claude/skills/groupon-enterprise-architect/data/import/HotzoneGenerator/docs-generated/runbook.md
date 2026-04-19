---
service: "HotzoneGenerator"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Cron job exit code (0 = success, non-zero = failure) | exec | Daily at 22:00 UTC | Duration of the batch run |
| Log output: "Job completed successfully" | log check | Per run | N/A |
| Log output: "Job Failed" | log check | Per run | N/A |

> There is no HTTP health endpoint. The job is a one-shot batch process; health is determined by the job completing without calling `System.exit(1)` and emitting "Job completed successfully" in the Steno log.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `generatedCount` | counter | Total hotzones successfully inserted per run (logged via Steno) | No evidence of configured alert threshold |
| `successCount` / `ofPossible` | counter | Hotzones accepted vs. attempted in the Proximity API insert response | No evidence of configured alert threshold |
| `expiredCount` | counter | Number of expired hotzones deleted at start of run | No evidence of configured alert threshold |
| `deleteSendLogCount` | counter | Number of send logs deleted at start of run | No evidence of configured alert threshold |
| `invalidRedemptionLocations` | counter | Redemption locations skipped due to missing open hours | No evidence of configured alert threshold |

### Dashboards

> No evidence found in codebase. Dashboard configuration is not present in the repository.

### Alerts

> No evidence found in codebase. Alert configuration is not present in the repository.

## Common Operations

### Restart Service
This is a cron-triggered batch job. To trigger a manual run:
1. SSH to the appropriate host as `svc_emerging_channel` (or with sudo access).
2. Execute the run script directly:
   ```
   /var/groupon/HotzoneGenerator/run_job
   ```
   Or invoke the jar directly:
   ```
   /usr/local/bin/java -Dcustom.logpath=/var/groupon/log/HotzoneGenerator \
     -jar /var/groupon/HotzoneGenerator/HotzoneGenerator-<version>-jar-with-dependencies.jar \
     production config
   ```

### Re-run with specific flags
Available third argument flags:
- (none) — normal run, auto-campaign generation only runs on Tuesdays
- `createAuto` — forces auto-category campaign generation regardless of day
- `cleanAutoOnly` — deletes all auto-generated campaigns without generating hotzones
- `stats` — outputs `locations_without_hours.txt` and logs inventory service ID distribution

### Restore cron after host roll
If a host is rolled, the cron job must be re-installed:
```
# For NA
cap production crontab

# For EMEA
cap production_emea crontab
```

### Scale Up / Down
> Not applicable. This is a single-instance batch job on a VM. No scaling mechanism.

### Database Operations
The only direct DB operation is a read via JDBC in `weekly_email` run mode:
- The query retrieves consumer UUIDs from the Proximity DB.
- Connection string: `jdbc:postgresql://{postgres.host}/{postgres.database}`.
- Credentials sourced from `postgres.app.user` / `postgres.app.pass` properties.

To inspect hotzone data in the database:
```sql
SELECT count(*), cat_name, audience_id, time_window
FROM proximityindexer.hot_zone_deals
GROUP BY cat_name, audience_id, time_window;
```

## Troubleshooting

### Job exits with code 1 mid-run
- **Symptoms**: Log contains "Job Failed" or "Deleting expired hotzones from db failed" or "Updating hotzone failed".
- **Cause**: A critical HTTP call to the Proximity Notifications API failed.
- **Resolution**: Check Proximity Notifications API health. Verify `proximity.url` is reachable from the host. Re-run the job after Proximity API recovery.

### Zero hotzones generated
- **Symptoms**: Log shows `generatedCount=0` or empty hotzone list.
- **Cause**: MDS returned no qualifying deals, all active configs are filtered out, or `proximity.enabled=false`.
- **Resolution**: Verify MDS is reachable and returning deals for the configured category/country. Check campaign configs via `GET hotzone/campaign?client_id=ec-team`. Confirm `proximity.enabled=true` in the active properties file.

### Cron job not running
- **Symptoms**: No log entries at expected 22:00 UTC time.
- **Cause**: Host was rolled and crontab was not reinstalled, or the cron entry was removed.
- **Resolution**: SSH to the production host and run `cap production crontab` (NA) or `cap production_emea crontab` (EMEA) to reinstall the cron entries.

### Auto-campaigns not being created
- **Symptoms**: No new campaigns on Tuesdays; deal-cluster call failing.
- **Cause**: Deal Clusters API (via API Proxy) is unreachable, or deal-cluster endpoint returns empty/null results.
- **Resolution**: Check `dealClusters.url` endpoint health. Verify `dealClusters.clientId` is still valid. Review logs for "Getting trending categories from deal clusters failed".

### Weekly emails not sending
- **Symptoms**: No emails sent after Friday `weekly_email_run_job`.
- **Cause**: Proximity DB unreachable (JDBC connection failure), or Proximity `send-email` endpoint returning errors.
- **Resolution**: Verify `postgres.host` and `postgres.database` settings. Test JDBC connectivity from host. Check Proximity API `send-email` endpoint health.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | No hotzones generated for an entire day; proximity notifications failing | Immediate | Emerging Channels team |
| P2 | Auto-campaign generation failing; degraded hotzone coverage for some categories | 30 min | Emerging Channels team |
| P3 | Weekly email run failing; individual category degraded | Next business day | Emerging Channels team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Proximity Notifications API | `GET hotzone/campaign?client_id=ec-team` returns HTTP 200 | None — critical failure causes `System.exit(1)` |
| Marketing Deal Service (MDS) | `GET deals.json?country=US&size=1&channel=g1&client=ecteam` returns HTTP 200 | Per-country/division errors are logged and skipped |
| Taxonomy Service v2 | `GET categories/{anyGuid}` returns HTTP 200 | Empty string used as fallback category name |
| Internal API Proxy (GAPI) | `GET /v2/deals/{uuid}?show=options(redemptionLocations)` returns HTTP 200 | Deals without open hours are skipped when `useOpenHours=true` |
| Deal Catalog Service | `GET deal_catalog/v2/deals/{uuid}` returns HTTP 200 | Exceptions bubble up as stack traces in deal enrichment |
| Proximity PostgreSQL | JDBC connection test | Returns empty consumer list; no emails sent |
