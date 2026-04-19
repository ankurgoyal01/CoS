---
service: "travel-inventory"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/v2/getaways/inventory/status/db` | http | Configured per environment | Configured per environment |
| `/v2/getaways/inventory/status/logging` | http | On-demand | Configured per environment |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `http_request_duration` | histogram | Latency of inbound HTTP requests by endpoint group | p99 > SLA threshold |
| `http_request_count` | counter | Count of inbound HTTP requests by endpoint and status code | Error rate > configured threshold |
| `db_query_duration` | histogram | MySQL query latency by operation type | p99 > configured threshold |
| `db_connection_pool_active` | gauge | Active database connections per pool (primary, read, audit, reporting) | Near pool max |
| `cache_hit_rate` | gauge | Cache hit ratio for Redis and Memcached caches | Below configured minimum |
| `mbus_publish_count` | counter | Count of messages published to message bus | Error rate spike |
| `mbus_consume_count` | counter | Count of messages consumed from message bus | Consumer lag |
| `sftp_transfer_status` | gauge | Status of daily SFTP report transfers | Transfer failure |
| `worker_task_duration` | histogram | Duration of background worker tasks | Exceeds expected runtime |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Getaways Inventory Service Overview | Monitoring tool (consult service owner) | Consult service owner |
| Database Connection Pools | Monitoring tool | Consult service owner |
| Cache Performance | Monitoring tool | Consult service owner |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High API error rate | HTTP 5xx rate exceeds threshold for 5 minutes | critical | Check application logs; verify database connectivity; verify external dependency health |
| Database connection pool exhaustion | Active connections near maximum for any pool | critical | Check for slow queries or connection leaks; consider increasing pool size |
| Redis cache unavailable | Hotel Product or Inventory Product Redis not responding | warning | Check Redis instance health; service degrades to database-only reads |
| Memcached unavailable | Backpack Availability Cache not responding | warning | Check Memcached instance health; shopping flows will query Backpack live |
| Daily report generation failure | Report job status = failed or no completion within expected window | warning | Check worker task logs; verify SFTP endpoint accessibility; retry via Worker API |
| Message bus connectivity lost | MBus connection failures detected | critical | Check broker health; reservation and cancel events are delayed until recovery |
| SFTP transfer failure | Daily report CSV transfer fails | warning | Verify SFTP endpoint availability; check SSH key validity; retry transfer |

## Common Operations

### Restart Service

1. Verify no in-flight report generation or long-running worker tasks by checking `/v2/getaways/inventory/workers/tasks`.
2. Drain active connections at the load balancer level.
3. Restart the Tomcat instance via the platform's standard restart procedure.
4. Verify health by calling `/v2/getaways/inventory/status/db` and confirming a 200 response.
5. Re-enable traffic at the load balancer.

### Scale Up / Down

1. Adjust the instance count via the GCP deployment configuration or auto-scaling policy.
2. Monitor connection pool metrics to ensure the database can handle additional connections from new instances.
3. Verify cache hit rates remain stable after scaling -- additional instances should not cause a cache stampede.

### Database Operations

- **Migrations**: Flyway manages schema migrations. Run `flyway migrate` against the target environment's database before deploying a new service version that requires schema changes.
- **Backfills**: Use the Backfill API (`POST /v2/getaways/inventory/backfill`) to trigger inventory product backfill jobs. Monitor progress via the Worker API.
- **Report regeneration**: Trigger a manual report generation via `POST /v2/getaways/inventory/reporter/generate` or wait for the next scheduled Cron invocation.

## Troubleshooting

### Shopping availability returning stale data

- **Symptoms**: Consumer shopping flows return outdated availability or pricing
- **Cause**: Redis or Memcached caches serving stale entries; cache invalidation may have failed after an Extranet update
- **Resolution**: Check recent Extranet updates in audit logs; verify cache TTLs; if needed, trigger a cache flush for the affected hotel/product via the service (consult service owner for cache management procedures)

### Daily inventory report not generated

- **Symptoms**: No report CSV file appears on the SFTP endpoint within the expected daily window
- **Cause**: Cron container failed to trigger; Worker API endpoint unreachable; report generation encountered a data error; SFTP transfer failed
- **Resolution**: Check Cron container logs for execution errors; check Worker task status via `/v2/getaways/inventory/workers/tasks`; verify SFTP endpoint connectivity; manually trigger via `POST /v2/getaways/inventory/reporter/generate`

### Reservation creation failures

- **Symptoms**: HTTP 500 on `POST /v2/getaways/inventory/reservations`; reservation events not appearing in Backpack
- **Cause**: Database write failure; Backpack Reservation Service unavailable; message bus publish failure
- **Resolution**: Check database connectivity and connection pool health; verify Backpack service health; check message bus connectivity; review application logs for stack traces

### OTA updates not applying

- **Symptoms**: OTA partners report that rate or inventory updates are not reflected in availability queries
- **Cause**: OTA Update API returning errors; persistence failures; cache not invalidated after OTA write
- **Resolution**: Check OTA API logs for error responses; verify database writes via audit logs; confirm cache invalidation is firing for affected rate plans

### High database latency

- **Symptoms**: API response times elevated; connection pool metrics showing high utilization
- **Cause**: Slow queries; missing indexes; read replica lag; connection pool exhaustion
- **Resolution**: Identify slow queries via DB metrics; check index health; verify read replica replication lag; consider increasing connection pool size if within database limits

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down -- shopping and Extranet APIs unavailable | Immediate | Getaways Inventory Team + Platform Engineering |
| P2 | Degraded -- elevated error rates or latency; some flows failing | 30 min | Getaways Inventory Team |
| P3 | Minor impact -- daily report delayed; non-critical cache issues | Next business day | Getaways Inventory Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Getaways Inventory DB (MySQL) | `/v2/getaways/inventory/status/db` endpoint | No fallback -- database is required for all operations |
| Hotel Product Detail Cache (Redis) | Redis PING command | Service degrades to direct MySQL reads; elevated latency |
| Inventory Product Cache (Redis) | Redis PING command | Service degrades to direct MySQL reads; elevated latency |
| Backpack Availability Cache (Memcached) | Memcached stats command | Shopping flows query Backpack Reservation Service live; increased latency |
| Getaways Content Service | HTTP health check | Inventory responses returned without content enrichment |
| Backpack Reservation Service | HTTP health check | Reservation flows fail or are delayed; cached availability may be served |
| Voucher Inventory Service | HTTP health check | Voucher-dependent availability checks fail; non-voucher flows unaffected |
| Forex Service | HTTP health check | Multi-currency pricing may use cached rates or fail |
| Message Bus (MBus) | Broker connectivity check | Async events are delayed until bus recovers; synchronous operations unaffected |
| AWS SFTP Transfer | SFTP connectivity test | Daily report delivery delayed; can be retried |

> Operational procedures not discoverable from the architecture model should be defined by the service owner. This runbook is generated from the federated architecture DSL and represents the architectural view of operations.
