---
service: "channel-manager-integrator-travelclick"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/grpn/status` (port 8080) | HTTP | Kubernetes probe | 60s (production) |
| Kubernetes readiness probe | HTTP | Every 5s (production) | 60s |
| Kubernetes liveness probe | HTTP | Every 15s (production) | 60s |
| Initial delay for probes | — | 60s delay before first probe | — |

> Note: The `.service.yml` marks the status endpoint as `disabled: true` for the service portal environment poller. Health checks are managed directly by Kubernetes probes.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| JVM heap utilization | gauge | JVM memory usage; max heap 2048m | OOM events trigger PagerDuty |
| MBus consumer lag | gauge | Number of unprocessed messages in reservation/cancellation topics | Alert when DLQ accumulates |
| TravelClick request latency | histogram | Outbound OTA XML call duration | Tracked via Wavefront dashboard |
| TravelClick error rate | counter | Count of non-success OTA XML responses | Tracked via Splunk alerts |
| Kafka producer errors | counter | ARI event publishing failures | Tracked via Splunk alerts |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Service dashboard | Wavefront | `https://groupon.wavefront.com/dashboards/channel-manager-integrator-travelclick` |
| Application logs | Splunk | Source type `getaways-channel-manager-integrator-travelclick` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Service down / pod crash | Kubernetes pod not ready | P1 | Page on-call via PagerDuty `PEAIXM8`; check pod logs in Kubernetes namespace |
| DLQ accumulation | MBus DLQ message count rising | P2 | Investigate TravelClick connectivity; check Splunk for error patterns |
| High TravelClick error rate | Repeated non-success OTA responses | P2 | Contact TravelClick support (see original runbook on Confluence) |
| OOM kill | Pod killed due to memory limit exceeded | P1 | Verify JVM heap settings; scale pods or increase memory limit |

## Common Operations

### Restart Service

1. Identify the failing pod in the appropriate Kubernetes namespace (`channel-manager-integrator-travelclick-production-sox` or `channel-manager-integrator-travelclick-staging-sox`)
2. Delete the pod: `kubectl delete pod <pod-name> -n <namespace>` — Kubernetes will reschedule automatically
3. Monitor readiness probe recovery (60s initial delay)
4. Verify log output in Splunk under source type `getaways-channel-manager-integrator-travelclick`

### Scale Up / Down

1. Scaling is managed by Kubernetes HPA targeting 50% CPU utilization
2. Manual scaling: `kubectl scale deployment <deployment-name> --replicas=<n> -n <namespace>`
3. Production limits: min 2, max 15 replicas; staging limits: min 1, max 2 replicas
4. For sustained increased load, update `minReplicas` in `.meta/deployment/cloud/components/app/production-us-central1.yml` and redeploy

### Database Operations

1. Schema migrations are managed by `jtier-migrations` and run automatically on service startup
2. For manual DB access, connect via the DaaS MySQL connection configured in the JTier run config for the target environment
3. Local schema initialization: `script/db/db-init.sql` creates `cmi_travelclick_development` and `cmi_travelclick_test` databases

## Troubleshooting

### TravelClick Connection Failures
- **Symptoms**: MBus messages accumulating in DLQ; Splunk logs showing OTA XML request timeouts or connection refused errors
- **Cause**: TravelClick API endpoint unreachable or returning errors; credential expiry; network issue
- **Resolution**: Check Wavefront dashboard for TravelClick request latency; verify credentials in Kubernetes secrets; contact TravelClick support via procedures in [Confluence runbook](https://confluence.groupondev.com/display/TRAV/Channel+Manager+Integrator+Travelclick)

### MBus Message Processing Failures
- **Symptoms**: Messages accumulating in DLQ; reservation records not being created in MySQL
- **Cause**: Malformed message payload; downstream dependency (TravelClick, Inventory service) unavailable; database connectivity issue
- **Resolution**: Inspect DLQ message contents in Splunk; verify all dependencies are healthy; replay DLQ messages once root cause is resolved

### ARI Push Endpoint Errors
- **Symptoms**: TravelClick reporting failed ARI push deliveries; validation error responses in Splunk
- **Cause**: Malformed OTA XML from TravelClick; validation constraint violations (OVal); Inventory service data mismatch
- **Resolution**: Review Splunk for OTA XML validation errors; cross-reference hotel codes and rate plan codes with the Getaways Inventory service

### OOM / High Memory Usage
- **Symptoms**: Pod OOM kills; Kubernetes events showing `OOMKilled`
- **Cause**: Memory leak or unexpected load spike; `MALLOC_ARENA_MAX` not set correctly
- **Resolution**: Verify `MALLOC_ARENA_MAX=4` in deployment config; check JVM heap usage; scale horizontally; review JVM heap settings in `.mvn/jvm.config`

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — reservations/cancellations not processing | Immediate | Getaways Engineering on-call via PagerDuty `PEAIXM8`; Slack `CF9BSJ5GX` |
| P2 | Degraded — DLQ accumulating or TravelClick errors | 30 min | Getaways Engineering on-call; `getaways-connect-dev@groupon.com` |
| P3 | Minor impact — ARI data delayed | Next business day | `getaways-eng@groupon.com` |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| TravelClick | Monitor Wavefront dashboard; check Splunk for OTA request error rates | Messages routed to MBus DLQ for retry after TravelClick recovers |
| MBus | Monitor DLQ depth in Splunk | DLQ provides retry buffer |
| Getaways Inventory | HTTP health check via JTier OkHttp | No explicit fallback; ARI processing may fail with incomplete hotel data |
| MySQL (DaaS) | JTier DaaS health check; Kubernetes readiness probe indirectly validates DB connectivity | Service goes unready if DB unavailable |
| Kafka | Kafka producer error counter in Splunk | ARI events not delivered to downstream consumers; no local buffering visible |
