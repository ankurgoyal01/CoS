---
service: "mobile-logging-v2"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /v2/mobile/health` | HTTP JSON | Dropwizard default | Dropwizard default |
| `GET /v2/mobile/health` (admin port 8081) | HTTP | Kubernetes liveness/readiness probe | — |
| `ThreadPoolExecutorHealthCheck` | Internal JVM health check | Polled by Dropwizard health check registry | — |

## Monitoring

### Metrics

Per-event-type counters are emitted for each GRP event processed. The `EventTypeMetricsEnum` controls which events receive detailed metrics (GRP5, GRP7, GRP8, GRP38, GRP40); all others fall under the `DEFAULT` bucket.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `exception` (per event type) | counter | Events that raised an unhandled exception during processing | — |
| `success` (per event type) | counter | Events successfully published to Kafka | — |
| `fail` (per event type) | counter | Events that failed processing or publishing | — |
| `processed` (per event type) | counter | Total events processed (all outcomes) | — |
| `error` (per event type) | counter | Events that encountered a processing error | — |
| JVM / HTTP metrics | gauge/histogram | Standard JTier Dropwizard metrics (thread pool, GC, request rate, latency) | — |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Mobile Logging V2 | Grafana | `https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/d/mobile-logging-v2/mobile-logging-v2` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| mobile-logging No events produced | No GRP events published to Kafka in the past hour | 4 (warning) | Check logs in Kibana; verify Kafka broker health; contact MBNXT team if HTTP traffic has shifted |

Alert notifications route to: `sem-da-alerts@groupon.com` / OpsGenie `sem-analytics-service@groupondev.opsgenie.net`

## Common Operations

### Restart Service

Mobile Logging V2 follows standard JTier Kubernetes restart procedures:

```bash
# Authenticate
kubectl cloud-elevator auth browser

# Select the correct context
kubectx mobile-logging-production-us-central1

# List pods
kubectl get pods -n mobile-logging-production

# Rolling restart (preferred — avoids downtime)
kubectl rollout restart deployment/<deployment-name> -n mobile-logging-production
```

### Change Log Level at Runtime

The service supports per-class log-level changes without restarting. Changes revert after `durationMillis`:

```bash
# For each pod that should be affected:
kubectl exec pod/<pod-name> --container filebeat -- \
  curl 'http://localhost:8080/v2/mobile/log_level?level=DEBUG&classNames=com.groupon.mobile.logging.decode.MessagePackDecoder&durationMillis=60000'
```

Supported levels: `INFO`, `ERROR`, `WARN`, `DEBUG`. Use `classNames=ROOT` to affect all loggers.

### Scale Up / Down

Adjust replicas via Deploybot or directly:

```bash
kubectl scale deployment/<deployment-name> --replicas=<N> -n mobile-logging-production
```

For permanent changes, update `minReplicas`/`maxReplicas` in `.meta/deployment/cloud/components/app/production-us-central1.yml` and redeploy.

### View Pod Logs

```bash
kubectl cloud-elevator auth browser
kubectl config get-contexts
kubectx mobile-logging-production-us-central1
kubectl get pods -o wide -n mobile-logging-production
kubectl logs <pod-name> -n mobile-logging-production
```

Live application logs are also queryable in Kibana: `https://prod-kibana-unified.us-central1.logging.prod.gcp.groupondev.com/app/r/s/oEaTM`

### Database Operations

> Not applicable. The service is stateless and owns no data stores.

## Troubleshooting

### No Events Produced Alert

- **Symptoms**: Nagios/OpsGenie alert fires; Grafana shows zero events published to `mobile_tracking` in the past hour
- **Cause**: Either (1) no HTTP requests are arriving at the service, or (2) Kafka is down or unreachable
- **Resolution**:
  1. Check Kibana logs for `KAFKA_SEND` errors or `READ_ERROR` / `DECODE_ERROR` entries
  2. Check the Grafana dashboard for HTTP request rate — if zero, the issue is upstream (api-proxy or mobile client traffic shift)
  3. Contact the Kafka team Google space to verify broker health
  4. Contact the MBNXT team to confirm no traffic shift has redirected requests away from this service

### Error Processing Messages to Kafka

- **Symptoms**: `KAFKA_SEND` errors in logs; `error` metric counter increasing; events not appearing in `mobile_tracking`
- **Cause**: Network connectivity issue or Kafka broker unavailability; TLS certificate mismatch
- **Resolution**:
  1. Verify Kafka broker status with the Kafka team
  2. Check that the TLS keystore was generated correctly at startup (look for `kafka tls cert generation` messages in pod logs)
  3. Verify the `kafkaProducer.broker` config value points to the correct cluster

### High CPU Consumption

- **Symptoms**: CPU alert fires; pods near resource limit
- **Cause**: May be `tsdaggr` process consuming excessive CPU (known JTier framework issue with the TSDAggr metrics daemon)
- **Resolution**:
  1. Identify the process consuming CPU inside the pod
  2. If `tsdaggr` is the cause, restart the pod — see [Confluence TSDAggr CPU issue](https://confluence.groupondev.com/display/METS/AINT+TSDAgg+%28MAD%29+Causes+CPU+Alerts)
  3. If the Java process itself is the cause, consider scaling horizontally

### Recurring Decode Errors in Logs

- **Symptoms**: Large number of `DECODE_ERROR`, `DECODE_ARRAY_ERROR`, or `CONTENT_TYPE_NOT_SUPPORTED` entries in logs
- **Cause**: Mobile clients sending incomplete or malformed log files; known issue expected to reduce once MBNXT fully replaces legacy app
- **Resolution**: This is a known and tolerated condition. Monitor for sustained spikes above baseline. No action required unless the volume significantly increases.

### iOS 3.10 Event Field Offset Issue

- **Symptoms**: Field values shifted by one position for iOS 3.10 funnel events in downstream data
- **Cause**: A known bug in iOS 3.10 (MBA-154) causing an extra field at index 6 in the event array
- **Resolution**: Handled automatically by `MessagePackDecoder.mapEventFieldsWithIOS310Fix()` — no operator action required.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down, all mobile events lost | Immediate | DA team on-call (OpsGenie P6QUNQO); sem-da-eng-support Google space |
| P2 | Degraded throughput, partial event loss | 30 min | DA team (sem-devs@groupon.com) |
| P3 | Minor processing errors, isolated event loss | Next business day | DA team (da-communications@groupon.com) |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Kafka (`messageBus`) | Grafana dashboard; "No events produced" Nagios alert; check Kafka team Google space | None — events are dropped if Kafka is unavailable |
| api-proxy | Grafana HTTP request rate drops to zero | None — no fallback routing |
| ELK / Kibana | Kibana URL accessible | Logging loss does not affect event processing |
