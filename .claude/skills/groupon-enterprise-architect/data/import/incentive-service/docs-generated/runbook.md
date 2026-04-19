---
service: "incentive-service"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /health` | http | > No evidence found in codebase. | > No evidence found in codebase. |

The `/health` endpoint is used by Kubernetes readiness and liveness probes. A non-2xx response causes the pod to be removed from the load balancer (readiness) or restarted (liveness).

## Monitoring

### Metrics

> No evidence found in codebase. Operational procedures to be defined by service owner. Standard JVM and Play Framework metrics (request rate, error rate, JVM heap, GC pause) are expected.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request rate | counter | Requests per second per endpoint | > No evidence found in codebase. |
| HTTP error rate | counter | 4xx/5xx responses per endpoint | > No evidence found in codebase. |
| Kafka consumer lag | gauge | Message processing lag per consumer group | > No evidence found in codebase. |
| JVM heap usage | gauge | JVM heap utilisation | > No evidence found in codebase. |
| Qualification job duration | histogram | Time to complete an audience qualification sweep | > No evidence found in codebase. |

### Dashboards

> No evidence found in codebase. Operational procedures to be defined by service owner.

| Dashboard | Tool | Link |
|-----------|------|------|
| Incentive Service Overview | > No evidence found. | > No evidence found. |

### Alerts

> No evidence found in codebase. Operational procedures to be defined by service owner.

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High HTTP error rate | 5xx rate exceeds threshold | critical | Check logs, verify data store connectivity |
| Kafka consumer lag growing | Consumer lag increasing over time | warning | Check messaging mode pod health; scale if needed |
| Qualification sweep failure | Akka job fails to complete | warning | Check batch mode logs; retry job via `/audience/qualify` |
| Bulk export job stuck | Export job status remains in-progress beyond expected duration | warning | Check bulk mode logs; review job status in PostgreSQL |

## Common Operations

### Restart Service

1. Identify the affected deployment by mode: `kubectl get deployments -l app=incentive-service`
2. Perform a rolling restart: `kubectl rollout restart deployment/<deployment-name>`
3. Monitor rollout: `kubectl rollout status deployment/<deployment-name>`
4. Verify health: `curl http://<pod-ip>:9000/health`

### Scale Up / Down

1. Adjust HPA min/max replicas: `kubectl patch hpa incentive-service-<mode> --patch '{"spec":{"minReplicas":<N>}}'`
2. Or directly scale deployment: `kubectl scale deployment incentive-service-<mode> --replicas=<N>`
3. HPA will resume automatic scaling based on CPU utilisation (70% target)

### Database Operations

- **PostgreSQL migrations**: > No evidence found in codebase. Operational procedures to be defined by service owner.
- **Cassandra schema changes**: > No evidence found in codebase. Operational procedures to be defined by service owner.
- **Redis cache flush**: Connect to `continuumIncentiveRedis` and flush relevant keys if stale cache causes validation inconsistencies.

## Troubleshooting

### Promo Code Validation Returning Incorrect Results

- **Symptoms**: Valid promo codes being rejected or invalid codes accepted
- **Cause**: Stale incentive definitions in Redis cache; PostgreSQL data inconsistency; Pricing Service returning incorrect eligibility context
- **Resolution**: Flush Redis incentive cache entries; verify PostgreSQL incentive record state; check Pricing Service (`continuumPricingService`) health and connectivity

### Audience Qualification Sweep Not Completing

- **Symptoms**: `GET /audience/:campaignId/status` shows stuck in-progress; `audience.qualified` event not published
- **Cause**: Akka actor job failure in batch mode; Bigtable connectivity issue; Cassandra write failures
- **Resolution**: Check batch mode pod logs for Akka actor errors; verify `BIGTABLE_PROJECT_ID`/`BIGTABLE_INSTANCE_ID` config; check `continuumIncentiveCassandra` or `continuumIncentiveKeyspaces` health; retry via `POST /audience/qualify`

### Order Redemptions Not Processing

- **Symptoms**: `order.confirmed` events consumed but redemptions not appearing in Cassandra; `incentive.redeemed` events not published
- **Cause**: `incentiveMessaging` consumer error; Cassandra write failure; Kafka producer failure
- **Resolution**: Check messaging mode pod logs; verify Cassandra/Keyspaces connectivity; verify Kafka broker connectivity (`KAFKA_BOOTSTRAP_SERVERS`)

### Bulk Export Jobs Stuck

- **Symptoms**: `GET /bulk-export/:jobId/status` shows in-progress beyond expected time
- **Cause**: Akka bulk export actor failure; Cassandra/PostgreSQL query timeouts on large date ranges; storage write failures
- **Resolution**: Check bulk mode pod logs; consider narrowing the export date range; verify data store connectivity

### Admin UI Not Loading

- **Symptoms**: `/admin/campaigns` returns errors or blank page
- **Cause**: Admin mode pod unhealthy; PostgreSQL connectivity issue
- **Resolution**: Check admin mode pod health via `GET /health`; verify `DB_URL`/`DB_USER`/`DB_PASSWORD` config; check `continuumIncentivePostgres` health

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — checkout validation failing | Immediate | CRM / Incentives Platform Team |
| P2 | Degraded — messaging or batch processing delayed | 30 min | CRM / Incentives Platform Team |
| P3 | Minor impact — admin UI or bulk export degraded | Next business day | CRM / Incentives Platform Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumIncentivePostgres` | Query test connection | No fallback — validation and admin flows blocked |
| `continuumIncentiveCassandra` / `continuumIncentiveKeyspaces` | CQL ping | No fallback — redemption and qualification writes blocked |
| `continuumIncentiveRedis` | PING command | Degraded caching; falls back to direct PostgreSQL reads |
| `continuumKafkaBroker` | Kafka consumer group status | Event publishing delayed; retry on reconnect |
| `messageBus` | STOMP connection status | Order events not processed; may cause redemption delays |
| `continuumPricingService` | `GET /health` on dependency | Validation eligibility checks fail; incentive validation blocked |
