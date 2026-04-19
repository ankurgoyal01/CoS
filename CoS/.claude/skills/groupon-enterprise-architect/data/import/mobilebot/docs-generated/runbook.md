---
service: "mobilebot"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /heartbeat` (port 80) | http | Kubernetes default (configured via `heartbeatPath: /heartbeat`) | Standard Kubernetes probe timeout |

The heartbeat server is started by `scripts/helpers/startup.js`. A successful response is HTTP 200 with an empty body and `Cache-Control: private, no-cache` headers. Each probe writes an `app.heartbeat` structured log event.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `app.heartbeat` (steno event) | counter | Increments on each health probe | Absence indicates service is down |
| `app.action` (steno event) | counter | Increments on each chat command received | — |
| `app.error` (steno event) | counter | Increments on command-handler errors | Elevated rate indicates integration failure |

Metrics are shipped via Telegraf to `metrics.{env}.{region}.aws.groupondev.com:8186`. Logs are shipped via Filebeat to Kafka endpoint (`kafka-elk-broker.snc1` for production US, `kafka-elk-broker.dub1` for EU).

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Mobilebot Operations | Wavefront | https://groupon.wavefront.com/u/7s2b2Nc1l7?t=groupon |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Heartbeat missing | `/heartbeat` stops responding | P1 | Check pod status; restart if CrashLoopBackOff |
| Redis connection failure | `app.error` events with Redis context at startup | P2 | Verify `REDIS_URL` secret and Redis cluster health |
| Jenkins trigger failure | `app.error` with `errType: bad status` or `errType: no response` | P2 | Check Jenkins controller health; verify `CI_BASE_URL` |

PagerDuty service: https://groupon.pagerduty.com/services/PPCS8HM
Emergency notification: mobilebot@groupon.pagerduty.com
GChat incident space: `AAAAxO5RYXk`

## Common Operations

### Restart Service

1. Identify the Kubernetes namespace: `mobilebot-{env}` (e.g., `mobilebot-production`)
2. Roll the deployment: `kubectl rollout restart deployment/mobilebot -n mobilebot-production`
3. Monitor rollout: `kubectl rollout status deployment/mobilebot -n mobilebot-production`
4. Confirm heartbeat: `curl http://mobilebot.prod.us-west-1.aws.groupondev.com/heartbeat`

### Scale Up / Down

Mobilebot is intentionally fixed at 1 replica. Do not increase replicas as this will cause duplicate chat responses. If capacity is needed, investigate the root cause (e.g., slow Ruby subprocess calls, Redis saturation).

### Force Release Branch Cache Reset

If the cached iOS release branch is stale, send this command in any chat room where mobilebot is active:

```
@mobilebot release_branch reset
```

This clears the Redis key `mobilebot:internal:ios:current_release_branch` and fetches the latest value from GitHub Enterprise.

### Manually Override Release Branch

```
@mobilebot release_branch set release/22.12
```

### Database Operations

- Redis is schema-less; no migrations
- To inspect Redis state: connect to the Redis instance and `GET mobilebot:internal:ios:current_release_branch`
- To clear all mobilebot state: `DEL mobilebot:internal:ios:current_release_branch` (use with caution in production)

## Troubleshooting

### Bot Not Responding to Commands

- **Symptoms**: `@mobilebot` commands in chat receive no reply
- **Cause**: Pod crash, Redis connection failure at startup, or chat adapter authentication failure
- **Resolution**: Check pod logs (`kubectl logs -n mobilebot-production deployment/mobilebot`); look for `app.start` event. Verify `REDIS_URL`, `HUBOT_SLACK_TOKEN` (Slack adapter), and GChat service account secrets are present and valid.

### App Store Status Query Fails

- **Symptoms**: `@mobilebot appstore_status` replies "Could not query app status at this time"
- **Cause**: Ruby Spaceship subprocess failure — likely expired or invalid Apple credentials (`ITC_USERNAME`, `ITC_PASSWORD`), 2FA issue, or network timeout
- **Resolution**: Verify secrets `ITC_USERNAME` and `ITC_PASSWORD` in Kubernetes. Check pod logs for Ruby subprocess stderr output. Apple credentials may need rotation.

### Play Store Status Query Fails

- **Symptoms**: `@mobilebot playstore_status` replies "Could not query app status at this time"
- **Cause**: Google Play service account JSON key expired or missing; `ci-groupon-playstore.json` secret not mounted
- **Resolution**: Check that the k8s secret is mounted at `.meta/deployment/cloud/secrets/ci-groupon-playstore.json`. Rotate the service account key via Google Cloud Console if expired.

### Jenkins Build Trigger Fails

- **Symptoms**: `@mobilebot upload release/22.12` replies with "Failed to start build... bad status" or "no response"
- **Cause**: Jenkins controller unreachable, wrong `CI_BASE_URL`, or job token mismatch
- **Resolution**: Verify `CI_BASE_URL` environment variable for the environment. Test Jenkins connectivity from the pod: `kubectl exec -it -n mobilebot-production deployment/mobilebot -- curl http://ci.production.service`

### GPROD Ticket Creation Fails

- **Symptoms**: `@mobilebot gprod ios 22.12 12345` replies "Whoops, looks like something went wrong"
- **Cause**: Atlassian API token expired, JIRA_BASE_URL incorrect, or TestRail token missing
- **Resolution**: Verify `ATLASSIAN_API_TOKEN`, `ATLASSIAN_API_EMAIL`, `JIRA_BASE_URL`, and `TESTRAIL_TOKEN` secrets. Token can be rotated in Atlassian account settings.

### On-Call Query Returns No User

- **Symptoms**: `@mobilebot oncall` replies "Could not get on call user"
- **Cause**: PagerDuty token expired or schedule IDs changed
- **Resolution**: Verify `PAGERDUTY_TOKEN` secret. Confirm schedule IDs `PQOLK3I` (iOS) and `PXD8WTR` (Android) are still valid in PagerDuty.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Bot completely unresponsive (no heartbeat) | Immediate | Mobile Consumer team via PagerDuty (`mobilebot@groupon.pagerduty.com`) |
| P2 | Bot up but commands failing (integration down) | 30 min | Mobile Consumer team via GChat space `AAAAxO5RYXk` |
| P3 | Individual command failure (non-critical) | Next business day | File ticket at https://github.groupondev.com/mobile-consumer/mobilebot/issues/new |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Redis | Check pod logs at startup for Redis connection errors | Release branch cache miss triggers live GitHub API fetch |
| Jenkins | HTTP GET to `CI_BASE_URL` from pod | Manual Jenkins UI trigger |
| PagerDuty | `@mapbox/pagerduty` GET to schedules endpoint | Manual on-call lookup in PagerDuty UI |
| GitHub Enterprise | Octokit GET to `GITHUB_BASE_URL/api/v3` | Manually set release branch: `@mobilebot release_branch set {branch}` |
| Jira (Atlassian) | HTTP GET to `JIRA_BASE_URL/rest/api/2/` | Manual Jira ticket creation |
| App Store Connect | Ruby Spaceship login test | Manual App Store Connect portal check |
| Google Play | Ruby Supply client initialization | Manual Play Console check |
