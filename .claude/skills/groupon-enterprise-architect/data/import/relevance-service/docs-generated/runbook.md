---
service: "relevance-service"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/health` | http | 30s | 5s |
| Elasticsearch cluster health | http (ES API) | 60s | 10s |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `rapi.search.latency_ms` | histogram | End-to-end search request latency | P99 > 500ms |
| `rapi.search.request_count` | counter | Total search requests processed | -- |
| `rapi.search.error_rate` | gauge | Percentage of search requests returning errors | > 5% |
| `rapi.ranking.latency_ms` | histogram | Ranking Engine scoring latency | P99 > 200ms |
| `rapi.indexer.batch_duration_s` | histogram | Duration of batch index build operations | > 2 hours |
| `rapi.indexer.last_success` | gauge | Timestamp of last successful index build | Stale > 24h |
| `rapi.booster.traffic_percentage` | gauge | Current percentage of traffic routed to Booster | -- |
| `es.cluster.status` | gauge | Elasticsearch cluster health status (green/yellow/red) | != green |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| RAPI Service Overview | Grafana | Internal Grafana instance |
| Elasticsearch Cluster Health | Grafana / Kibana | Internal monitoring |
| Booster Migration Progress | Grafana | Internal Grafana instance |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| RAPI High Latency | P99 search latency > 500ms for 5 minutes | critical | Check Elasticsearch cluster health; verify Booster endpoint status; review recent deployments |
| RAPI High Error Rate | Error rate > 5% for 5 minutes | critical | Check Elasticsearch connectivity; review application logs for exceptions; verify EDW batch job status |
| Elasticsearch Cluster Red | Cluster status = red | critical | Investigate unassigned shards; check node health; contact infrastructure team |
| Elasticsearch Cluster Yellow | Cluster status = yellow for 30 minutes | warning | Check replica allocation; verify node capacity |
| Indexer Stale | Last successful index build > 24 hours ago | warning | Check EDW connectivity; review indexer logs; manually trigger reindex if needed |
| Booster Endpoint Down | Booster health check failing | warning | Verify Booster deployment; traffic will fall back to Feynman Search automatically |

## Common Operations

### Restart Service

1. Verify current service health via the `/health` endpoint and Grafana dashboard
2. If restarting a single pod: `kubectl rollout restart deployment/relevance-api -n <namespace>`
3. Monitor pod startup and health check status
4. Verify search latency and error rate return to normal levels

### Scale Up / Down

1. Check current pod count: `kubectl get pods -l app=relevance-api -n <namespace>`
2. Update HPA or manually scale: `kubectl scale deployment/relevance-api --replicas=<N> -n <namespace>`
3. Monitor CPU and memory metrics to confirm scaling took effect
4. For Elasticsearch scaling, coordinate with the infrastructure team for node additions

### Database Operations

- **Reindex Elasticsearch**: Trigger via the Indexer component's batch job; monitor `rapi.indexer.batch_duration_s` metric for completion
- **Index template updates**: Deploy updated index templates via the standard CI/CD pipeline; reindex after deployment
- **Feature vector refresh**: Monitor EDW batch job status; stale features degrade ranking quality but do not cause service failure

## Troubleshooting

### High search latency

- **Symptoms**: P99 latency exceeds 500ms; user-visible slow search results
- **Cause**: Elasticsearch cluster under load, slow ranking model execution, EDW feature fetch timeouts, or Booster endpoint degradation
- **Resolution**: Check Elasticsearch cluster metrics (CPU, heap, GC); verify Booster endpoint health; review JVM garbage collection logs; consider scaling RAPI pods or Elasticsearch nodes

### Search returning no results

- **Symptoms**: Search queries return empty result sets for terms that should match
- **Cause**: Elasticsearch index corruption, stale index data, or indexer batch job failure
- **Resolution**: Check `rapi.indexer.last_success` metric; verify Elasticsearch index health; manually trigger reindex if needed; review EDW data freshness

### Ranking quality degradation

- **Symptoms**: Relevance metrics (click-through rate, conversion) decline without search volume changes
- **Cause**: Stale feature vectors from EDW, ranking model version mismatch, or Booster migration traffic split misconfigured
- **Resolution**: Verify EDW feature freshness; check active ranking model version; review Booster traffic percentage configuration; roll back model version if needed

### Elasticsearch cluster health degraded

- **Symptoms**: Cluster status yellow or red; increased search latency
- **Cause**: Node failures, disk space exhaustion, unassigned shards, or JVM heap pressure
- **Resolution**: Check node status and disk usage; reassign shards if needed; increase cluster capacity; contact infrastructure team for node recovery

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Search completely down or returning errors for all queries | Immediate | RAPI Team + Platform Engineering |
| P2 | Degraded search (high latency, partial failures, ranking quality drop) | 30 min | RAPI Team |
| P3 | Minor impact (stale indexes, non-critical metric anomalies) | Next business day | RAPI Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Feynman Search (Elasticsearch) | Elasticsearch cluster health API | None (primary search path); Booster may serve partial traffic |
| Booster | API health endpoint | Traffic falls back to Feynman Search |
| EDW | Batch job completion monitoring | Stale feature vectors and indexes continue serving; degraded ranking quality |

> Operational procedures should be refined by the RAPI team as implementation details are confirmed in the source repository.
