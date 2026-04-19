---
service: "bots"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/healthcheck` | http | Kubernetes liveness probe interval | Kubernetes liveness probe timeout |
| `/ping` | http | Kubernetes readiness probe interval | Kubernetes readiness probe timeout |

> Specific probe intervals and timeouts are defined in Kubernetes deployment manifests managed by the JTier platform. Contact the BOTS team for current values.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `bots.bookings.created` | counter | Number of bookings successfully created | — |
| `bots.bookings.canceled` | counter | Number of bookings canceled | — |
| `bots.bookings.errors` | counter | Number of booking operation errors | Alert if rate spikes above baseline |
| `bots.availability.query.latency` | histogram | Latency of availability query responses | Alert if p99 exceeds SLA |
| `bots.worker.job.failures` | counter | Number of failed Quartz job executions | Alert if non-zero for critical jobs |
| `bots.mbus.consumer.lag` | gauge | Message Bus consumer lag for BOTS topics | Alert if lag grows unboundedly |
| `bots.calendar.sync.failures` | counter | Google Calendar sync job failures | Alert on repeated failures |

> Specific metric names follow JTier/Dropwizard conventions and may include service prefixes. Confirm exact metric names with the BOTS team.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| BOTS API Overview | Internal (Grafana / Datadog) | > Link not available in inventory |
| BOTS Worker Job Health | Internal (Grafana / Datadog) | > Link not available in inventory |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High booking error rate | `bots.bookings.errors` rate exceeds threshold | critical | Check `continuumBotsMysql` connectivity and upstream service health |
| Worker job failure | Quartz job repeatedly fails | warning | Review job logs; check downstream service (VIS, Google Calendar, Salesforce) health |
| Message Bus consumer lag | Consumer lag growing on `deal.onboarding` or `gdpr.erasure` topics | warning | Check Worker pod health; restart if stuck |
| Calendar sync failure | `bots.calendar.sync.failures` non-zero | warning | Check Google OAuth token validity; re-authenticate merchant if needed |
| Database connectivity | `continuumBotsMysql` unreachable | critical | Escalate to DBA and platform on-call |

## Common Operations

### Restart Service

1. Identify the pod(s) for `continuumBotsApi` or `continuumBotsWorker` in the target Kubernetes cluster/namespace.
2. Use `kubectl rollout restart deployment/bots-api` or `kubectl rollout restart deployment/bots-worker` (adjust deployment names per environment).
3. Monitor rollout with `kubectl rollout status deployment/bots-api`.
4. Verify health endpoint responds after restart: `curl http://<pod-ip>:<port>/healthcheck`.

### Scale Up / Down

1. Update the Helm values for `replicaCount` in the target environment.
2. Apply the updated Helm release: `helm upgrade bots ./helm/bots -f values-<env>.yaml`.
3. Alternatively, use `kubectl scale deployment/bots-api --replicas=<N>` for immediate scaling.

### Database Operations

- Schema migrations are applied via the service's migration tooling (JTier DaaS MySQL conventions) before deploying a new version.
- For backfills: coordinate with the BOTS team to run migration scripts against `continuumBotsMysql` during a maintenance window.
- GDPR erasure backfills: trigger via the `gdpr.erasure` Message Bus topic or by direct DB operation under GDPR process governance.

## Troubleshooting

### Bookings Failing to Create

- **Symptoms**: `POST /merchants/{id}/bookings` returns 5xx errors; `bots.bookings.errors` counter rising
- **Cause**: `continuumBotsMysql` connectivity issue, or upstream dependency failure (`continuumM3MerchantService`, `continuumVoucherInventoryService`)
- **Resolution**: Check DB connection pool saturation in logs; verify `continuumM3MerchantService` and `continuumVoucherInventoryService` are healthy; restart API pods if connection pool is exhausted

### Calendar Sync Not Running

- **Symptoms**: Merchant calendars out of date; `bots.calendar.sync.failures` non-zero; Quartz job logs show errors
- **Cause**: Google OAuth token expired or revoked; Google Calendar API quota exceeded; `continuumBotsWorker` pod unhealthy
- **Resolution**: Check Google OAuth token validity for affected merchants; re-authenticate if expired; check Google API quota in Google Cloud Console; restart Worker pods if needed

### Message Bus Consumer Stuck

- **Symptoms**: `deal.onboarding` or `gdpr.erasure` events not processed; consumer lag growing
- **Cause**: Worker pod crashed or deadlocked; Message Bus broker connectivity issue
- **Resolution**: Restart `continuumBotsWorker` pods; verify Message Bus broker connectivity; check DLQ for failed messages

### GDPR Erasure Not Completing

- **Symptoms**: `gdpr.erasure` events in DLQ; personal data not removed from `continuumBotsMysql`
- **Cause**: DB write failure; worker crash during erasure processing
- **Resolution**: Review Worker logs for erasure job failures; replay events from DLQ after resolving underlying issue; escalate to BOTS team for manual erasure if automated processing cannot recover

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | BOTS API completely down; no bookings can be created or managed | Immediate | BOTS team (ssamantara, rdownes, joeliu) + platform on-call |
| P2 | Degraded availability (high latency, partial errors, worker jobs failing) | 30 min | BOTS team (ssamantara, rdownes, joeliu) |
| P3 | Calendar sync delayed; non-critical job failures | Next business day | BOTS team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumBotsMysql` | Check DB connection pool metrics; attempt test query | No fallback — booking operations fail if DB is unavailable |
| `continuumM3MerchantService` | Check service health endpoint; monitor error rates in logs | Booking creation fails gracefully with upstream error |
| `continuumVoucherInventoryService` | Check service health endpoint | Voucher redemption and booking creation fail gracefully |
| `messageBus` | Check consumer lag and broker connectivity | Event consumption pauses; events queue up for retry |
| Google Calendar API | Check sync job success metrics | Calendar sync suspended; bookings continue to function without calendar updates |
| Salesforce | Check onboarding job success in Worker logs | Onboarding sync jobs fail and retry; merchant setup may be delayed |
