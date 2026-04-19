---
service: "deal-service"
title: Runbook
generated: "2026-03-02"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `echo ready` (readiness probe) | exec | 5s period, 20s initial delay | > No evidence found |
| `echo live` (liveness probe) | exec | 15s period, 30s initial delay | > No evidence found |

Note: deal-service exposes no HTTP health endpoint. Kubernetes probes use exec commands inside the container.

## Monitoring

### Metrics

> No evidence found — metrics are not explicitly defined in the service inventory. Operational signals are derived from log analysis in Splunk (sourceType: `mds_json`) and from Kubernetes pod metrics surfaced via VPA.

### Dashboards

> No evidence found — dashboard links are not defined in the service inventory. Splunk is the primary log analysis tool.

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Pod restart alert | Pod restarts detected by Rapt | warning | Check Splunk logs for crash cause; verify Redis connectivity and config load; see [Worker Process Restart Flow](flows/worker-process-restart.md) |
| Deployment notification | Deploy event | info | Verify deal processing resumes within one polling interval (5s default) |

- **Alert channel**: Slack channel `mis-deployment`
- **Alert tool**: Rapt CI/CD agent (pod restart and deployment events)

## Common Operations

### Restart Service

1. Identify the Kubernetes deployment name for the target environment (e.g., `deal-service` in `production-us-west-1`).
2. Use `kubectl rollout restart deployment/deal-service -n <namespace>` to perform a rolling restart.
3. Confirm new pods reach `Running` state and pass readiness probe (`echo ready`).
4. Monitor Splunk (`sourceType: mds_json`) for log output confirming deal processing has resumed.
5. No deal data is lost on restart — in-flight deal IDs remain in the Redis `processing_cloud` sorted set and will be re-picked by the new worker.

### Scale Up / Down

1. HPA manages scaling automatically based on 50% CPU target (min 3, max 15 replicas).
2. To manually override: `kubectl scale deployment/deal-service --replicas=<N> -n <namespace>` (temporary; HPA will re-assert).
3. To adjust HPA bounds, update the Kubernetes HPA manifest and apply via Rapt deployment.

### Database Operations

- **PostgreSQL**: Schema migrations path is not evidenced in the service inventory. Contact the MIS team for migration procedures.
- **MongoDB**: Schema-less; no migration tooling observed.
- **Redis (Local)**: Inspect queue depth with `ZCARD processing_cloud` and retry queue depth with `ZCARD nodejs_deal_scheduler` on the local Redis instance.
- **Redis (BTS)**: Cache entries can be inspected or flushed via standard Redis CLI commands against `REDIS_BTS_HOST:REDIS_BTS_PORT`.

## Troubleshooting

### Deals not being processed

- **Symptoms**: Deal state in MongoDB not updating; inventory update events not appearing on message bus; `processing_cloud` queue growing without being drained
- **Cause**: Worker process crashed and not restarting; Redis connectivity failure; `feature_flags.processDeals.active` is `false` in keldor-config
- **Resolution**: Check pod status and logs in Splunk. Verify `REDIS_LOCAL_HOST` / `REDIS_LOCAL_PORT` connectivity. Check keldor-config flag `feature_flags.processDeals.active`. Restart pod if worker is stuck.

### Inventory update events not published to message bus

- **Symptoms**: `INVENTORY_STATUS_UPDATE` events missing from the message bus topic; `deal_mbus_updates` table showing unresolved records
- **Cause**: `deal_option_inventory_update.mbus_producer.active` feature flag is `false`; message bus connectivity issue; topic name misconfigured via `deal_option_inventory_update.mbus_producer.topic`
- **Resolution**: Verify the keldor-config flags via `KELDOR_CONFIG_SOURCE`. Check nbus-client connectivity. Inspect `deal_mbus_updates` in PostgreSQL for failed publish records.

### High retry queue depth

- **Symptoms**: `nodejs_deal_scheduler` Redis sorted set growing; deals not progressing to completion
- **Cause**: Upstream API failures (DMAPI, Deal Catalog, Geo Services, Forex) causing repeated processing failures; Salesforce connectivity issue
- **Resolution**: Check Splunk logs for which API calls are failing. Verify API client IDs in environment variables. Check upstream service health. Once upstream is restored, deals will self-recover from the retry queue.

### Worker process crash loop

- **Symptoms**: Frequent pod restarts; Rapt sending alerts to `mis-deployment` Slack channel
- **Cause**: Unhandled exception in CoffeeScript worker; MongoDB or PostgreSQL connection failure at startup; keldor-config unable to load
- **Resolution**: Check Splunk for stack trace. Verify `MONGO_STR`, Redis, and `KELDOR_CONFIG_SOURCE` env vars are set correctly. See [Worker Process Restart Flow](flows/worker-process-restart.md).

### Configuration not reflecting latest keldor-config values

- **Symptoms**: Processing running at old batch size or interval; feature flag changes not taking effect
- **Cause**: `configUpdate` listener not firing; `KELDOR_CONFIG_SOURCE` pointing to wrong environment
- **Resolution**: Restart the pod to force a fresh config load on startup. Verify `KELDOR_CONFIG_SOURCE` points to the correct environment endpoint. See [Dynamic Configuration Reload Flow](flows/dynamic-configuration-reload.md).

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Deal processing fully stopped; inventory state stale across all deals | Immediate | Marketing Information Systems (MIS) on-call |
| P2 | Inventory update publishing disabled; processing degraded | 30 min | MIS team via `mis-deployment` Slack |
| P3 | Individual deal processing failures; retry queue elevated | Next business day | MIS team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumDealServiceRedisLocal` | `ZCARD processing_cloud` returns non-error | Worker cannot process; stalls until Redis is available |
| `continuumDealServiceMongo` | Connection established at startup | Startup fails; pod restarts via Kubernetes liveness probe |
| `continuumDealServicePostgres` | Sequelize connection pool established at startup | Startup fails; pod restarts |
| `continuumDealManagementApi` | HTTP response to deal fetch request | Deal rescheduled to `nodejs_deal_scheduler` with backoff |
| `messageBus` | nbus-client publish succeeds | Publish failure tracked in `deal_mbus_updates`; retried on next processing cycle |
| Keldor Config Service | Config load response on startup | Service starts with defaults or last-known config |

> Operational procedures beyond those evidenced in the service inventory should be defined by the MIS service owner.
