---
service: "message-service"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /heartbeat.txt` | http | Not documented in architecture inventory | Not documented |

## Monitoring

### Metrics

> Operational procedures to be defined by service owner. The following are expected based on the service's role.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `getmessages.latency` | histogram | Response time for `/api/getmessages` requests | Not documented |
| `messageevent.count` | counter | Number of user interaction events recorded | Not documented |
| `audience_import.duration` | histogram | Time taken for batch audience import jobs to complete | Not documented |
| `kafka.consumer.lag` | gauge | Consumer group lag on the `ScheduledAudienceRefreshed` Kafka topic | Not documented |
| `redis.cache.hitrate` | gauge | Cache hit rate for campaign/template lookups | Not documented |
| `bigtable.write.errors` | counter | Errors writing assignment data to Bigtable | Not documented |

### Dashboards

> Operational procedures to be defined by service owner.

| Dashboard | Tool | Link |
|-----------|------|------|
| CRM Message Service | Not documented | Not documented |

### Alerts

> Operational procedures to be defined by service owner.

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| `/heartbeat.txt` unhealthy | HTTP non-200 from health check | critical | Restart service pod; escalate to crm-eng |
| Kafka consumer lag high | Consumer group lag exceeds threshold | warning | Check `messagingKafkaConsumers` logs; verify audience import jobs are processing |
| Bigtable write errors | Error rate on Bigtable writes elevated | warning | Check GCP Bigtable health; consider triggering `/api/bigtable/scale` |
| MySQL connection pool exhausted | DB connection errors in Play logs | critical | Check MySQL health; scale service replicas if pool is saturated |

## Common Operations

### Restart Service

1. Identify the service pod(s) in the Kubernetes cluster
2. Drain traffic from the target pod (if graceful restart is required)
3. Delete or rollout-restart the pod: `kubectl rollout restart deployment/message-service -n <namespace>`
4. Verify `GET /heartbeat.txt` returns 200 on the new pod before removing the drain

### Scale Up / Down

**Horizontal (application pods)**: Adjust Kubernetes deployment replicas or HPA configuration via the cluster management tooling.

**Bigtable capacity**: POST to `/api/bigtable/scale` with the desired read/write capacity parameters. This is an operational control plane endpoint — use with caution in production.

### Database Operations

- **MySQL migrations**: Run via SBT or migration tool against the target environment's `continuumMessagingMySql` instance. Coordinate with crm-eng before applying to production.
- **Cache invalidation**: Campaign cache entries in `continuumMessagingRedis` are invalidated automatically on campaign state changes. Manual flush can be performed via Redis CLI if stale data is suspected.
- **Bigtable backfill**: Re-trigger audience import by posting a `ScheduledAudienceRefreshed` event to the Kafka topic, which causes `messagingAudienceImportJobs` to re-run the assignment build for the specified audience.

## Troubleshooting

### Messages Not Appearing for Users

- **Symptoms**: `/api/getmessages` returns empty or fewer-than-expected messages
- **Cause**: Audience assignments may be stale (Kafka consumer lag or failed import job), Redis cache may have stale entries, or targeting constraints may be filtering out the campaign
- **Resolution**: Check Kafka consumer lag; verify most recent `ScheduledAudienceRefreshed` event was processed successfully; inspect Bigtable/Cassandra for expected assignment records; check campaign status in MySQL via the admin UI

### Audience Import Job Failures

- **Symptoms**: Kafka consumer lag growing; Bigtable or Cassandra assignment data not updating; error logs in `messagingAudienceImportJobs`
- **Cause**: AMS unavailable; GCP Storage/HDFS export files not yet available; Bigtable write errors; Akka actor failure
- **Resolution**: Check AMS health; verify GCP Storage bucket contains the expected export; check Bigtable write error metrics; review Akka supervisor logs; re-trigger by replaying the Kafka event

### Campaign Not Visible in Admin UI

- **Symptoms**: Campaign manager cannot find a campaign in `/campaign/*`
- **Cause**: Campaign not committed to MySQL; Redis serving stale data; UI backend error
- **Resolution**: Verify campaign record exists in `continuumMessagingMySql`; flush relevant Redis key if stale; check Play application logs for UI controller errors

### Bigtable Throughput Degradation

- **Symptoms**: High latency or errors on Bigtable reads/writes during peak audience import
- **Cause**: Insufficient Bigtable node capacity for the current load
- **Resolution**: POST to `/api/bigtable/scale` to increase capacity; monitor GCP Bigtable metrics for node utilization

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no messages delivered to web/mobile/email | Immediate | crm-eng on-call (is-ms-engg@groupon.com) |
| P2 | Degraded — messages partially delivered; audience assignments stale | 30 min | crm-eng on-call |
| P3 | Minor impact — campaign UI issues; non-critical batch delays | Next business day | crm-eng team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumMessagingMySql` | MySQL connection pool health in Play logs | Service cannot create or update campaigns; read from Redis cache where possible |
| `continuumMessagingRedis` | Redis connection errors in application logs | Message delivery falls back to direct MySQL reads; increased latency expected |
| `continuumMessagingBigtable` | GCP Bigtable console / write error metrics | Fall back to `continuumMessagingCassandra` if configured for the environment |
| `continuumAudienceManagementService` | HTTP health check on AMS endpoint | Audience validation and import stall; existing assignments remain in use |
| `messageBus` | MBus connection errors in publisher logs | Campaign metadata events are not delivered to EDW or downstream consumers |
| Kafka | Consumer group lag / broker connectivity | `ScheduledAudienceRefreshed` events not processed; audience assignments not refreshed |
