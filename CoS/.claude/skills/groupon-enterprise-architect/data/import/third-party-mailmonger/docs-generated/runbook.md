---
service: "third-party-mailmonger"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/status` (port 8080) | http | Default JTier interval | (status_endpoint.disabled: true in .service.yml — check via admin port) |
| Dropwizard admin healthcheck (port 8081) | http | Default JTier interval | JTier default |

> Note: The `status_endpoint` is marked `disabled: true` in `.service.yml`. Health verification in cloud environments should use `kubectl get pods` and Kubernetes liveness/readiness probes managed by the JTier base image.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `jtier/POST/mailmonger/v1/sparkpost-callback/status` | counter | HTTP response status codes for the SparkPost relay webhook | Non-2xx status triggers alert |
| `jtier/POST/mailmonger/v1/sparkpost-callback` | histogram | Response time for the SparkPost relay webhook | TP99 > 5000ms triggers alert |
| `jtier/POST/mailmonger/v1/sparkpost-event/status` | counter | HTTP response status codes for the debug SparkPost event endpoint | Non-2xx status triggers alert |
| `jtier/GET/v1/masked/consumer/request/status` | counter | HTTP response status codes for the masked email endpoint | Non-2xx status triggers alert |
| `jtier/GET/v1/masked/consumer` | histogram | Response time for masked email endpoint | TP99 > 100ms triggers alert |
| `jtier/POST/v1/partner/request/status` | counter | HTTP response status codes for the partner email endpoint | Non-2xx status triggers alert |
| MessageBus queue depth (`jms.queue.3pip.mailmonger`) | gauge | Number of messages pending processing | High depth triggers alert |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Mailmonger Application (on-prem production) | Wavefront | https://groupon.wavefront.com/dashboard/mail-monger |
| Mailmonger SMA (cloud) | Wavefront | https://groupon.wavefront.com/dashboards/third-party-mailmonger--sma |
| Mailmonger System Metrics | Wavefront | https://groupon.wavefront.com/u/KdZPrhKTqx?t=groupon |
| Mailmonger Hosts (on-prem) | Wavefront | https://groupon.wavefront.com/dashboard/mail-monger-hosts |
| Mailmonger Staging (on-prem) | Wavefront | https://groupon.wavefront.com/dashboard/snc1-mailmonger-staging |
| MessageBus Queue Graph | mbus-dashboard | https://mbus-dashboard.groupondev.com/graph.py?host=prod-snc1-mbus18.snc1&subscription=jms.queue.3pip.mailmonger&view=aggregated |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| `jtier/POST/mailmonger/v1/sparkpost-callback/status/xxx` | Inbound relay webhook returning non-2xx | 4 | Check Kibana/Splunk `sourcetype=mailmonger`; check DB for data issues; monitor dashboards |
| `jtier/POST/mailmonger/v1/sparkpost-callback` (latency) | Relay webhook response time above threshold | 4 | Check Kibana for errors; check DB latency; check SparkPost status at status.sparkpost.com |
| `jtier/GET/v1/masked/consumer/request/status/xxx` | Masked email endpoint returning non-2xx | 4 | Check Kibana for errors; check DB; this blocks checkout if down |
| `jtier/POST/v1/partner/request/status/xxx` | Partner email endpoint returning non-2xx | 4 | Check Kibana for errors; check DB |
| MessageBus queue depth / latency | Queue depth growing or response time high | 4 | Check Kibana; check mbus graphs; engage MessageBus team if needed |
| `jtier/POST/mailmonger/v1/sparkpost-event/status/xxx` | Debug event endpoint non-2xx | 5 | Informational; check Kibana |

Alert configurations: https://github.groupondev.com/AINT/metrics-configuration/blob/master/alerts/mailmonger.json

PagerDuty service: https://groupon.pagerduty.com/services/P8X27XH

OpsGenie: https://groupondev.app.opsgenie.com/service/9c40a26b-d4b8-4eb0-9f7b-b6a77678f301

## Common Operations

### Restart Service (Cloud)

```bash
# View pods
kubectl config use-context third-party-mailmonger-staging-us-west-1
kubectl get pods

# Restart by scaling down and up
kubectl scale --replicas=0 deployment <deployment_name>
kubectl scale --replicas=<expected> deployment <deployment_name>

