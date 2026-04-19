---
service: "regulatory-consent-log"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Notes |
|---------------------|------|-------|
| `GET :8080/grpn/healthcheck` | HTTP | Returns `OK` when the service is running |
| `GET :8081/healthcheck?pretty=true` | HTTP (admin) | Returns JSON with individual component health |
| `/var/groupon/jtier/heartbeat.txt` | File | Load balancer heartbeat file; must exist for traffic routing |

Healthcheck response includes:

```json
{
  "deadlocks":                                    { "healthy": true },
  "heartbeatFile":                                { "healthy": true },
  "postgres-session-pool-0.pool.ConnectivityCheck":     { "healthy": true },
  "postgres-transaction-pool-0.pool.ConnectivityCheck": { "healthy": true },
  "redis":                                        { "healthy": true }
}
```

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `POST /v1/consents` 4xx rate | counter | Percentage of 4xx responses on the consent creation endpoint | Alert: increase in percentage (Wavefront) |
| `POST /v1/consents` 5xx rate | counter | Percentage of 5xx responses on the consent creation endpoint | Alert: increase in percentage (Wavefront) |
| `POST /v1/consents` p99 response time | histogram | 99th percentile response time | SLA: 50ms; alert on increase |
| `GET /v1/cookie` p99 response time | histogram | 99th percentile for cookie lookup | SLA: 10ms (US), p95: 6ms |
| DB connection pool | gauge | Active / idle connections to Postgres session and transaction pools | Alert on pool exhaustion |
| Redis health | gauge | Redis connectivity status from healthcheck | Alert on `healthy: false` |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Application metrics (requests, responses, latency by endpoint) | Wavefront | `https://groupon.wavefront.com/dashboard/regconsentlog` |
| System metrics (CPU, memory, disk, network) | Wavefront | `https://groupon.wavefront.com/dashboard/regulatory-consent-log-system-metrics` |
| Message Bus topics | MBus Dashboard | `https://mbus-dashboard.groupondev.com/` (browse to `erased.complete` or `RegulatoryConsentLog`) |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| `regconsentlog /consents POST response 4XX rps` | Increase in 4xx response percentage | 1 (High) | Search Splunk: `index=steno sourcetype=regconsentlog::jtier` filtered on `data.status=4*` |
| `regconsentlog /consents POST response 5XX error percentage` | Increase in 5xx response percentage | 1 (High) | Search Splunk: `index=steno sourcetype=regconsentlog::jtier` filtered on `data.status=5*` |
| `regconsentlog /consents POST Response Time` | Increase in 2xx response time | 1 (High) | Search Splunk: `index=steno sourcetype=regconsentlog::jtier` filtered on `data.status=2*` |
| LB VIP down | VIP health check fails in Nagios | High | Check VipStatus; redeploy same version if VIP is unhealthy |

## Common Operations

### Restart Service

On Kubernetes (current):

```bash
kubectl rollout restart deployment/regulatory-consent-log-app -n regulatory-consent-log-production
kubectl rollout restart deployment/regulatory-consent-log-util -n regulatory-consent-log-production
```

On legacy VM hosts (historical reference):

```bash
ssh svc_jtier@regulatory-consent-log-app1.snc1
sudo /usr/local/bin/sv restart jtier
```

### Scale Up / Down

Adjust `minReplicas` and `maxReplicas` in `.meta/deployment/cloud/components/app/{env}.yml` and redeploy. Production HPA range: min 5, max 30. Worker is fixed at 3 replicas.

### Database Operations

- Migration path: managed via DaaS provisioning. Contact GDS team for schema changes.
- To verify DB connectivity: check `/healthcheck?pretty=true` on admin port 8081; look for `postgres-*-pool.ConnectivityCheck: healthy: true`.
- On replication lag: do not restart service; contact GDS team. Reduce message processing batch size or run rate if the lag is caused by the worker.

### Release Cut

```bash
cd regulatory-consent-log
./scripts/setup.sh        # first time only
./scripts/release.sh      # follow interactive prompts; press Enter for defaults
```

### Deploy to Staging (canary then full)

