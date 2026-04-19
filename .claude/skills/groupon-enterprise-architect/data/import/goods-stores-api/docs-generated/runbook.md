---
service: "goods-stores-api"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /heartbeat` | http | Configured by platform | Configured by platform |
| `GET /status` | http | Configured by platform | Configured by platform |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request rate | counter | Requests per second to `continuumGoodsStoresApi` | Platform-defined |
| HTTP error rate (5xx) | counter | Server error responses from the API | Alert on sustained elevation |
| Resque queue depth | gauge | Number of pending jobs across all Resque queues in `continuumGoodsStoresRedis` | Alert on queue backup |
| Resque job failure rate | counter | Failed Resque jobs in `continuumGoodsStoresWorkers` | Alert on elevated failure count |
| Elasticsearch index lag | gauge | Time between domain change and successful index in `continuumGoodsStoresElasticsearch` | Alert on sustained lag |
| MessageBus consumer lag | gauge | Event processing delay detected by `continuumGoodsStoresMessageBusConsumer_baseHandler` | Alert on latency detection trigger |
| Database connection pool | gauge | Active/waiting connections to `continuumGoodsStoresDb` | Alert on pool exhaustion |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Goods Stores API Overview | Datadog / Grafana (Continuum platform) | Managed by Continuum platform team |
| Resque Worker Health | Resque web UI / platform monitoring | Managed by Continuum platform team |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| API 5xx Error Spike | HTTP 5xx rate exceeds threshold for > 5 minutes | critical | Check application logs; verify DB and Redis connectivity; check dependent services |
| Resque Queue Backup | Queue depth exceeds threshold for > 10 minutes | warning | Check worker pod health; verify Redis connectivity; scale workers if needed |
| Resque Job Failures | Failure count exceeds threshold | warning | Inspect failed job payloads in Resque UI; check downstream service health |
| Elasticsearch Index Lag | Indexing lag exceeds threshold | warning | Check `continuumGoodsStoresWorkers_elasticsearchIndexer` logs; verify ES cluster health |
| MessageBus Consumer Lag | Latency detection triggers in `continuumGoodsStoresMessageBusConsumer_baseHandler` | warning | Check MessageBus broker connectivity; inspect consumer logs |
| Database Connection Exhaustion | Connection pool full | critical | Restart API pods if needed; investigate long-running queries |

## Common Operations

### Restart Service

1. Identify the deployment target (API, Workers, or MessageBus Consumer container).
2. Issue a rolling restart via the Continuum platform orchestration tooling (Kubernetes `kubectl rollout restart` or equivalent platform command).
3. Monitor `/heartbeat` endpoint to confirm pods return to healthy state.
4. Check Resque queue depth to confirm workers resume processing after restart.

### Scale Up / Down

1. For the API (Puma): Adjust replica count via platform orchestration or HPA configuration.
2. For Workers (Resque): Adjust `RESQUE_WORKER_COUNT` environment variable and redeploy, or scale pod replicas.
3. For MessageBus Consumer: Scale swarm process pod replicas via orchestration.
4. Monitor queue depth and error rates after scaling to confirm stability.

### Database Operations

- **Migrations**: Run `bundle exec rake db:migrate` in a one-off container against the target environment. Migrations are in `db/migrate/`. Coordinate with Goods CIM Engineering for production runs.
- **Backfills**: Use `continuumGoodsStoresWorkers_batch` Resque jobs for large-scale data backfills. Submit jobs via Resque UI or rake tasks.
- **Paper Trail audit queries**: Query the `versions` table in `continuumGoodsStoresDb` to retrieve audit history for SOX compliance reviews.

## Troubleshooting

### API returns 500 errors

- **Symptoms**: Elevated HTTP 5xx responses; client requests failing
- **Cause**: Database connectivity loss, Redis connectivity loss, unhandled exception in Grape endpoint, or downstream service timeout
- **Resolution**: Check Rails logs for exception traces; verify `continuumGoodsStoresDb` and `continuumGoodsStoresRedis` connectivity; check dependent service health endpoints; review recent deploys for regressions

### Resque jobs not processing

- **Symptoms**: Queue depth growing; no worker activity; background tasks delayed
- **Cause**: Worker pods crashed, Redis connectivity lost, or job exceptions causing worker to halt
- **Resolution**: Check worker pod logs; verify `continuumGoodsStoresRedis` is reachable; inspect Resque UI for failed jobs; restart worker pods if unresponsive

### Search returning stale or missing results

- **Symptoms**: Product search via `/v2/search/products` returns outdated records or misses recently created products
- **Cause**: Elasticsearch indexing lag; `continuumGoodsStoresWorkers_elasticsearchIndexer` job backlog or failure
- **Resolution**: Check `continuumGoodsStoresElasticsearch` cluster health; inspect indexing worker logs; manually trigger re-index for affected records via Resque

### MessageBus consumer not processing events

- **Symptoms**: Market data or pricing changes not reflected in product state; consumer lag alert firing
- **Cause**: MessageBus broker connectivity lost; consumer swarm pods crashed; Redis batching state corruption
- **Resolution**: Check broker connectivity (`MESSAGE_BUS_URL`); restart consumer pods; inspect `continuumGoodsStoresMessageBusConsumer` logs for error patterns

### Attachment uploads failing

- **Symptoms**: POST `/v2/attachments` returns error; images not appearing in product records
- **Cause**: S3 connectivity or credential issue; CarrierWave misconfiguration; bucket permission error
- **Resolution**: Verify `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_S3_BUCKET` env vars; check S3 bucket ACLs; inspect CarrierWave initializer logs

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — API returning no responses or sustained 500s | Immediate | Goods CIM Engineering on-call |
| P2 | Degraded — elevated errors, worker backlog, search unavailable | 30 min | Goods CIM Engineering on-call |
| P3 | Minor impact — stale search results, slow response, single job failure | Next business day | Goods CIM Engineering team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumGoodsStoresDb` | MySQL connectivity check in `/status` | API returns 503; no write operations possible |
| `continuumGoodsStoresRedis` | Redis ping in `/status` | Resque enqueue fails; background processing halted |
| `continuumGoodsStoresElasticsearch` | Elasticsearch cluster health check | Search endpoints return error; CRUD operations still functional |
| `continuumDealCatalogService` | HTTP call to service health endpoint | Deal sync operations fail; API may return partial data |
| `continuumPricingService` | HTTP call to service health endpoint | Pricing enrichment returns error or stale data |
| `messageBus` | MessageBus consumer connectivity | Consumer processes no events until connectivity restored |
