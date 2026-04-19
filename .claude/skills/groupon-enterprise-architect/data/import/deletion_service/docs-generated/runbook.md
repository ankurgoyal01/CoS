---
service: "deletion_service"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/var/groupon/jtier/heartbeat.txt` | File heartbeat | Kubernetes liveness probe default | Kubernetes default |
| `http://localhost:8080/grpn/status` | HTTP (status endpoint disabled per `.service.yml`) | Not active | Not active |
| Port `8080` | HTTP health check (Kubernetes `healthcheckPort`) | Kubernetes liveness probe default | Kubernetes default |

> The `status_endpoint` is marked `disabled: true` in `.service.yml`. Kubernetes liveness probes target port `8080` via the `heartbeatPath`.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `eraseProcessor.received` | counter | Number of erase messages received from MBUS | — |
| `eraseProcessor.success` | counter | Number of erase messages successfully processed | — |
| `eraseProcessor.rejected` | counter | Number of erase messages rejected (null payload) | — |
| `eraseProcessor.error` | counter | Number of erase messages that caused processing errors | Alert on sustained increase |
| `eraseAction.success` | counter | Number of erase requests fully completed by the scheduler job | — |
| `eraseAction.fail` | counter | Number of erase requests that failed during scheduler execution | Alert on sustained increase |
| `eraseJob.success` | counter | Number of scheduler job executions that completed | — |

Metrics are emitted via the JTier SMA metrics system (Wavefront).

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Deletion Service SMA | Wavefront | `https://groupon.wavefront.com/dashboards/deletion-service--sma` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Wavefront alert (custom) | See `https://groupon.wavefront.com/u/rbhZp0CXYs?t=groupon` | warning/critical | Check MBUS connectivity, database connections, and error logs |

## Common Operations

### Restart Service

1. Log in to DeployBot: `https://deploybot.groupondev.com/goods/deletion_service`
2. Identify the current deployed version.
3. Re-deploy the same version to trigger a rolling restart in Kubernetes.
4. Monitor `eraseProcessor` and `eraseAction` metrics in Wavefront for recovery.

### Scale Up / Down

Scaling is managed via Kubernetes HPA. To temporarily override:
1. Update the `minReplicas`/`maxReplicas` values in the appropriate Raptor deployment YAML under `.meta/deployment/cloud/components/deletion-service-component/`.
2. Deploy the updated configuration via the deployment pipeline or DeployBot.

### Database Operations

To access the PostgreSQL Deletion Service DB from CLI:
1. Retrieve DaaS credentials from `deletion_service_secrets` (refer to internal secrets management tooling).
2. Use the DaaS CLI proxy to establish a connection.
3. Verify pending erasure requests: query the erase request table filtering on `finished_at IS NULL`.
4. Check failed service tasks: query the erase service table filtering on `error_code IS NOT NULL`.

Database migrations run automatically on service startup via JTier `jtier-migrations`.

## Troubleshooting

### Pending Erasure Requests Not Progressing

- **Symptoms**: Erase requests remain in an unfinished state; `eraseAction.success` metric not incrementing; no completion events published to MBUS
- **Cause**: Scheduler job disabled (`flags.runJobScheduler=false`), database connection saturation, or a downstream integration failure exhausting retries
- **Resolution**: Check `flags.runJobScheduler` in the active config file; check DaaS connection pool status; review ELK logs for `ERASE_ACTION_ERROR` or `ERASE_ACTION_PROCESS_FAIL` events; check downstream service health

### MBUS Consumer Not Receiving Messages

- **Symptoms**: `eraseProcessor.received` counter not incrementing; GDPR erasure requests not being created
- **Cause**: `flags.runMBusWorker=false`; MBUS broker connectivity issue; misconfigured topic name
- **Resolution**: Verify `flags.runMBusWorker=true` in config; check MBUS broker connectivity; confirm topic name matches `jms.topic.gdpr.account.v1.erased`; review ELK logs for MBUS connection errors

### Rocketman Integration Failures (ATTENTIVE option)

- **Symptoms**: SMS consent erase tasks marked failed; `ERASE_ACTION_PROCESS_DELETE_FAIL` log events referencing `SmsConsentServiceIntegration`
- **Cause**: Rocketman API unavailable; misconfigured `emailTo`, `emailType`, or `rocketmanServiceClient` credentials
- **Resolution**: Verify Rocketman API health; check `attentive` and `rocketmanServiceClient` configuration blocks; review ELK logs for `IntegrationFailedException` stack traces

### High Database Connection Usage

- **Symptoms**: Slow API response times; JDBC connection timeout errors in ELK logs; DaaS connection pool exhausted
- **Cause**: Scheduler job executing concurrent erasures; pending MBUS message backlog creating burst of new requests
- **Resolution**: Check pending erase request count; temporarily reduce MBUS consumer concurrency or scheduler frequency; check for long-running SQL queries via DaaS CLI

## Log Access

- **NA ELK**: `https://prod-kibana-unified.us-central1.logging.prod.gcp.groupondev.com/app/r/s/D40Dm`
- **EMEA ELK**: `https://logging-prod-eu-unified1.grpn-logging-prod.eu-west-1.aws.groupondev.com/goto/918062f0-a4b9-11ef-968a-91823da5ac96`

Filter by `sourceType: deletion_service`. Key log event names: `ERASE_PROCESSOR_RECEIVED`, `ERASE_PROCESSOR_SUCCESS`, `ERASE_PROCESSOR_ERROR`, `ERASE_ACTION_START`, `ERASE_ACTION_PROCESS_COMPLETE`, `ERASE_ACTION_PROCESS_FAIL`, `MBUS_ERASE_COMPLETE`, `MBUS_ERASE_COMPLETE_ERROR`.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no GDPR erasures being processed | Immediate | Display Advertising team (`da-communications@groupon.com`), GChat space `AAAAYDlPZ8Q` |
| P2 | Degraded — erasures processing slowly or accumulating failures | 30 min | Display Advertising team |
| P3 | Minor impact — isolated integration failures within retry threshold | Next business day | Display Advertising team |

- **SLA**: 99.9% uptime; p99 response time <5s for both GET and POST requests

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Deletion Service DB (PostgreSQL) | Query a simple read from the erase request table via DaaS CLI | No fallback; service cannot persist new requests without the DB |
| Orders MySQL | Query the Orders DaaS endpoint or check DaaS health dashboard | Erase tasks for `ORDERS` will fail and be retried up to `eraseRequestMaxRetries` times |
| Rocketman API | Call `POST /transactional/sendmessage` with a test payload | SMS consent tasks will fail and be retried; no circuit breaker in place |
| MBUS | Check MBUS broker health dashboard | New erase events will not be consumed; existing pending requests in DB will continue to be processed by the scheduler |