```bash
./scripts/deploy.sh       # select target environment and version from interactive menu
```

Approve the DeployBot trigger manually. Monitor `#regulatory-consent` Slack channel and Wavefront for anomalies. Verify correct version at `:8080/grpn/status`.

## Troubleshooting

### DaaS (Postgres) Down or Unreachable

- **Symptoms**: 5xx errors on `POST /v1/consents`; Splunk shows DB exception logs; healthcheck returns `postgres-*-pool.ConnectivityCheck: healthy: false`.
- **Cause**: DaaS infrastructure issue (not RCL-side).
- **Resolution**: Confirm with Splunk and telnet to GDS VIP. Contact SOC ("Production Operations") and GDS team ("GDS (DaaS)"). No action on RCL side; restart hosts if issue persists after GDS resolves.

### DaaS Write Connection Pool Exhausted

- **Symptoms**: DB exceptions on write operations; Wavefront shows connection count at limit.
- **Cause**: Shared DaaS instance under load; slow DB responses inflating connection count.
- **Resolution**: Verify connection count in Wavefront. Contact SOC and GDS team. If RCL is requesting unusually many connections, investigate for increased load or slow queries.

### DaaS Slow Query Response

- **Symptoms**: Splunk shows DB timeout exceptions; Wavefront shows elevated DB response times.
- **Resolution**: Contact SOC and GDS team. Restart hosts after GDS resolves if slowness persists.

### DaaS Replication Lag

- **Symptoms**: Stale data returned by `GET /v1/cookie`; mismatch between master DB and API results.
- **Resolution**: Monitor `Replication_Delay` metric in CheckMK. Contact GDS team. If caused by worker message processing, reduce batch size / run rate.

### Message Bus — Cannot Publish

- **Symptoms**: Splunk shows MBus traffic gaps; Cronus outbox rows accumulate in Postgres.
- **Resolution**: Check MBus dashboard for the relevant topic. Contact SOC and MBus team ("Global Message Bus"). Restart hosts after resolution.

### Message Bus — Not Receiving Messages

- **Symptoms**: User erasure pipeline stalls; Redis work queue not growing.
- **Resolution**: Check MBus dashboard; verify subscription `rfs_gapi` is listed with non-zero listeners. Contact SOC and MBus team.

### Redis (RaaS) Unreachable or Slow

- **Symptoms**: Splunk shows Redis timeout/unreachable exceptions; healthcheck shows `redis: healthy: false`; MBus user erasure messages not being ACKed (messages retried up to 10 times).
- **Resolution**: Check Redis health on `:8081/healthcheck`. Contact RaaS team ("Redis (RaaS, Redis Labs, ...)"). RCL stops ACKing erasure messages when Redis is down; processing will resume automatically when Redis recovers.

### Janus Aggregator Unreachable

- **Symptoms**: Splunk shows Janus client failures; b-cookie mappings not being written to DB; erasure pipeline stalls.
- **Resolution**: Verify Janus endpoint (`/v1/bcookie_mapping/consumers/{user_uuid}`). Contact Janus Aggregator team. Failures are recorded in RaaS error queue for retry; no data is lost.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — consents not being recorded | Immediate | Groupon API team (`#regulatory-consent`); SOC |
| P2 | Degraded — elevated 5xx or high latency | 30 min | Groupon API team; check Splunk and Wavefront |
| P3 | Minor impact — b-cookie lookup latency elevated | Next business day | Groupon API team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| PostgreSQL DaaS | `GET :8081/healthcheck` — `postgres-*-pool.ConnectivityCheck` | No fallback; 5xx returned on DB failure |
| Redis RaaS | `GET :8081/healthcheck` — `redis` check | No fallback; MBus messages not ACKed (retried by broker) |
| Message Bus | MBus dashboard, Splunk topic traffic | Cronus outbox accumulates; delivered when MBus recovers |
| Janus Aggregator | Splunk log check; telnet to VIP | Failures recorded in Redis error queue; retried on next processing cycle |
| Transcend Privacy Platform | Splunk log check on webhook endpoint | Async upload retried on next Quartz job execution |
