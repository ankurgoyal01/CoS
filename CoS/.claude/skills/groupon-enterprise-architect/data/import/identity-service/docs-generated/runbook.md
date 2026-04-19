---
service: "identity-service"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /heartbeat` | http | To be configured by deployment | To be configured by deployment |
| `GET /status` | http | To be configured by deployment | To be configured by deployment |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request rate | counter | Requests per second to `continuumIdentityServiceApp` | To be defined |
| HTTP error rate (5xx) | counter | Rate of server errors on identity API endpoints | Alert if above 1% sustained |
| HTTP latency (p99) | histogram | Request latency at the 99th percentile | Alert if above SLA threshold |
| Resque queue depth | gauge | Number of pending jobs in the Mbus consumer Resque queue | Alert if growing unbounded |
| Resque failed jobs | counter | Number of failed Resque jobs | Alert if non-zero sustained |
| PostgreSQL connection pool | gauge | Active vs. available DB connections | Alert near pool exhaustion |
| Message Bus publish failures | counter | Undelivered messages in `message_bus_messages` outbox | Alert if backlog grows |

Metrics emitted via Sonoma metrics library (sonoma-logger/metrics).

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Identity Service HTTP API | To be confirmed | Managed by Identity / Account Management team |
| Resque Job Queue | To be confirmed | Managed by Identity / Account Management team |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Identity API down | `/heartbeat` returns non-200 | critical | Restart pods; check Puma logs for startup errors |
| High 5xx error rate | HTTP 5xx rate above threshold | critical | Check PostgreSQL connectivity; check Message Bus connectivity; inspect application logs |
| Resque queue depth growing | Queue depth increasing monotonically | warning | Check Mbus consumer worker health; verify Redis connectivity; check for stuck jobs in failed queue |
| GDPR erasure backlog | GDPR erasure jobs not processing | critical | Check `continuumIdentityServiceMbusConsumer` pods; verify Message Bus connectivity; escalate to GDPR Platform team |
| Message Bus publish backlog | `message_bus_messages` outbox growing | warning | Check Message Bus connectivity; verify publisher process is running |

## Common Operations

### Restart Service

**HTTP API (`continuumIdentityServiceApp`)**:
1. Perform a rolling restart: `kubectl rollout restart deployment/identity-service-app -n <namespace>`.
2. Verify `/heartbeat` returns 200: `curl https://<host>/heartbeat`.
3. Confirm identity API responds correctly with a test request.

**Mbus Consumer (`continuumIdentityServiceMbusConsumer`)**:
1. Perform a rolling restart: `kubectl rollout restart deployment/identity-service-mbus-consumer -n <namespace>`.
2. Verify Resque queue depth begins decreasing after restart.

### Scale Up / Down

**HTTP API**: Adjust the HPA `maxReplicas` in the Kubernetes manifest or manually: `kubectl scale deployment/identity-service-app --replicas=N -n <namespace>`.

**Mbus Consumer**: Scale based on Resque queue depth: `kubectl scale deployment/identity-service-mbus-consumer --replicas=N -n <namespace>`. Resque workers are stateless and safe to scale horizontally.

### Database Operations

- **Run migrations**: `bundle exec rake db:migrate RACK_ENV=production` — run from a migration job pod, not from a running API pod.
- **Check pending migrations**: `bundle exec rake db:migrate:status RACK_ENV=production`.
- **Inspect message bus outbox**: Query `SELECT COUNT(*) FROM message_bus_messages WHERE published_at IS NULL` to check for unpublished events.
- **Manual erasure verification**: After a GDPR erasure, verify the identity record is erased in PostgreSQL by UUID.

## Troubleshooting

### Identity API returns 500 for all requests
- **Symptoms**: All `/v1/identities` calls return HTTP 500; `/heartbeat` may still return 200
- **Cause**: PostgreSQL connection failure, ActiveRecord pool exhaustion, or a code-level exception
- **Resolution**: Check application logs for ActiveRecord connection errors; verify `DATABASE_URL` is reachable from the pod; check PostgreSQL max connections; restart if connection pool is exhausted

### GDPR erasure events not being processed
- **Symptoms**: GDPR erasure requests arrive but identities are not erased; Resque failed queue grows
- **Cause**: Mbus consumer worker is down, Redis is unavailable, or a bug in the erasure handler
- **Resolution**: Check `continuumIdentityServiceMbusConsumer` pod logs; verify Redis connectivity; inspect Resque failed queue for error details; if needed, manually re-enqueue failed jobs

### Message Bus publish backlog growing
- **Symptoms**: `message_bus_messages` table has a growing count of unpublished rows
- **Cause**: Message Bus is unreachable, or the outbox relay process is not running
- **Resolution**: Check Message Bus connectivity (`MBUS_HOST`, `MBUS_PORT`, credentials); verify the outbox relay process is running; check for authentication errors in application logs

### JWT authentication failures (401 on all requests)
- **Symptoms**: All authenticated API calls return 401 Unauthorized
- **Cause**: `JWT_SECRET` is misconfigured, expired, or rotated without updating the service
- **Resolution**: Verify `JWT_SECRET` environment variable matches the signing key used by the issuer; coordinate with the auth team for key rotation

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Identity API fully down — no identity operations possible | Immediate | Identity / Account Management team |
| P1 | GDPR erasure completely stalled — compliance at risk | Immediate | Identity team + GDPR / Privacy Engineering |
| P2 | Degraded API (high error rate or latency) | 30 min | Identity / Account Management team |
| P2 | Mbus consumer lagging — events not processing promptly | 30 min | Identity / Account Management team |
| P3 | Minor — isolated endpoint errors, slow cache hit rate | Next business day | Identity / Account Management team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| PostgreSQL (`continuumIdentityServicePrimaryPostgres`) | ActiveRecord ping; connection pool status | No fallback — all identity CRUD fails if PostgreSQL is unavailable |
| Redis (`continuumIdentityServiceRedis`) | Redis PING command | Cache miss fallback to PostgreSQL reads; Resque jobs stall if Redis is unavailable |
| Message Bus | Check `message_bus_messages` outbox depth; verify consumer lag | Publishing buffers in outbox; consumption stops until reconnected |
| GDPR Platform | Monitor GDPR erasure event delivery and `gdpr.account.v1.erased.complete` confirmation rate | No automated fallback — escalate to GDPR Platform team |
