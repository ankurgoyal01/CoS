---
service: "channel-manager-integrator-derbysoft"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /ping` (HotelSyncApi) | HTTP | Per Kubernetes probe schedule | Per probe config |
| Dropwizard health check (`/healthcheck` on admin port 8081) | HTTP | Per Kubernetes liveness probe | 60s |
| Kubernetes readiness probe | HTTP | 5s period, 60s initial delay | 60s |
| Kubernetes liveness probe | HTTP | 15s period, 60s initial delay | 60s |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| MBus message processing duration (`IswBookingMessageProcessor`) | histogram | Time in milliseconds to process each `RESERVE`/`CANCEL` message | Operational procedures to be defined by service owner |
| Kafka publish success/failure | counter | Tracks whether `ARIMessage` events are successfully produced to Kafka | Operational procedures to be defined by service owner |
| Reservation state transitions | counter | Tracks prebook/book success and failure counts per hotel | Operational procedures to be defined by service owner |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Channel Manager Integrator Derbysoft | Wavefront | https://groupon.wavefront.com/dashboards/channel-manager-integrator-derbysoft |
| SMA HTTP In/Out | Wavefront | https://groupon.wavefront.com/u/MXjGbhwtsW?t=groupon |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Splunk alert — ARI push errors | Elevated ARI push validation failure rate | warning / critical | Check ARI request/response tables; verify Derbysoft payload format; contact Derbysoft if partner-side issue |
| PagerDuty — service down | Liveness probe fails; no healthy pods | critical | Restart pods; check JVM OOM (increase `MALLOC_ARENA_MAX` or memory limit); review logs |
| MBus DLQ growth | Dead-letter queue accumulating messages | warning | Inspect DLQ messages; check Derbysoft API reachability; force-replay or mark reservations as failed via admin tool |
| Kafka producer timeout | `requestTimeOutInMillis` exceeded repeatedly | warning | Check Kafka broker health; verify TLS cert validity; check `kafkaConfig.brokerList` |

SRE notification address: `getaways-monitoring+inventory-production@groupon.com`
PagerDuty service: https://groupon.pagerduty.com/service-directory/PNID06D
Slack channel ID: `CF9BSJ5GX`

## Common Operations

### Restart Service

1. Identify the target Kubernetes cluster and namespace (e.g., `channel-manager-integrator-derbysoft-production-sox`)
2. Use `kubectl rollout restart deployment/channel-manager-integrator-derbysoft-app -n channel-manager-integrator-derbysoft-production-sox`
3. Monitor readiness probe (60s delay) and confirm pods reach `Running` state
4. Verify MBus listeners reconnect by checking Wavefront dashboard for resumed message throughput

### Scale Up / Down

1. Edit the HPA or update the deployment manifest min/max replica values in `.meta/deployment/cloud/components/app/<env>.yml`
2. Run the deploy script: `bash .meta/deployment/cloud/scripts/deploy.sh <env> <deployEnv> <namespace>`
3. Alternatively, use `kubectl scale` for immediate manual scaling without a release artifact

### Database Operations

Migrations run automatically at startup via the `jtier-migrations` / `PostgresMigrationBundle`. To apply new migrations:
1. Add migration scripts in the expected migration directory (bundled in the JAR)
2. Deploy a new artifact — the bundle applies pending migrations before the application accepts traffic
3. For emergency rollback: coordinate with the DaaS team to revert migration on the managed PostgreSQL instance

## Troubleshooting

### Reservations Stuck in RESERVATION_INIT or PRE_BOOK_SUCCEED State
- **Symptoms**: Booking messages stop being acknowledged; MBus consumer lag grows; Wavefront shows no state transitions
- **Cause**: Derbysoft API is unreachable or returning errors; or MBus listener is not processing messages
- **Resolution**: Check Derbysoft API connectivity (use `GET /ping`); inspect logs for `RecoverableExecutionException`; verify `derbysoftClient` Retrofit config; restart service if MBus listener has stalled

### ARI Push Returning Validation Errors
- **Symptoms**: Partners report 422 errors on `POST /ari/daily/push`; ARI response table shows repeated failures
- **Cause**: Derbysoft payload does not match expected schema; hotel/room-type/rate-plan mapping is missing or stale
- **Resolution**: Check ARI request log table; compare payload against schema in `channel-manager-async-schema`; trigger a hotel sync via `GET /hotels/{supplierId}` to refresh mapping; use `PUT /getaways/v2/channel_manager_integrator/mapping` to update stale mappings

### Kafka TLS Certificate Expiry
- **Symptoms**: Kafka producer fails to connect; `WorkerKafkaMessageProducer` logs TLS handshake errors; ARI messages not forwarded
- **Cause**: Keystore or truststore certificate has expired
- **Resolution**: Rotate Kafka TLS certificates in Kubernetes secrets; restart pods to pick up new certificates (Kafka TLS is configured at container start via `kafka-tls.sh`)

### DLQ Accumulation
- **Symptoms**: `DLQMessageProcessor` is processing messages but reservation state table shows failures accumulating
- **Cause**: Persistent error in booking processing (Derbysoft returning unexpected response format; mapping data corrupt)
- **Resolution**: Inspect DLQ message payloads; if Derbysoft issue, contact Derbysoft (via escalation process at `docs/runbook/contact_derbysoft.md`); if mapping issue, use the PUT mapping endpoint to correct data

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no reservations or ARI processing | Immediate | Getaways Engineering on-call (PagerDuty PNID06D); Slack CF9BSJ5GX |
| P2 | Degraded — partial booking failures or DLQ growth | 30 min | Getaways Engineering on-call |
| P3 | Minor impact — elevated ARI validation errors, non-critical mapping issues | Next business day | getaways-eng@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Derbysoft Channel Manager API | Call `GET /ping` (HotelSyncApi); check Wavefront for outbound HTTP error rates | Reservations fail with error response back to ISW; DLQ absorbs unprocessable messages |
| MBus Broker | Wavefront MBus consumer lag metric; check listener lifecycle in Dropwizard admin | Booking messages queue up in MBus until listener reconnects; no data loss expected |
| Kafka Broker | Check Kafka broker health via platform tooling; watch for Kafka producer timeout logs | ARI payloads not forwarded downstream; Kafka can be disabled via `kafkaConfig.enabled = false` as a last resort |
| PostgreSQL (DaaS) | Dropwizard health check (`/healthcheck` admin endpoint) | Service cannot persist state; all operations fail; contact DaaS team for restore |
| Getaways Inventory API | No dedicated health check; mapping validation failures indicate unavailability | ARI push validation fails; mapping endpoints return errors until inventory API recovers |
