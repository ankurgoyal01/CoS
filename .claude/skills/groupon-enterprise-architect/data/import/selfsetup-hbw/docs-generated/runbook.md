---
service: "selfsetup-hbw"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/heartbeat.txt` | http GET | Managed by EKS liveness probe | > Not evidenced in inventory |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request count | counter | Number of inbound requests processed by `ssuMetricsReporter` via `influxdb-php` | > Not evidenced in inventory |
| HTTP response latency | histogram | Request duration emitted to Telegraf by `ssuMetricsReporter` | > Not evidenced in inventory |
| Cron job execution count | counter | Count of reminder and DWH reconciliation cron executions | > Not evidenced in inventory |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| selfsetup-hbw metrics | InfluxDB / Grafana (via Telegraf) | > Not evidenced in inventory |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Liveness probe failure | `/heartbeat.txt` returns non-200 | critical | Restart pod via EKS; investigate Apache/PHP error logs in Splunk |
| Salesforce integration error spike | Elevated 5xx from `/api/opportunity` or `/sf` | warning | Check Salesforce service status; verify `SALESFORCE_*` credentials are valid; check Splunk logs |
| BookingTool API error spike | Elevated errors from BookingTool push step | warning | Check BookingTool API status; verify `BOOKINGTOOL_CREDENTIALS`; check Splunk logs |

## Common Operations

### Restart Service

1. Access the EKS cluster for the target environment (`dub1` for production, `snc1` for staging)
2. Identify the `selfsetup-hbw` deployment
3. Perform a rolling restart: `kubectl rollout restart deployment/selfsetup-hbw -n <namespace>`
4. Monitor pod readiness and confirm `/heartbeat.txt` returns 200

### Scale Up / Down

> Operational procedures to be defined by service owner. Scaling is managed via DeployBot 2 or direct EKS `kubectl scale` commands targeting the `selfsetup-hbw` deployment.

### Database Operations

> Operational procedures to be defined by service owner. The `continuumSsuDatabase` MySQL instance is accessed via the `ssuPersistence` component credentials. No migration tooling is evidenced in the inventory — schema changes are applied manually or via Capistrano deploy hooks.

## Troubleshooting

### Merchant Cannot Access Setup Wizard

- **Symptoms**: Merchant reports blank page or error on landing at `/` or `/front`
- **Cause**: Expired or invalid Salesforce invitation token; Salesforce API unreachable; PHP/Apache pod not running
- **Resolution**: Check `/heartbeat.txt`; check Salesforce service status; review Splunk logs tagged to the merchant's session; verify `SALESFORCE_*` env vars are set correctly in the pod

### Setup Submission Fails (Salesforce push)

- **Symptoms**: Merchant completes wizard but receives error on final submit (`/sf`)
- **Cause**: Salesforce API timeout or auth failure; MySQL write failure
- **Resolution**: Check Splunk logs for the failing request; verify OAuth token is being refreshed; confirm MySQL connectivity from the pod; retry the submission

### Setup Submission Fails (BookingTool push)

- **Symptoms**: Salesforce update succeeds but BookingTool availability/capping is not updated
- **Cause**: BookingTool API unavailable; incorrect per-country endpoint; invalid `BOOKINGTOOL_CREDENTIALS`
- **Resolution**: Check Splunk logs for HTTP 4xx/5xx from `selfsetupHbw_ssuBookingToolClient`; verify `BOOKINGTOOL_CREDENTIALS` secret; confirm BookingTool API is healthy for the affected country endpoint

### Cron Jobs Not Running

- **Symptoms**: Reminder emails not sent; DWH reconciliation records missing
- **Cause**: Cron job container not scheduled; MySQL job queue stuck
- **Resolution**: Confirm cron pod is running in EKS; check Splunk logs for cron execution; inspect MySQL job queue table for stuck or failed entries

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down — merchants cannot complete setup | Immediate | International Booking-tool team (booking-tool-engineers@groupon.com) |
| P2 | Degraded — setup wizard errors for subset of locales or countries | 30 min | International Booking-tool team |
| P3 | Minor — cron jobs delayed; metrics/logging degraded | Next business day | International Booking-tool team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Salesforce | Check Salesforce status page; test OAuth token acquisition manually | No fallback — merchant setup cannot proceed without Salesforce |
| BookingTool API | Check per-country endpoint with `BOOKINGTOOL_CREDENTIALS` | Configuration is persisted in MySQL; retry push when API recovers |
| `continuumSsuDatabase` | Check MySQL connectivity from pod | No fallback — session and queue state unavailable |
| Telegraf / InfluxDB | Check Telegraf pod status | Metrics loss only; no merchant impact |
| Log Aggregation (Splunk) | Check Splunk HEC connectivity | Log loss only; no merchant impact |