# Or: authenticate and view logs first
kubectl cloud-elevator auth
kubectl logs <pod-name> main
```

### Restart Service (On-Prem)

```bash
sudo sv start jtier
```

### Scale Up / Down (Cloud)

```bash
kubectl scale --replicas=<expected_replica_num> deployment <deployment_name>
```

Alternatively, use DeployBot UI to trigger a redeployment with updated replica counts.

### Manually Retry a Failed Email

Call the retry endpoint with the emailContentId UUID:

```
POST /v1/email/{emailContentId}/retry
```

This re-queues the email for processing via the Quartz scheduler.

### Database Operations

- Schema migrations are managed by JTier DaaS migration tooling and `jtier-quartz-postgres-migrations`
- Migrations run automatically on application startup
- For manual DB inspection: connect to `prod-third-pt-mm-rw-vip.us.daas.grpn` database `third_pt_mm_prod` (requires DaaS access credentials)
- Quartz job state is stored in standard Quartz tables; do not manually edit without understanding Quartz internals

## Troubleshooting

### SparkPost callback endpoint is returning errors

- **Symptoms**: Nagios/Wavefront alert `jtier/POST/mailmonger/v1/sparkpost-callback/status/xxx` fires; inbound emails are not being received
- **Cause**: Application error in parsing relay message, database write failure, or application restart
- **Resolution**: Check Kibana `sourcetype=mailmonger` for stack traces; check PostgreSQL connectivity; check pod health with `kubectl get pods`; check SparkPost relay webhook configuration at app.sparkpost.com

### Masked email endpoint is slow or returning errors

- **Symptoms**: TPIS failing to get masked emails; checkout may be impacted
- **Cause**: Database latency spike, application overload, or users-service unavailability
- **Resolution**: Check DB latency in Wavefront; check users-service health; check pod CPU/memory usage; consider scaling up replicas

### MessageBus queue depth is growing

- **Symptoms**: Wavefront alert for queue depth; emails are being received but not processed
- **Cause**: Consumer threads stalled, application crash, or downstream dependency (SparkPost/MTA) unavailable
- **Resolution**: Check Kibana for MessageBus consumer errors; verify pod health; verify SparkPost status; check MTA connectivity; engage MessageBus team if broker is unhealthy

### Emails stuck in Pending status

- **Symptoms**: Email records in DB remain in `Pending` status for extended period
- **Cause**: MessageBus consumer is not processing; MAX_SEND_LIMIT not reached but delivery not succeeding
- **Resolution**: Check MessageBus queue; check email content in DB for malformed data; use retry endpoint `POST /v1/email/{emailContentId}/retry`

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no masked emails served, checkout broken | Immediate | Mailmonger team (PagerDuty: mailmonger-alert@groupon.pagerduty.com) |
| P2 | Degraded — emails backed up in queue or slow masked email response | 30 min | Mailmonger team |
| P3 | Minor impact — debug endpoint errors, non-critical alerts | Next business day | Mailmonger team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| SparkPost | Check status.sparkpost.com; check Kibana for SparkPost SDK errors | Switch `emailClientType` to MTA if configured |
| users-service | Check https://services.groupondev.com/services/users-service | Emails cannot be sent without user email resolution; retry up to MAX_SEND_LIMIT |
| PostgreSQL (DaaS) | Check DaaS VIP connectivity; check pool metrics in Wavefront | No fallback — service is stateful; reads and writes will fail |
| MessageBus | Check mbus-dashboard.groupondev.com; check broker pod health | Inbound emails saved to DB but not processed until queue recovers |

## Logging

Cloud environment logs are available in Kibana:

- Staging US-West-1: https://logging-stable-unified01.grpn-logging-stable.us-west-2.aws.groupondev.com/goto/739288f8c0044fb2cba7c6f37284d2e5
- Production US-West-1: https://logging-prod-us-unified1.grpn-logging-prod.us-west-2.aws.groupondev.com/goto/739288f8c0044fb2cba7c6f37284d2e5

On-prem: Splunk `sourcetype=mailmonger`

Steno source type: `mailmonger` (set via `stenoSourceType` in common deployment config).
