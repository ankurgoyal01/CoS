---
service: "push-infrastructure"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/dashboard/*` | http | Periodic (interval managed externally) | Managed externally |
| Kubernetes liveness probe | http | Managed externally | Managed externally |
| Kubernetes readiness probe | http | Managed externally | Managed externally |

> Specific health check endpoint paths and probe configuration are managed externally by the Rocketman / Push Platform Engineering team.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Message enqueue rate | counter | Messages enqueued per second across all channels | Managed externally |
| Delivery success rate | counter | Messages successfully delivered per channel (push/email/sms) | Managed externally |
| Delivery error rate | counter | Failed delivery attempts per channel | Managed externally |
| Kafka consumer lag | gauge | Per-topic lag for all seven consumed topics (rm_daf, rm_preflight, rm_coupon, rm_user_queue_default, rm_rapi, rm_mds, rm_feynman) | Alert if sustained lag growth detected |
| Redis queue depth | gauge | Number of messages pending in Redis delivery queues per channel | Managed externally |
| Template cache hit rate | gauge | Ratio of Redis template cache hits to total render requests | Low hit rate may indicate cache invalidation issues |
| PostgreSQL error record count | gauge | Number of unresolved error records in the error store | Alert on sustained growth |
| RabbitMQ publish lag | gauge | Delay in status-exchange event publication | Managed externally |

> Metrics are instrumented via metrics-core 3.1.0 (Dropwizard Metrics) and reported to InfluxDB (`externalInfluxDb_9e3c`).

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Push Infrastructure Delivery Dashboard | `/dashboard/*` (internal API) | Internal service URL |
| Operational Metrics | InfluxDB / Grafana (assumed Continuum standard) | Managed externally |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High delivery error rate | Error rate exceeds threshold for push, email, or SMS channel | critical | Check downstream delivery dependency (SMTP/FCM/APNs/SMS Gateway); review error records via `/errors/retry` |
| Kafka consumer lag growing | Sustained lag increase on any of the seven rm_* topics | warning | Check `continuumPushInfrastructureService` consumer health; scale consumers if needed |
| Redis queue depth growing | Delivery queue depth growing without corresponding delivery throughput | warning | Check queue processor workers; verify Redis connectivity |
| PostgreSQL error records growing | Unresolved error record count increasing without retry activity | warning | Investigate root cause of delivery failures; trigger retry via `/errors/retry` |
| Service unreachable | Health check fails | critical | Restart service; check JVM heap, external dependency connectivity |

## Common Operations

### Restart Service

1. Confirm the deployment target (Kubernetes namespace, deployment name) with the Rocketman team
2. Drain in-flight requests if possible (check Redis queue depth before restart)
3. Issue rolling restart via Kubernetes: `kubectl rollout restart deployment/<push-infrastructure-deployment> -n <namespace>`
4. Monitor readiness probe recovery and Kafka consumer group rebalance
5. Verify delivery throughput resumes via `/dashboard/*` and InfluxDB metrics

### Scale Up / Down

1. Identify the scaling target (replica count or HPA min/max)
2. Adjust Kubernetes deployment replica count: `kubectl scale deployment/<push-infrastructure-deployment> --replicas=<N> -n <namespace>`
3. Monitor Kafka consumer group rebalance across new/removed replicas
4. Verify Redis queue processing rate adjusts proportionally

### Database Operations

> Operational procedures to be defined by service owner.

- **Migrations**: Schema migrations for PostgreSQL/MySQL transactional database are managed externally; contact Rocketman team for migration runbook
- **Error backlog clearance**: Use `/errors/clear` API to remove stale error records after root cause resolution
- **Error retry**: Use `/errors/retry` API to re-enqueue failed messages after dependency recovery

## Troubleshooting

### Messages Not Being Delivered

- **Symptoms**: Delivery error rate rising; user complaints of missing push/email/SMS; error records growing in PostgreSQL
- **Cause**: Downstream delivery dependency unavailable (SMTP, FCM, APNs, SMS Gateway); misconfigured credentials; rate-limit exhaustion
- **Resolution**: Check delivery dependency health; verify credentials via configuration; inspect error records via `/dashboard/*`; retry eligible messages via `/errors/retry`

### Kafka Consumer Lag Growing

- **Symptoms**: rm_* topic lag increasing; event-triggered messages delayed; InfluxDB consumer lag metric rising
- **Cause**: Consumer processing too slow; `continuumPushInfrastructureService` replicas insufficient; downstream bottleneck slowing processing
- **Resolution**: Check service logs for processing errors; scale up replicas; check Redis queue depth for downstream bottleneck

### High Memory / JVM GC Pressure

- **Symptoms**: Slow response times; JVM GC pauses logged; OOM errors
- **Cause**: Template cache warming too large; message payload sizes unexpectedly large; memory leak
- **Resolution**: Review Redis template cache size; tune JVM heap settings (-Xmx); restart service; escalate to Rocketman team if persistent

### Template Rendering Failures

- **Symptoms**: Messages enqueued but not sent; errors logged referencing FreeMarker; `/render_template` returning errors
- **Cause**: Template content invalid; template not found in Redis cache; data binding mismatch
- **Resolution**: Verify template exists in Redis via `/cache/invalidate` then re-warm; validate template syntax; check data payload format

### Cache Invalidation Not Taking Effect

- **Symptoms**: Stale template content delivered to users after template update
- **Cause**: Redis cache not invalidated after template change
- **Resolution**: Call `/cache/invalidate` with the affected template identifier; verify Redis key deletion; confirm subsequent renders pick up updated template

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — all channels failing; no messages delivered | Immediate | Rocketman / Push Platform Engineering on-call |
| P2 | Single channel degraded (e.g., email failing, push working); partial delivery failure | 30 min | Rocketman / Push Platform Engineering |
| P3 | Minor impact — slow delivery, elevated latency, non-critical errors | Next business day | Rocketman / Push Platform Engineering |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `externalSmtpService_2a7d` (SMTP) | Test SMTP connection; check error records for SMTP failures | Log error; record in error store for retry |
| `externalKafkaCluster_2f8c` (Kafka) | Monitor consumer lag via InfluxDB; check kafka-clients connection logs | Messages remain in Kafka; no data loss within retention window |
| `externalRedisCluster_5b2e` (Redis) | Check Redis ping; monitor queue depth and cache hit rate | Service degraded — rendering and queue processing fail; manual recovery required |
| `externalTransactionalDatabase_3f1a` (PostgreSQL/MySQL) | JDBC connectivity check; check error record counts | Service cannot persist state; delivery fails; restart required after DB recovery |
| `externalRabbitMqBroker_4a6b` (RabbitMQ) | Check AMQP connection; monitor status-exchange publish failures | Status events not delivered to consumers; delivery proceeds but status tracking degrades |
| FCM / APNs | Delivery error rate by channel in InfluxDB | Log error; record in error store for retry |
| SMS Gateway | Delivery error rate for SMS channel in InfluxDB | Log error; record in error store for retry |
