---
service: "selfsetup-fd"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| > No evidence found of a dedicated health endpoint | > Operational procedures to be defined by service owner | — | — |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Application metrics via `influxdb-php` | gauge/counter | Emitted to `TELEGRAF_URL` (InfluxDB via Telegraf) | No evidence found of specific metric names or thresholds |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| > No evidence found | > Operational procedures to be defined by service owner | — |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| > No evidence found | > Operational procedures to be defined by service owner | — | — |

## Common Operations

### Restart Service

1. Identify the Kubernetes deployment for `selfsetup-fd` in the `dub1` or `snc1` cluster.
2. Run `kubectl rollout restart deployment/<selfsetup-fd-deployment-name> -n <namespace>`.
3. Monitor rollout with `kubectl rollout status deployment/<selfsetup-fd-deployment-name> -n <namespace>`.

### Scale Up / Down

1. Adjust the Kubernetes deployment replica count: `kubectl scale deployment/<selfsetup-fd-deployment-name> --replicas=<N> -n <namespace>`.
2. Alternatively, update the HPA configuration if autoscaling is configured.

### Database Operations

- MySQL database is `continuumEmeaBtSelfSetupFdDb`.
- Queue jobs can be inspected directly in the MySQL queue table to check for stuck or failed jobs.
- No migration tooling is evidenced in the inventory; schema changes to be coordinated with the International Booking-tool team (ssamantara).

## Troubleshooting

### Setup wizard fails to load opportunity data
- **Symptoms**: `/api/getopportunity` returns an error or empty response; employee sees no opportunity in the wizard
- **Cause**: Salesforce connectivity issue or OAuth token expiry in `selfsetupFd_ssuSalesforceClient`
- **Resolution**: Verify Salesforce credentials and OAuth token. Check `TELEGRAF_URL` metrics for error spikes. Inspect application logs via Monolog output.

### Queued BT setup jobs not being processed
- **Symptoms**: Jobs remain in pending state in the MySQL queue table; merchants not getting BT instances created
- **Cause**: Cron jobs (`ssuCronJobs`) not running, Salesforce merchant ID fetch failing, or Booking Tool API (`bookingToolSystem_7f1d`) unavailable
- **Resolution**: Verify cron schedule is active in the container. Check connectivity to Salesforce and Booking Tool System. Inspect MySQL queue table for job status and error fields.

### Application not responding on port 8080
- **Symptoms**: HTTP requests to the service time out; Kubernetes liveness/readiness probes failing
- **Cause**: Apache process crashed inside the container, or container is in CrashLoopBackOff
- **Resolution**: Check `kubectl logs` for the pod. Restart the deployment (see Restart Service above). Verify `APACHE_LISTEN_PORT=8080` is correctly set.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no employee can initiate F&D BT setups | Immediate | International Booking-tool team (ssamantara) |
| P2 | Degraded — async queue not processing; setups delayed | 30 min | International Booking-tool team (ssamantara) |
| P3 | Minor impact — metrics not flowing to Telegraf | Next business day | International Booking-tool team (ssamantara) |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `salesForce` | Attempt an authenticated SOQL query; verify HTTP 200 response | No fallback — setup wizard cannot proceed without opportunity data |
| `bookingToolSystem_7f1d` | Verify HTTPS connectivity to BT API base URL | No fallback — BT creation cannot proceed; jobs remain queued |
| `continuumEmeaBtSelfSetupFdDb` | Verify MySQL connection from within the container | No fallback — queue and session state unavailable; service non-functional |
| `telegrafGateway_6a2b` | Verify HTTP connectivity to `TELEGRAF_URL` | Non-critical — application continues to run; metrics gap only |
