---
service: "jtier-oxygen"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/status` | HTTP (returns `commitId`) | Default Kubernetes probe interval | Default |
| Heartbeat file (`/var/groupon/jtier/heartbeat.txt`) | File existence check | `heartbeatCheckIntervalSeconds` (default) | — |
| `healthcheckPort: 8080` | HTTP (Kubernetes readiness/liveness) | Per Kubernetes probe config | — |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request rate | counter | Inbound requests per endpoint | BFM status check alert on failure |
| Broadcast MPS (`overallMPS`) | gauge | Overall message-per-second throughput for active broadcasts | — |
| Average per-message MPS (`avgPerMessageMPS`) | gauge | Per-message-id send rate across a broadcast | — |
| JVM metrics | gauge/counter | Heap, GC, threads — collected via Codahale/Dropwizard metrics | Nagios alerts: `cpu`, `mem`, `swap` |
| HTTP outbound (GitHub) | histogram | `githubService / get-stars-calls` (configured in `httpClient.metrics`) | — |

Metrics are flushed to Telegraf/Wavefront at `http://localhost:8186/` every 10 seconds (`metrics.yml`).

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| JTier Oxygen SMA | Wavefront | `https://groupon.wavefront.com/dashboard/jtier-oxygen--sma` |
| JTier Oxygen Overview | Wavefront | `https://groupon.wavefront.com/u/yRYyB4Ly5y?t=groupon` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| status check (BFM) | Service not responding | P1 (Sev 1) | 1. Check VIP in Load Balancer. 2. Inspect individual app servers. 3. Review recent deploys and consider rollback. Engage Dev Team via PagerDuty POVGKE5 |
| cpu (Nagios) | Excessive CPU usage | P1 (Sev 1) | Engage Dev Team via PagerDuty |
| disk_space (Nagios) | Running out of disk | P1 (Sev 1) | Delete temp files; escalate to Dev Team |
| http_heartbeat (Nagios) | Service not responding to heartbeat | P1 (Sev 1) | Run `touch /var/groupon/jtier/heartbeat.txt` on affected box; escalate |
| mem (Nagios) | Excessive memory usage | P1 (Sev 1) | Check top processes; escalate |
| iostat (Nagios) | I/O saturation | P2 (Sev 2) | Escalate to Dev Team |
| load (Nagios) | High system load | P2 (Sev 2) | Escalate to Dev Team |
| ssh (Nagios) | SSH unreachable | P2 (Sev 2) | Escalate to Dev Team |
| swap (Nagios) | Excessive disk swapping | P2 (Sev 2) | Escalate to Dev Team |
| net_eth0 (Nagios) | Excessive network usage | P3 (Sev 3) | Escalate to Dev Team |
| ntp (Nagios) | NTP sync down | P3 (Sev 3) | Escalate to Dev Team |
| proc_splunkd (Nagios) | Splunk agent not running | P3 (Sev 3) | Escalate to Dev Team |

PagerDuty service: `https://groupon.pagerduty.com/services/POVGKE5`

## Common Operations

### Restart Service

Deployments are managed via the JTier deployment pipeline (Deploybot). To restart:
1. Check `https://deploybot.groupondev.com/jtier/oxygen` for the current deployed build
2. Re-trigger a deployment of the current build to the affected environment
3. Kubernetes will perform a rolling restart of the pods
4. Verify `GET /grpn/status` returns the expected `commitId` after restart

### Scale Up / Down

Follow the steps in the [JTier Manual host config guide](https://pages.github.groupondev.com/jtier/jtier-docs/devops/host_config.html). Scaling is controlled via `minReplicas`/`maxReplicas` in `.meta/deployment/cloud/components/app/{environment}.yml` and applied through the Raptor/Conveyor deploy pipeline.

### Database Operations

- Schema migrations are applied automatically by the JTier framework on service startup via `jtier-migrations`
- Quartz schema is managed via `jtier-quartz-postgres-migrations`
- Manual backfills or schema changes require DBA access to `jtier-oxygen-rw-na-{env}-db.gds.{vpc}.gcp.groupondev.com`
- Database replication is master/slave with backups enabled

## Troubleshooting

### Service Is Overloaded
- **Symptoms**: High CPU, high load Nagios alerts; BFM status check failure; slow API responses
- **Cause**: Likely a performance test running in `#perf-runs` channel, or a runaway broadcast with high iteration counts
- **Resolution**: Check `#perf-runs` (Slack channel CFBNRDHTR). If a performance test is running, wait for completion. Otherwise: (1) stop running broadcasts via `DELETE /broadcasts/{name}/running`, (2) check Wavefront dashboard for throughput anomalies, (3) review recent deploys and roll back if correlated

### Broadcast Messages Stalled
- **Symptoms**: `GET /broadcasts/{name}/stats` shows `numSends` not increasing; `updatedAt` on messages is stale
- **Cause**: MessageBus broker is down or unreachable; or the broadcast has hit `maxIterations`
- **Resolution**: (1) Verify MessageBus connectivity from the host. (2) Check if `maxIterations` has been reached via `GET /broadcasts/{name}`. (3) Restart the broadcast if appropriate.

### Database Connection Failures
- **Symptoms**: Greetings and broadcasts endpoints return 500 errors
- **Cause**: Postgres is unreachable or credentials have rotated
- **Resolution**: (1) Verify DaaS-managed Postgres host is reachable. (2) Confirm `DAAS_APP_USERNAME`/`DAAS_APP_PASSWORD` env vars are correctly injected (check Kubernetes secrets). (3) Check DaaS team for infrastructure issues.

### Redis Errors
- **Symptoms**: `POST /redis` or `GET /redis/{key}` return 500 errors
- **Cause**: Redis (GCP Memorystore) is unreachable or endpoint configuration is wrong
- **Resolution**: Verify the Redis endpoint in the active config file and network connectivity from the pod

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down / status check failing | Immediate | JTier team via PagerDuty POVGKE5; gchat space AAAA-S-mEoo |
| P2 | Degraded performance (high load, swap, SSH down) | 30 min | JTier team via PagerDuty POVGKE5 |
| P3 | Minor (network usage, NTP, Splunk) | Next business day | JTier team via PagerDuty POVGKE5 |

Emergency notification: `jtier-alerts@groupon.com`

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Postgres (`continuumOxygenPostgres`) | DaaS-managed; check host connectivity and `DAAS_APP_*` secrets | No fallback; greetings and broadcast endpoints return errors |
| Redis (`continuumOxygenRedisCache`) | Check Redis endpoint connectivity from pod | No fallback; Redis resource endpoints return errors |
| MessageBus | Check port 61613 on broker host; verify Artemis broker console | No fallback; broadcasts stall and publish/consume endpoints return errors |
| GitHub Enterprise | Check `https://api.github.groupondev.com` reachability | No fallback; `/repos/{team}/{repo}` returns error |
