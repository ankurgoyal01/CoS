---
service: "travel-affiliates-api"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /resources/manage/heartbeat` | http | Configured by Nagios/Pingdom | Not specified in code |
| `gpn-mgmt.py test ta-api` | exec | Manual / on-deploy | N/A |
| Elastic APM agent | apm | Continuous | N/A |

The heartbeat endpoint returns `200 OK` when the application is healthy and the heartbeat file is present. If the heartbeat is disabled, the load balancer removes the instance from rotation.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP response time (1 hotel) | histogram | Latency for single-hotel availability queries | Average: 200ms / Max: 300ms |
| HTTP response time (10 hotels) | histogram | Latency for 10-hotel availability queries | Average: 250ms / Max: 500ms |
| HTTP response time (50 hotels) | histogram | Latency for 50-hotel availability queries | Average: 500ms / Max: 2000ms |
| Request volume | counter | Total requests per minute | SLA: 3000 RPM |
| Error rate | gauge | Percentage of non-2xx responses | Warning: 10% / Critical: 15% |
| JVM heap usage | gauge | Tomcat JVM heap; monitored via GC log | Full GC frequency alert |
| Disk usage | gauge | Log and data disk space | Standard Nagios thresholds |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Services page | Nagios | `https://services.groupondev.com/services/affiliate-travel-metasearch-api` |
| APM | Elastic APM | Configured per environment via `apm.endpoint` in deployment manifests |
| Splunk: average response time | Splunk | `http://gr.pn/1CaP0Cj` (SNC1) |
| Splunk: request volume | Splunk | `http://gr.pn/1DwSL74` (SNC1) |
| Splunk: error rate | Splunk | `http://gr.pn/1DwSQrt` (SNC1) |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| `api_heartbeat` | Heartbeat endpoint not accessible | P1 (critical) | Restart Apache Tomcat; see Restart Service below |
| CPU load | CPU above threshold | P3 (low) | Check JVM GC logs; restart Tomcat if GC-related |
| Memory | High memory usage | P3 (low) | Check OOM in catalina-daemon.out; take heap dump; restart |
| Disk space | Disk above threshold | P3 (low) | Prune log files (stop Tomcat first for catalina-daemon.out) |
| iostat | IO utilization above threshold | P3 (low) | Inform team; no immediate action required |
| NTP | NTP skew or daemon issue | P3 (low) | Run `ntpdate -s ns1`; inform team |
| Error rate warning | >10% non-2xx responses | P2 (warning) | Check logs; identify failing endpoint; contact partner if external-caused |
| Error rate critical | >15% non-2xx responses | P1 (critical) | Escalate to Getaways Engineering immediately |

## Common Operations

### Restart Service

**In Kubernetes (Conveyor):**
```
kubectl rollout restart deployment/getaways-affiliate-api-app -n getaways-affiliate-api-{env}
```

**Legacy (bare-metal Tomcat, for reference):**
```bash
# Stop heartbeat first
/var/groupon/apache-tomcat/scripts/gpn-mgmt.py hb-stop

# Stop Tomcat (allow up to 30 seconds for shutdown)
/var/groupon/apache-tomcat/scripts/gpn-mgmt.py stop

# Start Tomcat (allow up to 2 minutes for services to initialize)
/var/groupon/apache-tomcat/scripts/gpn-mgmt.py start

# Re-enable heartbeat
/var/groupon/apache-tomcat/scripts/gpn-mgmt.py hb-start
```

### Enable / Disable Heartbeat

**Via HTTP:**
```bash
# Disable
curl -X DELETE http://{host}:8080/resources/manage/heartbeat --basic --user "admin:{password}"

# Enable
curl -X PUT http://{host}:8080/resources/manage/heartbeat --basic --user "admin:{password}"
```

### Scale Up / Down

Scaling is managed via Kubernetes HPA. Adjust `minReplicas`/`maxReplicas` in `.meta/deployment/cloud/components/app/{env}.yml` and redeploy via Conveyor. The HPA target CPU utilization is 50% (`hpaTargetUtilization: 50`).

