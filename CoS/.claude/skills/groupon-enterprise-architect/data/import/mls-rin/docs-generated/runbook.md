---
service: "mls-rin"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/grpn/healthcheck` (port 8080) | http (Kubernetes readiness probe) | 20s | 15s |
| `/ping` (port 8080) | http (Kubernetes liveness probe) | 15s | 5s |
| `/grpn/status` (port 8080) | http (manual / diagnostic) | on-demand | — |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Incoming HTTP failure rate (`http.in` 5xx) | counter | Rate of incoming request failures | Alert if > 5 failures in 1 min (Wavefront alert 1632306081692) |
| Outgoing HTTP failure rate (`http.out` 5xx) | counter | Rate of failures on downstream client calls | Alert if > 10 failures in 1 min (Wavefront alert 1632306081780) |
| Incoming P99 latency | histogram | 99th percentile response time for inbound requests | Alert if > 10s for 4 mins (Wavefront alert 1630328619882) |
| SLA P90 response time | histogram | 90th percentile end-to-end response time | Target: 2s |
| SLA P99 response time | histogram | 99th percentile end-to-end response time | Target: 10s |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| MLS RIN SMA (cloud primary) | Wavefront | https://groupon.wavefront.com/dashboard/mls-rin--sma |
| MLS RIN Staging | Wavefront | https://groupon.wavefront.com/dashboard/mls-rin-staging |
| MLS RIN DUB1 | Wavefront | https://groupon.wavefront.com/dashboard/mls-rin-dub1 |
| MLS RIN SAC1 | Wavefront | https://groupon.wavefront.com/dashboard/mls-rin-sac1 |
| MLS RIN SNC1 | Wavefront | https://groupon.wavefront.com/dashboard/mls-rin-snc1 |
| MLS Production (on-prem) | Wavefront | https://groupon.wavefront.com/dashboard/snc1-mls-production |
| Conveyor Cloud Customer Metrics | Wavefront | https://groupon.wavefront.com/dashboard/Conveyor-Cloud-Customer-Metrics |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| MLS RIN API Failures (on-prem Nagios) | Increased 500 responses | — | Check Splunk; identify DB or downstream cause; engage GDS (DB), dependency team, or Merchant Experience |
| MLS RIN API Response Time (on-prem Nagios) | Increased response time | — | Check Splunk; identify DB or downstream slowness; low urgency, usually self-resolving |
| Outgoing Failure Alert (Wavefront 1632306081780) | `http.out` failures > 10 in 1 min | warning | Identify failing downstream service from `http.out` metrics; report to respective service team |
| Incoming Failure Alert (Wavefront 1632306081692) | `http.in` failures > 5 in 1 min | warning | Find RCA via Splunk; check app logs for exceptions |
| Incoming Latency Alert (Wavefront 1630328619882) | Incoming P99 > 10s for 4 min | warning | Check `http.out` and `db-out` sections in Wavefront to identify slow dependency or DB query |

## Common Operations

### Restart Service

**On cloud (Kubernetes):**
```
kubectl scale --replicas=0 deployment/mls-rin--app--default
kubectl scale --replicas=<desired> deployment/mls-rin--app--default
kubectl get pods
```

**On-premises (JTier / runit):**
```
ssh mls-rin-appN.snc1
sudo sv stop jtier
sudo sv start jtier
```

**Graceful restart via Capistrano (removes from LB, restarts, smoke tests, re-adds):**
```
bundle exec cap snc1:staging_us graceful_restart
```

### Scale Up / Down

**Cloud — quick (immediate effect):**
```
kubectl scale --replicas=<N> deployment/mls-rin--app--default
```

**Cloud — planned (persisted):**
Edit `minReplicas` / `maxReplicas` in `.meta/deployment/cloud/components/app/<env-region>.yml` and redeploy.

**On-premises:**
Add new hosts to `Capfile`, apply host template, deploy current version via `cap`.

### Database Operations

- Schema migrations are managed externally via the `mls-db-schemas` artifact; MLS RIN does not run migrations in production
- Flyway is a test-scope dependency only; production schema changes must be coordinated with the MLS team before deployment
- For heavy DB query issues causing overload: add capacity (scale up replicas) and engage GDS if the issue is at the PostgreSQL layer

### Remove Host from Load Balancer (on-premises)
```
bundle exec cap dub1:production1 invoke COMMAND="sudo rm /var/groupon/jtier/heartbeat.txt"
```

### Rejoin Load Balancer (on-premises)
```
bundle exec cap dub1:production1 invoke COMMAND="touch /var/groupon/jtier/heartbeat.txt"
```

## Troubleshooting

### High Error Rate (5xx)
- **Symptoms**: Elevated 5xx responses visible in Wavefront `http.in` or Nagios "MLS RIN API failures" alert firing
- **Cause**: Database connectivity issue, downstream dependency failure, or application bug
- **Resolution**: Check Splunk for exceptions (`sourcetype=mls-rin:us:app exception`); identify whether errors are concentrated on a specific endpoint or downstream service; engage GDS for DB issues, dependency team for downstream failures, or Merchant Experience for code bugs

### High Latency (P99 > 10s)
- **Symptoms**: Wavefront incoming latency alert firing; Merchant Center portal slow
- **Cause**: Heavy or long-running database queries; slow downstream inventory service; resource saturation
- **Resolution**: Check `http.out` and `db-out` sections in Wavefront SMA dashboard; if DB-related, consider scaling up replicas; if downstream service related, check that service's health; bottlenecks documented: number of requests against inventory services (like VIS), long-running heavy DB queries

### Service Not Starting
- **Symptoms**: Pod crash-looping; liveness probe failures
- **Cause**: Bad configuration file; missing secret; DB connectivity at startup
- **Resolution (cloud)**: Check pod logs via `kubectl logs`; verify `JTIER_RUN_CONFIG` points to a valid file; check secret mount
- **Resolution (on-prem)**: Check runit log: `less /var/groupon/log/jtier/runit/current`; check app log: `less /var/groupon/jtier/logs/jtier.steno.log`

### Deployment Rollback
**DeployBot:**
1. Navigate to the deployment entry in DeployBot
2. Locate the GPROD ticket created by DeployBot
3. Use the link in the GPROD ticket to the last successful build to trigger rollback
4. Repeat for each stage: `production_snc1`, `production_sac1`, `production_dub1`

**Capistrano (on-prem):**
```
bundle exec cap snc1:staging_us rollback
```

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — Merchant Center cannot load deal data | Immediate | bmx-alert@groupon.com; PagerDuty PV2ZOZL; Merchant Experience team |
| P2 | Degraded — high error rate or severe latency | 30 min | bmx-alert@groupon.com; Slack #global-merchant-exper |
| P3 | Minor impact — single endpoint slow or partial data | Next business day | Merchant Experience team via email |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| mlsRinDealIndexDb (PostgreSQL) | DaaS health check via JTier; check Wavefront `db-out` metrics | No fallback — deal list endpoints will fail if DB unreachable |
| mlsRinHistoryDb (PostgreSQL) | DaaS health check | No fallback — history endpoints will fail |
| mlsRinMetricsDb (PostgreSQL) | DaaS health check | No fallback — metrics endpoints will fail |
| mlsRinUnitIndexDb (PostgreSQL) | DaaS health check | Unit search falls back to FIS direct calls for count strategies that support it |
| mlsRinYangDb (PostgreSQL) | DaaS health check (optional) | Module disabled if `yangConfig` is absent in config |
| Downstream HTTP services | Check Splunk `http.out` by data.service; Wavefront outgoing failure metrics | Optional clients (VIS, GLive, Getaways, Discussion) degrade gracefully; required clients degrade endpoint responses |
