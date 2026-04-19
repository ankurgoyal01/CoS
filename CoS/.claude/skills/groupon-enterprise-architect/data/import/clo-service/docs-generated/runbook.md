---
service: "clo-service"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/health` or `/status` (Rails standard) | http | Not evidenced | Not evidenced |
| Sidekiq Web UI (`/admin/sidekiq`) | http | On demand | Not evidenced |
| Scheduled health reporter job | scheduled | Periodic (sidekiq-scheduler) | Not evidenced |

> Operational procedures to be defined by service owner. Specific health endpoint paths and intervals are not evidenced in the architecture inventory.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Sidekiq queue depth | gauge | Number of pending jobs per queue | Operational procedures to be defined by service owner |
| Sidekiq dead job count | counter | Count of permanently failed jobs | Any increase |
| Claim processing rate | counter | Number of claims processed per interval | Operational procedures to be defined by service owner |
| Enrollment success rate | gauge | Ratio of successful card enrollments to attempts | Operational procedures to be defined by service owner |
| Card network callback latency | histogram | Response time for Visa/Mastercard/Amex callbacks | Operational procedures to be defined by service owner |
| Statement credit failure count | counter | Count of failed statement credit issuances | Any increase — SOX-sensitive |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| CLO Service Operations | Not evidenced | Operational procedures to be defined by service owner |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Sidekiq dead jobs spike | Dead job queue growing | critical | Investigate failed jobs; check card network connectivity; review retry backlog |
| Claim processing stopped | No claims processed for extended period | critical | Check worker health; verify Message Bus connectivity; check card network callbacks |
| GDPR erasure backlog | `gdpr.erasure` messages not being processed | critical | Immediate escalation — compliance SLA breach risk |
| Card network callback errors | High error rate on `/clo/api/v1/visa` or `/clo/api/v1/mastercard` | critical | Check card network status; verify authentication credentials; review payload format |
| Statement credit failures | Elevated statement credit error rate | warning | Check Orders Service connectivity; review claim state; escalate if persistent |

## Common Operations

### Restart Service

> Operational procedures to be defined by service owner. Standard Kubernetes rolling restart applies: `kubectl rollout restart deployment/clo-service-api` and `kubectl rollout restart deployment/clo-service-worker`.

### Scale Up / Down

> Operational procedures to be defined by service owner. Adjust Kubernetes replica count for API pods. For worker scaling, increase `SIDEKIQ_CONCURRENCY` or add worker pods. Be aware that increasing Sidekiq concurrency increases database connection pool pressure.

### Database Operations

> Operational procedures to be defined by service owner. Standard Rails migration process: `bundle exec rake db:migrate RAILS_ENV=production`. The `ar-octopus` shard configuration must be considered when running migrations against sharded databases. Run migrations during low-traffic windows given SOX in-scope status.

## Troubleshooting

### Enrollment failures from card networks
- **Symptoms**: High error rate on card enrollment API calls; users report cards not activating
- **Cause**: Card network API credential rotation, network outage, or payload format change
- **Resolution**: Verify card network API credentials in vault; check card network status pages; review error responses in logs; re-enqueue failed enrollment jobs via Sidekiq Web UI

### Claims not being processed
- **Symptoms**: Claims not appearing in user accounts; Sidekiq queue depth growing
- **Cause**: Worker down, Redis connectivity issue, or Message Bus consumer failure
- **Resolution**: Check `continuumCloServiceWorker` pod health; verify `continuumCloServiceRedis` connectivity; check Message Bus consumer group offsets; review Sidekiq dead jobs

### GDPR erasure not completing
- **Symptoms**: `gdpr.erasure` events in queue but not processed; user data still present
- **Cause**: Worker failure, database connectivity issue, or code error in erasure handler
- **Resolution**: Immediate escalation to CLO Team lead and compliance; investigate worker logs; manually process if necessary; this is a compliance-critical path

### Statement credits not issuing
- **Symptoms**: Approved claims not resulting in statement credits; users reporting missing credits
- **Cause**: Orders Service unavailable, billing record mismatch, or Visa/Mastercard settlement file delay
- **Resolution**: Check `continuumOrdersService` health; verify `BillingRecordUpdate` events are flowing; check card network file transfer status; review claim state machine transitions in database

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no enrollments or claims processing | Immediate | CLO Team (sox-inscope) |
| P2 | Degraded — partial claim failures or enrollment errors | 30 min | CLO Team |
| P3 | Minor impact — delayed processing or non-critical errors | Next business day | CLO Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumCloServicePostgres` | ActiveRecord connection check | No fallback — service cannot function without database |
| `continuumCloServiceRedis` | Redis PING | No fallback for Sidekiq; cache misses gracefully degrade to DB reads |
| `messageBus` | Consumer group lag monitoring | Events buffer in Message Bus; delayed processing when reconnected |
| Visa / Mastercard / Amex | Card network status pages; callback endpoint monitoring | Enrollment and claim processing suspended until restored |
| `continuumOrdersService` | REST health endpoint | Statement credit processing paused; claims remain in pending state |
