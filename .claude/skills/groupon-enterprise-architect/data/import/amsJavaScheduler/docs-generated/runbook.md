---
service: "amsJavaScheduler"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Readiness probe (`/bin/true`) | exec | 5s (delay: 20s) | 5s |
| Liveness probe (`/bin/true`) | exec | 15s (delay: 30s) | 5s |

Both probes use `exec: ["/bin/true"]` — they confirm only that the container is running, not that the scheduler logic itself is healthy. For on-premise deployments, `scheduler_proc_monitor.py` runs every 30 minutes via crontab to detect and restart a missing Java process.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Scheduler process count | gauge | Number of running `amsJavaScheduler` Java processes (on-premise, via `scheduler_proc_monitor.py`) | Alert if count < 1 |
| Job pod completion | gauge | Whether the Kubernetes CronJob pod completed successfully (cloud, via kubectl / cluster monitoring) | Alert on pod failure or not-started |

Additional metrics are emitted to Groupon's monitoring infrastructure via `com.arpnetworking.metrics:metrics-client:0.2.2.GRPN.3`.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Jenkins CI | Jenkins | https://cloud-jenkins.groupondev.com/job/crm/job/amsJavaScheduler/ |
| DeployBot | DeployBot | https://deploybot.groupondev.com/crm/amsJavaScheduler |
| Log search | Kibana | Index: `audience-scheduler` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| AMS Scheduler Missing Alert | Scheduler process count < 1 (on-premise) | P1 (production) | PagerDuty page to `audience_service@groupon.pagerduty.com`; script attempts auto-restart |
| AMS Scheduler Missing Alert Soft | Scheduler process count < 1 (staging/UAT) | P3 | Email to `audience-alert@groupon.com` |
| AMS Scheduler Restarted | Process restarted successfully after a missing-process alert | Info | Email notification to `audience-eng@groupon.com` |
| Kubernetes CronJob pod failure | Pod exits with non-zero status | P2 | Investigate pod logs via `kubectl logs`; check AMS service availability |

## Common Operations

### Restart Service

**Cloud (Kubernetes):**
1. Authenticate: `kubectl cloud-elevator auth`
2. Switch to the appropriate context and namespace (e.g., `kubectl config use-context ams-gcp-production-us-central1; kubens ams-production`)
3. Force an immediate run: `kubectl create job --from=cronjob/<cronjob-name> <custom-job-name>`
4. Or wait for the next scheduled CronJob trigger (suspend/resume not needed if the job completed normally)

**On-premise:**
The `scheduler_proc_monitor.py` script auto-restarts the process. To manually restart:
```
export ACTIVE_ENV=<environment>_<realm>
java -DBASE_PATH=/var/groupon/ams -jar /var/groupon/ams/amsJavaScheduler/current/AMSJavaScheduler-current.jar &
```

### Scale Up / Down

All CronJob components are set to `parallelism: 1`. Scaling beyond one concurrent pod is not supported by design (each job type runs sequentially).

To temporarily disable a job:
```
kubectl patch cronjobs <cronjob-name> -p '{"spec" : {"suspend" : true }}'
```

To re-enable:
```
kubectl patch cronjobs <cronjob-name> -p '{"spec" : {"suspend" : false }}'
```

### Database Operations

This service does not own a database. Schedule file updates require a code change, PR to the `development` branch, a Jenkins build, and a DeployBot deployment. No runtime database migrations are applicable.

## Troubleshooting

### Scheduled Job Did Not Run
- **Symptoms**: No AMS materialization activity at the expected time; AMS SAIs not created
- **Cause**: CronJob pod may have failed, been suspended, or the cluster context may be mismatched
- **Resolution**: Check `kubectl get cronjob` and `kubectl get pods` for recent job status; review pod logs with `kubectl logs <pod-name>` or search Kibana index `audience-scheduler`

### AMS API Calls Failing
- **Symptoms**: Pod logs show HTTP errors when calling `continuumAudienceManagementService`; SAIs not created
- **Cause**: AMS service unavailable or degraded; network/auth issue between scheduler and AMS
- **Resolution**: Verify AMS service health independently; check `RUN_CONFIG` and `ACTIVE_ENV` env vars are correct for the environment; retry via a manual CronJob run once AMS recovers

### EDW Feedback Push Failing
- **Symptoms**: No audience data delivered to Teradata; pod logs show SSH errors
- **Cause**: SSH connectivity to `hadoopEdwFeedbackHost` broken; EDW host unreachable or keyless auth misconfigured
- **Resolution**: Verify SSH connectivity from the pod; check EDW host status; review JSch error messages in pod logs; contact EDW team if host is down

### Stale SADs Not Detected by Integrity Check
- **Symptoms**: SADs stuck with old next-materialized timestamps; no integrity-reset emails sent
- **Cause**: `sadintegrationcheck` CronJob not running or AMS API returning unexpected results
- **Resolution**: Check `sadintegrationcheck` CronJob status; review AMS SAD search API for stale records; manually trigger a job run via `kubectl create job`

### Unverified SAD Alert Emails Flooding
- **Symptoms**: Excessive alert emails from `amsScheduler_alerting` for unverified SADs
- **Cause**: A large number of SADs are in unverified state in AMS
- **Resolution**: Investigate root cause in `continuumAudienceManagementService`; the scheduler only reports, it does not remediate SAD verification state

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down / no audience materialization | Immediate | `audience_service@groupon.pagerduty.com` / `audience-eng@groupon.com` |
| P2 | Degraded (partial job failures, some regions affected) | 30 min | `audience-eng@groupon.com` |
| P3 | Minor impact (staging/UAT failure, soft alerts) | Next business day | `audience-alert@groupon.com` |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumAudienceManagementService` | Call AMS health endpoint directly; check Jenkins / DeployBot for recent deployments | No fallback; scheduled run fails and retries at next CronJob trigger |
| YARN ResourceManager | Query YARN API from cluster; check Hadoop cluster status | Capacity-gated jobs skip or use default parallelism |
| EDW Feedback Host | SSH connectivity test from pod | No fallback; EDW push skipped for that run; next run retries |
| SMTP relay | Send test email | Alerting silently fails; job execution continues unaffected |
