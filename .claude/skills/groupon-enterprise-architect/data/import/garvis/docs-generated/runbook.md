---
service: "garvis"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/healthcheck` | http | Configured by orchestration layer | Configured by orchestration layer |
| `/django-rq/` dashboard | http (manual) | On demand | N/A |

## Monitoring

### Metrics

> Operational procedures to be defined by service owner. No metrics definitions are discoverable from the architecture model.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| RQ Job Queue Status | django-rq (`/django-rq/`) | Internal — served by `continuumJarvisWebApp` |
| Django Admin | Django (`/admin/`) | Internal — served by `continuumJarvisWebApp` |

### Alerts

> Operational procedures to be defined by service owner. No alert definitions are discoverable from the architecture model.

## Common Operations

### Restart Service

1. Identify which container requires restart: `continuumJarvisWebApp`, `continuumJarvisBot`, or `continuumJarvisWorker`
2. Trigger a rolling restart via the orchestration platform (Kubernetes: `kubectl rollout restart deployment/<deployment-name>`)
3. Verify the `/grpn/healthcheck` endpoint returns HTTP 200 for `continuumJarvisWebApp`
4. Verify the RQ dashboard at `/django-rq/` shows workers connected for `continuumJarvisWorker`
5. Verify `continuumJarvisBot` is consuming Pub/Sub messages by sending a test command in Google Chat

### Scale Up / Down

1. Adjust replica count for the target container in the Kubernetes deployment manifest or via HPA configuration
2. For `continuumJarvisWorker`: increase replica count to process a backlog of RQ jobs; monitor the failed queue in `/django-rq/`
3. For `continuumJarvisWebApp`: scale horizontally for increased webhook or admin traffic
4. `continuumJarvisBot` should remain at one replica per Pub/Sub subscription to avoid duplicate message processing

### Database Operations

1. **Migrations**: Run `python manage.py migrate` as a Kubernetes job before deploying new application versions that include schema changes
2. **Backfills**: Execute via Django management commands (`python manage.py <command>`) as a one-off Kubernetes job
3. **Failed job cleanup**: Use the `/django-rq/` dashboard to inspect and retry or delete failed RQ jobs; failed jobs persist in `continuumJarvisRedis` until manually cleared

## Troubleshooting

### Bot not responding in Google Chat
- **Symptoms**: Google Chat commands sent to Jarvis receive no response; no errors visible to users
- **Cause**: `continuumJarvisBot` Pub/Sub subscriber is not running or has lost its subscription connection
- **Resolution**: Check `continuumJarvisBot` pod status; restart the container; verify `GOOGLE_CHAT_SUBSCRIPTION_NAME` and `GOOGLE_APPLICATION_CREDENTIALS` are correctly configured; check Google Cloud Pub/Sub subscription backlog in the GCP console

### Background jobs not executing
- **Symptoms**: Bot commands appear to succeed (acknowledgment sent to Chat) but follow-up notifications or JIRA tickets are not created
- **Cause**: `continuumJarvisWorker` is not running, `continuumJarvisRedis` is unreachable, or jobs are failing and accumulating in the RQ failed queue
- **Resolution**: Check worker status in `/django-rq/`; verify `REDIS_URL` is correct; inspect failed jobs in the RQ failed queue for error tracebacks; restart `continuumJarvisWorker` if needed

### JIRA tickets not created
- **Symptoms**: Change approval or incident commands complete without creating JIRA tickets; error messages may appear in Google Chat
- **Cause**: Invalid `JIRA_API_TOKEN`, `JIRA_USERNAME`, or `JIRA_SERVER` configuration; JIRA API rate limiting; JIRA outage
- **Resolution**: Verify JIRA credentials in environment config; check JIRA service status; inspect RQ failed jobs for JIRA API error responses

### PostgreSQL connection errors
- **Symptoms**: Django admin is inaccessible (500 errors); background jobs fail with database errors
- **Cause**: `continuumJarvisPostgres` is unreachable or `DATABASE_URL` is misconfigured
- **Resolution**: Verify `DATABASE_URL` environment variable; check database instance health; ensure database migrations have been run for the current application version

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Bot fully unresponsive; all change/incident workflows blocked | Immediate | deployment@groupon.com (Change Management team) |
| P2 | Partial degradation (e.g., JIRA integration down, workers not processing) | 30 min | deployment@groupon.com |
| P3 | Minor impact (e.g., non-critical integration unavailable, UI errors) | Next business day | deployment@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumJarvisPostgres` | Django ORM connection check on startup; `/grpn/healthcheck` | No fallback; web and worker containers fail to start |
| `continuumJarvisRedis` | RQ connection check on worker startup | No fallback; background job processing stops |
| Google Cloud Pub/Sub | Subscriber connection log; bot stops receiving messages if disconnected | No fallback; manual restart required |
| JIRA | Test JIRA API call; check credentials validity | Bot returns error message to user; jobs fail to RQ failed queue |
| PagerDuty | Test pdpyras API call | On-call lookup returns no results; non-critical degradation |
| GitHub | Test PyGithub API call | Change records lack GitHub context; non-critical degradation |
