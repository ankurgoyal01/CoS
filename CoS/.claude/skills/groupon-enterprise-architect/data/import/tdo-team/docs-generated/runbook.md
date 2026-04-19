---
service: "tdo-team"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `cat /tdo-team/grpn/healthcheck` (readiness) | exec | 5s | Not set |
| `cat /tdo-team/grpn/healthcheck` (liveness) | exec | 15s | Not set |
| `touch /tmp/signals/terminated` (job completion) | exec (in-script) | On script exit | Per activeDeadlineSeconds |

## Monitoring

### Metrics

> No evidence found in codebase. No Prometheus metrics, StatsD counters, or structured metrics emission is implemented in the active scripts. The `influxdb` dependency appears in Pipfile but is not actively configured in the scripts.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| TDO Overview | Wavefront | `https://groupon.wavefront.com/dashboard/TDO-overview` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| CronJob pod fails to start | Kubernetes `startingDeadlineSeconds` (60s) exceeded | warning | Check pod events with `kubectl describe pod`; check image availability in conveyor |
| CronJob run exceeds deadline | `activeDeadlineSeconds` exceeded; pod killed | warning | Check pod logs; investigate external dependency (Jira, Google, OpsGenie, Pingdom) availability |
| OpsGenie alert | Configured at `https://groupondev.app.opsgenie.com/service/73dc97e7-5f53-4001-95d5-3df50b3bc726` | varies | Follow OpsGenie runbook; contact incident-management@groupon.com |

## Common Operations

### Restart a CronJob

CronJobs run on a schedule; they cannot be "restarted" in the traditional sense. To trigger a manual run:

1. Identify the CronJob name in Kubernetes: `kubectl get cronjobs -n tdo-team-production`
2. Create a manual Job from the CronJob: `kubectl create job --from=cronjob/{component-name} {component-name}-manual-run -n tdo-team-production`
3. Monitor the pod: `kubectl get pods -n tdo-team-production -w`
4. Review logs: `kubectl logs -n tdo-team-production {pod-name}`

### Suspend / Resume a CronJob

To temporarily halt a cronjob from triggering:

1. Suspend: `kubectl patch cronjob {component-name} -n tdo-team-production -p '{"spec":{"suspend":true}}'`
2. Resume: `kubectl patch cronjob {component-name} -n tdo-team-production -p '{"spec":{"suspend":false}}'`

Alternatively, set `suspend: true` in the per-environment YAML and redeploy.

### Update a Cron Schedule

1. Edit the `jobSchedule` field in `.meta/deployment/cloud/components/{component}/{env}.yml`
2. Commit to `master` branch
3. Jenkins pipeline will build and redeploy all components

### Scale Up / Down

Not applicable. CronJobs run as single pods per scheduled invocation. Resource requests can be adjusted in `common.yml` per component.

### Database Operations

Not applicable. This service owns no database. State lives in Jira and Google Drive.

## Troubleshooting

### Jira Comments Not Being Added

- **Symptoms**: Advisory action, subtask, SEV4, logbook, or IR reminders are missing; no comments appear in Jira tickets
- **Cause**: Jira Basic Auth credentials may have expired; Jira filter ID may have changed; Jira API returning non-201 response
- **Resolution**:
  1. Check pod logs: `kubectl logs -n tdo-team-production {pod-name}`
  2. Verify Jira filter IDs by accessing `GET https://groupondev.atlassian.net/rest/api/2/filter/{id}` with current credentials
  3. Confirm auth token is valid: test with `curl -u incident-management@groupon.com:{token} https://groupondev.atlassian.net/rest/api/2/myself`
  4. Rotate credentials and update the script or Kubernetes secret as needed

### IR Documents Not Being Created

