---
service: "glive-inventory-service"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /status` | HTTP | 30s (Kubernetes liveness probe) | 5s |
| Resque worker heartbeat | Redis-based | Continuous (Resque worker registration) | — |
| MySQL connection check | TCP | On request (ActiveRecord connection pool) | 5s |
| Redis connection check | TCP | On request (Redis client pool) | 3s |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `http_request_duration_seconds` | histogram | API request latency by endpoint and status code | p99 > 2s |
| `http_requests_total` | counter | Total HTTP requests by endpoint, method, and status | Error rate > 5% |
| `resque_queue_depth` | gauge | Number of pending jobs in each Resque queue | Depth > 1000 for > 5 min |
| `resque_failed_jobs_total` | counter | Total failed background jobs | > 50 failures/hour |
| `external_client_request_duration` | histogram | Latency of calls to external providers (TM, AXS, TC, PV) | p99 > 5s |
| `external_client_errors_total` | counter | Failed external provider API calls | Error rate > 10% per provider |
| `varnish_cache_hit_ratio` | gauge | Varnish cache hit/miss ratio | Hit ratio < 60% |
| `reservation_created_total` | counter | Reservations created successfully | Anomaly detection |
| `reservation_expired_total` | counter | Reservations that expired without purchase | Anomaly detection |
| `mysql_connection_pool_active` | gauge | Active MySQL connections in the pool | > 80% of pool size |
| `redis_connection_pool_active` | gauge | Active Redis connections | > 80% of pool size |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| GLive Inventory Service Overview | Grafana / Sonoma | Internal Grafana dashboard |
| GLive API Latency & Errors | Grafana / Sonoma | Internal Grafana dashboard |
| GLive Resque Worker Health | Grafana / Sonoma | Internal Grafana dashboard |
| GLive External Provider Status | Grafana / Sonoma | Internal Grafana dashboard |
| Elastic APM Service Map | Elastic APM | Internal Elastic APM dashboard |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| API Error Rate High | HTTP 5xx rate > 5% for 5 min | critical | Check application logs; verify MySQL and Redis connectivity; check external provider status |
| API Latency High | p99 latency > 2s for 5 min | warning | Check MySQL query performance; verify Redis cache health; check Varnish hit ratio |
| Resque Queue Backlog | Queue depth > 1000 for > 5 min | warning | Scale worker pods; check for stuck jobs; verify Redis connectivity |
| Resque Failed Jobs Spike | > 50 failed jobs in 1 hour | warning | Check failed job error messages; verify external provider availability; retry or clear failed queue |
| External Provider Down | > 10 consecutive failures to a single provider | critical | Check provider status page; verify credentials; check network connectivity; engage provider support if prolonged |
| MySQL Connection Pool Exhausted | Active connections > 80% of pool | warning | Check for connection leaks; consider increasing pool size; check for long-running queries |
| Varnish Cache Hit Ratio Low | Hit ratio < 60% for 15 min | warning | Check cache invalidation frequency; verify Varnish configuration; check for excessive PURGE requests |
| Health Check Failing | `/status` returns non-200 for 3 consecutive checks | critical | Check pod health; verify MySQL and Redis reachability; restart pod if unrecoverable |

## Common Operations

### Restart Service

1. Identify the affected pod(s) via Kubernetes dashboard or `kubectl get pods`
2. For a single pod restart: `kubectl delete pod <pod-name>` (Kubernetes will recreate)
3. For a rolling restart of all API pods: `kubectl rollout restart deployment/glive-inventory-service-api`
4. For a rolling restart of all worker pods: `kubectl rollout restart deployment/glive-inventory-service-workers`
5. Monitor health check endpoint and Resque queue depth during restart
6. Verify logs show clean startup with successful MySQL, Redis, and MessageBus connections

### Scale Up / Down

1. **API tier**: Adjust HPA target or manually scale replicas
   - `kubectl scale deployment/glive-inventory-service-api --replicas=<N>`
2. **Worker tier**: Scale based on Resque queue backlog
   - `kubectl scale deployment/glive-inventory-service-workers --replicas=<N>`
3. Monitor queue depth and processing latency after scaling
4. Ensure MySQL and Redis connection pools can handle the increased connection count

### Database Operations

1. **Run pending migrations**: Execute via Rails migration task in a one-off pod or job
   - `bundle exec rake db:migrate RAILS_ENV=production`
2. **Check migration status**: `bundle exec rake db:migrate:status RAILS_ENV=production`
3. **Database backfills**: Run via Rails console or Rake tasks in a one-off pod
4. **Connection pool tuning**: Adjust `pool` setting in `config/database.yml` and redeploy
5. **Query performance**: Monitor slow query log; add indexes via migration if needed

## Troubleshooting

### Reservations Failing for a Specific Provider

- **Symptoms**: Reservation creation returns errors for one provider (e.g., Ticketmaster) while other providers work normally
- **Cause**: External provider API outage, expired credentials, or rate limiting
- **Resolution**: Check provider status page; verify API credentials have not expired or been rotated; check logs for specific error codes; if rate-limited, reduce request rate and retry

### Background Jobs Stuck or Not Processing

- **Symptoms**: Resque queue depth growing; no new jobs being completed; worker pods appear healthy
- **Cause**: Redis connectivity issues, stuck worker process, or misconfigured queue names
- **Resolution**: Verify Redis connectivity from worker pods; check Resque web UI for stuck workers; restart worker pods; verify queue names in Resque configuration match job class queue declarations

### Varnish Cache Not Invalidating

- **Symptoms**: Stale inventory/availability data returned after updates; API shows correct data when bypassing Varnish
- **Cause**: PURGE requests failing, Varnish misconfiguration, or network issues between service and Varnish
- **Resolution**: Check PURGE request logs; verify `VARNISH_PURGE_URL` configuration; test PURGE manually; check Varnish error logs

### High API Latency

- **Symptoms**: p99 latency exceeding SLA thresholds; slow responses across multiple endpoints
- **Cause**: MySQL slow queries, Redis latency, connection pool exhaustion, or increased traffic bypassing Varnish cache
- **Resolution**: Check MySQL slow query log; verify Redis response times; monitor connection pool utilization; check Varnish cache hit ratio; scale API pods if needed

### MessageBus Event Publishing Failures

- **Symptoms**: Downstream services not receiving inventory updates; MessageBus error logs in the service
- **Cause**: MessageBus broker connectivity issues, topic misconfiguration, or broker capacity limits
- **Resolution**: Verify MessageBus broker health; check `messagebus.yml` configuration; check broker logs for capacity issues; events will be retried when connectivity is restored

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down; no reservations or purchases possible | Immediate | GrouponLive Engineering on-call -> Platform Engineering |
| P2 | One external provider integration down; degraded availability | 30 min | GrouponLive Engineering on-call |
| P3 | Non-critical feature degraded (reporting, cache issues) | Next business day | GrouponLive Engineering |
| P4 | Minor cosmetic or logging issue | Sprint backlog | GrouponLive Engineering |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| MySQL (`continuumGliveInventoryDb`) | ActiveRecord connection pool health; query execution | Service degraded -- all reads/writes fail; return 503 |
| Redis (`continuumGliveInventoryRedis`) | Redis PING; connection pool check | Cache misses fall through to MySQL; locks unavailable (risk of concurrent conflicts); background jobs cannot be enqueued |
| Varnish (`continuumGliveInventoryVarnish`) | HTTP health check to Varnish | Requests route directly to API service; higher backend load |
| Ticketmaster API (`continuumTicketmasterApi`) | HTTP call success/failure tracking | TM-sourced inventory operations fail; other providers unaffected |
| AXS API (`continuumAxsApi`) | HTTP call success/failure tracking | AXS-sourced inventory operations fail; other providers unaffected |
| Telecharge (`continuumTelechargePartner`) | HTTP call success/failure tracking | TC-sourced operations fail; other providers unaffected |
| ProVenue (`continuumProvenuePartner`) | HTTP call success/failure tracking | PV-sourced operations fail; other providers unaffected |
| GTX Service (`continuumGtxService`) | HTTP call success/failure tracking | Reservation and purchase orchestration fails; inventory queries still work |
| Accounting Service (`continuumAccountingService`) | HTTP call success/failure tracking | Payment reports cannot be generated; core inventory operations unaffected |
| Mailman Service (`continuumMailmanService`) | HTTP call success/failure tracking | Emails not delivered; core operations unaffected |
| MessageBus (`messageBus`) | STOMP connection health | Events not published/consumed; MySQL remains source of truth; events replayed on recovery |
