---
service: "sem-gtm"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/healthz` (tagging server) | http GET | 30s (after 300s initial delay) | 4s |
| `/healthz` (preview server) | http GET | 30s (after 300s initial delay) | 4s |

## Monitoring

### Metrics

> No evidence found in codebase of Groupon-defined custom metrics. The GTM Cloud image exposes default runtime metrics. Operational visibility is provided via the Wavefront dashboard.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| sem-gtm operational dashboard | Wavefront | https://groupon.wavefront.com/u/12gRF83b52?t=groupon |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| PagerDuty P6BR82L | Service degradation or outage detected | critical | Page SEM on-call engineer; check Kubernetes events and pod logs; verify GTM Cloud API connectivity |

PagerDuty service directory: https://groupon.pagerduty.com/service-directory/P6BR82L
Google Chat space: `AAAAYDlPZ8Q`

## Common Operations

### Restart Service

To restart the tagging server pods in production:
```
kubectl --context gcp-production-us-central1 --namespace sem-gtm-production rollout restart deployment/sem-gtm--tagging--default
```

To restart the preview server pods in production:
```
kubectl --context gcp-production-us-central1 --namespace sem-gtm-production rollout restart deployment/sem-gtm--preview--default
```

### Scale Up / Down

Scaling is managed through HPA configuration in the Helm values files. To manually scale the tagging server temporarily:
```
kubectl --context gcp-production-us-central1 --namespace sem-gtm-production scale deployment/sem-gtm--tagging--default --replicas=<N>
```
Note: Manual scaling will be overridden by the HPA controller. Permanent scaling changes require modifying `minReplicas`/`maxReplicas` in `.meta/deployment/cloud/components/tagging/common.yml` and redeploying.

### Check Rollout Status

After a deployment, check rollout status to verify completion:
```
kubectl --context gcp-production-us-central1 --namespace sem-gtm-production rollout status deployment/sem-gtm--tagging--default
```

### Database Operations

> Not applicable. This service is stateless and does not own any data stores.

## Troubleshooting

### Deployment Failed

- **Symptoms**: Deploybot reports a failed deployment; pods not reaching Running state
- **Cause**: Commonly caused by container startup failure, failed health probes, or unavailable GTM Cloud API
- **Resolution**: Check Kubernetes events with `kubectl --context gcp-production-us-central1 --namespace sem-gtm-production events sem-gtm--tagging--default-<pod-hash>`; review pod logs with `kubectl logs -n sem-gtm-production <pod-name>`

### Timeout in Deploybot

- **Symptoms**: Deploybot reports a timeout during deployment (after 30+ minutes)
- **Cause**: krane global timeout is set to 2000s (~33 minutes). GTM container startup can be slow due to fetching container config from Google
- **Resolution**: Check current deployment status: `kubectl --context gcp-production-us-central1 --namespace sem-gtm-production rollout status deployment/sem-gtm--tagging--default`. If the rollout is progressing, wait for completion. If stuck, investigate pod startup logs.

### Health Probe Failures

- **Symptoms**: Pods repeatedly restart; liveness probe failures in Kubernetes events
- **Cause**: GTM Cloud image not yet ready to serve `/healthz` within the 300s initial delay window, or GTM Cloud API is unreachable
- **Resolution**: Verify connectivity to Google's GTM Cloud infrastructure. Confirm `CONTAINER_CONFIG` is valid and not expired. Check pod logs for startup errors.

### Tag Events Not Processing

- **Symptoms**: Marketing analytics data gaps; GTM events not appearing in tag destinations
- **Cause**: Tagging server pods may be down, misconfigured, or GTM Cloud API connectivity degraded
- **Resolution**: Verify tagging server pod health; check Wavefront dashboard for traffic anomalies; confirm `CONTAINER_CONFIG` credentials are valid in the GTM console.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Tagging server down — all tag events lost, marketing attribution broken | Immediate | SEM on-call via PagerDuty P6BR82L; escalate to dredmond |
| P2 | Tagging server degraded — partial event loss or high latency | 30 min | SEM on-call; Google Chat space AAAAYDlPZ8Q |
| P3 | Preview server down — tag debugging unavailable, production unaffected | Next business day | gtm-engineers@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Google Tag Manager Cloud API | Verify GTM console connectivity; check pod logs for auth errors | No fallback — if GTM API is unreachable, the server cannot process events |
| GTM Preview Server (from tagging server) | `kubectl get pods -n sem-gtm-production` for preview deployment; access `https://gtm.groupon.com/preview/` | Production tagging continues; only preview/debug sessions are affected |
