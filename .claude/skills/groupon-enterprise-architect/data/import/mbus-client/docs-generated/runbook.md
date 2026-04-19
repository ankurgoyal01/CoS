---
service: "mbus-client"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

The MBus Client Library is embedded in host services and does not expose its own health endpoint. Health is assessed through the MBus broker infrastructure dashboards and host service metrics.

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| MBus VIP HTTP dynamic server list | HTTP GET `http://{vip}:{port}` | On consumer startup and every `connectionLifetime` ms (default: 5 min) | Connect: 1000 ms, Read: 5000 ms |
| STOMP keepalive frame | STOMP (TCP) | Every `keepAlivePeriodSeconds` (default: 60 s) per connection | N/A (fire-and-forget; resets connection on failure) |
| STOMP connection state check | In-process | On each prefetch cycle | N/A |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Publish count | counter | Number of messages published (via `metricslib` under `metricAppName`, default `mbus`) | Depends on host service SLA |
| Publish latency | histogram | Time per publish operation | Depends on host service SLA |
| Consumer receive rate | counter | Number of messages consumed | Depends on host service SLA |
| Connection retry count | counter | Number of broker reconnect attempts (logged at WARN/DEBUG level) | Monitor for sustained spikes |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| MBus General Dashboard | Custom | `https://mbus-dashboard.groupondev.com/` |
| MBus Wavefront | Wavefront | `https://groupon.wavefront.com/dashboard/mbus` |
| MBus Destination Wavefront | Wavefront | `https://groupon.wavefront.com/dashboard/mbus-destination` |
| MBus Broker Hosts (snc1/lup1/dub1/sac1) | CheckMK | `https://checkmk-lvl3.groupondev.com/ber1_prod/check_mk/index.py` (see `.service.yml` for full URL) |
| MBus General CheckMK | CheckMK | `https://checkmk-lvl3.groupondev.com/ber1_prod/check_mk/index.py?name=mbus_general` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Broker connection failure | Consumer or producer unable to connect after 3 retries | critical | Check broker VIP health; verify network connectivity to `mbus-vip.{colo}:61613`; escalate to GMB team |
| `TooManyConnectionRetryAttemptsException` logged repeatedly | Consumer sleeping 60 s between retry cycles | warning | Verify broker cluster health at `mbus-dashboard.groupondev.com`; check if VIP endpoint is returning valid host list |
| Keepalive failure | `KeepAliveFailedException` logged; connection reset triggered | warning | Monitor for pattern; if persistent, check broker health and connection stability |
| Messages not being consumed | Consumer receive rate drops to zero; no `ReceiveTimeoutException` logged | critical | Check if broker disconnected consumer (ERROR frame "disconnected by server"); restart consumer instance |

## Common Operations

### Restart Service

As a library, restart is performed by the host service. Standard process:

1. Identify the host service embedding `mbus-client` that needs restarting.
2. Deploy or restart the host service using its own deployment pipeline.
3. On startup, the host service's consumer or producer calls `start(config)`, which re-establishes STOMP connections automatically.
4. Verify messages are flowing via MBus dashboards.

### Scale Up / Down

> Operational procedures to be defined by service owner.

Consumer parallelism is controlled by `ConsumerConfig.setThreadPoolSize(int)` (default: 4) and by the number of consumer instances deployed. Increasing the thread pool size allows more concurrent broker connections. Adjust and redeploy the host service.

### Database Operations

> Not applicable. The library is stateless and owns no database.

## Troubleshooting

### Consumer not receiving messages

- **Symptoms**: Application `receive()` blocks indefinitely; no messages processed; consumer appears healthy
- **Cause**: Subscription may have been removed by broker (durable subscription expired or broker restarted); consumer may be connected to wrong broker; message selector may be filtering all messages
- **Resolution**: Verify destination name and `destinationType` match the broker configuration. Check that `subscriptionId` matches expected durable subscription. Verify `messageSelector` if set. Check MBus dashboard to confirm messages are being published to the destination. Restart the consumer to force reconnect and re-subscribe.

### `TooManyConnectionRetryAttemptsException` on startup

- **Symptoms**: Consumer or producer throws `TooManyConnectionRetryAttemptsException` immediately on `start()`
- **Cause**: Broker VIP is unreachable; incorrect host/port in `HostParams`; network firewall blocking port 61613
- **Resolution**: Verify broker VIP host and port (port 61613 for STOMP). Confirm connectivity from the host service's network segment. Check broker health at `https://mbus-dashboard.groupondev.com/`. Contact GMB team via `#global-message-bus` Slack if broker appears healthy but connections still fail.

### `sendSafe` timing out frequently

- **Symptoms**: `SendFailedException` with "receipt timeout" message; high retry counts in logs
- **Cause**: Broker overloaded; network latency high; `receiptTimeoutMillis` too low for current load
- **Resolution**: Check broker load via MBus dashboards. Consider increasing `ProducerConfig.setReceiptTimeoutMillis()` (default: 5000 ms). Consider switching to fire-and-forget `send()` if message loss tolerance allows. Reduce message rate if broker is saturated.

### Messages received more than once (duplicate delivery)

- **Symptoms**: Application processes same message ID multiple times
- **Cause**: Consumer acknowledged message over a broken connection; broker redelivered before ack reached it
- **Resolution**: Implement idempotency in the application message handler. Use `ackSafe()` instead of `ack()` to receive server confirmation before marking message as processed. Ensure message processing is completed before acking.

### Consumer disconnected by server

- **Symptoms**: Log entry: `Server {host}:{port} has disconnected the consumer: disconnected by server`
- **Cause**: MBus broker (Artemis) removed the consumer from the queue but kept TCP connection active — typically due to broker-side consumer timeout
- **Resolution**: The library detects this error frame and disconnects automatically, then reconnects on the next prefetch cycle. If persistent, check `keepAlivePeriodSeconds` configuration and ensure the consumer is processing messages within the broker-configured TTL.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Broker cluster down; no messages flowing across all services | Immediate | GMB team via PagerDuty `mbus@groupon.pagerduty.com` |
| P2 | One colo broker degraded; partial message flow affected | 30 min | GMB team via Slack `#global-message-bus` |
| P3 | Single consumer or producer failing; isolated impact | Next business day | GMB team via `messagebus-team@groupon.com` |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| MBus Broker (`messageBus`) | Check `https://mbus-dashboard.groupondev.com/` and `https://groupon.wavefront.com/dashboard/mbus` | No automatic fallback; client retries with backoff; application should implement its own fallback if messages cannot be published |
| MBus VIP Concierge (dynamic server list) | HTTP GET to `http://{vip}:{port}` returns comma-separated host list | Set `useDynamicServerList=false` to disable and use static host list (local testing only) |
| Metrics Stack (`metricslib`) | JMX availability on host JVM | Metrics silently dropped if metricslib unavailable; core messaging unaffected |
