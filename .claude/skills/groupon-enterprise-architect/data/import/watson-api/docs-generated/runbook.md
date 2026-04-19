---
service: "watson-api"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET :8081/healthcheck` | http (Dropwizard admin) | Kubernetes liveness probe interval | Per JTier platform defaults |
| `WatsonApiHealthCheck` (registered as `math`) | Dropwizard health check | On demand | Per JTier platform defaults |

The `WatsonApiHealthCheck` is a basic Dropwizard health check registered under the name `math`. No per-dependency health checks (Redis, Cassandra, PostgreSQL, HBase) are wired in the current codebase.

## Monitoring

### Metrics

Watson API uses `SMAMetrics` (initialized per component name) for structured metrics tracking. All components have APM enabled (`apm.enabled: true`).

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Request count per class/method | counter | Tracks successful requests via `SMAMetrics.countRequest(className, methodName)` | Operational procedures to be defined by service owner |
| Failed request count | counter | Tracks failures via `SMAMetrics.countFailedRequests(className, methodName)` | Operational procedures to be defined by service owner |
| Empty response count | counter | Tracks empty responses via `SMAMetrics.countEmptyResponse(className, methodName)` | Operational procedures to be defined by service owner |
| Event request/response time | histogram | Measures latency via `SMAMetrics.measureEventRequestResponseTime(className, methodName, startTime)` | Operational procedures to be defined by service owner |

### Dashboards

> Operational procedures to be defined by service owner. Dashboards are not discoverable from this repository.

### Alerts

> Operational procedures to be defined by service owner. Alert configurations are not discoverable from this repository.

## Common Operations

### Restart Service

1. Identify the affected component deployment (e.g., `watson-api--dealkv`) in the appropriate Kubernetes cluster
2. Use `kubectl rollout restart deployment/watson-api--{component}` in the relevant namespace and cluster context
3. Monitor the rollout with `kubectl rollout status deployment/watson-api--{component}`
4. Verify health at `:8081/healthcheck` on a newly started pod

### Scale Up / Down

1. Scaling is controlled by HPA. Emergency manual scaling:
   - `kubectl scale deployment/watson-api--{component} --replicas={n}`
2. Permanent scaling changes must be made in the `minReplicas`/`maxReplicas` fields in `.meta/deployment/cloud/components/{component}/common.yml` and re-deployed

### Database Operations

- **Redis**: No migration tooling — schema-less. Key TTLs are managed by application code. Use Redis CLI or a dashboarding tool for key inspection.
- **PostgreSQL (Janus)**: Schema managed externally by the Janus team. No migration path is present in this repository.
- **Cassandra**: Schema managed externally by the Holmes analytics pipeline. No migration path is present in this repository.
- **HBase**: Schema managed externally by the Holmes identity pipeline. ZooKeeper quorum: `cerebro-zk{1-5}.snc1:2181`.

## Troubleshooting

### Redis Connection Failure
- **Symptoms**: 500 errors on KV read/write or freshness endpoints; `RedisException` logged
- **Cause**: Redis cluster unreachable or TLS certificate issue
- **Resolution**: Verify Redis host/port configuration in service YAML; check TLS certificates at `/var/groupon/certs`; verify `KAFKA_TLS_ENABLED` / `KAFKA_MTLS_ENABLED` env vars if applicable; check Redis cluster health independently

### Kafka Publish Failure
- **Symptoms**: `Error in publishing data` logged by `KvKafkaProducer`; KV write still returns 200 to caller (fire-and-forget)
- **Cause**: Kafka broker unreachable, topic misconfigured, or TLS/mTLS credential issue
- **Resolution**: Verify `kafka.bootstrapServer` and `kafka.topic` in configuration; check `KAFKA_TLS_ENABLED`, `KAFKA_MTLS_ENABLED`, and `JKS_MSK_PASSWORD` environment variables; confirm JKS keystore at `kafka.keyStoreFile` is accessible

### Component Not Starting (`DEPLOY_COMPONENT` null)
- **Symptoms**: Service throws `WatsonApiRuntimeException("service name cannot be null")` on startup
- **Cause**: `DEPLOY_COMPONENT` environment variable is missing from the pod spec
- **Resolution**: Verify the Kubernetes deployment manifest includes `DEPLOY_COMPONENT` with a valid value (`dealkv`, `userkv`, `emailfreshness`, `rvd`, `janusaggregation`, `useridentities`, or `analytics`)

### Invalid Bucket Name
- **Symptoms**: 400 Bad Request response on KV endpoints
- **Cause**: Bucket name passed in path does not match any entry in the `KvBucket` enum
- **Resolution**: Confirm the bucket name matches a valid entry from the `KvBucket` enum. Deal buckets are prefixed to `/v1/dds/`; user buckets to `/v1/cds/`

### Janus Event Query Returning 400
- **Symptoms**: `IllegalArgumentException` with `EVENT_DATE_TIME_IS_IN_INVALID_FORMAT` or `timeAggregation is not valid!`
- **Cause**: `startDateTime`/`endDateTime` not in `NOW` or `NOW-{n}{unit}` format; `timeAggregation` not one of `5MIN`, `HOURLY`, `DAILY`; requested time window exceeds the configured bounds
- **Resolution**: Confirm time window format; check bounds: `5MIN` max 30 min, `HOURLY` max 24 hours, `DAILY` max 7 days

### OOMKilled Pods
- **Symptoms**: Pods are OOMKilled; memory limit is 500 MiB
- **Cause**: Heap expansion or JVM native memory growth; `MALLOC_ARENA_MAX` tuning may be insufficient
- **Resolution**: `MALLOC_ARENA_MAX=4` is set for all components to limit virtual memory. If OOM persists, consider increasing the memory limit in the component YAML and re-deploying

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down (all KV reads/writes failing) | Immediate | Watson team |
| P2 | Degraded (one component unavailable) | 30 min | Watson team |
| P3 | Minor impact (elevated latency, increased error rate) | Next business day | Watson team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Redis | No built-in health check wired; verify independently via Redis CLI or monitoring | No fallback — Redis is primary operational store |
| Cassandra / Amazon Keyspaces | No built-in health check wired; verify via AWS console or `cqlsh` | No fallback — analytics component returns errors |
| PostgreSQL (Janus) | No built-in health check wired; DaaS platform monitors connection pool | No fallback — bcookie endpoint returns errors |
| HBase | No built-in health check wired; verify ZooKeeper quorum connectivity | No fallback — useridentities component returns errors |
| Kafka | No built-in health check wired; Kafka publish failures are logged but do not block the HTTP response | KV write succeeds to Redis even if Kafka publish fails; downstream pipeline may lag |