- **Symptoms**: GPROD resolved incidents missing IR Document Link field in Jira; no new documents in TDO Drive
- **Cause**: Google OAuth token expired; drive ID or folder ID changed; IR template document deleted
- **Resolution**:
  1. Check pod logs for `ir-automation` cronjob
  2. Verify Google OAuth credentials in `secrets/google_secrets.json` are still valid
  3. Confirm TDO Team Drive ID (`0AP8-rRMZoqbNUk9PVA`), IR Review Folder (`1TFPzaVdHjAg552ebDGTw1tLLsprqPiur`), and IR Template (`17RdOoak4QWMOHQ2Adu649eOQ0ZIlOpYz0cJbSkdCy0o`) still exist
  4. Re-authenticate following the [Google Project Setup guide](../../../import-repos/tdo-team/cronjobs/ir-automation/docs/google_project.md) if tokens need rotation

### Pingdom Shift Report Not Posting to Google Chat

- **Symptoms**: IMOC team does not receive 4-hour Pingdom summary in Google Chat
- **Cause**: Pingdom API key expired or revoked; Google Chat webhook URL changed or expired; script runtime exceeds `activeDeadlineSeconds` (1500s) on large Pingdom check sets
- **Resolution**:
  1. Check pod logs for `pingdom-shift-report` cronjob
  2. Verify Pingdom API key: `curl -H "App-key:{key}" -H "Account-Email:pingdom@groupon.com" https://api.pingdom.com/api/2.1/checks`
  3. Test Google Chat webhook: `curl -X POST -H "Content-Type: application/json" -d '{"text":"test"}' {webhook_url}`
  4. If runtime is the issue, review the number of active Pingdom checks and consider optimizing the script's API call pattern

### Weekend On-Call Not Posted to Google Chat

- **Symptoms**: IMOC Google Chat space does not show the weekend roster on Wednesday or Friday
- **Cause**: OpsGenie schedule ID changed; OpsGenie API key expired; Google Chat webhook URL changed
- **Resolution**:
  1. Check pod logs for `weekend-oncall` cronjob
  2. Verify OpsGenie schedule IDs `1c2e68a5-8acf-4ea5-b1b7-b5f7d36c0c19` and `6d34656d-6ccb-4d3c-a674-9611edff860b` still exist
  3. Test OpsGenie API: `curl -H "Authorization: GenieKey {key}" https://api.opsgenie.com/v2/schedules`
  4. Update schedule IDs or API key in `cronjobs/weekend-oncall.sh` and redeploy

### Logbook Tickets Not Being Closed

- **Symptoms**: Old GPROD logbook tickets (>10 days past planned start date) remain open
- **Cause**: Jira filter `47402` returning empty; Jira transition IDs `21` (TO DO -> DONE) or `41` (IN PROGRESS -> DONE) no longer valid; credential issue
- **Resolution**:
  1. Verify filter `47402` has results in Jira
  2. Check valid transition IDs for the logbook ticket type: `GET https://groupondev.atlassian.net/rest/api/2/issue/{key}/transitions`
  3. Update transition IDs in `cronjobs/close_old_logbooks_LOCAL.sh` if they have changed

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | All automated incident workflows stopped | Immediate | incident-management@groupon.com; page IMOC via OpsGenie |
| P2 | One or more cronjobs failing; partial automation loss | 30 min | incident-management@groupon.com |
| P3 | Delayed notifications; minor reminder gaps | Next business day | incident-management@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Jira (groupondev.atlassian.net) | `GET /rest/api/2/myself` with current credentials | No fallback; job fails and logs error |
| Service Portal | `GET /api/v2/services/{name}` | Falls back to IMOC team account ID for Jira mentions |
| Google Drive/Docs API | OAuth token validation via `google-auth` library | No fallback; IR automation job fails and logs exception |
| OpsGenie API | `GET /v2/schedules` with GenieKey | No fallback; on-call message posted with empty roster |
| Pingdom API | `GET /api/2.1/checks` with API key | Partial report posted; null-response checks skipped |
| Google Chat webhooks | HTTPS POST returns 200 | No fallback; failure logged |
