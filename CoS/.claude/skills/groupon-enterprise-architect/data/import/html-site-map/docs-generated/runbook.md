---
service: "html-site-map"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/grpn/healthcheck` | http | — (polled by Conveyor Cloud) | — |

Check health manually:
```bash
curl -k https://conveyor-html-site-map-<environment>-vip.<data-center>/grpn/healthcheck
# Expected output: OK
```

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Memory Usage GC | gauge | Node.js heap memory utilization | Severity 4 — critical level; risk of OOMKilled pod restarts |
| Pod Restarts | counter | Kubernetes pod restart count (typically OOMKilled) | Severity 4 — triggers dev team page |
| CPU Usage | gauge | Container CPU consumption | Severity 4 — app may be overloaded |
| Crashes (CrashLoopBackOff) | counter | Pod crash loop detection | Severity 5 — code failure or misconfiguration |
| HB 503 Errors | counter | Hybrid Boundary 503 responses (unreachable backend) | Severity 4 — backend failure or overload |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| HTML Sitemap Application Metrics | Wavefront | https://groupon.wavefront.com/dashboard/html-site-map |
| Conveyor Cloud Customer Metrics | Wavefront | https://groupon.wavefront.com/dashboard/Conveyor-Cloud-Customer-Metrics |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Memory Usage GC | Node.js heap at critical level | 4 | Check for memory leaks; correlate with Pod Restarts chart; rollback if needed |
| Pod Restarts | Pods restarting (likely OOMKilled) | 4 | Check `kubectl logs <pod> -c <container> --previous`; check events `kubectl get events -n html-site-map-production` |
| CPU Usage | CPU saturation | 4 | Check Wavefront CPU chart; check for pod starvation events |
| Crashes | CrashLoopBackOff detected | 5 | Verify secrets; verify `PORT=8000`; check startup probe timing; check logs |
| HB 503 Errors | Hybrid Boundary receiving 503 from backend | 4 | Check CPU Usage; check Crashes; verify pod count |

Alert notifications route to: `seo-alerts@groupon.pagerduty.com` — PagerDuty service [PLAI6WB](https://groupon.pagerduty.com/service-directory/PLAI6WB)

## Common Operations

### Restart Service

Restart by redeploying the current artifact via Deploybot:
1. Navigate to https://deploybot.groupondev.com/seo/html-site-map
2. Find the current deployment in "Last Successful Deploy Per Environment"
3. Click "Retry" to re-run the deployment with the same artifact

Or via napistrano CLI:
```bash
npx nap --cloud deploy --artifact <current-sha> staging us-central1
```

### Scale Up / Down

Scaling is controlled by updating `minReplicas` / `maxReplicas` in `package.json` under `napistrano.environment` and regenerating deploy configs:
```bash
npx nap --cloud deploy:configs
```
Then commit and redeploy. Current production limits: min 1–2, max 3–5 per region.

### Rollback a Deploy

Via Deploybot UI:
1. Navigate to https://deploybot.groupondev.com/seo/html-site-map
2. Click on the deployment version in the "Version" column
3. Click the "ROLLBACK" button

Via napistrano CLI:
```bash
npx nap --cloud rollback staging us-west-1
npx nap --cloud rollback production eu-west-1
```

### Database Operations

> Not applicable — this service is stateless and does not own any data stores.

## Troubleshooting

### Memory Usage / OOMKilled Pods
- **Symptoms**: Pod restarts; `OOMKilled` in pod events; Memory Usage GC alert fires
- **Cause**: Node.js heap exceeds pod memory limit; possible memory leak or traffic spike
- **Resolution**: Check correlation between Memory Usage GC and Pod Restarts charts in Wavefront. Run `kubectl get events -n html-site-map-production`. If OOMKilled, rollback to previous stable artifact immediately. Create Jira ticket for root cause investigation.

### HB 503 Errors
- **Symptoms**: Users receive 503 errors; HB 503 alert fires
- **Cause**: All backend pods are unavailable — may be crashing, OOMKilled, or CPU-starved
- **Resolution**: Check CPU Usage alert and Crashes alert. Verify pod status with `kubectl get pods -n html-site-map-production`. Rollback if pods are in CrashLoopBackOff.

### LPAPI Unavailability
- **Symptoms**: All sitemap pages return 503 or unexpected status codes; no Wavefront memory/CPU alerts
- **Cause**: LPAPI (`continuumApiLazloService`) is unreachable or returning errors
- **Resolution**: Check LPAPI health independently. The sitemap service degrades gracefully (propagates LPAPI status code). Monitor LPAPI team's alerts. No local mitigation is possible — the service has no fallback data source.

### CrashLoopBackOff at Startup
- **Symptoms**: Pods crash immediately after deployment; "Crashes" alert fires
- **Cause**: Misconfiguration (wrong `PORT`, missing env vars) or code error
- **Resolution**: Check pod logs: `kubectl logs <pod-name> -c main --previous`. Verify `PORT=8000` and `KELDOR_CONFIG_SOURCE` are set. Rollback if startup cannot be resolved quickly.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down (all regions) | Immediate | SEO team via `#seo-eng` Slack; PagerDuty PLAI6WB |
| P2 | Single region degraded or elevated error rate | 30 min | SEO team via `#seo-eng` Slack |
| P3 | Minor impact (e.g. elevated latency, isolated errors) | Next business day | Jira ticket in GSEO project |

Recommended deployment caution: Avoid major production deployments during hard moratoriums, long holidays, or high-traffic events. When promoting from staging to production, deploy EMEA first (lower traffic), validate, then deploy to North America.

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| LPAPI (`continuumApiLazloService`) | Monitor LPAPI's own health dashboard and Wavefront metrics | No fallback — sitemap pages return LPAPI's error status code (404/503) |
| Layout Service | Monitor via shared platform health dashboards | Partial page render (body content without shared shell) |
| Groupon CDN | Monitor CDN availability; check asset loading in browser dev tools | Pages render without CSS/JS styling |

## Log Access

- **ELK Production US**: https://logging-us.groupondev.com/app/kibana#/discover?_a=(index:'us-*:filebeat-html-site-map_itier--*')
- **ELK Production EU**: https://logging-eu.groupondev.com/app/kibana
- **Kube Web View (Prod US)**: https://kube-web-view.prod.us-central1.gcp.groupondev.com/clusters/local/namespaces/html-site-map-production/deployments/html-site-map--itier--default/logs
- **Kube Web View (Prod EU)**: https://kube-web-view.prod.eu-west-1.aws.groupondev.com/clusters/local/namespaces/html-site-map-production/deployments/html-site-map--itier--default/logs
- **CLI**: `npx nap --cloud logs --follow production us-central1`
