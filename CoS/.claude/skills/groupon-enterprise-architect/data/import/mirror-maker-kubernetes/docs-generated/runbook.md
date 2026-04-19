---
service: "mirror-maker-kubernetes"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `pgrep java` (readiness) | exec | Every 5s (after 20s initial delay) | Default kubectl timeout |
| `pgrep java` (liveness) | exec | Every 15s (after 30s initial delay) | Default kubectl timeout |

Note: Health probes verify only that the JVM process is running. They do not confirm active Kafka consumer/producer connectivity. A pod may pass health checks while replication is stalled due to broker connectivity issues.

## Monitoring

### Metrics

All metrics are scraped via Jolokia2 agent on port 8778 and forwarded to InfluxDB by the Telegraf sidecar at 60-second intervals. Metric tags include `service=mirror-maker-kubernetes`, `component=<mirror-component-name>`, `env=production`, and `source=mirror-maker-kubernetes-production`.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `kafka_consumer.records-lag-max` | gauge | Maximum consumer lag in records across all partitions of a topic | Operational procedures to be defined by service owner |
| `kafka_consumer.records-consumed-rate` | counter | Records consumed per second per topic | Operational procedures to be defined by service owner |
| `kafka_consumer.bytes-consumed-rate` | counter | Bytes consumed per second per topic | Operational procedures to be defined by service owner |
| `kafka_consumer.heartbeat-rate` | gauge | Consumer group heartbeat rate (health of group membership) | Drop to 0 indicates consumer group failure |
| `kafka_consumer.assigned-partitions` | gauge | Number of partitions assigned to this consumer instance | Operational procedures to be defined by service owner |
| `kafka_producer.record-send-rate` | counter | Records sent per second per topic | Operational procedures to be defined by service owner |
| `kafka_producer.record-error-rate` | counter | Producer send errors per second | Any sustained non-zero value is an alert |
| `kafka_producer.record-retry-rate` | counter | Producer send retries per second | Operational procedures to be defined by service owner |
| `kafka_producer.byte-rate` | counter | Bytes produced per second per topic | Operational procedures to be defined by service owner |
| `mirror_maker.MirrorMaker-numDroppedMessages` | counter | Total messages dropped by MirrorMaker (producer buffer overflow or error) | Any increment indicates data loss |
| `kafka_consumer.request-latency-avg` | gauge | Average consumer fetch request latency | Operational procedures to be defined by service owner |
| `kafka_producer.request-latency-avg` | gauge | Average producer send request latency | Operational procedures to be defined by service owner |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| MirrorMaker Kubernetes | Grafana/InfluxDB | Operational procedures to be defined by service owner |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Consumer lag growing | `records-lag-max` increasing consistently | warning/critical | Check source broker connectivity and consumer group status; check pod logs |
| Dropped messages | `MirrorMaker-numDroppedMessages` incrementing | critical | Check destination broker connectivity; increase `BATCH_SIZE` or `LINGER_MS`; scale up pod count |
| Pod not running | `pgrep java` fails liveness probe | critical | Pod will be restarted by Kubernetes automatically |
| Zero records consumed | `records-consumed-rate` = 0 for sustained period | warning | Verify source broker reachability; check `SOURCE_USE_MTLS` and certificate validity |

## Common Operations

### Restart Service

Trigger a fresh deploy via deploy_bot to the target component:
1. Navigate to deploy_bot for the `mirror-maker-kubernetes` service
2. Select the target component (e.g., `production-k8s-msk-janus-mirrors-eu-west-1`)
3. Deploy the current version to force a pod rollout
4. Monitor `kafka_consumer.assigned-partitions` and `records-consumed-rate` to confirm recovery
5. Check Slack channel `kafka-deploys` for deploy status notifications

### Scale Up / Down

1. Edit the per-component YAML (e.g., `.meta/deployment/cloud/components/mirror-maker/eu-west-1/production/production-k8s-msk-janus-mirrors.yml`)
2. Adjust `minReplicas` and `maxReplicas`
3. Trigger a deploy via deploy_bot for that component
4. Monitor consumer lag per-partition to confirm new replicas are consuming

### Database Operations

> Not applicable. This service is stateless and owns no databases.

## Troubleshooting

### Consumer Lag Accumulating

- **Symptoms**: `kafka_consumer.records-lag-max` increasing; downstream services observe stale data
- **Cause**: Insufficient consumer throughput (too few streams or pods), source broker congestion, or network latency between source cluster and pod
- **Resolution**: Increase `NUM_STREAMS` (default 10) or `maxReplicas` in the component YAML and redeploy; verify source broker health independently

### Messages Being Dropped

- **Symptoms**: `mirror_maker.MirrorMaker-numDroppedMessages` incrementing
- **Cause**: Destination broker is unavailable or slow; producer buffer (`BATCH_SIZE`) filled before messages could be sent
- **Resolution**: Check destination broker connectivity; verify `DESTINATION_USE_MTLS` and certificate validity in `/var/groupon/certs`; consider increasing `BATCH_SIZE` or reducing `LINGER_MS`; verify destination broker capacity

### Pod Failing Liveness Probe

- **Symptoms**: Pod enters CrashLoopBackOff; `pgrep java` repeatedly fails
- **Cause**: JVM crashed (typically OOMKilled) or startup failure in `mirrorMaker_envValidator` or `mirrorMaker_securityBootstrap`
- **Resolution**: Check pod logs (`/var/log/mirror-maker/mirror-maker.log`) and Kubernetes events; increase `KAFKA_HEAP_OPTS` (e.g., `-Xmx2024M`) and memory limit if OOMKilled

### mTLS Connection Failure

- **Symptoms**: MirrorMaker fails to connect to source or destination broker; pod logs show SSL handshake errors; zero `assigned-partitions`
- **Cause**: TLS certificate in `/var/groupon/certs` expired, missing, or wrong cluster
- **Resolution**: Verify `client-certs` Kubernetes secret is present in namespace and up-to-date; redeploy pod to pick up refreshed certificate volume

### Topic Not Being Mirrored

- **Symptoms**: Expected topic records not appearing on destination cluster with `<prefix>.<topic>` naming
- **Cause**: Topic not in `WHITELIST` env var; `USE_DESTINATION_TOPIC_PREFIX=false` when prefix is expected; wrong component deployed to wrong region
- **Resolution**: Review the component YAML `WHITELIST` value; verify `USE_DESTINATION_TOPIC_PREFIX` and `DESTINATION_TOPIC_PREFIX`; redeploy with corrected config

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | All Janus topic replication stopped (downstream notification services impacted) | Immediate | Kafka Platform Team |
| P2 | Single mirror component down or severe lag | 30 min | Kafka Platform Team |
| P3 | Staging mirror degraded; non-critical topic lag | Next business day | Kafka Platform Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Source Kafka Cluster | Check `kafka_consumer.assigned-partitions` metric; verify broker endpoint from within pod | No automatic fallback; replication halts |
| Destination Kafka Cluster | Check `kafka_producer.record-send-rate` and `record-error-rate`; verify broker endpoint from within pod | No automatic fallback; messages dropped |
| InfluxDB (Metrics) | Check Telegraf sidecar logs | Replication continues; only metrics are lost |
| Logging Stack (Filebeat) | Check Filebeat sidecar logs | Replication continues; only logs are lost |
