---
service: "janus-engine"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Filesystem liveness flag | exec (file presence check) | Per Kubernetes liveness probe config (managed externally) | Per Kubernetes liveness probe config |

Health is signaled via a filesystem flag managed by `janusEngine_healthAndMetrics`. The flag is written on startup and removed on unhealthy state. No HTTP health endpoint is exposed. Kubernetes liveness probes should be configured to check for this flag file.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Event processing rate | counter | Number of source events received and processed per unit time, emitted by each adapter | > No evidence found |
| Curation success/failure rate | counter | Curated events published vs. failed events routed to DLQ, emitted by `curationProcessor` | > No evidence found |
| Kafka Streams lag | gauge | Consumer group lag on Kafka source topics (KAFKA mode), emitted by `kafkaIngestionAdapter` | > No evidence found |
| MBus processing rate | counter | Events consumed from MBus topics (MBUS/DLQ modes), emitted by `mbusIngestionAdapter` / `dlqProcessor` | > No evidence found |
| Health flag status | gauge | Liveness state written by `janusEngine_healthAndMetrics` | 0 = unhealthy |

> Metric names and alert thresholds are configured in `metricsStack` (SMA metrics) and are managed externally.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Janus Engine operational metrics | > No evidence found — dashboards managed externally | — |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Health flag absent | Liveness flag file missing | critical | Investigate `janusOrchestrator` startup logs; check MBus and Kafka connectivity |
| High DLQ depth | DLQ topic backlog growing | warning | Deploy in DLQ mode to drain queue; investigate root cause of curation failures |
| Kafka consumer lag | Consumer group lag exceeds threshold | warning | Check Kafka cluster health; verify `kafkaIngestionAdapter` throughput |
| Metadata service unreachable | HTTP calls to Janus metadata service failing | warning | Verify Janus metadata service availability; check `janusMetadataClientComponent` cache TTL |

## Common Operations

### Restart Service

1. Identify the Kubernetes pod(s) running Janus Engine.
2. Drain in-flight events where possible (Kafka Streams checkpoints state automatically).
3. Delete the pod(s) to trigger a Kubernetes-managed restart: `kubectl delete pod <pod-name> -n <namespace>`.
4. Verify the liveness flag is written and metrics resume flowing after startup.

### Scale Up / Down

1. Update the Kubernetes Deployment replica count for the target `ENGINE_MODE` instance.
2. Kafka Streams partitions are automatically rebalanced across additional instances in KAFKA mode.
3. MBus subscriptions in MBUS mode may require coordination — verify no duplicate consumption with the dnd-ingestion team.

### Database Operations

> Not applicable — Janus Engine is stateless and owns no data stores.

## Troubleshooting

### Events not appearing in Janus sink topics

- **Symptoms**: No new messages on `janus-cloud-tier1/tier2/tier3/impression/email/raw` topics; no processing errors logged
- **Cause**: MBus topic subscription dropped, Kafka source topic empty, or `curationProcessor` silently skipping events due to missing mapper metadata
- **Resolution**: Check MBus connectivity and topic subscription config; verify Janus metadata service is reachable and returning mappers; inspect `curationProcessor` logs for skip/error signals

### High DLQ depth

- **Symptoms**: DLQ topic backlog increasing; events not completing curation
- **Cause**: Curation failures due to malformed source payloads, missing mapper definitions, or transient metadata service outages
- **Resolution**: Deploy Janus Engine in `DLQ` mode to replay failed events; investigate root payload issues with the upstream service team; update mapper definitions in Janus metadata service if schema changed

### Liveness flag missing (pod unhealthy)

- **Symptoms**: Kubernetes liveness probe fails; pod restart loop
- **Cause**: `janusOrchestrator` failed to initialize (MBus connection refused, Kafka unreachable, metadata service timeout on startup)
- **Resolution**: Check startup logs for connection errors; verify environment variables (`KAFKA_BOOTSTRAP_SERVERS`, `JANUS_METADATA_SERVICE_URL`, `MBUS_TOPICS`); confirm upstream services are reachable from the pod network

### Metadata cache stale after mapper update

- **Symptoms**: Events routed to wrong sink topic or rejected after a mapper definition change in Janus metadata service
- **Cause**: In-memory cache in `janusMetadataClientComponent` holding outdated mapper definitions
- **Resolution**: Restart the Janus Engine pod to force cache reload from the metadata service

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no events processed; canonical topic consumers starved | Immediate | dnd-ingestion@groupon.com |
| P2 | Degraded — partial processing; DLQ growing; some event types failing | 30 min | dnd-ingestion@groupon.com |
| P3 | Minor impact — elevated latency; non-critical mode degraded | Next business day | dnd-ingestion@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| MBus | Verify MBus broker connectivity via client logs; check topic subscription status | No automatic fallback — events accumulate in MBus until reconnected |
| Kafka cluster | Check Kafka consumer group lag via Kafka tooling; verify bootstrap server reachability | Kafka Streams pauses; events buffer in Kafka until connectivity restored |
| Janus metadata service | HTTP GET to metadata service health endpoint (if available); check `janusMetadataClientComponent` logs | In-memory cache continues to serve last-known metadata; stale mappers may cause routing errors |
