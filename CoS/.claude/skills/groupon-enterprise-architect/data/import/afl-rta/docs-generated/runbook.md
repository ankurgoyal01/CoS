---
service: "afl-rta"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/grpn/healthcheck` (port 8080) | http | readiness: 5s period / 20s delay; liveness: 15s period / 30s delay | Per Kubernetes probe defaults |
| Heartbeat file (`/var/groupon/jtier/heartbeat.txt`) | exec (file presence) | Created on pod `postStart`; deleted on `preStop` + 30s sleep | Kubernetes lifecycle hook |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Attribution count (order) | counter | Number of order attributions produced per time window | Zero for N hours triggers AFL-RTA Zero Attributions alert |
| Exception count | counter | Number of exceptions raised by the service | Non-zero over threshold triggers RTA Exceptions Alert |
| HTTP outbound latency | histogram | Latency of calls to Orders API and MDS | Visible in `afl-rta--sma` Wavefront dashboard |
| Kafka consumer lag | gauge | Consumer lag on `janus-tier2` topic | Monitored via Wavefront janus-tier2 dashboard |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| RTA Attribution Dashboard | Wavefront | https://groupon.wavefront.com/dashboards/RTA |
| AFL RTA SMA Dashboard | Wavefront | https://groupon.wavefront.com/dashboards/afl-rta--sma |
| Staging Kibana | ELK | https://stable-kibana-unified.us-central1.logging.stable.gcp.groupondev.com/ |
| Production US Kibana | ELK | https://prod-kibana-unified.us-central1.logging.prod.gcp.groupondev.com/ |
| Production INT (EMEA) Kibana | ELK | https://prod-kibana-unified-eu.logging.prod.gcp.groupondev.com/ |

> Kibana index for application logs: `filebeat-afl-rta_app--*`. Filter on `data.name` for event-name-based log entries. Use `groupon.region` to filter US/EMEA and `groupon.source` to filter staging/production.

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| AFL-RTA Zero Attributions | Zero order attributions for the last N hours | P4 | Check Janus upstream; check consumer logs in Kibana; consider pod restart if consumer stalled |
| RTA Exceptions Alert | AFL RTA is raising exceptions above threshold | P4 | Identify exception type in Kibana; for `URISyntaxException` notify business team about malformed URLs; escalate to AFL eng team if unclear |

> PagerDuty service: https://groupon.pagerduty.com/services/PP9FGY1 — alerts route to `gpn-alerts@groupon.com`.

## Common Operations

### Restart Service

> Only restart after understanding the root cause. Unexplained restarts should be escalated.

1. Redeploy via [DeployBot](https://deploybot.groupondev.com/AFL/afl-rta) (preferred — performs a rolling restart with the current version)
2. Or restart pods directly via kubectl:
   ```bash
   # Authenticate in the cluster
   kubectl cloud-elevator auth

   # Set the context (adjust environment/region as needed)
   kubectx afl-rta-<production,staging>-us-central1

   # Stop pods
   kubectl scale --replicas=0 deployment/afl-rta--app--default

   # Start pods
   kubectl scale --replicas=1 deployment/afl-rta--app--default
   ```
3. After restart, verify Wavefront dashboards and Kibana logs for exceptions or errors.

### Scale Up / Down

1. Scaling is managed automatically by HPA based on CPU utilization target (120%).
2. For manual intervention, update replica count via kubectl or adjust `minReplicas`/`maxReplicas` in the environment config YAML and redeploy via DeployBot.
3. Production bounds: min 2 / max 10 replicas. Staging bounds: min 1 / max 2 replicas.

### Database Operations

- Schema migrations are managed by `jtier-migrations` and run automatically on service startup.
- Manual DB access requires connection through the JTier DaaS platform using credentials from the Kubernetes secret `afl-rta--app--default--<secretName>`.
- No manual migration or backfill procedures are documented in this repository.

## Troubleshooting

### Zero Order Attributions

- **Symptoms**: Wavefront `AFL-RTA Zero Attributions` alert fires; no attributed order records in Kibana for a sustained period
- **Cause**: Either upstream Janus `janus-tier2` topic has stopped producing events, or the RTA consumer has stalled (e.g., Kafka coordinator error), or a critical exception is preventing processing
- **Resolution**:
  1. Check [Janus upstream Wavefront](https://groupon.wavefront.com/u/gXc9dN4Zvl?t=groupon) for topic activity. If Janus is down, contact the Janus team via Google Chat room `AAAAar-shcM`.
  2. If Janus is healthy, check Kibana (`filebeat-afl-rta_app--*`) for consumer or exception logs.
  3. If the Kafka `NOT_COORDINATOR` error appears: `"Group coordinator ... is unavailable or invalid due to cause: error response NOT_COORDINATOR"` — a new Kafka `groupId` credential is required (see [PR example](https://github.groupondev.com/AFL/afl-rta/pull/193)).
  4. If no Kibana logs appear at all, the application may be down — restart via DeployBot or kubectl (see [Restart Service](#restart-service)).
  5. Escalate to Affiliates Engineering if the issue cannot be resolved.

### RTA Exceptions

- **Symptoms**: Wavefront `RTA Exceptions Alert` fires; exception entries visible in Kibana
- **Cause**: Most common cause is `java.net.URISyntaxException` from malformed click URLs in `externalReferrer` events
- **Resolution**:
  1. Check Kibana for the exception type and the affected click URL.
  2. For `URISyntaxException`: notify the business team ([JIRA reference](https://groupondev.atlassian.net/l/cp/ADARHb1s)) about the malformed URL source.
  3. For other exceptions: investigate the stack trace, consult the AFL engineering team.

### Check Pod Logs (When Kibana is Unavailable)

```bash
kubectl cloud-elevator auth
kubectx afl-rta-<production,staging>-<us,europe>-<central,west>1
kubectl get pods
kubectl logs -f pod/<pod-name> -c main
```

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down | Immediate | gpn-alerts@groupon.com (PagerDuty PP9FGY1) |
| P2 | Degraded | 30 min | gpn-alerts@groupon.com (PagerDuty PP9FGY1) |
| P3 | Minor impact | Next business day | gpn-dev@groupon.com or #affiliates Google Chat |

> SLA targets: 90% availability, < 0.01% error rate. Note: a 1–2 hour outage is not critical as RTA catches up faster than events are produced.

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Kafka `janus-tier2` | Wavefront Janus upstream dashboard; Kibana for consumer log activity | Consumer stalls; resumes from committed offset on restart |
| `continuumOrdersService` | `failsafe` retry; outbound HTTP metrics in `afl-rta--sma` dashboard | Attribution falls back to `LoggingOrderRegistration` |
| `continuumMarketingDealService` | `failsafe` retry; `cache2k` in-memory cache reduces blast radius | Attribution falls back to `LoggingOrderRegistration` |
| `continuumAflRtaMySql` | JTier DaaS platform health; JVM connection pool metrics on Wavefront | No fallback — DB unavailability halts click storage and attribution |
| `messageBus` (MBus) | Wavefront RTA dashboard for publish counts | `LoggingOrderRegistration` logs attributed orders as fallback |
