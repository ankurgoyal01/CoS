---
service: "darwin-groupon-deals"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/healthcheck` (Dropwizard default) | http | Kubernetes liveness probe interval | Kubernetes liveness probe timeout |
| `/admin/healthcheck` (Dropwizard admin) | http | Kubernetes readiness probe interval | Kubernetes readiness probe timeout |
| `/admin/hystrix` | http (SSE stream) | On-demand | Persistent connection |

> Exact probe intervals and timeouts are configured in the Helm chart. Confirm with service owner.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request rate (`darwin-aggregator.*`) | counter | Total inbound requests across all endpoints | Operational baseline |
| HTTP error rate (5xx) | counter | Count of 5xx responses from `apiResource` | Alert if > operational baseline |
| Aggregation engine latency | histogram | End-to-end latency of the `aggregationEngine` fan-out and ranking | Alert if p99 exceeds SLA |
| Cache hit rate (Redis) | gauge | Ratio of cache hits to total requests in `cacheLayer` | Alert if drops significantly below baseline |
| Hystrix open circuit count | gauge | Number of open circuit breakers across dependency calls | Alert if any circuit opens |
| Kafka consumer lag | gauge | Consumer group lag on the aggregation request topic | Alert if lag exceeds threshold |

> Exact metric names and alert thresholds are managed in the monitoring platform. Confirm with the Relevance Engineering team.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Darwin Aggregator Service — Overview | Grafana / Datadog | Confirm with service owner |
| Hystrix Circuit Breaker State | Hystrix Dashboard or Turbine | `/admin/hystrix` stream endpoint |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High 5xx error rate | 5xx responses exceed baseline for > 5 minutes | critical | Check Hystrix dashboard; identify failing upstream dependency; review recent deployments |
| Elasticsearch circuit open | Hystrix circuit for Elasticsearch is open | critical | Verify Elasticsearch cluster health; check `elasticsearchClusterExt_b8f21c`; consider fallback to cache-only mode |
| Redis unavailable | Redis connection failures spike | critical | Verify `redisClusterExt_9d0c11` health; service will degrade to full aggregation on every request (increased latency) |
| High aggregation latency | p99 latency exceeds SLA | warning | Identify slowest upstream dependency via Hystrix metrics; check Elasticsearch query latency; check Redis hit rate |
| Kafka consumer lag | Consumer group lag exceeds threshold on request topic | warning | Check Kafka cluster health (`kafkaClusterExt_4b2e1f`); review async aggregation consumer thread count |

## Common Operations

### Restart Service

1. Identify the affected Kubernetes deployment: `kubectl get deployments -n <namespace> | grep darwin`
2. Perform a rolling restart: `kubectl rollout restart deployment/<darwin-deployment-name> -n <namespace>`
3. Monitor rollout: `kubectl rollout status deployment/<darwin-deployment-name> -n <namespace>`
4. Verify health: `curl http://<pod-ip>:8080/healthcheck`

### Scale Up / Down

1. Update Helm values for replica count or trigger HPA manually:
   `kubectl scale deployment/<darwin-deployment-name> --replicas=<N> -n <namespace>`
2. Confirm new pods are healthy before routing traffic: `kubectl get pods -n <namespace> | grep darwin`

### Database Operations

The Darwin Aggregator Service does not own a database schema and performs no migrations. For cache operations:

- **Flush Redis cache**: Connect to `redisClusterExt_9d0c11` and execute `FLUSHDB` (use with caution in production — will cause cache misses and increased upstream load until cache warms)
- **Update ML models**: Publish new model artifacts to `watsonObjectStorageExt_3a1f2c` using the Relevance ML pipeline; the service picks up new models on next load cycle

## Troubleshooting

### High Latency on Deal Search

- **Symptoms**: `/v2/deals/search` or `/cards/v1/search` response times elevated; user-facing deal pages slow
- **Cause**: One or more upstream dependencies slow or timing out; Redis cache miss rate elevated; Elasticsearch query latency high
- **Resolution**: Open `/admin/hystrix` stream and identify any circuits with elevated latency or open state; isolate the slow dependency; check Elasticsearch query performance; verify Redis cache hit rate

### Elasticsearch Circuit Open

- **Symptoms**: Deal search returning empty results or 5xx errors; Hystrix dashboard shows `elasticsearchClusterExt_b8f21c` circuit open
- **Cause**: Elasticsearch cluster unreachable or overloaded
- **Resolution**: Verify Elasticsearch cluster health; check network connectivity from pod to cluster; if cluster is healthy, check for query-level issues (slow queries, mapping errors); if cluster is unhealthy, escalate to platform team

### Redis Cache Degraded

- **Symptoms**: Increased aggregation latency; upstream dependency call rate spikes; Redis connection errors in logs
- **Cause**: Redis cluster unavailable or evicting keys at high rate
- **Resolution**: Verify `redisClusterExt_9d0c11` health; service continues operating without cache but at higher latency; escalate to platform team if cluster issue confirmed

### Kafka Consumer Not Processing

- **Symptoms**: Async batch aggregation not producing results; Kafka consumer lag increasing
- **Cause**: Consumer group offset issue, Kafka cluster connectivity problem, or consumer thread crash
- **Resolution**: Check consumer group status; restart the service if consumer threads are stuck; verify `kafkaClusterExt_4b2e1f` connectivity

### ML Model Load Failure

- **Symptoms**: Relevance ranking quality degraded; service logs show model load errors
- **Cause**: Watson Object Storage unavailable or model artifact missing/corrupt in `watsonObjectStorageExt_3a1f2c`
- **Resolution**: Verify Watson Object Storage connectivity and bucket contents; service falls back to default ranking; escalate to Relevance ML pipeline team

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — deal search returning no results or all 5xx | Immediate | Relevance Engineering on-call (relevance-engineering@groupon.com, tkuntz) |
| P2 | Degraded — elevated latency or partial errors | 30 min | Relevance Engineering on-call |
| P3 | Minor impact — non-critical feature degraded (e.g., sponsored ads, targeted messages) | Next business day | Relevance Engineering team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `elasticsearchClusterExt_b8f21c` | Hystrix circuit state at `/admin/hystrix`; cluster health API | Cached responses returned; empty results if cache also unavailable |
| `redisClusterExt_9d0c11` | Redis `PING` command; Jedis connection pool stats | Full aggregation pipeline executes on every request (higher latency) |
| `continuumDealCatalogService` | Hystrix circuit state | Partial deal data returned; aggregation continues with available data |
| `continuumBadgesService` | Hystrix circuit state | Deals returned without badge annotations |
| `continuumUserIdentitiesService` | Hystrix circuit state | Non-personalized ranking applied |
| `continuumGeoPlacesService` | Hystrix circuit state | Geo-based filtering may be degraded |
| `continuumGeoDetailsService` | Hystrix circuit state | Geo enrichment omitted from results |
| `kafkaClusterExt_4b2e1f` | Kafka consumer group lag metrics | Async batch flow paused; synchronous REST path unaffected |
| `watsonObjectStorageExt_3a1f2c` | Object storage SDK connectivity check | Stale or default ranking model used |
