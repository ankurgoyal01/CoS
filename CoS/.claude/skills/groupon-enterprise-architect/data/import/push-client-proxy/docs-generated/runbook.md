---
service: "push-client-proxy"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/healthcheck` | http | Kubernetes liveness/readiness (interval not in source) | Not specified in source |
| `GET /api/health` | http | On-demand | — |

Both endpoints return a JSON body with `status`, `timestamp`, `application`, `kafka`, and `redis` fields.

## Monitoring

### Metrics

All metrics are written to InfluxDB under the `custom.cdp.*` prefix. Tags on every metric: `env`, `service` (`push-client-proxy`), `region`.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `custom.cdp.email.send.request.duration` | Timer | Total request latency for `POST /email/send-email` | Consumer-defined |
| `custom.cdp.email.send.request` | Counter | Total `POST /email/send-email` request count, tagged by `status_code` (2xx, 4xx, 5xx) | Consumer-defined |
| `custom.cdp.audience.patch.request.duration` | Timer | Total request latency for `PATCH /audiences/{audienceId}` | Consumer-defined |
| `custom.cdp.audience.patch.request` | Counter | Total `PATCH /audiences/{audienceId}` request count, tagged by `status_code` | Consumer-defined |
| `custom.cdp.audience.get_counts.request.duration` | Timer | Total request latency for `GET /audiences/{audienceId}` | Consumer-defined |
| `custom.cdp.audience.get_counts.request` | Counter | Total `GET /audiences/{audienceId}` request count, tagged by `status_code` | Consumer-defined |
| `NEW_EMAIL_SEND_REQUEST_COUNT` | Counter | Total email send requests including drops (rate limit, denylist, no account) | Consumer-defined |
| `NEW_EMAIL_SEND_REQUEST_DROPPED_COUNT` | Counter | Dropped email sends, tagged by `reason` (`rate_limit`, `denylist`, `user_account_not_exists`, `treatment_mismatch`, `invalid_or_missing_user_id`, `missing_required_headers`) | Consumer-defined |
| `email.send.kafka.injection.duration` | Timer | Latency of the email injection step inside the send handler | Consumer-defined |

Metrics are batched and flushed every 1000 ms (default `metrics.flush-duration-millis`). Metrics can be disabled by setting `metrics.enabled=false`.

### Dashboards

> No evidence found in codebase. Dashboard links not documented in the repository.

### Alerts

As recommended in `KAFKA_CONSUMPTION_IMPROVEMENTS.md`:

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High consumer lag | Lag > 1000 messages per partition | warning | Investigate processing errors; check SMTP relay availability; scale consumers |
| High error rate | Failed message processing > 5% of total | warning | Check logs for `Not acknowledging messages` and `Error processing batch messages`; review SMTP and Redis connectivity |
| High memory usage | Heap > 80% of allocated | warning | Review Kafka batch sizes; consider increasing pod memory limits |
| Network timeouts | Repeated Kafka reconnect backoff events | warning | Verify Kafka cluster health and SSL certificate validity |

## Common Operations

### Restart Service

```
kubectl rollout restart deployment/push-client-proxy -n push-client-proxy-production
```

Wait for the rollout to complete:

```
kubectl rollout status deployment/push-client-proxy -n push-client-proxy-production
```

### Scale Up / Down

To manually override replicas (e.g., during an incident):

```
kubectl scale deployment/push-client-proxy --replicas=<N> -n push-client-proxy-production
```

Normal scaling is handled automatically by the HPA configured in deployment manifests (`hpaTargetUtilization: 20`).

### Database Operations

> Operational procedures to be defined by service owner. No migration tooling (Flyway/Liquibase) was detected in the repository. Schema changes require coordination with the owning team.

### Enabling or Disabling Kafka

Kafka consumption is gated by `spring.kafka.enabled=true`. To disable all Kafka consumers without redeploying, update the config and perform a rolling restart. The HTTP API remains available when Kafka is disabled.

## Troubleshooting

### Kafka consumer not processing messages

- **Symptoms**: Consumer lag growing in `msys_delivery` or `email-send-topic`; no `Successfully processed and acknowledged` log lines
- **Cause**: SMTP failure causing non-acknowledgment; Redis unavailability causing lookup failures; Kafka SSL certificate expiry
- **Resolution**: Check pod logs for `Not acknowledging messages due to processing error`; verify SMTP relay connectivity; verify Redis health; check certificate expiry on `/var/groupon/kafka.client.keystore.jks`

### Emails dropped with reason `rate_limit`

- **Symptoms**: High `NEW_EMAIL_SEND_REQUEST_DROPPED_COUNT` with `reason=rate_limit` metric; Bloomreach receiving `429` responses
- **Cause**: Token-bucket capacity exhausted in primary Redis
- **Resolution**: Verify Redis cluster health; review rate-limit bucket configuration; coordinate with Bloomreach on send rate

### Emails dropped with reason `user_account_not_exists`

- **Symptoms**: High drop count for `user_account_not_exists`
- **Cause**: Users lookup MySQL DB returning no record for the provided `userId`
- **Resolution**: Verify MySQL users DB connectivity; check if user accounts have been deleted or if there is a data sync lag

### Emails dropped with reason `denylist`

- **Symptoms**: High drop count for `denylist`
- **Cause**: Recipient address matches a record in the exclusions PostgreSQL database
- **Resolution**: Review exclusion records for unintended wildcard patterns; contact the team that owns the exclusions database

### Batch timeout on email-send-topic

- **Symptoms**: Log lines containing `Email batch failed or timed out`; consumer re-processing same offsets
- **Cause**: One or more SMTP sends within a 250-message batch exceeded the 30-second timeout
- **Resolution**: Check SMTP relay latency; reduce batch size if needed (`spring.kafka.consumer.max-poll-records`)

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no emails delivered, API returning 5xx | Immediate | Subscription Engineering on-call |
| P2 | Degraded — high drop rate, consumer lag building | 30 min | Subscription Engineering on-call |
| P3 | Minor impact — elevated latency, single region affected | Next business day | Subscription Engineering team channel |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Kafka | `GET /api/health` returns `"kafka": "CONFIGURED"`; check consumer lag | If Kafka unavailable, HTTP API remains up; consumer restarts with exponential backoff |
| Redis (primary) | `GET /api/health` returns `"redis": "CONFIGURED"`; check Redis cluster metrics | Rate limiting fails open if Redis is unavailable (Bucket4j will error); email metadata lookups return empty |
| SMTP relay | Check `email.send.request.duration` latency spikes | Retries via Kafka `email-send-topic` for up to configured retry limit |
| PostgreSQL (main) | JPA startup validation | Audience patch/get operations fail; email send persistence fails silently with exception logged |
| MySQL (users lookup) | JPA startup validation | User account check fails; emails for unknown users are dropped |
