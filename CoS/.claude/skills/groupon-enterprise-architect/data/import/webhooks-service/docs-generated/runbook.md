---
service: "webhooks-service"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /heartbeat` | http | Readiness: 5s; Liveness: 15s | Default Kubernetes timeout |
| Kubernetes readiness probe | http | 5s (initial delay 20s) | Default |
| Kubernetes liveness probe | http | 15s (initial delay 30s) | Default |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| CPU utilization | gauge | Per-node CPU usage | Alert: CPU > 95% for 10 minutes |
| Memory available | gauge | Free memory on node | Alert: Free memory < 50MB for 10 minutes |
| Disk available | gauge | Free disk space on node | Alert: Free disk < 8% for 10 minutes |
| `app.heartbeat` | counter | Steno event written on each `/heartbeat` call; confirms service is alive | No alert; presence confirms liveness |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Webhooks On-Prem | Wavefront | https://groupon.wavefront.com/dashboards/webhooks-on-prem |
| Webhooks SMA | Wavefront | https://groupon.wavefront.com/dashboard/webhooks-service--sma |
| Kibana Log Search | Kibana | https://logging-us.groupondev.com/app/kibana#/discover/f1061820-0826-11eb-9355-d7fc37b44258 |
| Staging Logs | Kibana | https://logging-us.groupondev.com/goto/94d69b8a9c4484ecb222ed14a0dcd796 |
| Deployment Status Logs | Kibana | https://logging-us.groupondev.com/goto/cfebe81685be9b281cd902230f01cf13 |
| Traffic Dashboard | Kibana | https://logging-us.groupondev.com/goto/ac028efeb71c5f15d01e7d7f47711f9d |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| webhook-app1 CPU | CPU > 95% for 10 minutes | P1 | Investigate logs, profile, consider restarting service |
| webhook-app2 CPU | CPU > 95% for 10 minutes | P1 | Investigate logs, profile, consider restarting service |
| webhook-app1 MEM | Free memory < 50MB for 10 minutes | P1 | Investigate memory leak in logs, restart service |
| webhook-app2 MEM | Free memory < 50MB for 10 minutes | P1 | Investigate memory leak in logs, restart service |
| webhook-app1 DISK | Free disk < 8% for 10 minutes | P1 | Check log volume accumulation; clear stale logs; restart filebeat |
| webhook-app2 DISK | Free disk < 8% for 10 minutes | P1 | Check log volume accumulation; clear stale logs; restart filebeat |

Alerts are managed via PagerDuty: https://groupon.pagerduty.com/services/PW2Z1UF
Alert notifications go to: `da-alerts@groupon.com`

## Common Operations

### Restart Service

For cloud deployments (Kubernetes/Conveyor):
1. Log a Logbook ticket for the change
2. Use Deploybot to trigger a re-deploy or rolling restart of the `webhooks-service` component
3. Verify readiness via `/heartbeat` endpoint on the new pod
4. Monitor error rates in Kibana

For on-prem VMs (legacy):
1. SSH into the VM
2. Run `sudo killall node`
3. The Docker service will automatically restart the application

### Scale Up / Down

1. Update `minReplicas` and `maxReplicas` in the appropriate `.meta/deployment/cloud/components/webhooks-service/{env}.yml` file
2. Merge the change to `main` to deploy to staging, then promote to production via Deploybot
3. Reach out to the mobile team for capacity changes (per `OWNERS_MANUAL.md`)

### Database Operations

> Not applicable. This service is stateless and has no database.

## Troubleshooting

### Webhooks Not Firing / Automations Not Executing

- **Symptoms**: GitHub events are delivered (confirmed in GitHub webhook delivery logs) but no Slack messages, Jira updates, or CI triggers occur
- **Cause**: Missing or invalid `.webhooks.yml` in the repository; hook is disabled (`enabled: false`); unsupported event type
- **Resolution**: Verify `.webhooks.yml` exists on the default branch of the triggering repository. Check Kibana logs for "No .webhooks.yml file found" or config parse error messages. Validate hook names against the supported list in `webhooks/src/utils/config.ts`.

### Slack Notifications Not Delivered

- **Symptoms**: PR events occur but expected Slack DMs or channel messages are not received
- **Cause**: `SLACK_API_TOKEN` invalid or expired; GitHub username cannot be resolved to a Groupon email; user not found in Slack
- **Resolution**: Check Kibana for "Could not lookup slack user" or "User not found in slack" log entries. Verify `SLACK_API_TOKEN` is valid. Check the `#webhook-errors` Slack channel (`CF7MWGCNM`) for service-posted error messages.

### Jira Transitions Not Firing

- **Symptoms**: PR merged/opened but Jira issue state unchanged
- **Cause**: Jira issue key not parseable from PR title or commit messages; issue does not exist; transition name does not match Jira workflow states; `JIRA_API_TOKEN` invalid
- **Resolution**: Check Kibana for "Could not retrieve issue" or "Could not update status" entries. Verify the Jira project key in `.webhooks.yml` matches the issue prefix. Confirm the transition names in `.webhooks.yml` match available workflow transitions in Jira.

### CI Jobs Not Triggering

- **Symptoms**: Label is applied but no Jenkins build starts
- **Cause**: `CI_SERVICE_URL` or `CJ_SERVICE_URL` unreachable; Jenkins job URL invalid; label name mismatch in config
- **Resolution**: Check Kibana for CI client error logs. Verify the CI job URL is accessible from the service's network. Confirm `trigger_label` in `.webhooks.yml` exactly matches the label applied to the PR (case-insensitive is not guaranteed).

### High CPU / Memory Alerts

- **Symptoms**: Wavefront CPU or memory alert fires
- **Cause**: Large GitHub payloads; hook implementations with expensive GitHub pagination calls; memory leak in long-running process
- **Resolution**: Check Kibana for unusually long request durations. Profile the service if needed. Restart as a short-term mitigation (`sudo killall node` on-prem, or Deploybot rolling restart for cloud). SLA: average response time should be < 1 second.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down / CPU/Memory/Disk alert | Immediate | Mobile Release Engineering (PagerDuty: PW2Z1UF) |
| P2 | Degraded — hooks failing intermittently | 30 min | iOS Platform and Performance team |
| P3 | Minor — single hook type not working | Next business day | iOS Platform and Performance team (da-communications@groupon.com) |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| GitHub Enterprise | Octokit client call succeeds; `getFileContents` returns non-null | If GitHub is unreachable, config load fails; event is logged and skipped; no hooks run |
| Slack | `users.lookupByEmail` returns `ok: true` | If Slack is down, notification hooks fail and log errors; error is posted to `#webhook-errors` room if Slack is partially up |
| Jira Cloud | `getIssueBasics` returns non-null | Jira hooks fail gracefully; other hooks continue; error is logged |
| Jenkins CI | HTTP POST to build URL returns 2xx | CI hooks log errors and return; other hooks continue |
