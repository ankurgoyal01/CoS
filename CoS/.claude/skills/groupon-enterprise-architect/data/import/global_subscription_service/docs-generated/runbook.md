---
service: "global_subscription_service"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/healthcheck` (port 9000) | http | 30s | 30s |
| `GET /grpn/healthcheck` (port 9000) — liveness | http | 30s | 30s |

Both readiness and liveness probes hit the same `/grpn/healthcheck` endpoint with a 30-second initial delay and 30-second period. The endpoint returns HTTP 200 with `text/plain` body when healthy.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| JVM heap usage | gauge | Heap memory utilized by the JVM process | Set by memory limit: 6Gi (common), 10Gi (production) |
| HTTP request rate | counter | Inbound requests per second across all endpoints | Baseline established from Wavefront dashboard |
| HTTP error rate (5xx) | counter | Server-side errors on consent and push token APIs | Threshold defined in PagerDuty alert rules |
| MBus consumer lag | gauge | Message processing backlog for subscription/GDPR/travellers consumers | Threshold defined by MBus platform |
| Kafka consumer lag (PTS) | gauge | Push token system event processing backlog | Threshold defined by Kafka platform |
| Database connection pool | gauge | Active/idle connections to SMS Consent Postgres and Push Token Postgres | Pool saturation triggers |

> Metric names follow Dropwizard Metrics conventions as shipped via `metrics3-tools` (4.1.0).

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Global Subscription Service ELK | Wavefront | https://groupon.wavefront.com/dashboard/global-subscription-service-elk |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Service down | Health check fails | P1 | Page on-call via PagerDuty P1NQCYT; check pod status and logs |
| High error rate | 5xx response rate exceeds baseline | P2 | Check downstream dependency health (User Service, Consent Service, Postgres); review steno.log |
| MBus consumer stopped | Consumer thread not processing messages | P2 | Check `messageBusConsumersEnabled` config; restart pod if consumer is stuck |
| OOM kill | Container killed by Kubernetes OOM | P2 | Review `MALLOC_ARENA_MAX` setting; check heap usage; scale up memory or replicas |
| Kafka connectivity failure | Cannot connect to `KAFKA_ENDPOINT` | P2 | Verify `kafka-tls-v2.sh` ran successfully at startup; check cert expiry in `/var/groupon/certs` |

PagerDuty: https://groupon.pagerduty.com/services/P1NQCYT
Alert email: global-subscription-service-alert@groupon.pagerduty.com
Slack: #subscription-engineering (C017W7A3NKT)

## Common Operations

### Restart Service

1. Identify the affected pod: `kubectl get pods -n global-subscription-service-<env>`
2. Delete the pod to trigger a rolling restart: `kubectl delete pod <pod-name> -n global-subscription-service-<env>`
3. Kubernetes will reschedule a replacement pod automatically.
4. For a full rolling restart: `kubectl rollout restart deployment/global-subscription-service-gss -n global-subscription-service-<env>`
5. Verify health via `kubectl get pods` and `/grpn/healthcheck`.

### Scale Up / Down

Scaling is managed via Kubernetes HPA. To manually override:
1. `kubectl scale deployment/global-subscription-service-gss --replicas=<N> -n global-subscription-service-<env>`
2. Or update `minReplicas` / `maxReplicas` in the relevant `.meta/deployment/cloud/components/gss/<env>-<region>.yml` file and redeploy.

### Database Operations

- **Schema changes in production**: Coordinate with the DBA team via a GDS Jira ticket. Schema changes must be backward-compatible and executed before any dependent code deploy.
- **Schema migrations**: Managed by `jtier-migrations` (Flyway); run automatically on service startup in non-SOX environments; manually triggered by DBA in production.
- **Connection pool issues**: Check JVM metrics for pool exhaustion; MALLOC_ARENA_MAX is set to 4 to prevent vmem explosion.

### Replay Push Token Events

If push token events are missing downstream:
1. Use `GET /push-token/device-token/{deviceToken}/replay/create` to re-publish a create event for a specific token.
2. Use `GET /push-token/device-token/{deviceToken}/replay/update` to re-publish an update event.
3. Use `GET /push-subscription/replay/{deviceId}` to replay a push subscription create event for a device.

### Retry Failed Operations

Use `GET /retry/errors` to trigger a manual retry of failed internal operations. This endpoint is internal and should only be used under guidance from the on-call runbook.

## Troubleshooting

### High Response Latency
- **Symptoms**: Elevated P99 response times on consent or push token endpoints
- **Cause**: Database query slowness (Postgres connection pool exhaustion or slow queries), or downstream service (User Service, Consent Service) latency
- **Resolution**: Check Postgres connection pool metrics; check User Service and Consent Service health; review slow query logs; scale up replicas if CPU-bound

### MBus Consumer Not Processing
- **Symptoms**: Growing message backlog; subscription events not propagating downstream
- **Cause**: `messageBusConsumersEnabled` set to `false`, or consumer thread deadlocked
- **Resolution**: Verify config value; check steno.log for consumer error stack traces; restart the pod if consumer thread is stuck

### Kafka TLS Certificate Failure
- **Symptoms**: Pod fails to start; logs show Kafka connection refused or SSL handshake error
- **Cause**: Expired or missing certificates in `/var/groupon/certs`; `kafka-tls-v2.sh` failed
- **Resolution**: Check Kubernetes secret `client-certs` for certificate expiry; rotate certificates; redeploy

### Container OOM Killed
- **Symptoms**: Pod is restarted with OOM exit code; `kubectl describe pod` shows OOMKilled
- **Cause**: JVM heap exceeded memory limit; MALLOC_ARENA_MAX not reducing native memory fragmentation
- **Resolution**: Confirm `MALLOC_ARENA_MAX=4` is set; review heap dump if available; increase memory limit in deployment manifest; check for memory leaks in steno.log

### Push Token Data Inconsistency (Cassandra vs Postgres)
- **Symptoms**: Push token lookups return inconsistent results; `/push-token/` endpoints return 404 for known tokens
- **Cause**: Data migration from Cassandra to Postgres incomplete for that token
- **Resolution**: Use `GET /push-subscription/migration/{token}` to trigger migration for the specific token; verify record appears in Postgres

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no consent reads/writes possible | Immediate | Page on-call via PagerDuty P1NQCYT; notify #subscription-engineering |
| P2 | Degraded — subset of operations failing or slow | 30 min | On-call investigation; notify team via Slack |
| P3 | Minor impact — single endpoint degraded, non-critical feature | Next business day | File Jira ticket; no immediate escalation |

Full on-call procedure: https://wiki.groupondev.com/Subscriptions/Global_Subscription_Service/Oncall

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumSmsConsentPostgres` | JDBC connection pool status in JVM metrics | No fallback — consent reads and writes fail |
| `continuumPushTokenPostgres` | JDBC connection pool status | No fallback — push token operations fail |
| `continuumPushTokenCassandra` | Cassandra session health in JVM metrics | Postgres-only reads continue for migrated tokens |
| `continuumUserService` | `GET /grpn/healthcheck` on User Service | Consent creation fails with 404; reads continue |
| `continuumConsentService` | `GET /grpn/healthcheck` on Consent Service | Consent recorded locally; regulatory sync retried |
| MBus | Consumer thread activity metric | Events queued; delivery delayed if MBus is down |
| Kafka | Kafka consumer group lag metric | Push token events queued in Kafka; delayed downstream notification |
