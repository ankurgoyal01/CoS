---
service: "janus-schema-inferrer"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `pgrep java` | exec (readiness probe) | 5s | — |
| `cat /var/groupon/jtier/schema_inferrer_health.txt` | exec (liveness probe) | 15s | — |
| `SMAMetrics.gaugeSchemaInferrerFailure` (0 = ok, 1 = failed) | metrics gauge | Per CronJob run (hourly) | — |

> The health flag file (`/var/groupon/jtier/schema_inferrer_health.txt`) is created by `HealthFlag.create()` at application startup. Its presence indicates that the JVM initialized successfully.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `custom_data_` (Jolokia prefix) + sample size gauge | gauge | Number of messages sampled from each topic per run (`SMAMetrics.gaugeMessageSampleSize`) | Low sample count may indicate broker connectivity issues |
| Schema inferrer failure flag | gauge | `0` = run succeeded; `1` = run encountered an exception | Alert on value `1` |
| Schema inferrer topic count | counter | Number of topics processed in a single run | Decrease may indicate topic list config issue |
| Schema inferrer duration | histogram/timer | Per-topic inference duration from start to completion | Increase may indicate Spark or Janus latency |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| janus-schema-inferrer SMA | Wavefront | https://groupon.wavefront.com/dashboards/janus-schema-inferrer--sma |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Schema inferrer failure | `gaugeSchemaInferrerFailure = 1` | warning | Check CronJob logs in Kibana/Filebeat; verify Kafka/MBus and Janus Metadata service reachability |
| CronJob not completing | No successful run in past 2 hours | critical | Check Kubernetes events in `janus-schema-inferrer-production` namespace; check pod logs |
| PagerDuty service | https://groupon.pagerduty.com/services/P25RQWA | — | Contact janus-prod-alerts@groupon.com or #janus-robots Slack channel |

## Common Operations

### Restart Service

The service runs as a CronJob — there is no long-running pod to restart. To force an immediate re-run:

1. Identify the target namespace: `janus-schema-inferrer-production` (production) or `janus-schema-inferrer-staging` (staging)
2. Manually trigger a Kubernetes Job from the CronJob:
   ```
   kubectl create job --from=cronjob/<cronjob-name> <job-name> -n janus-schema-inferrer-production
   ```
3. Monitor the job pod logs:
   ```
   kubectl logs -f <pod-name> -n janus-schema-inferrer-production
   ```

### Scale Up / Down

The service is fixed at `minReplicas: 1` / `maxReplicas: 1` / `parallelism: 1`. Scaling is not applicable — it is a batch CronJob, not a long-running server.

To change resource limits, update the Helm values in `.meta/deployment/cloud/components/{kafka|mbus}/{environment}.yml` and redeploy via deploy_bot.

### Database Operations

This service owns no database. All schema persistence is handled by `continuumJanusWebCloudService`. For schema data issues, consult the Janus Metadata service runbook.

## Troubleshooting

### CronJob Fails to Start

- **Symptoms**: Pod enters `Error` or `OOMKilled` state; no metrics emitted
- **Cause**: Startup failure — typically Janus Metadata service unreachable at `JanusMetadataClient.initInstance()` or health flag file creation failure
- **Resolution**: Check pod logs for `JanusSchemaInferrerRuntimeException`; verify `janus.metadata.serverUrl` is reachable; check Kubernetes secrets for Kafka keystore mount; verify `INFERRER_TYPE` env var is set to `kafka` or `mbus`

### Low or Zero Message Sample Count

- **Symptoms**: `gaugeMessageSampleSize` metric is 0 or very low for a topic
- **Cause**: Kafka/MBus broker unreachable, topic has no recent messages, or TLS certificate issue
- **Resolution**: Verify broker URLs in the config file for the affected environment; check Kafka TLS keystores are mounted correctly (`KAFKA_TLS_ENABLED=true` in production Kafka); confirm topic exists and has activity

### Schema Not Updating in Janus

- **Symptoms**: Janus UI shows stale schema; no schema diff published
- **Cause**: Either the sampled messages are identical to the stored schema (no diff), the `enabledRawEventsForInferringSchema` filter excludes the event, or Janus persist API returned an error
- **Resolution**: Check service logs for `All Keys present in the stored schema. Skipping the new schema` (expected — no change); check `enabledRawEventsForInferringSchema` setting; check for errors logged in `JanusMetadataClient.persistSchema()`

### Malformed JSON Messages

- **Symptoms**: Log warning `Malformed json. Skipping this batch of messages`; low schema coverage for a topic
- **Cause**: Messages from the topic do not parse as valid JSON via `SparkSession.read.json()`
- **Resolution**: Investigate the message format for the affected topic. If the topic uses a non-JSON encoding, it may need to be excluded from the topics list or handled with a custom extractor rule in Janus

### INFERRER_TYPE Not Set

- **Symptoms**: Service logs `Null Schema Inferrer Type. Schema Inferrer type cannot be Null` and exits
- **Cause**: `INFERRER_TYPE` env var is missing from the Kubernetes deployment
- **Resolution**: Verify Helm deployment values include `INFERRER_TYPE: kafka` or `INFERRER_TYPE: mbus` in `envVars`

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Schemas entirely stale (multiple hours, no runs completing) | Immediate | #janus-robots Slack; janus-prod-alerts@groupon.com; PagerDuty P25RQWA |
| P2 | Some topics failing; partial schema coverage | 30 min | #janus-robots Slack; dnd-ingestion team |
| P3 | Minor impact — single topic missing or low sample | Next business day | dnd-ingestion team via platform-data-eng@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Kafka | Verify broker URL reachability from pod; check `kafka-clients` consumer logs | No fallback — topic is skipped; failure metric emitted |
| MBus | Check MBus broker URL (`mbusBrokerUrls`) connectivity on port 61613 | No fallback — run fails with retry |
| Janus Metadata Service (`continuumJanusWebCloudService`) | `GET {serverUrl}/janus/api/v1/sources` returns 200 | No fallback — run aborts at startup if Janus unreachable |
