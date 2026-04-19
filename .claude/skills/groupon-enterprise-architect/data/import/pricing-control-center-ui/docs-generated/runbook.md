---
service: "pricing-control-center-ui"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Kubernetes pod liveness | http | Managed by Conveyor Cloud / Kubernetes | Not specified in repo |
| Wavefront dashboard | metrics | Continuous | N/A |

> Specific health check endpoint path not evidenced in codebase. iTier framework provides a standard `/grpn/versions` endpoint (referenced in OWNERS_MANUAL VIP links).

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP error rate (5xx) | counter | Rate of 5xx responses from the service; HB 503s indicate HB cannot reach the service | Alert triggers on elevated 503 rate |
| Application crashes | event | Pod crash/restart events in Kubernetes | Alert triggers on crash |

Metrics are instrumented via `itier-instrumentation ^9.10.4` and shipped to Wavefront via Telegraf/InfluxDB.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| pricing-control-center-ui | Wavefront | `https://groupon.wavefront.com/dashboard/pricing-control-center-ui` |
| Additional ops dashboard | Wavefront | `https://groupon.wavefront.com/u/6Nxn7MDZV8?t=groupon` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| HB 503 Errors | HB cannot reach the service (upstream unreachable) | warning | Check K8s pod status; verify all containers are up; contact #hybrid-boundary if service is running |
| Crashes | App crashes / pod restarts in K8s | critical | Check ELK logs for root cause; delete impacted pod to trigger recreation; verify config/env is correct in staging before prod deploy |

## Common Operations

### Restart Service

Restart by deleting a pod (Kubernetes will recreate it automatically):
```
kubectl -n pricing-control-center-ui-production-sox get pods
kubectl -n pricing-control-center-ui-production-sox delete pod/<pod_name>
```

Or via Napistrano re-deploy of the current artifact:
```
npx nap --cloud deploy --artifact <current-artifact> production us-central1
```

### Scale Up / Down

Scaling is managed via Napistrano/Helm — adjust `minReplicas`/`maxReplicas` in `.deploy-configs/production-us-central1.yml` and redeploy. Current limits: production min 2 / max 3; staging min 1 / max 3.

### Database Operations

> Not applicable. This service owns no database.

## Troubleshooting

### HB 503 Errors — Service unreachable

- **Symptoms**: Users receive 503 responses; Wavefront shows elevated 503 rate
- **Cause**: Hybrid Boundary cannot reach the backend service pods
- **Resolution**:
  1. Check Wavefront dashboard for error pattern
  2. Check pod status: `kubectl -n pricing-control-center-ui-production-sox get pods`
  3. Describe failing pods: `kubectl describe pod/<pod_name>`
  4. If pods are unhealthy, check ELK logs for application errors
  5. If pods appear healthy, contact `#hybrid-boundary` team

### Application Crashes

- **Symptoms**: Pods in CrashLoopBackOff; users see errors or cannot load pages
- **Cause**: Configuration change, bad deployment, or downstream dependency change
- **Resolution**:
  1. Check ELK logs: [Production ELK](https://logging-us.groupondev.com/app/kibana#/discover?_a=(index:'us-*:filebeat-pricing-control-center-ui_itier--*'))
  2. If single pod: `kubectl -n pricing-control-center-ui-production-sox delete pod/<pod_name>`
  3. If all pods: Identify cause from logs; if downstream (jtier/Doorman) issue, contact respective team; if deployment issue, roll back

### High Latency from Downstream (pricing-control-center-jtier)

- **Symptoms**: Slow page loads; Wavefront shows elevated response times
- **Cause**: `pricing-control-center-jtier` is experiencing latency or degradation
- **Resolution**:
  1. Check Wavefront for which endpoint is slow
  2. Check ELK logs for timeout errors (connect timeout is 10,000 ms on all jtier calls)
  3. Contact the Dynamic Pricing backend team responsible for `pricing-control-center-jtier`

### Authentication Issues (Doorman)

- **Symptoms**: Users stuck in redirect loop; `/doorman` redirect fails
- **Cause**: Doorman SSO outage or misconfigured destination path
- **Resolution**:
  1. Verify Doorman service status (staging: `doorman-staging-na.groupondev.com`; production: `doorman-na.groupondev.com`)
  2. Check `DEPLOY_ENV` environment variable is set correctly in running pods
  3. Currently authenticated users (valid `authn_token` cookie) are not affected until their 6-hour session expires

### Rollback a Deploy

1. Via Deploybot: `https://deploybot.groupondev.com/sox-inscope/pricing-control-center-ui` — click the version to roll back, then click "ROLLBACK"
2. Via Napistrano: `npx nap --cloud rollback production us-central1`

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down — all users blocked | Immediate | Dynamic Pricing team (dp-engg@groupon.com); GChat space `AAAAi3yfoYY` |
| P2 | Degraded — some routes failing or high latency | 30 min | Dynamic Pricing team |
| P3 | Minor impact — non-critical route degradation | Next business day | Dynamic Pricing team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| pricing-control-center-jtier | Wavefront dashboard; ELK logs for timeout/error patterns | No fallback — all data routes fail if jtier is down |
| Doorman SSO | Doorman service status page | Existing sessions (valid cookie) continue for up to 6 hours; new logins blocked |
| Hybrid Boundary | `#hybrid-boundary` Slack channel; HB UI dashboards | No application-level fallback |

## Useful Commands

```bash
# Get pods
kubectl -n pricing-control-center-ui-production-sox get pods

# Describe a pod
kubectl -n pricing-control-center-ui-production-sox describe pod/<pod_name>

# View live pod logs
kubectl -n pricing-control-center-ui-production-sox logs -f <pod_name> -c main

# Login to a pod shell
kubectl -n pricing-control-center-ui-production-sox exec -it pod/<pod_name> -c main -- /bin/sh

# Port-forward for local inspection
kubectl -n pricing-control-center-ui-production-sox port-forward <pod_name> 8080:8000

# Napistrano logs
npx nap --cloud logs --follow production us-central1

# List available artifacts
npx nap artifacts --available staging us-central1
```
