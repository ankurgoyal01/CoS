---
service: "elit-github-app"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/status` | http | JTier platform default | JTier platform default |

The status endpoint reports `commitId` as the SHA key. The endpoint is available on port 8080. The admin port 8081 exposes additional JTier admin metrics.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| JVM heap usage | gauge | JVM memory usage — memory limit is 500Mi | Monitor for sustained near-limit usage |
| HTTP request rate on `/elit-github-app/webhook` | counter | Rate of inbound GitHub webhook events | Operational procedures to be defined by service owner |
| HTTP 401 rate on `/elit-github-app/webhook` | counter | Failed signature validations — may indicate misconfigured secret or GitHub config change | Any sustained elevation |
| HTTP 500 rate on `/elit-github-app/webhook` | counter | Unhandled exceptions during event processing | Any non-zero rate |
| Thread pool saturation (fixed pool of 20 threads) | gauge | Scan work queue depth — pool has fixed 20 threads for async scan execution | Operational procedures to be defined by service owner |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| SMA HTTP-in | Grafana (JTier SMA) | Defined in `doc/_dashboards/components/sma/http-in.js` |
| SMA HTTP-out | Grafana (JTier SMA) | Defined in `doc/_dashboards/components/sma/http-out.js` |
| JVM dashboard | Grafana (JTier) | Defined in `doc/_dashboards/components/jvm.js` |
| Cloud dashboard | Grafana (JTier) | Defined in `doc/_dashboards/components/cloud.js` |
| Service dashboard | PagerDuty | https://groupon.pagerduty.com/services/P5XOVS7 |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Service down | `/grpn/status` returns non-200 | P1 | Restart pod; check GitHub Enterprise connectivity |
| High 401 rate | Sustained webhook signature failures | P2 | Verify `github.secret` matches GitHub App webhook secret; check GitHub App configuration |
| High 500 rate | Unhandled processing errors | P2 | Review Steno structured logs for stack traces; verify GitHub Enterprise API availability |
| Memory limit | JVM heap approaching 500Mi limit | P2 | Scale up memory or reduce concurrent scans |

PagerDuty notification address: `ellit-github-app@groupon.pagerduty.com`
Slack channel: `alasdair` (service owner channel — update to team channel for production incidents)

## Common Operations

### Restart Service

1. Identify the Kubernetes namespace for the target environment (e.g., `elit-github-app-production`).
2. Run: `kubectl rollout restart deployment/elit-github-app-api -n elit-github-app-production`
3. Monitor rollout: `kubectl rollout status deployment/elit-github-app-api -n elit-github-app-production`
4. Verify health: `curl http://<pod-ip>:8080/grpn/status`

### Scale Up / Down

Scaling is configured via `.meta/deployment/cloud/components/api/<env>.yml`. To change replica counts:

1. Update `minReplicas` and `maxReplicas` in the relevant environment YAML file.
2. Commit and merge to trigger a deploy, or use `kubectl scale` for an immediate temporary change: `kubectl scale deployment/elit-github-app-api --replicas=<N> -n elit-github-app-production`

### Database Operations

> Not applicable — This service is stateless and owns no databases.

## Troubleshooting

### Webhook signature validation failures (HTTP 401)

- **Symptoms**: GitHub App webhook deliveries show HTTP 401 responses in the GitHub App configuration UI. The service logs `Unable to verify message signature`.
- **Cause**: The `github.secret` in the JTier YAML config does not match the webhook secret configured in the GitHub App settings.
- **Resolution**: Verify the webhook secret in the GitHub App configuration and ensure the JTier config file contains the matching value. Rotate the secret if necessary.

### Check runs not appearing on PRs

- **Symptoms**: Pull requests in repositories with the app installed do not show the ELIT check.
- **Cause**: The service may not be receiving webhook events. Possible causes: service is unreachable from GitHub Enterprise, GitHub App is not installed on the repository, or the webhook event types are not configured (requires `check_suite` and `check_run` events).
- **Resolution**: Check GitHub App configuration — verify the service URL is correct and that Read & Write access on Checks plus subscription to `check_suite` and `check_run` events are configured. Check service health.

### Check runs stuck in `in_progress` state

- **Symptoms**: GitHub shows a check run as in-progress indefinitely. The service accepted the `created` event but the scan did not complete.
- **Cause**: An unhandled exception in the async thread pool during scan execution. The `StartCheckActionHandler` catches exceptions and marks the run `SKIPPED` with an error output, but a JVM crash or OOM may prevent this.
- **Resolution**: Review structured logs (Steno) for the check run ID. Look for OOM errors or thread pool exhaustion. Restart the service if threads are stuck.

### ELIT rule file parse errors

- **Symptoms**: Scans complete but use only default rules; service logs show `Error parsing .elit.yml for <repo>`.
- **Cause**: The per-repo `.elit.yml` file has invalid YAML syntax.
- **Resolution**: Examine the repository's `.elit.yml` file. On parse error, `ElitScannerFactory` falls back to the default ELIT configuration and logs an error — scans will still execute with default rules.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down — no checks being created | Immediate | PagerDuty: `ellit-github-app@groupon.pagerduty.com` |
| P2 | Degraded — checks failing or incorrect results | 30 min | PagerDuty: `ellit-github-app@groupon.pagerduty.com` |
| P3 | Minor impact — individual check annotation issues | Next business day | alasdair@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| GitHub Enterprise API | Attempt a GitHub API call; verify HTTP 200 response | No fallback — if GitHub Enterprise is unavailable, webhook processing will fail. Errors are caught and the check run is marked `SKIPPED`. |
