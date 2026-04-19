---
service: "subscription-programs-app"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/healthcheck` | http (Dropwizard standard) | Per Continuum platform k8s liveness probe config | Per k8s probe config |
| MySQL connectivity | Dropwizard health check (jtier-daas-mysql) | Included in `/healthcheck` response | — |
| MBus connectivity | Dropwizard health check (jtier-messagebus-client) | Included in `/healthcheck` response | — |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `membership.create.success` | counter | Successful membership creations | — |
| `membership.create.failure` | counter | Failed membership creation attempts | Spike above baseline |
| `membership.cancel.success` | counter | Successful cancellations | — |
| `killbill.webhook.received` | counter | KillBill webhook events received at `/select/killbill-event` | — |
| `killbill.webhook.processing.error` | counter | KillBill webhook events that failed processing | Any non-zero |
| `mbus.publish.success` | counter | Successful `MembershipUpdate` event publishes | — |
| `mbus.publish.failure` | counter | Failed MBus publish attempts | Any non-zero |
| `quartz.job.run` | counter | Background Quartz job executions (Worker container) | — |

### Dashboards

> Operational procedures to be defined by service owner. Dashboards are managed in Continuum's central monitoring tooling.

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| KillBill webhook processing errors | `killbill.webhook.processing.error` count > 0 in 5-minute window | warning | Inspect logs for event type and consumerId; verify KillBill connectivity and membership state in DB |
| MBus publish failures | `mbus.publish.failure` count > 0 | warning | Verify MBus broker connectivity; check for serialization errors in logs |
| Healthcheck failing | `/healthcheck` returns non-200 | critical | Check DB connectivity and MBus connectivity via sub-checks |
| High membership creation failure rate | `membership.create.failure` rate spikes | warning | Check KillBill availability; review error logs for root cause |

## Common Operations

### Restart Service

> Operational procedures to be defined by service owner. Use standard Continuum k8s rolling restart: `kubectl rollout restart deployment/subscription-programs-app` in the appropriate namespace.

### Scale Up / Down

> Operational procedures to be defined by service owner. Adjust k8s deployment replica count or HPA configuration through Continuum platform tooling.

### Database Operations

- Schema migrations: apply via the configured migration tooling (migration path not present in architecture inventory — confirm with AFL/Loyalty team)
- Ad-hoc queries: connect to `mm_programs` MySQL via Continuum's standard DB access controls
- Backfills: coordinate with AFL/Loyalty team; run as Quartz job or via migration script to avoid lock contention

## Troubleshooting

### Membership creation fails immediately after deploy

- **Symptoms**: `membership.create.failure` counter spikes; API returns 5xx errors
- **Cause**: KillBill connectivity lost (network policy, credential rotation, or KillBill downtime); or DB connectivity failure
- **Resolution**: Check `/healthcheck` sub-checks; verify `KILLBILL_BASE_URL`, `KILLBILL_USERNAME`, `KILLBILL_API_KEY` configuration; test KillBill reachability from the pod

### KillBill webhook events not updating membership status

- **Symptoms**: Members remain in incorrect status despite KillBill reporting payment success/failure
- **Cause**: Webhook endpoint returning errors; event deserialization failure; DB write failure
- **Resolution**: Check logs for `/select/killbill-event` requests; verify KillBill is receiving 200 responses; inspect `killbill.webhook.processing.error` metric; replay events from KillBill admin if necessary

### MembershipUpdate events not reaching downstream consumers

- **Symptoms**: Downstream services report stale membership state; `mbus.publish.failure` counter elevated
- **Cause**: MBus broker unreachable; topic misconfiguration; serialization error
- **Resolution**: Verify MBus broker connectivity (`MBUS_BROKER_URL`); check `jtier-messagebus-client` logs; confirm topic name `jms.topic.select.MembershipUpdate` matches consumer configuration

### Quartz worker jobs not executing

- **Symptoms**: Background membership maintenance not occurring (memberships not expiring, incentives not reconciled)
- **Cause**: Quartz scheduler misconfiguration; Worker container crashed; DB connectivity for Quartz job store
- **Resolution**: Check Worker container health; review Quartz scheduler logs; verify DB connectivity for job store tables

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no membership operations possible | Immediate | AFL/Loyalty team on-call |
| P2 | Degraded — KillBill integration failing, billing events not processed | 30 min | AFL/Loyalty team on-call |
| P3 | Minor impact — MBus publish failures, email delivery failures | Next business day | AFL/Loyalty team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumSubscriptionProgramsDb` | Included in `/healthcheck` via jtier-daas-mysql | No fallback — DB is required for all operations |
| KillBill | Tested on startup via `killbill-client-java`; no live health endpoint evidenced | Membership create/cancel operations fail-fast; webhook receipt can queue for retry |
| MBus (`jms.topic.select.MembershipUpdate`) | Included in `/healthcheck` via jtier-messagebus-client | Events may be lost if broker is unavailable; no local queue evidenced |
| Incentive Service | No dedicated health check evidenced | `guava-retrying` provides retry; incentive enrollment fails gracefully on timeout |
| Rocketman | No dedicated health check evidenced | Non-critical; email failures logged and not retried indefinitely |
