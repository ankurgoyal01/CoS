---
service: "darwin-indexer"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET :9001/healthcheck` | http | > No evidence found | > No evidence found |
| `GET :9001/ping` | http | > No evidence found | > No evidence found |

The `/healthcheck` endpoint validates connectivity to Elasticsearch, PostgreSQL, and key upstream services. A non-200 response or unhealthy subsystem entry indicates a degraded or failed state.

## Monitoring

### Metrics

darwin-indexer uses Dropwizard Metrics 4.1.8. The following metrics are expected based on standard Dropwizard conventions and the service's known operations:

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `darwin-indexer.deal-index-job.duration` | histogram | Time taken for a full deal indexing run | > No evidence found |
| `darwin-indexer.deal-index-job.documents-indexed` | counter | Number of deal documents indexed in a run | > No evidence found |
| `darwin-indexer.deal-index-job.failures` | counter | Number of failed deal indexing runs | > 0 consecutive failures |
| `darwin-indexer.hotel-index-job.duration` | histogram | Time taken for a full hotel offer indexing run | > No evidence found |
| `darwin-indexer.hotel-index-job.documents-indexed` | counter | Number of hotel offer documents indexed in a run | > No evidence found |
| `darwin-indexer.elasticsearch.bulk-write.errors` | counter | Elasticsearch bulk write error count | > 0 |
| `darwin-indexer.upstream.deal-catalog.latency` | histogram | Latency of Deal Catalog REST calls | > No evidence found |
| `jvm.memory.heap.used` | gauge | JVM heap usage | > 85% of configured heap |

> Exact metric names should be confirmed by the service owner from the application source.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| darwin-indexer Operations | > No evidence found | > No evidence found |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Deal indexing job failed | Job exits with error status | critical | Check logs, verify upstream services, inspect Elasticsearch connectivity, re-trigger manually if safe |
| Hotel offer indexing job failed | Job exits with error status | critical | Check logs, verify Hotel Offer Catalog and Taxonomy service availability |
| Elasticsearch bulk write errors > 0 | Bulk write returns errors | warning | Inspect Elasticsearch cluster health; check index mapping compatibility |
| JVM heap > 85% | Heap usage sustained above threshold | warning | Review heap configuration; check for memory leak in enrichment pipeline |
| Upstream service latency spike | REST call duration exceeds threshold | warning | Identify affected upstream service; check for service degradation |

## Common Operations

### Restart Service

> Operational procedures to be defined by service owner. Standard Kubernetes procedure:
1. Identify the pod: `kubectl get pods -l app=darwin-indexer -n <namespace>`
2. Delete the pod to trigger a rolling restart: `kubectl delete pod <pod-name> -n <namespace>`
3. Confirm the new pod reaches Running state: `kubectl get pods -l app=darwin-indexer -n <namespace>`
4. Verify health: `curl http://<pod-ip>:9001/healthcheck`

### Scale Up / Down

> darwin-indexer is a single-replica scheduled service. Horizontal scaling is not recommended without coordination to prevent duplicate indexing runs. To adjust resources, update the Kubernetes Deployment resource requests/limits and re-deploy.

### Trigger Manual Index Run

> Operational procedures to be defined by service owner. If a Dropwizard Task endpoint is configured for manual job triggering, it would be accessible at `POST :9001/tasks/<task-name>`. Confirm with the service owner whether ad-hoc index runs can be triggered via the admin interface or require a deployment flag change.

### Database Operations

- **Check indexer run state**: Query the PostgreSQL indexer metadata tables to view the last successful run, current offsets, and any error records.
- **Reset incremental offset**: Update the offset record in PostgreSQL to force a full re-index on the next scheduled run. Requires coordination with the Relevance Platform Team to avoid serving stale data during re-index.
- **Migrations**: Run via the standard Maven/Flyway or Liquibase workflow in the application repository. Confirm with the service owner.

## Troubleshooting

### Indexing Job Not Running

- **Symptoms**: Elasticsearch index is stale; no recent indexing activity in logs; Dropwizard Metrics show no recent job completions
- **Cause**: Quartz scheduler misconfigured; JVM crash; upstream dependency health check failure causing startup abort
- **Resolution**: Check pod logs for Quartz startup errors; verify `/healthcheck` passes; confirm cron expression in `config.yml` is valid; restart pod if scheduler deadlocked

### Elasticsearch Bulk Write Failures

- **Symptoms**: `elasticsearch.bulk-write.errors` counter rising; deal index not updating; logs show Elasticsearch exceptions
- **Cause**: Elasticsearch cluster unhealthy; index mapping conflict (schema change incompatibility); version conflict on concurrent writes
- **Resolution**: Check Elasticsearch cluster health; if mapping conflict, re-create the index with correct mapping and trigger a full re-index; verify index alias points to correct index

### Upstream Service Unavailable

- **Symptoms**: Indexing job fails partway through; logs show HTTP 5xx or connection timeout from a specific upstream service
- **Cause**: Deal Catalog, Taxonomy, Geo, Merchant API, Inventory, Badges, or another upstream service is down or degraded
- **Resolution**: Identify the failing upstream from logs; check that service's health; if transient, the next scheduled indexing run will retry; if prolonged, escalate to the owning team

### Index Alias Switchover Failed

- **Symptoms**: New index built but alias not updated; search consumers still querying old index
- **Cause**: Alias switchover step failed (Elasticsearch error or service crash after index build)
- **Resolution**: Manually execute alias switchover via Elasticsearch API; confirm the new index is healthy before switching; see [Index Alias Switchover flow](flows/index-alias-switchover.md)

### Kafka Publish Failures

- **Symptoms**: `ItemIntrinsicFeatureEvent` messages not appearing in Holmes platform; Kafka producer errors in logs
- **Cause**: Kafka broker unavailable; producer misconfiguration; topic does not exist
- **Resolution**: Check Kafka broker connectivity; verify `KAFKA_BOOTSTRAP_SERVERS` configuration; confirm topic exists; Holmes team should be notified if events are delayed

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Deal index completely stale; search results severely degraded | Immediate | Relevance Platform Team on-call |
| P2 | Partial indexing failures; some deals not appearing in search | 30 min | Relevance Platform Team |
| P3 | Minor enrichment signals missing (e.g., badges, reviews); core search operational | Next business day | Relevance Platform Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Elasticsearch | `GET :9001/healthcheck` (Dropwizard health check) | Indexing run fails; previous index remains in service |
| PostgreSQL | `GET :9001/healthcheck` | Job cannot persist run state; indexing run may abort |
| Deal Catalog Service | HTTP connectivity check to base URL | Indexing run cannot proceed; no deal data to index |
| Taxonomy Service | HTTP connectivity check to base URL | Deal and hotel offer documents indexed without taxonomy enrichment |
| Redis Cache | Connection check at startup | Deal documents indexed without sponsored/feature data from cache |
| Kafka | Producer connectivity | Feature events not published; Holmes ML models operate on stale data |
