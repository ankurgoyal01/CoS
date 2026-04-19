---
service: "releasegen"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Dropwizard admin health check (`/healthcheck`) | http | Kubernetes liveness/readiness probe interval (jtier default) | jtier default |
| JIRA `/myself` call at startup | http | Once at startup | jtier default |

> Detailed probe intervals are managed by the jtier Helm chart defaults and are not overridden in `common.yml`.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `publish` event duration | histogram | Logged via Steno structured logging on each `DeploymentServiceImpl.publishDeployment` call | Operational procedures to be defined by service owner |
| `jira.search` event duration | histogram | Logged per poll cycle in `JiraDeploymentSource`; includes issue count, release count, deployment count | Operational procedures to be defined by service owner |
| `jira.search.start` / `jira.search.stop` | counter | Worker lifecycle events logged via Steno | Operational procedures to be defined by service owner |

### Dashboards

> Operational procedures to be defined by service owner. Dashboards are expected to be available via the jtier observability platform (Splunk / Grafana based on Steno log output).

### Alerts

> Operational procedures to be defined by service owner.

## Common Operations

### Restart Service

Releasegen is stateless. A rolling restart can be performed via Deploybot by redeploying the current version, or via `kubectl rollout restart deployment/releasegen-production` in the appropriate namespace.

The background worker (`JiraDeploymentSource`) uses an in-memory `since` cursor. On restart, it resets to `now() - initialWindow` (default: 8 days), so recently processed deployments may be re-evaluated. Re-evaluation is idempotent: GitHub releases already tagged to the SHA are updated rather than duplicated, and JIRA tickets already labeled `releasegen` are excluded from the JQL query.

### Scale Up / Down

Scaling is managed via the Kubernetes HPA. To manually override, edit the `minReplicas` / `maxReplicas` in the environment-specific YAML under `.meta/deployment/cloud/components/app/` and redeploy via Deploybot. The HPA target CPU utilization is set to 50%.

### Reprocess Historical Deployments

Use the admin UI at `https://releasegen.staging.service.us-west-1.aws.groupondev.com/list/{org}/{repo}` (or the equivalent production URL) to browse deployment records. Call `POST /deployment/{org}/{repo}/{id}` with the Deploybot deployment ID to reprocess a specific deployment. Open the browser JavaScript console to see errors.

Alternatively, stop the worker via `DELETE /worker`, then restart it via `POST /worker` to trigger a fresh JIRA poll from the configured time window.

### Stop / Start Background Worker

```
# Stop worker
curl -X DELETE http://<host>:8080/worker

# Start worker
curl -X POST http://<host>:8080/worker
```

The worker auto-starts on service boot when `worker.autoStart=true` (the default).

### Database Operations

> Not applicable. Releasegen is stateless and owns no database.

## Troubleshooting

### Release Not Created After Production Deployment

- **Symptoms**: A production deployment completed in Deploybot but no GitHub release was created or updated for the SHA
- **Cause**: Either the Releasebot GitHub App is not installed in the repository, the worker has not yet polled (poll period default is 1 minute), or the JIRA RE ticket for the deployment was not in `Done` status at the time of the poll, or the deployment ID was not found in Deploybot
- **Resolution**: Verify the Releasebot app is installed. Wait one poll cycle. If the issue persists, call `POST /deployment/{org}/{repo}/{id}` directly with the Deploybot ID. Check service logs for `publish` event entries and any error details.

### JIRA Tickets Not Labeled or Linked

- **Symptoms**: JIRA tickets referenced in PR titles are not labeled `releasegen` or do not have a remote link to the GitHub release
- **Cause**: The JIRA ticket key was not present in the PR title at the time release notes were generated, or the JIRA API call failed
- **Resolution**: Edit the PR title to include the JIRA key and reprocess the deployment via `POST /deployment/{org}/{repo}/{id}`. Check logs for JIRA API errors.

### Worker Stuck in Loop

- **Symptoms**: `jira.search` log events show the same `since` value repeated with non-empty `issues` count
- **Cause**: `JiraDeploymentSource.adjustSince` detects the loop condition and advances `since` by 1 minute automatically
- **Resolution**: Monitor the `newSince` field in logs to confirm the cursor is advancing. If stuck, restart the worker via `DELETE /worker` then `POST /worker`.

### GitHub Rate Limit Exceeded

- **Symptoms**: GitHub API calls fail with HTTP 403 or 429 responses; release creation or note generation errors in logs
- **Cause**: The GitHub App installation token has exhausted its rate limit for the installation
- **Resolution**: Rate limits reset hourly. If persistent, reduce the frequency of manual reprocessing. Consider requesting a higher rate limit for the GitHub App installation.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down, no releases being created | Immediate | release-engineering team |
| P2 | Worker stopped or JIRA/GitHub integration degraded | 30 min | release-engineering team |
| P3 | Individual deployment not processed; admin UI unavailable | Next business day | release-engineering team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Deploybot | `GET /v1/deployments/{org}/{name}` — returns HTTP 200 with JSON array | Deployment publication fails; worker skips the deployment and continues |
| GitHub Enterprise | GitHub App token fetch succeeds; `GET /repos/{org}/{repo}/deployments` accessible | Release creation fails; caller receives an error |
| JIRA | `GET /myself` at startup confirms connectivity and retrieves timezone | Startup fails if JIRA is unreachable at boot time; during operation, polling errors are logged and the worker retries on next cycle |
