---
service: "selfsetup-hbw"
title: "Health Check and Monitoring"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "health-check-and-monitoring"
flow_type: synchronous
trigger: "EKS liveness probe (GET /heartbeat.txt) and background metric/log emission on every request"
participants:
  - "ssuWebUi"
  - "ssuMetricsReporter"
  - "ssuLogger"
architecture_ref: "dynamic-selfsetup-hbw"
---

# Health Check and Monitoring

## Summary

selfsetup-hbw exposes a static liveness endpoint (`/heartbeat.txt`) consumed by the EKS Kubernetes liveness probe to confirm that the Apache/PHP process is alive. Separately, on every merchant request, `ssuMetricsReporter` emits HTTP and business metrics to a Telegraf agent and `ssuLogger` emits structured Splunk-formatted log records to the log aggregation pipeline. These two background concerns run alongside every other flow.

## Trigger

- **Type**: infrastructure probe (liveness) + per-request background emission (metrics/logs)
- **Source**: EKS liveness probe for `/heartbeat.txt`; every inbound HTTP request for metrics and logging
- **Frequency**: Liveness probe: every N seconds (interval managed by EKS pod spec); metrics/logs: every request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| EKS liveness probe | Calls `/heartbeat.txt` on the configured interval | — (EKS infrastructure) |
| Web UI / Controllers | Serves the `/heartbeat.txt` response | `ssuWebUi` |
| Metrics Reporter | Emits request and business metrics to Telegraf on every request | `ssuMetricsReporter` |
| Logging | Emits Splunk-formatted log records on every request | `ssuLogger` |
| Telegraf Agent | Receives metrics in InfluxDB line protocol | `telegrafAgent` |
| Log Aggregation (Splunk) | Receives and indexes structured log records | `logAggregation` |

## Steps

### Liveness Check

1. **Probe sends HTTP GET**: EKS liveness probe sends HTTP GET to `/heartbeat.txt`.
   - From: EKS liveness probe
   - To: `ssuWebUi` (Apache/PHP)
   - Protocol: REST / HTTP

2. **Returns static OK response**: Apache serves the static `heartbeat.txt` file. No PHP execution or database call is required.
   - From: `ssuWebUi`
   - To: EKS liveness probe
   - Protocol: REST / HTTP (200 OK, text/plain)

3. **EKS records pod as healthy**: EKS evaluates the 200 response and marks the pod as healthy. If non-200 is received, EKS initiates a pod restart after the configured failure threshold.
   - From: EKS liveness probe
   - To: EKS control plane
   - Protocol: EKS internal

### Per-Request Metrics Emission

4. **Request received**: Any inbound merchant request is processed by `ssuWebUi`.
   - From: Merchant browser
   - To: `ssuWebUi`
   - Protocol: REST / HTTPS

5. **Emits HTTP metrics**: After processing, `ssuMetricsReporter` writes request duration, response status code, and endpoint path metrics using `influxdb-php` in InfluxDB line protocol.
   - From: `ssuMetricsReporter`
   - To: `telegrafAgent`
   - Protocol: UDP/TCP (InfluxDB line protocol)

6. **Emits log record**: `ssuLogger` (monolog + monolog-splunk-formatter) writes a structured log entry recording the request, outcome, and any notable events or errors.
   - From: `ssuLogger`
   - To: `logAggregation`
   - Protocol: TCP / Splunk HEC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `/heartbeat.txt` returns non-200 | EKS liveness probe increments failure counter; after threshold, pod is restarted | Pod restarted; traffic rerouted to healthy pods during restart |
| Telegraf agent unreachable | `ssuMetricsReporter` write fails silently (fire-and-forget) | Metrics loss for that request; no merchant impact |
| Log aggregation unreachable | `ssuLogger` monolog handler catches write failure | Log record lost; no merchant impact; monolog may fall back to a secondary handler if configured |

## Sequence Diagram

```
EKS_Probe -> ssuWebUi: GET /heartbeat.txt
ssuWebUi --> EKS_Probe: HTTP 200 OK (text/plain)
EKS_Probe -> EKS_ControlPlane: pod=healthy

Merchant -> ssuWebUi: GET/POST <any endpoint>
ssuWebUi -> ssuWebUi: process request
ssuMetricsReporter -> telegrafAgent: write metrics (InfluxDB line protocol)
ssuLogger -> logAggregation: write log record (Splunk HEC)
ssuWebUi --> Merchant: HTTP response
```

## Related

- Architecture dynamic view: `dynamic-selfsetup-hbw`
- Related flows: [Merchant Signup and Opportunity Lookup](merchant-signup-and-opportunity-lookup.md), [Scheduled SSU Reminder and Reconciliation](scheduled-ssu-reminder-and-reconciliation.md)
