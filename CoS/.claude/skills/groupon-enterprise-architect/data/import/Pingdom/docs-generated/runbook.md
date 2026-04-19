---
service: "pingdom"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `https://status.pingdom.com/` | External status page (manual check) | On demand | Not applicable |
| PagerDuty service `P45XDA0` | PagerDuty alert | Triggered by Pingdom SaaS | Not applicable |

The `.service.yml` explicitly disables the standard Groupon status endpoint (`status_endpoint: disabled: true`). There is no HTTP health endpoint for this service.

## Monitoring

### Metrics

> No evidence found in codebase. No application metrics are emitted by this service. Uptime metrics for monitored Groupon services are collected and stored by `ein_project` in the `pingdom_logs` database table.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Pingdom Status | Pingdom SaaS | https://status.pingdom.com/ |
| Pingdom Checks | Pingdom SaaS | https://my.pingdom.com/app/newchecks/checks |
| Owners Manual | Confluence | https://confluence.groupondev.com/display/GSOC/Pingdom |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| PagerDuty `P45XDA0` | Triggered by Pingdom SaaS when a monitored check enters down/unconfirmed state | Critical | Page on-call via `pingdom@groupon.com`; review check results at `https://my.pingdom.com/app/newchecks/checks` |
| JSM uptime alert | Services with `no_latency_uptime` below `UPTIME_ALERT_THRESHOLD` (default 99%) for the previous day | P3 | Assigned to IMOC team; review affected tags in ProdCAT portal |
| IMOC Google Chat shift report | Monitors flapping >5 times, downtime >5 minutes, or avg response >4 seconds in the last 4 hours | Informational | Review in IMOC Pingdom Shift Reports space; escalate to owning team |

## Common Operations

### Restart Service

> Not applicable. There is no deployable application runtime for this service. To re-trigger data collection, use the `ein_project` management command:
> ```
> python manage.py collect_pingdom_data --days 1
> ```

### Scale Up / Down

> Not applicable. No application runtime exists to scale.

### Database Operations

> Not applicable. This service owns no data stores. For `pingdom_logs` table maintenance, see the `ein_project` runbook. The `cleanup_old_pingdom_data` Django management command in `ein_project` handles removal of stale uptime records.

## Troubleshooting

### No uptime data available for yesterday

- **Symptoms**: `ein_project` `trigger_uptime_alert` returns `status: "skipped"` with message `"No data available for <date> yet — waiting for sync to complete"`
- **Cause**: The `add_pingdom_uptimes` daily collection task has not yet completed for yesterday, or it failed silently
- **Resolution**: Run `python manage.py collect_pingdom_data --start-date YYYY-MM-DD --end-date YYYY-MM-DD` manually. Check `ein_project` logs for Pingdom API errors (HTTP 429 rate limiting or connection failures).

### Pingdom API rate limit exceeded

- **Symptoms**: `ein_project` logs show `"No uptime data returned from Pingdom API for check <id> on <date> (may be rate limited or no data)"`
- **Cause**: Pingdom API HTTP 429 returned; the `toolbox.modules.pingdom.PD` client's exponential backoff was exhausted
- **Resolution**: Reduce the number of tags in the `pingdom_tags` Setting, or increase the `batch_delay` parameter in `add_pingdom_uptimes`. Re-run collection for the affected date range once rate limit window resets.

### Shift report not posted to Google Chat

- **Symptoms**: No message appears in the IMOC Pingdom Shift Reports Google Chat space after the scheduled cron window
- **Cause**: The `tdo-team` pingdom-shift-report cron job failed or exceeded `activeDeadlineSeconds` (1500s)
- **Resolution**: Check Kubernetes pod logs for the `pingdom-shift-report` CronJob in the `tdo-team` namespace. Verify Pingdom API credentials (`PINGDOM_API_KEY`, `PINGDOM_AUTHORIZATION_KEY`) are current. Re-run the script manually: `./cronjobs/pingdom-shift-report.sh`

### PagerDuty alert not routing correctly

- **Symptoms**: Pingdom triggers a check failure but no page is received
- **Cause**: PagerDuty service `P45XDA0` may be in maintenance mode, or the notification rules for `pingdom@groupon.com` need updating
- **Resolution**: Check PagerDuty service `P45XDA0` at `https://groupon.pagerduty.com/services/P45XDA0`. Verify escalation policies and on-call schedules. Raise a ticket at `https://ops-request.groupondev.com/`.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Pingdom checks failing across multiple critical services; production down | Immediate | pingdom@groupon.com + PagerDuty P45XDA0 |
| P2 | Uptime alerts firing for one or more services below 99% threshold | 30 min | IMOC team via JSM alert; Slack CDVLKLM4K |
| P3 | Shift report missing or uptime data collection gap | Next business day | pingdom@groupon.com; ops-request.groupondev.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Pingdom SaaS API (`https://api.pingdom.com/api/2.1`) | Check `https://status.pingdom.com/` for platform status | Data collection skipped; `ein_project` logs warnings; no historical data gap filled automatically |
| JSM (Jira Service Management) | Check JSM service health via Atlassian status page | `ein_project` logs `notification_failures`; alerts are not sent; re-trigger manually after JSM recovers |
| Google Chat webhooks | Attempt a test POST to webhook URL | Shift report is lost for that run; no retry mechanism; re-run cron script manually |
