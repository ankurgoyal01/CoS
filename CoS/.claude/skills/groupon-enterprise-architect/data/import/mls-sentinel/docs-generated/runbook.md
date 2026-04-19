---
service: "mls-sentinel"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/healthcheck` (port 8080) | HTTP | Kubernetes liveness probe (Conveyor default) | Kubernetes default |
| `GET /grpn/status` (port 8080) | HTTP | Manual / monitoring | — |
| Heartbeat file: `/var/groupon/jtier/heartbeat.txt` | File-based | Conveyor heartbeat check | — |

Verification after start/restart:
```sh
curl "localhost:8080/grpn/healthcheck"   # Expected: OK
curl "localhost:8080/grpn/status"         # Expected: JSON with build info and library versions
```

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `mbus_message_consume` (Splunk) | counter | MBus messages consumed per topic, with success/failure breakdown | Failure rate monitored by `MlsSentinel-US_MBUS_CONSUMED` Nagios alert |
| `kafka_message_produce` (Splunk) | counter | Kafka messages produced per topic, with success/failure breakdown | Failure rate monitored by `MlsSentinel-US_KAFKA_PRODUCED` Nagios alert |
| `http.out` (Splunk) | histogram | Outbound HTTP call status and latency by host | Wavefront alert fires if failure rate > 100 per 4 minutes |
| Incoming API P95 latency | histogram | P95 end-to-end latency for trigger/history endpoints | Wavefront alert fires if P95 > 10 seconds for 4 minutes |
| MBus queue depth | gauge | Length of each MessageBus consumer queue | Unbounded increase indicates Sentinel is overloaded |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| MLS Sentinel SMA | Wavefront | `https://groupon.wavefront.com/dashboard/mls-sentinel--sma` |
| MLS Production (SNC1) | Wavefront | `https://groupon.wavefront.com/dashboard/snc1-mls-production` |
| MLS Staging (SNC1) | Wavefront | `https://groupon.wavefront.com/dashboard/snc1-mls-staging` |
| MLS Kafka Topics | Wavefront | `https://groupon.wavefront.com/dashboard/sac1_snc1-mls-kafka` |
| Kafka Wavefront graph | Wavefront | `https://groupon.wavefront.com/dashboards/kafka-topics` (filter for `mls_` prefix) |
| Conveyor Cloud Application Metrics | Wavefront | `https://groupon.wavefront.com/dashboards/Conveyor-Cloud-Application-Metrics` |
| Conveyor Cloud Customer Metrics | Wavefront | `https://groupon.wavefront.com/dashboard/Conveyor-Cloud-Customer-Metrics` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| `MlsSentinel-US_KAFKA_PRODUCED` | Errors when producing messages to Kafka | Warning | Check Splunk for exceptions (`sourcetype=mls-sentinel:us:app exception`); check Kafka cluster health; no urgent escalation unless unhandled for 2 days |
| `MlsSentinel-US_MBUS_CONSUMED` | Errors when consuming messages from MBus | Warning | Check Splunk for exceptions; check MBus broker health; no urgent escalation unless unhandled for 2 days |
| Outgoing call rate (Wavefront) | Outgoing call failures > 100 for 4 minutes | Warning | Identify failing upstream service via `http.out` Splunk query; report to responsible team |
| Incoming API status (Wavefront) | Incoming API failures > 100 for 4 minutes | Warning | Find RCA via Splunk; fix identified issue |
| Incoming API time (Wavefront) | Incoming P95 latency > 10 seconds for 4 minutes | Warning | Check downstream calls (`http.out`) and DB operations for latency spikes |

**PagerDuty service**: `https://groupon.pagerduty.com/services/PV2ZOZL`
**Alert email**: `bmx-alert@groupon.com`
**Slack channel**: `global-merchant-exper`

## Common Operations

### Restart Service

**Cloud (Kubernetes):**
```sh
kubectl rollout restart deployment/mls-sentinel--app--default -n mls-sentinel-production
```

**On-prem:**
```sh
ssh mls-sentinel-appN.snc1
sudo sv stop jtier
sudo sv start jtier
```

After restart, verify health endpoint returns `OK` and monitor Splunk for MBus consumption resuming.

### Scale Up / Down

**Cloud — immediate:**
```sh
kubectl scale --replicas=<N> deployment/mls-sentinel--app--default
```

**Cloud — permanent:** Update `minReplicas` and `maxReplicas` in `.meta/deployment/cloud/components/app/<env-region>.yml` and redeploy.

