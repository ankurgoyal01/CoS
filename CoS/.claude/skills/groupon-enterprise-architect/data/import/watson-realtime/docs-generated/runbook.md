---
service: "watson-realtime"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| File-based probe (exec health check) | exec | Not discoverable | Not discoverable |

Each worker uses a file-based liveness probe rather than an HTTP health endpoint. The container orchestrator executes a command that verifies the presence of a health marker file written by the JVM process. If the process crashes or hangs, the file is absent and the probe fails, triggering a container restart.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Kafka consumer group lag | gauge | Number of unconsumed messages per partition for each worker's consumer group on `janus-tier2_snc1` and `janus-impression_snc1` | Not discoverable — to be defined by service owner |
| Kafka Streams task processing rate | counter | Records processed per second per worker | Not discoverable |
| Redis write error rate | counter | Failed Jedis write operations per worker | Not discoverable |
| Cassandra write error rate | counter | Failed Cassandra driver write operations in `continuumAnalyticsKsService` and `continuumKsTableTrimmerService` | Not discoverable |
| PostgreSQL write error rate | counter | Failed JDBI3 write operations in `continuumCookiesService` | Not discoverable |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| watson-realtime overview | Not discoverable | Operational procedures to be defined by service owner |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High consumer lag — tier2 | `janus-tier2_snc1` consumer group lag exceeds threshold | warning | Investigate worker health, check for JVM OOM, verify Redis/Cassandra/PostgreSQL connectivity |
| High consumer lag — impression | `janus-impression_snc1` consumer group lag exceeds threshold | warning | Investigate `continuumAnalyticsKsService` health and Cassandra/Keyspaces write throughput |
| Worker container restart loop | Container restart count exceeds threshold | critical | Check JVM logs for OOM or dependency connection failures |
| Cassandra write failures | Elevated error rate on `cassandraKeyspaces_5c9a` writes | critical | Check AWS Keyspaces service health, verify SigV4 credentials have not expired |

## Common Operations

### Restart Service

1. Identify the specific worker container to restart (`continuumAnalyticsKsService`, `continuumCookiesService`, `continuumDealviewService`, `continuumRealtimeKvService`, `continuumRvdService`, `continuumUserIdentitiesService`, or `continuumKsTableTrimmerService`).
2. Trigger a rolling restart via the container orchestrator (Kubernetes rollout restart).
3. Kafka Streams will resume from the last committed offset on startup — no data loss for at-least-once processing.
4. Monitor consumer group lag to confirm the worker catches up to the live offset.

### Scale Up / Down

1. Kafka Streams workers scale horizontally by adding container replicas; each additional instance claims additional Kafka partitions.
2. Maximum useful parallelism equals the number of partitions on the consumed topic.
3. Adjust replica count in the Kubernetes deployment manifest (managed externally).

### Database Operations

- **Redis**: No schema migrations. Key TTL and eviction policies are managed at the Redis cluster level by the infrastructure team.
- **Cassandra/Keyspaces**: Table trimming is handled automatically by `continuumKsTableTrimmerService` on its configured schedule. Manual trimming is not recommended without coordination with the owning team.
- **PostgreSQL**: Schema migration procedures are managed externally. Contact dnd-ds-search-ranking@groupon.com before performing manual schema changes on `postgresCookiesDb_2f7a`.

## Troubleshooting

### Worker Not Processing Events (Consumer Lag Growing)

- **Symptoms**: Kafka consumer group lag increases continuously for a worker; downstream data in Redis/Cassandra/PostgreSQL becomes stale
- **Cause**: Worker container crashed, JVM OOM, or a dependency (Redis, Cassandra, PostgreSQL, Kafka) is unavailable
- **Resolution**: Check container logs for stack traces; verify dependency health (Redis ping, Cassandra connectivity, PostgreSQL connection); restart the affected worker if a transient failure is suspected

### Cassandra/Keyspaces Write Failures (SigV4 Auth)

- **Symptoms**: `continuumAnalyticsKsService` or `continuumKsTableTrimmerService` logs show authentication or signing errors against `cassandraKeyspaces_5c9a`
- **Cause**: AWS credentials (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) have expired or been rotated without updating the deployment
- **Resolution**: Rotate and update AWS credentials in the secrets store; trigger a rolling restart of the affected workers

### Schema Resolution Failures (Janus Metadata Service)

- **Symptoms**: Workers that call `janusMetadataService_4d1e` (cookies, dealview, realtime-kv, rvd, user-identities) log schema fetch errors; Caffeine cache exhausted
- **Cause**: `janusMetadataService_4d1e` is unavailable or returning errors
- **Resolution**: Verify Janus Metadata Service health; workers will serve cached schemas until cache expires — check cache TTL configuration; escalate to Janus team if sustained

### Table Trimmer Not Running

- **Symptoms**: Cassandra/Keyspaces tables grow unbounded; query latency on `cassandraKeyspaces_5c9a` increases
- **Cause**: `continuumKsTableTrimmerService` container is not scheduled or is failing silently
- **Resolution**: Verify the trimmer job's schedule and last successful execution; check container logs for errors; restart the job if needed

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Multiple workers down; watson-api serving stale data across all features | Immediate | dnd-ds-search-ranking@groupon.com |
| P2 | Single worker down; partial stale data (e.g., only cookie mappings stale) | 30 min | dnd-ds-search-ranking@groupon.com |
| P3 | Elevated lag but processing still active; minor data staleness | Next business day | dnd-ds-search-ranking@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `kafkaCluster_9f3c` | Monitor consumer group lag via Kafka metrics | Workers pause and retry; no fallback writes — data will be stale until Kafka recovers |
| `raasRedis_3a1f` | Redis PING from ops tooling | No fallback — write failures cause processing errors and growing lag |
| `cassandraKeyspaces_5c9a` | Cassandra driver connection check; AWS Keyspaces console | No fallback — write failures cause processing errors and growing lag |
| `postgresCookiesDb_2f7a` | PostgreSQL connection health check | No fallback — write failures cause `continuumCookiesService` processing errors |
| `janusMetadataService_4d1e` | HTTP health endpoint (if available) | Caffeine in-process cache provides short-term resilience; sustained failure degrades schema resolution |