### Adding Capacity (emergency manual scale)

```
kubectl scale deployment/getaways-affiliate-api-app --replicas={N} -n getaways-affiliate-api-production
```

### Database Operations

> No evidence found in codebase of database migration tooling. Schema changes to `continuumTravelAffiliatesDb` must be coordinated with the Getaways Engineering team.

## Troubleshooting

### Java Garbage Collection Issues

- **Symptoms**: Increased latency, high CPU usage, frequent Full GC events in logs
- **Cause**: JVM heap exhaustion; possible if memory settings are misconfigured or if abnormal data volumes are cached
- **Resolution**:
  1. Check GC log: `tail -n 200 /var/groupon/apache-tomcat/logs/gc/gc.log | grep "Full GC"`
  2. If Full GC is occurring every 2 seconds with little memory reclaimed, the application is CPU-bound
  3. Stop the heartbeat, take a heap dump with `jmap`, restart Tomcat, and notify Getaways Engineering
  4. Analyze heap dump to identify memory leak or increase heap allocation via `CATALINA_OPTS`

### Services Unavailable

- **Symptoms**: Heartbeat returns non-200; load balancer reports instance as unhealthy
- **Cause**: Tomcat crash, OOM kill, or Getaways API dependency failure
- **Resolution**:
  1. Check Kubernetes pod status: `kubectl get pods -n getaways-affiliate-api-{env}`
  2. Check pod logs: `kubectl logs -n getaways-affiliate-api-{env} {pod-name}`
  3. If OOM-killed, increase memory limit in deployment manifest or reduce JVM heap contention
  4. If Getaways API is down, the service cannot serve availability responses — escalate to Getaways Engineering

### High Load / Overload

- **Symptoms**: Latency exceeds SLA; request queue growing; CPU spiking
- **Cause**: Partner traffic spike; GC pause; or Getaways API slowness cascading via slow HTTP calls
- **Resolution**:
  1. Check access logs at `/var/groupon/apache-tomcat/logs/api/travel-affiliates-api-access.log`
  2. Identify the source partner from logs
  3. Contact partner to reduce request rate if external-caused
  4. Scale out replicas via HPA or manually if load is legitimate

### Disk Space Issues

- **Symptoms**: Disk space alert from Nagios
- **Cause**: Log files growing unboundedly
- **Resolution**:
  1. Run `df -h` and `du -sh *` to locate disk usage
  2. Application logs in `/var/groupon/apache-tomcat/logs/` can be pruned
  3. `catalina-daemon.out` cannot be deleted while Tomcat is running — stop Tomcat first
  4. GC logs in `/var/groupon/apache-tomcat/logs/gc/` can be safely deleted

### Cron Job Not Running

- **Symptoms**: Hotel feed files in S3 are stale (older than 24 hours)
- **Cause**: CronJob pod failed to start; `JobRunner` threw an exception; Getaways API unavailable during feed generation
- **Resolution**:
  1. Check CronJob status: `kubectl get cronjob -n getaways-affiliate-api-{env}`
  2. Check most recent job pod logs: `kubectl logs -n getaways-affiliate-api-{env} {cron-pod-name}`
  3. Manual trigger if needed: create a Job from the CronJob spec
  4. Verify Getaways API health before re-triggering

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down / heartbeat failing | Immediate | Getaways Engineering via gpn-alerts@groupon.com (PagerDuty) |
| P2 | Degraded availability or elevated error rate | 30 min | Getaways Engineering via gpn-alerts@groupon.com |
| P3 | Minor impact (disk, CPU, load, NTP) | Next business day | Getaways Engineering via gpn-support@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumGetawaysApi` | HTTP GET to Getaways availability endpoint; check for 2xx response | No fallback; availability requests fail with `HotelAvailabilityBusyException` |
| `continuumTravelAffiliatesFeedBucket` | AWS SDK S3 list-objects call to configured bucket | No fallback; feed uploads fail silently and must be retried |
| `continuumTravelAffiliatesDb` | JNDI connection pool health check | No evidence of explicit fallback configured |