**On-prem:** Add new hosts to Capfile, apply host template, deploy current version.

> Scaling up Sentinel increases load on VIS, M3, Reading Rainbow, and Deal Catalog. Coordinate with dependent service teams before large scale-up events.

### Database Operations

Migrations are applied via the shared `mls-db-schemas` Flyway artifact. Schema changes are bundled with deployments; no manual migration steps are required under normal operations.

For DLQ retry (replaying failed messages from a specific database):
```sh
POST /trigger/retryDLQs/{database}?earliest=<ISO8601>&latest=<ISO8601>
```

## Troubleshooting

### MBus Events Processed but No Kafka Commands Created

- **Symptoms**: Splunk shows `mbus_message_consume` success events but `kafka_message_produce` count is zero or very low for the same time window
- **Cause**: Sentinel validates the entity (voucher, inventory unit, merchant) against the owner service (VIS, M3) before emitting a command. If the RO database of the owner service has not yet received the write from the RW database (replication lag), Sentinel nacks the MBus message — it will not produce a Kafka command.
- **Resolution**: Verify replication lag in the owner service's database. Wait for replication to catch up (MBus will redeliver nacked messages after ~15 minutes). If lag is persistent, engage the database / platform team.

### MBus Queue Depth Growing (Overloaded)

- **Symptoms**: MBus queue depth metrics show unbounded increase; events are queuing faster than Sentinel can process them
- **Cause**: Message volume exceeds current instance capacity
- **Resolution**: Scale up Sentinel instances (see Scale Up above). Note that adding capacity increases load on upstream dependencies.

### Kafka Producer Errors

- **Symptoms**: `MlsSentinel-US_KAFKA_PRODUCED` Nagios alert firing; Splunk shows `kafka_message_produce` failures
- **Cause**: Kafka broker connectivity issue, TLS certificate problem, or topic/partition issue
- **Resolution**: Check Kafka cluster health. Verify TLS certificates have not expired (managed via `kafka-tls.sh`). Check Splunk for exception type (`exception.type`) in `kafka_message_produce` events. Restart pod if certificate refresh is needed.

### Outgoing HTTP Client Failures

- **Symptoms**: Wavefront outgoing call rate alert; Splunk `http.out` shows 5xx responses for a specific upstream host
- **Cause**: Upstream service (VIS, M3, Reading Rainbow, Deal Catalog) is degraded or down
- **Resolution**: Identify failing host via `http.out` Splunk query grouped by `data.url.host`. Report to the respective service team. Sentinel will retry via MBus redelivery.

### High API Latency (History or Trigger Endpoints)

- **Symptoms**: Wavefront incoming API latency alert; P95 > 10 seconds
- **Cause**: Likely downstream HTTP call latency or DB query latency
- **Resolution**: Check `http.out` Wavefront section for upstream call times. Check DB-out Wavefront section for slow query patterns. Scale Sentinel or upstream services as needed.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down, all MLS Command production stopped | Immediate | Merchant Experience Team via PagerDuty (`PV2ZOZL`) |
| P2 | Kafka producer failing; commands not reaching Yang | 30 min | Merchant Experience Team (`bmx-alert@groupon.com`) |
| P3 | Queue depth growing; minor processing lag | Next business day | Merchant Experience Team (Slack: `global-merchant-exper`) |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Voucher Inventory Service (VIS) | Splunk `http.out` filtered by VIS host; Wavefront outgoing call rate | Merchant blacklist mode (if `useMerchantBlacklistOnVisTimeout` enabled); MBus message retried after 15 minutes |
| M3 Merchant Service | Splunk `http.out` filtered by M3 host | MBus message nacked; retried after 15 minutes |
| Reading Rainbow | Splunk `http.out` filtered by Reading Rainbow host | MBus message nacked; retried after 15 minutes |
| Deal Catalog Service | Splunk `http.out` filtered by Deal Catalog host | MBus message nacked; retried after 15 minutes |
| MessageBus broker | `MlsSentinel-US_MBUS_CONSUMED` Nagios alert | No fallback — MBus is the primary event source; service cannot process events without it |
| Kafka broker | `MlsSentinel-US_KAFKA_PRODUCED` Nagios alert | Kafka producer errors are logged; events already consumed from MBus cannot be re-emitted without replay |
| PostgreSQL databases | Splunk DB-out log events | No fallback — DB write failures cause flow processing errors; MBus messages nacked and retried |
