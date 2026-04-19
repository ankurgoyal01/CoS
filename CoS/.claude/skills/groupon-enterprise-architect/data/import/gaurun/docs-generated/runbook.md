---
service: "gaurun"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/healthcheck` | HTTP (returns `200 ok`) | Kubernetes default | Kubernetes default |
| Logstash sidecar port `9113` | TCP | 10 seconds | — |
| Logstash sidecar liveness port `9113` | TCP | 20 seconds | — |

## Monitoring

### Metrics

All metrics are emitted to Telegraf/InfluxDB under the `telegraf` database. Metric names are prefixed with `gaurun.` and use underscores converted to dots.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `gaurun.requests` | counter | Inbound push requests, tagged `valid=true/false` and `platform=1/2` | Spike in `valid=false` |
| `gaurun.succeeded.push` | counter | Successful push deliveries, tagged `deviceType=ios/android` | Drop from baseline |
| `gaurun.failed.push` | counter | Failed push deliveries, tagged `deviceType=ios/android` | Sustained high rate |
| `gaurun.queue.size` | gauge | Size of named in-memory queues (polled every 60 seconds), tagged `queue_name` | Sustained growth |
| `gaurun.retry.attempt` | counter | Retry attempts, tagged `retry-count` | High count |
| `gaurun.retry.exhausted` | counter | Notifications that exhausted max retries and were dropped | Any non-zero value |

Application stats also available at `GET /stat/app` (queue_max, queue_usage, pusher_max, pusher_count, ios/android push_success and push_error counts) and `GET /stat/go` (Go runtime stats).

### Dashboards

> Operational procedures to be defined by service owner. Dashboard links are not discoverable from this repository.

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High push failure rate | `gaurun.failed.push` sustained high for platform | critical | Check APNs/FCM connectivity; verify cert/key not expired; check retry topic backlog |
| Queue depth growing | `gaurun.queue.size` for `android-kafka-producer` or `ios-kafka-producer` sustained above threshold | warning | Check Kafka connectivity; increase `pusher_max` via `PUT /config/pushers?max=N`; scale replicas |
| Retry exhausted | `gaurun.retry.exhausted` > 0 | warning | Investigate root cause of persistent delivery failure; check APNs/FCM error logs |
| Pod OOM/crash | Kubernetes pod restarts | critical | Check `GOMEMLIMIT` vs actual memory usage; review `gaurun_error.log`; consider increasing memory limits |

## Common Operations

### Restart Service

Gaurun performs graceful shutdown on `SIGTERM` (sent by Kubernetes). The shutdown sequence:
1. Kubernetes sends `SIGTERM`; Gaurun stops accepting new HTTP connections.
2. Gaurun waits up to `core.shutdown_timeout` seconds (default 30 in production) for in-flight requests to complete.
3. `PusherWg.Wait()` blocks until all push worker goroutines finish.
4. Log files are closed; sidecar `preStop` hook sleeps 60 seconds to drain Logstash.

To restart via Kubernetes: `kubectl rollout restart deployment/gaurun -n <namespace>`

To reload log files without restart (log rotation), send `SIGHUP` to the main process. Gaurun reopens access, error, and accept log file handles.

### Scale Up / Down

**Horizontal scaling** (add replicas):
```
kubectl scale deployment/gaurun --replicas=N -n <namespace>
```
Or adjust `minReplicas`/`maxReplicas` in `.meta/deployment/cloud/components/app/<env>.yml` and redeploy.

**Pusher goroutine scaling** (adjust in-process concurrency at runtime without restart):
```
PUT /config/pushers?max=N
```
Returns `200 ok` on success. Use `GET /stat/app` to verify `pusher_max` changed.

**Worker count**: Requires config file change and restart (set `core.workers` in TOML).

### Database Operations

> Not applicable. Gaurun owns no database. Kafka topic management (partition count, retention) is handled by the central Kafka cluster team.

### Crash Recovery (Replay)

Gaurun can replay failed notifications from access logs. In the container:
```
/app/gaurun_recover -c /app/conf/<env>.toml -l /tmp/gaurun.log
```
This replays only failed entries from the access log file.

## Troubleshooting

### High push failure rate on iOS

- **Symptoms**: `gaurun.failed.push{deviceType=ios}` elevated; `gaurun_error.log` contains APNs error reasons.
- **Cause**: Expired APNs certificate, invalid device token, APNs service outage, or network connectivity issue.
- **Resolution**: Check APNs certificate expiry dates in `conf/grpn-ios-cert/cert.pem`; verify `core.dry_run=false`; check Apple system status; review `gaurun_error.log` for specific APNs error codes.

### High push failure rate on Android

- **Symptoms**: `gaurun.failed.push{deviceType=android}` elevated; `gaurun_error.log` contains FCM error details.
- **Cause**: Invalid FCM API key or service account, invalid device token, FCM quota exceeded, or network connectivity issue.
- **Resolution**: Validate FCM API key/service account credentials; check for `Unavailable` vs `InvalidRegistration` errors in logs; review Google FCM console.

### In-memory queue full (429 responses)

- **Symptoms**: Upstream callers receive `429 Too Many Requests`; `gaurun.queue.size{queue_name=android-kafka-producer}` or `ios-kafka-producer` at capacity (100,000).
- **Cause**: Kafka connectivity issue causing producer backpressure, or notification send rate exceeding consumer throughput.
- **Resolution**: Check Kafka connectivity and broker health; verify Kafka TLS certificates are valid; increase `pusher_max` via `PUT /config/pushers?max=N`; scale Gaurun replicas if needed.

### Retry topic backlog growing

- **Symptoms**: `gaurun.retry.attempt` count high; `mta.gaurun.retry` topic consumer lag growing.
- **Cause**: Persistent delivery failures causing notifications to cycle through retry. Could indicate APNs/FCM outage or cert expiry.
- **Resolution**: Identify root cause of delivery failure first. If outage is resolved, backlog will drain automatically (subject to `retry_later.min_message_age` delay and `retry_later.max_retries` cap).

### Logstash sidecar not shipping logs

- **Symptoms**: Missing send/push records in downstream Kafka topics; Logstash Pod readiness probe failing on port 9113.
- **Cause**: Kafka cluster unreachable from Logstash (TLS cert issue, network policy), Logstash configuration error, or shared volume mount issue.
- **Resolution**: Check Logstash container logs: `kubectl logs <pod> -c logstash -n <namespace>`; verify Kafka bootstrap address and TLS keystores; check `/var/groupon/logstash/log/logstash.log` inside the sidecar.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no push notifications delivered | Immediate | MTA team on-call |
| P2 | Degraded — high failure rate or significant queue backlog | 30 min | MTA team |
| P3 | Minor — elevated retry rate or single-region issue | Next business day | MTA team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Apple APNs | `gaurun.failed.push{deviceType=ios}` metric; `gaurun_error.log` APNs errors | Notifications queued in `ios_gaurun_pn` Kafka topic; retry processor will reattempt up to 12 times |
| Google FCM | `gaurun.failed.push{deviceType=android}` metric; `gaurun_error.log` FCM errors | Notifications queued in `android_gaurun_pn` Kafka topic; retry processor will reattempt up to 12 times |
| Kafka cluster | `gaurun.queue.size` growth; producer flush timeouts in error log | In-memory channels buffer up to 100,000 notifications per platform; backpressure causes 429 responses if channels fill |
| Telegraf/InfluxDB | Metric write errors in `gaurun_error.log` | Non-critical — delivery continues; metrics are lost |
