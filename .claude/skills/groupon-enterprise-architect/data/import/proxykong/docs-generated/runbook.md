---
service: "proxykong"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `https://proxykong.production.service.us-west-1.aws.groupondev.com/grpn/versions` | HTTP | Kubernetes liveness probe (Napistrano default) | Kubernetes default |
| `https://proxykong.production.service.eu-west-1.aws.groupondev.com/grpn/versions` | HTTP | Kubernetes liveness probe | Kubernetes default |
| `https://proxykong.staging.service.us-west-1.aws.groupondev.com/grpn/versions` | HTTP | Kubernetes liveness probe | Kubernetes default |

## Monitoring

### Metrics

Metrics conform to the Groupon Standard Measurement Architecture and are emitted via Telegraf to Wavefront.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Request rate | counter | HTTP requests per second to ProxyKong endpoints | Operational procedures to be defined by service owner |
| Error rate | counter | HTTP 4xx/5xx responses | Operational procedures to be defined by service owner |
| Response latency | histogram | Request duration per endpoint | Operational procedures to be defined by service owner |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| GAPI Overview | Wavefront | `https://groupon.wavefront.com/dashboard/gapi-overview` |
| ELK Production US | Kibana | `https://logging-us.groupondev.com/app/kibana#/discover?_a=(index:'us-*:filebeat-proxykong_itier--*')` |
| ELK Production EU | Kibana | `https://logging-eu.groupondev.com/app/kibana#/discover?_a=(index:'eu-*:filebeat-proxykong_itier--*')` |
| ELK Non-Production | Kibana | `https://logging-stable-unified01.grpn-logging-stable.us-west-2.aws.groupondev.com/app/discover#/` |
| Kube Web View Production US | Kube Web View | `https://kube-web-view.prod.us-west-1.aws.groupondev.com/clusters/local/namespaces/proxykong-production/deployments/proxykong--itier--default` |
| Kube Web View Production EU | Kube Web View | `https://kube-web-view.prod.eu-west-1.aws.groupondev.com/clusters/local/namespaces/proxykong-production/deployments/proxykong--itier--default` |
| Kube Web View Staging US | Kube Web View | `https://kube-web-view.stable.us-west-1.aws.groupondev.com/clusters/local/namespaces/proxykong-staging/deployments/proxykong--itier--default` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Pod crash looping | Pod repeatedly restarts | critical | Check startup logs; verify `GITHUB_TOKEN` secret is present and valid; check `/api-proxy-config` clone succeeded |
| High error rate | Elevated 5xx responses | warning | Check ELK logs for exception stack traces; validate GitHub and Jira connectivity |
| Stale config | Git refresh cron fails | warning | Check cron logs in Kubernetes; verify `GITHUB_TOKEN` has not expired |

## Common Operations

### Restart Service

```bash
# Via Napistrano
cd my-app-repo
npx nap --cloud deploy --artifact <artifact-id> staging us-west-1

# Via kubectl
kubectl -n proxykong-production rollout restart deployment/proxykong--itier--default
```

### Scale Up / Down

Scaling is handled by Kubernetes HPA. To manually override:

```bash
kubectl -n proxykong-production scale deployment proxykong--itier--default --replicas=<N>
```

Production min/max replicas are defined in `.deploy-configs/production-us-west-1.yml` (min: 2, max: 3).

### Database Operations

> Not applicable. ProxyKong does not own a database. Route configuration is managed via Git pull requests against `groupon-api/api-proxy-config`.

## Troubleshooting

### Route changes not being submitted (Jira or GitHub errors)

- **Symptoms**: UI shows an error response when submitting a route add/promote/delete request.
- **Cause**: Expired `GITHUB_TOKEN` or `jira-auth` credentials; GitHub Enterprise or Jira service unavailability.
- **Resolution**: Check pod logs (`kubectl -n proxykong-production logs --follow <pod-name> -c main`) for exception details. Rotate the `git-auth` or `jira-auth` Kubernetes secret if credentials have expired, then restart the pod.

### `/api-proxy-config` returns stale data

- **Symptoms**: Route queries return outdated configuration; recently merged routes not visible.
- **Cause**: The 10-minute cron job (`gitRefreshMaster.sh`) failed or the pod was recently restarted before the cron ran.
- **Resolution**: Check cron output in Kubernetes logs. If the `GITHUB_TOKEN` has changed, update the `git-auth` secret and restart the pod to re-initialize the remote URL.

### Pod fails to start

- **Symptoms**: Pod in `CrashLoopBackOff`; startup logs show errors in `start-proxykong.sh`.
- **Cause**: Missing `GITHUB_TOKEN` secret; unable to `cd /api-proxy-config`; cron daemon failure.
- **Resolution**: Verify the `git-auth` Kubernetes secret exists in the correct namespace (`proxykong-production` or `proxykong-staging`). Confirm the `api-proxy-config` clone is healthy inside a running pod.

### Rollback a deploy

Via DeployBot:
1. Visit `https://deploybot.groupondev.com/groupon-api/proxykong`.
2. Click on the deployment to roll back (in the **Version** column).
3. Click the "ROLLBACK" button.

Via Napistrano:
```bash
npx nap --cloud rollback staging us-west-1
```

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down; engineers cannot submit route changes | Immediate | Groupon API (apidevs@groupon.com) |
| P2 | Partial functionality; some endpoints failing | 30 min | Groupon API (apidevs@groupon.com) |
| P3 | Minor impact; stale data or cosmetic issues | Next business day | Groupon API (apidevs@groupon.com) |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| GitHub Enterprise | Attempt a `git pull` from within the pod; check `git-auth` secret validity | No fallback; PR creation will fail |
| Jira | Check ELK logs for Jira client errors; verify `/secrets/jira/jira.json` is mounted | No fallback; ticket creation will fail |
| `api-proxy-config` clone | `git status` inside `/api-proxy-config`; check cron logs | Stale config data served from last successful pull |
| Service Portal | `curl http://service-portal.snc1/api/v2/services/<name>` | Returns error JSON to caller; not blocking |
| Hybrid Boundary | `curl` the VIP validation endpoint | Returns `false` (VIP not found) to the UI |
