---
service: "regla"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /health` | http | 30s | 5s |
| `GET /status` | http | 60s | 5s |
| Kubernetes liveness probe on `reglaService` pod | http (`/health`) | 30s | 5s |
| Kubernetes readiness probe on `reglaService` pod | http (`/health`) | 10s | 3s |
| `reglaStreamJob` Kafka consumer lag | kafka consumer group lag metric | 60s | — |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `rule_evaluation_latency` | histogram | P95 latency of synchronous rule evaluation queries (`/userHasDealPurchaseSince`, `/userHasAnyPurchaseEver`) | > 200ms |
| `rule_evaluation_count` | counter | Total rule evaluations processed by stream job and API | — |
| `kafka_consumer_lag` | gauge | Kafka consumer group lag for deal-purchase and browse event topics | > 10000 messages |
| `redis_cache_hit_rate` | gauge | Redis cache hit rate for purchase history lookups | < 80% |
| `rule_action_dispatch_errors` | counter | Count of failed action dispatches to Rocketman, Email Campaign, Incentive Service | > 5 per minute |
| `postgres_query_latency` | histogram | P95 query latency on `reglaPostgresDb` | > 500ms |
| `stream_job_processing_rate` | gauge | Events processed per second by `reglaStreamJob` | Drop > 50% from baseline |

> Metrics are emitted to TSD Aggregator via `metrics-sma-influxdb` (5.12.0).

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| regla Service Health | Datadog | Link to be defined by service owner |
| regla Stream Job Kafka Lag | Datadog | Link to be defined by service owner |
| Rule Evaluation Latency | Datadog | Link to be defined by service owner |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Kafka Consumer Lag High | `kafka_consumer_lag` > 10000 for > 5 min | critical | Check `reglaStreamJob` pod status; verify Kafka broker connectivity; check `KAFKA_BOOTSTRAP_SERVERS` and SSL cert validity; consider scaling stream job pods |
| Rule Evaluation Errors Spiking | `rule_evaluation_count` drops to 0 or HTTP 500s on `/userHasDealPurchaseSince` | critical | Check `reglaService` pod logs; verify `reglaPostgresDb` and `reglaRedisCache` connectivity |
| PostgreSQL Unreachable | `reglaService` and `reglaStreamJob` cannot connect to `reglaPostgresDb` | critical | Check PostgreSQL instance health; verify `POSTGRES_URL`, `POSTGRES_USER`, `POSTGRES_PASSWORD` are correctly set; contact DBA team |
| Redis Unreachable | Jedis connection failures; rule evaluation latency spikes | critical | Check Redis instance health; verify `REDIS_HOST` and `REDIS_PORT`; evaluation falls back to PostgreSQL with degraded latency |
| Rule Action Dispatch Failures | `rule_action_dispatch_errors` > 5/min sustained | warning | Check Rocketman v2, Email Campaign, and Incentive Service health; check outbound HTTP connectivity from `reglaService` pods |
| Taxonomy Cache Stale | Taxonomy Service v2 unreachable; `TAXONOMY_CACHE_SYNC_INTERVAL_SECONDS` elapsed without refresh | warning | Check Taxonomy Service v2 health; verify `TAXONOMY_SERVICE_URL`; Redis taxonomy cache will serve stale data until service recovers |

## Common Operations

### Restart Service

**reglaService:**
1. Run `kubectl rollout restart deployment/regla-service -n <namespace>` in the target cluster.
2. Monitor pod rollout: `kubectl get pods -n <namespace> -l app=regla-service`.
3. Verify health: `kubectl exec -n <namespace> <pod> -- curl -s localhost:9000/health`.

**reglaStreamJob:**
1. Run `kubectl rollout restart deployment/regla-stream-job -n <namespace>`.
2. Monitor pod rollout: `kubectl get pods -n <namespace> -l app=regla-stream-job`.
3. Verify Kafka consumer group is re-assigned and lag is not growing.

### Scale Up / Down

**reglaService:**
1. Check current replicas: `kubectl get deployment/regla-service -n <namespace>`.
2. Scale: `kubectl scale deployment/regla-service --replicas=<N> -n <namespace>`.
3. HPA may override manual scaling — check HPA config with `kubectl get hpa -n <namespace>`.

**reglaStreamJob:**
1. Stream job scaling is driven by Kafka partition count. Scaling beyond the number of partitions provides no additional parallelism.
2. Consult Emerging Channels team before scaling stream job pods.

### Database Operations

**Run PostgreSQL migration:**
1. Obtain a `reglaPostgresDb` connection via approved DBA access method.
2. Apply migration scripts in order from the service's migration path.
3. Verify schema version: `SELECT version FROM schema_migrations ORDER BY version DESC LIMIT 1;`.

**Clear rule cache sync (force reload):**
1. Restart the `reglaStreamJob` pod to trigger a full reload of active rules from PostgreSQL.
2. Alternatively, trigger the rule cache sync by adjusting `RULE_CACHE_SYNC_INTERVAL_SECONDS` temporarily.

**Flush Redis taxonomy cache:**
1. Connect to `reglaRedisCache` via approved access method.
2. Identify taxonomy cache keys and `DEL` them to force a fresh load on next sync.
3. Monitor `TAXONOMY_CACHE_SYNC_INTERVAL_SECONDS` for automatic repopulation.

## Troubleshooting

### Rule evaluation queries returning stale or incorrect results
- **Symptoms**: `GET /userHasDealPurchaseSince` or `GET /userHasAnyPurchaseEver` returns unexpected results; purchase history appears missing
- **Cause**: Redis cache is stale (TTL 403200s / ~4.67 days); PostgreSQL may have diverged from cache; stream job may be lagging
- **Resolution**: 1. Check Kafka consumer lag — if high, the stream job is not processing recent purchases. 2. Check Redis hit rate metric. 3. If cache is stale, flush the relevant Redis keys to force a fresh load from PostgreSQL. 4. If stream job lag is high, scale stream job pods or investigate Kafka connectivity.

### Kafka consumer lag growing
- **Symptoms**: `kafka_consumer_lag` metric increasing steadily; stream job not keeping up with event volume
- **Cause**: `reglaStreamJob` is under-provisioned, Kafka SSL connectivity is disrupted, or a processing error is causing retries
- **Resolution**: 1. Check `reglaStreamJob` pod logs: `kubectl logs <pod> -n <namespace>`. 2. Verify Kafka SSL certificates have not expired (`KAFKA_SSL_TRUSTSTORE_PASSWORD`, `KAFKA_SSL_KEYSTORE_PASSWORD`). 3. Check for exceptions in stream processing — a poison pill message may be causing repeated retry failures. 4. Scale stream job pods if processing capacity is insufficient.

### Rule actions not being dispatched (push/email/incentive not firing)
- **Symptoms**: Rules appear to evaluate (execution records in PostgreSQL), but users do not receive push notifications, emails, or incentives
- **Cause**: Rocketman v2, Email Campaign service, or Incentive Service is unreachable; action dispatch is failing silently
- **Resolution**: 1. Check `rule_action_dispatch_errors` metric. 2. Check `reglaService` logs for outbound HTTP errors. 3. Verify downstream service health (Rocketman v2, Email Campaign, Incentive Service). 4. Check `executions` table in `reglaPostgresDb` for `failed_action_dispatched` records.

### Category tree resolution returning incorrect results
- **Symptoms**: `GET /categoryInCategoryTree` returns unexpected true/false values; rule conditions based on categories are misfiring
- **Cause**: Taxonomy cache in Redis is stale; Taxonomy Service v2 returned incorrect data; Redis TTL has not expired
- **Resolution**: 1. Verify Taxonomy Service v2 is returning correct hierarchy data by direct query. 2. Flush taxonomy cache keys in Redis to force a fresh load. 3. Check `TAXONOMY_CACHE_SYNC_INTERVAL_SECONDS` — if too long, reduce it in the environment config and restart `reglaService`.

### PostgreSQL connection pool exhausted
- **Symptoms**: Timeouts on rule CRUD API endpoints; `reglaService` logs show connection pool exhaustion errors
- **Cause**: Connection pool is under-configured for current request volume; long-running queries holding connections
- **Resolution**: 1. Check active connections in PostgreSQL: `SELECT count(*) FROM pg_stat_activity WHERE datname='regla';`. 2. Identify long-running queries and cancel if appropriate. 3. Increase connection pool size via `application.conf` and redeploy.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | `reglaService` completely down; rule evaluations failing; stream job stopped; inbox management decisions blocked | Immediate | Emerging Channels team on-call; escalate to Continuum platform team for infrastructure issues |
| P2 | Rule evaluation latency degraded; Kafka consumer lag high; action dispatch failing for a subset of rule types | 30 min | Emerging Channels team |
| P3 | Taxonomy cache stale; minor evaluation inconsistencies; non-blocking rule admin errors | Next business day | Emerging Channels team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `reglaPostgresDb` | `SELECT 1` connectivity check; monitor `postgres_query_latency` | No fallback — `reglaService` and `reglaStreamJob` cannot function without PostgreSQL |
| `reglaRedisCache` | Redis PING via jedis; monitor cache hit rate | Rule evaluation falls back to direct PostgreSQL queries; latency degrades significantly (potential P2 impact at high volume) |
| Kafka (SSL) | Monitor `kafka_consumer_lag`; check broker connectivity | `reglaStreamJob` stops processing; no stream-evaluated rules fire; synchronous API evaluation continues unaffected |
| Taxonomy Service v2 | `GET <TAXONOMY_SERVICE_URL>/health`; monitor sync success | Redis taxonomy cache serves stale data until TTL expires or sync resumes |
| Rocketman v2 | Check Rocketman health endpoint | Push notification actions fail silently; execution records written with failed status |
| Email Campaign | Check Email Campaign health endpoint | Email actions fail silently; execution records written with failed status |
| Incentive Service | Check Incentive Service health endpoint | Incentive grants fail silently; execution records written with failed status |

> Operational procedures to be defined by service owner for exact Datadog dashboard links, Kubernetes namespace names, and on-call rotation details.
