---
service: "inbox_management_platform"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/healthcheck` | http | Kubernetes liveness probe interval | Kubernetes liveness probe timeout |

The `/grpn/healthcheck` endpoint is served by the Admin UI container (`continuumInboxManagementAdminUi`) and reflects overall daemon and dependency health.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `calc_queue_depth` | gauge | Current depth of the calculation queue in Redis | Alert when sustained above configured max |
| `dispatch_queue_depth` | gauge | Current depth of the dispatch queue in Redis | Alert when sustained above configured max |
| `send_error_count` | counter | Number of send errors received via SendErrorEvents | Alert on spike above baseline |
| `coordination_worker_lag` | gauge | Processing lag of the coordination worker daemon | Alert on high lag |
| `user_sync_lag` | gauge | Lag in user attribute synchronization | Alert on extended staleness |

Metrics are emitted via `arpnetworking-metrics-client` 0.3.2.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Inbox Management Queue Health | Internal monitoring platform | > Link to be provided by service owner |
| Daemon Processing Rates | Internal monitoring platform | > Link to be provided by service owner |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| CalcQueueDepthHigh | Calc queue depth exceeds configured threshold for > 5 min | warning | Check coord-worker daemon status; verify Campaign Management is not overproducing; scale coord-worker replicas if needed |
| DispatchQueueDepthHigh | Dispatch queue depth exceeds configured threshold for > 5 min | warning | Check dispatcher and rocketman-publisher status; verify Kafka topic is healthy; check RocketMan availability |
| DaemonDown | Kubernetes pod for a daemon type has 0 running replicas | critical | Restart deployment; check pod logs; verify Redis and Postgres connectivity |
| SendErrorRateHigh | Send error count spikes significantly above baseline | warning | Check SendErrorEvent topic; review error records in Postgres; check RocketMan health |

## Common Operations

### Restart Service

1. Identify the affected daemon deployment in Kubernetes (e.g., `inbox-coord-worker`, `inbox-dispatcher`).
2. Run `kubectl rollout restart deployment/<daemon-name> -n <namespace>`.
3. Monitor pod status with `kubectl get pods -n <namespace> -l app=<daemon-name>`.
4. Confirm `/grpn/healthcheck` returns healthy after rollout completes.

### Scale Up / Down

1. To temporarily adjust daemon active state without redeployment, use the Admin API:
   - `PUT /im/admin/config/daemon.<daemon_name>.active` with value `false` to pause a daemon.
   - `PUT /im/admin/config/daemon.<daemon_name>.active` with value `true` to resume.
2. To change Kubernetes replica count: `kubectl scale deployment/<daemon-name> --replicas=<N> -n <namespace>`.

### Adjust Throttle Rates

Use the Admin API to update throttle and circuit breaker config without redeployment:
- `PUT /im/admin/config/<throttle_key>` with the new numeric value.
- Changes take effect on the next daemon config reload cycle.

### Database Operations

- Config changes: Managed via `/im/admin/config/*` Admin API; direct Postgres modification is not recommended.
- Error record review: Query `continuumInboxManagementPostgres` error tables filtered by error_type and time range.
- Schema migrations: Managed by the Push - Inbox Management team via their standard migration process (not discoverable from architecture model).

## Troubleshooting

### Calc Queue Not Draining
- **Symptoms**: `calc_queue_depth` metric rising; no coord-worker throughput
- **Cause**: Coord-worker daemon stopped or paused; CAS arbitration circuit open blocking processing; Campaign Management API unavailable
- **Resolution**: Check `daemon.coord_worker.active` config flag; check circuit breaker config for CAS; verify Campaign Management API health; restart coord-worker if needed

### Dispatch Queue Backing Up
- **Symptoms**: `dispatch_queue_depth` rising; SendEvents not appearing in RocketMan
- **Cause**: Dispatcher or rocketman-publisher stopped; Kafka broker unavailable; RocketMan consumer lag
- **Resolution**: Check dispatcher daemon status; verify Kafka topic health; check rocketman-publisher logs for producer errors; verify Kafka bootstrap server connectivity

### User Attributes Stale
- **Symptoms**: User sync lag metric high; dispatch decisions using outdated user data
- **Cause**: EDW JDBC connection failure; user-sync daemon paused or down
- **Resolution**: Check `daemon.user_sync.active` flag; verify EDW credentials and connectivity; restart user-sync daemon

### High Send Error Rate
- **Symptoms**: `send_error_count` spike; error records accumulating in Postgres
- **Cause**: RocketMan returning errors; downstream channel (SMTP/APNS/FCM) degraded; malformed payload
- **Resolution**: Check RocketMan health; review error records in Postgres for error_type patterns; check payload serialization if errors are schema-related

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | All daemon processing stopped; no sends dispatched | Immediate | Push - Inbox Management team (dgupta) |
| P2 | One or more daemon types degraded; partial send throughput | 30 min | Push - Inbox Management team (dgupta) |
| P3 | Minor metric anomaly; no user-visible impact | Next business day | Push - Inbox Management team (dgupta) |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumInboxManagementRedis` | Check Jedis connection pool; queue depth metrics nominal | Queues back up; processing pauses; daemons enter retry loop |
| `continuumInboxManagementPostgres` | JDBC connection test; config reads succeed | Daemons use last loaded config; error writes fail and retry |
| Campaign Management API | `inbox_campaignManagementClient` call succeeds | Circuit breaker opens; coordination pauses for affected campaigns |
| CAS Arbitration | `inbox_arbitrationClient` call succeeds | Circuit breaker opens; configurable fail-open or fail-closed behavior |
| RocketMan (Kafka) | Kafka producer send succeeds; no errors in publisher logs | Dispatch queue backs up; no sends delivered downstream |
| EDW | Hive JDBC query returns results | Stale user attributes used; user sync falls behind |
