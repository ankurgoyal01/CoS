---
service: "bynder-integration-service"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/healthcheck` (Dropwizard built-in) | http | > No evidence found in codebase. | > No evidence found in codebase. |
| `/ping` (Dropwizard built-in) | http | > No evidence found in codebase. | > No evidence found in codebase. |

> Dropwizard registers `/healthcheck` and `/ping` on the admin port by default. Exact admin port configuration is in `config.yml`.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `bynder.sync.images.pulled` | counter | Number of images pulled from Bynder per sync cycle | > No evidence found in codebase. |
| `bynder.sync.duration` | histogram | Duration of each scheduled Bynder sync cycle | > No evidence found in codebase. |
| `iam.sync.images.pulled` | counter | Number of images pulled from IAM per sync cycle | > No evidence found in codebase. |
| `messagebus.events.consumed` | counter | Count of message bus events processed by `bisMessageProcessors` | > No evidence found in codebase. |
| `messagebus.events.failed` | counter | Count of failed message bus event processing attempts | > No evidence found in codebase. |
| `api.request.duration` | histogram | HTTP request duration across all API endpoints | > No evidence found in codebase. |

> Exact metric names require verification against service code. Dropwizard/Codahale Metrics are expected given the JTier framework.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| > No evidence found in codebase. | > No evidence found in codebase. | > No evidence found in codebase. |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Bynder sync failure | Scheduled Bynder pull job fails consecutively | critical | Check Bynder API credentials and connectivity; inspect Quartz job logs |
| Message bus consumer lag | Event processing queue depth grows without decrease | warning | Check `bisMessageProcessors` thread health; verify message bus connectivity |
| Database connection failures | MySQL connection pool exhausted or unreachable | critical | Verify database host, credentials, and pool configuration |
| Image Service propagation failures | Errors pushing to Image Service after sync | warning | Check Image Service health; verify `IMAGE_SERVICE_URL` config |

## Common Operations

### Restart Service

> Operational procedures to be defined by service owner.

1. Identify the running container/process for `continuumBynderIntegrationService`
2. Issue a graceful shutdown (allow in-flight HTTP requests and active Quartz jobs to complete)
3. Restart the container
4. Verify Dropwizard health check at `/healthcheck` returns healthy status
5. Confirm Quartz jobs are scheduled by checking service startup logs

### Scale Up / Down

> Operational procedures to be defined by service owner.

Adjust deployment replicas via the orchestration platform. Note that Quartz scheduler runs in-process — if multiple instances are deployed, ensure Quartz is configured for clustered mode to avoid duplicate scheduled job execution.

### Database Operations

- **Migrations**: Run via Maven/Flyway or JDBI migration tooling against `continuumBynderIntegrationMySql`
- **Backfills**: Trigger via GET `/bynder/pull` or `/iam/pull` to re-sync all assets
- **Manual single asset resync**: Trigger via GET `/bynder/images/{id}/pull` or `/iam/images/{id}/pull`

## Troubleshooting

### Bynder images not appearing in the Editorial Client App
- **Symptoms**: Images visible in Bynder DAM are not queryable via `/api/v1/images/`
- **Cause**: Scheduled sync job not running, Bynder API credentials expired, or Image Service propagation failing
- **Resolution**: Trigger a manual sync via GET `/bynder/pull`; check Bynder OAuth token validity; verify `IMAGE_SERVICE_URL` is reachable

### Taxonomy metadata stale or missing
- **Symptoms**: Incorrect or missing taxonomy categories in image metadata
- **Cause**: Taxonomy sync job not running or Taxonomy Service returning errors
- **Resolution**: Trigger manual taxonomy sync via GET `/taxonomy/update`; check `TAXONOMY_SERVICE_URL` and Taxonomy Service health

### Message bus events accumulating unprocessed
- **Symptoms**: Growing queue depth; images not updating despite events being published
- **Cause**: `bisMessageProcessors` threads deadlocked or message bus connectivity lost
- **Resolution**: Check Dropwizard thread pool utilization; verify `MESSAGE_BUS_URL` and credentials; restart service if threads are stuck

### Upload endpoint returns error
- **Symptoms**: POST `/api/v1/images/upload` returns 500 or 422
- **Cause**: Bynder API upload endpoint error, payload validation failure, or database write failure
- **Resolution**: Check Bynder API response in application logs; verify request payload format; confirm database connectivity

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — Editorial team cannot access or sync images | Immediate | > No evidence found in codebase. |
| P2 | Sync pipeline stalled — images not updating, API degraded | 30 min | > No evidence found in codebase. |
| P3 | Minor impact — stock recommendations unavailable, taxonomy stale | Next business day | > No evidence found in codebase. |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `bynder` | Bynder SDK connectivity check at startup; verify OAuth token validity | Sync pauses; local cached data remains queryable |
| `continuumBynderIntegrationMySql` | Dropwizard DB health check in `/healthcheck` | 503 on all read/write API endpoints |
| `continuumImageService` | HTTP GET to Image Service health endpoint | Images sync to local DB but not propagated |
| `messageBus` | Message bus consumer connectivity check | Event-driven updates stall; scheduled sync continues |
