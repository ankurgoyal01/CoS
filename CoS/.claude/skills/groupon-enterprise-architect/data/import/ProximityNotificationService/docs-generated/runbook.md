---
service: "proximity-notification-service"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /heartbeat.txt` | http | per-request (Dropwizard health check) | — |
| `GET /grpn/status` | http | Deployment readiness probe | — |
| PostgreSQL health probe | jdbc (via `ProximitynotificationserviceHealthCheck`) | Dropwizard health check interval | — |
| Redis health probe | tcp/jedis (via `OldProximityHealthCheck`) | Dropwizard health check interval | — |

Status URLs per environment:
- Staging: `https://proximity-notifications.staging.service.us-west-1.aws.groupondev.com/grpn/status`
- Staging EMEA: `https://proximity-notifications.staging.service.us-west-2.aws.groupondev.com/grpn/status`
- Prod US: `https://proximity-notifications.production.service.us-west-1.aws.groupondev.com/grpn/status`
- Prod EMEA: `https://proximity-notifications.production.service.eu-west-1.aws.groupondev.com/grpn/status`

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Request rate | counter | Geofence requests per minute (RPM) | Baseline ~7500 RPM |
| TP99 latency | histogram | 99th percentile latency for geofence endpoint | Alert if > 800ms |
| Push notification success rate | counter | Ratio of successful push sends to total attempts | Alert on significant drop |
| PostgreSQL health | gauge | Dropwizard health check pass/fail | Alert on fail |
| Redis health | gauge | Dropwizard health check pass/fail | Alert on fail |

Service is instrumented with Finch (`finch` 3.6) for A/B experiment and conversion metrics emitted to the `finch.log` stream.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Proximity Notifications SMA | Wavefront | https://groupon.wavefront.com/dashboards/proximity-notifications--sma |
| Proximity Notification Service | Wavefront | https://groupon.wavefront.com/dashboards/proximity-notification-service |
| Conveyor Cloud Customer Metrics | Wavefront | https://groupon.wavefront.com/dashboards/Conveyor-Cloud-Customer-Metrics |
| Conveyor Cloud Application Metrics | Wavefront | https://groupon.wavefront.com/dashboards/Conveyor-Cloud-Application-Metrics |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| ELK alert (Nagios) | See Nagios alerts wiki | warning/critical | See owners manual #nagios-alerts |
| Wavefront alerts | See Wavefront alert configurations | warning/critical | See owners manual #other-alerts |
| PagerDuty | Any critical service incident | critical | Page via https://groupon.pagerduty.com/services/PGV083B |

Alert contact: `ec-proximity-alert@groupon.com`

## Common Operations

### Restart Service (Cloud)

```bash
kubectl cloud-elevator auth
kubectx <context>   # e.g., proximity-notifications-production-us-west-1
kubectl get pods
kubectl rollout restart deployment/<deployment-name>
```

### Restart Service (On-Prem)

SSH to the application host and run:
```bash
sudo sv restart jtier
```

To stop or start:
```bash
sudo sv stop jtier
sudo sv start jtier
```

### Scale Up / Down (Cloud)

Adjust HPA settings at runtime:
```bash
kubectl edit hpa
kubectl edit deployment
```

To make permanent changes, edit the files in `.meta/deployment/cloud/components/app/` and redeploy:
- `maxReplicas` — maximum number of pods
- `hpaTargetUtilization` — CPU utilization target before scaling
- `cpu.main.request` — initial CPU requested
- `memory.main.request` / `memory.main.limit` — memory bounds

### Scale Up (On-Prem)

1. Obtain new hosts
2. Apply host template (copy from existing host in same environment)
3. Create ticket to add new host to PostgreSQL allowlist
4. Deploy and verify application
5. Create ticket to add new host to VIP

### Database Operations

- Migrations are run automatically on startup via `jtier-migrations`
- PostgreSQL backups are managed by the GDS team (no manual backup procedure)
- PostgreSQL connection pool: managed by `jtier-daas-postgres` (HikariCP)
- To request increased connection limits or storage, contact the GDS team

### Delete Send Logs (Testing / Debugging)

```
POST /proximity/delete-send-log?client_id=<bcookie>
```

This clears rate-limit history for a specific device, allowing re-testing of notification delivery.

## Troubleshooting

### Service is Overloaded (High Load / GC)

- **Symptoms**: High CPU or GC pauses, elevated latency, HTTP 500 responses
- **Cause**: Traffic spike or memory pressure
- **Resolution**: Add capacity (see Scale Up above). Check PostgreSQL connection limits with GDS team.

### Pods Crashing Repeatedly

- **Symptoms**: Pods in CrashLoopBackOff or frequent restarts
- **Cause**: Application startup error, OOM, or misconfiguration
- **Resolution**:
  ```bash
  kubectl get pods
  kubectl logs <pod_name> main-log-tail --tail -f
  ```
  Or for all pods:
  ```bash
  kubectl logs -n proximity-notifications-production -l groupon.com/service=proximity-notifications--app -c main --prefix=true --tail=100
  ```

### EDS (Event Delivery Service) Down / HTTP 500 Responses

- **Symptoms**: Proximity API returning HTTP 500
- **Cause**: Dependency service (EDS or push) unavailable
- **Resolution**: Page the Emerging Channels team via PagerDuty (`ec-proximity@groupon.pagerduty.com`)

### RBAC Access Denied

- **Symptoms**: `RBAC: Access Denied` when attempting to access endpoints
- **Cause**: Access denied in Hybrid Boundary
- **Resolution**: Contact HB team in Slack `#hybrid-boundary` channel

### Authentication Expired (kubectl)

- **Symptoms**: `Unable to connect to the server: No valid id-token, and cannot refresh without refresh-token`
- **Cause**: kubectl auth token expired
- **Resolution**: `kubectl cloud-elevator auth`

## Logs

### ELK Access

- Prod US (SNC/SAC): https://logging-us.groupondev.com/
- Prod EMEA (DUB): https://logging-eu.groupondev.com/
- Pre-prod (staging): https://logging-preprod.groupondev.com

Log index patterns:
- Production: `*:filebeat-mobile_notifications--*`
- Staging: `filebeat-mobile_notifications--*`

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down | Immediate | Emerging Channels team via PagerDuty https://groupon.pagerduty.com/services/PGV083B |
| P2 | Degraded (high latency, push failures) | 30 min | ec-proximity-alert@groupon.com |
| P3 | Minor impact | Next business day | emerging-channels@groupon.com |

- Criticality Tier: **Tier 3**
- SLA: 99.9% uptime, TP99 800ms latency, ~7500 RPM throughput

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| PostgreSQL (`continuumProximityNotificationPostgres`) | Dropwizard health check via JDBI | Service startup fails if unreachable |
| Redis (`continuumProximityNotificationRedis`) | Dropwizard health check via Jedis | Rate-limit checks may fail open |
| Rocketman push service | No circuit breaker; HTTP call failure logged | Geofence response still returned to mobile client |
| Coupon, CLO, Voucher, Audience, Watson services | No circuit breaker | Notification may not be sent; geofences still returned |
