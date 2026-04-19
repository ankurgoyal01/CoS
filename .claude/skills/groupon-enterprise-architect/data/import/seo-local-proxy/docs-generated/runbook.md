---
service: "seo-local-proxy"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/healthcheck` | http (returns 200) | Kubernetes default | — |
| `GET /heartbeat.txt` | http (returns 200) | Kubernetes default | — |
| `GET /nginx_status` | http (stub_status) | manual/monitoring | — |
| Cron job readiness probe (`echo ready`) | exec | 5s period, 5s delay | 5s |
| Cron job liveness probe (`echo live`) | exec | 20s period, 10s delay | 5s |
| Public availability | `https://www.groupon.{tld}/robots.txt` and `/sitemap.xml` returning 200 | manual | — |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request rate | counter | Nginx access log — `index=marketing sourcetype="seo_local_nginx"` in Splunk | — |
| HTTP error rate (4xx) | counter | 4xx errors indicate missing S3 files | Alert on sustained 4xx |
| HTTP error rate (5xx) | counter | 5xx errors indicate S3 / Hybrid Boundary connectivity issues | Alert on any 5xx |
| Cron job exit code | gauge | Non-zero exit triggers alert; logged to `/tmp/sitemap_cron.log` | Non-zero exit |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| SEO Local Proxy SMA | Wavefront | https://groupon.wavefront.com/dashboards/seo-local-proxy--sma |
| SEO Local Proxy custom | Wavefront | https://groupon.wavefront.com/u/7sYcTtqyjL?t=groupon |
| Wavefront alerts | Wavefront | https://groupon.wavefront.com/u/lB5wRyRwQj?t=groupon |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| robots.txt content sporadically bad | Wrong file served due to bad configuration | 3 | Fix nginx configuration and redeploy |
| Pod not running | `kubectl get pods` shows non-Running state | — | See "Restart Service" below; check `kubectl logs pod/{name} -c main` |
| CrashLoopBackOff | Pod restarts repeatedly | — | Run crashloopbackoff diagnostic script; check `mainContainerCommand` in YML |
| 4xx spike | Nginx returns 404 on sitemap/robots requests | — | Check S3 bucket contents; verify cron job ran successfully |
| 5xx spike | Nginx cannot reach Hybrid Boundary / S3 | — | Check Hybrid Boundary integration and AWS S3 status |

- **PagerDuty**: https://groupon.pagerduty.com/services/POQLFLJ
- **PagerDuty email**: seo-local-proxy@groupon.pagerduty.com

## Common Operations

### Restart Service (Nginx Pod)

1. Authenticate with cloud-elevator:
   ```bash
   kubectl cloud-elevator auth browser
   ```
2. Switch to the correct Kubernetes context:
   ```bash
   kubectx seo-local-proxy-production-us-central1
   # or: seo-local-proxy-staging-us-central1 | seo-local-proxy-staging-us-west-2 | seo-local-proxy-production-eu-west-1
   ```
3. Find and delete the pod (Kubernetes will restart it automatically):
   ```bash
   kubectl get pods --namespace seo-local-[staging|production]
   kubectl delete pod NAME_OF_POD --namespace seo-local-[staging|production]
   ```

### Manually Run the Sitemap / Robots.txt Cron Job

1. Authenticate and switch to the correct context.
2. Create a one-off job from the CronJob spec:
   ```bash
   kubectl create job oneoff --from=cronjob/seo-local-proxy--cron-job--default
   ```
3. Tail the log:
   ```bash
   kubectl logs pod/oneoff-XXXXX -c main -f
   ```

### Manual Sitemap Generation (exec into pod)

For US production:
```bash
kubectl exec --stdin --tty POD_NAME -c main -- /bin/bash
cd ~/local_proxy/groupon-site-maps/current
nohup ./scripts/daily_us.sh > /tmp/out.log 2>&1 &
tail -f /tmp/sitemap.log
```

For EMEA production:
```bash
kubectl exec --stdin --tty POD_NAME -c main -- /bin/bash
cd ~/local_proxy/groupon-site-maps/current
nohup ./scripts/daily_emea.sh > /tmp/out.log 2>&1 &
tail -f /tmp/sitemap.log
```

### Robots.txt Only Deployment (staging)

```bash
kubectl exec --stdin --tty POD_NAME -c main -- /bin/bash
cd ~/local_proxy_staging/groupon-site-maps/current
DEPLOY_MODE=robots VERBOSE=true DRYRUN=false DCS=snc1 COUNTRIES=US SITEMAPS="https" NODE_ENV=staging ./scripts/upload.sh
```

### Verify S3 Bucket Contents

Inside the cron job pod:
```bash
aws s3 ls s3://$SEO_LOCAL_PROXY_S3_BUCKET_NAME/
```

### Scale Up / Down

Nginx scaling is managed by HPA in staging (1–2 replicas). To manually adjust, update the Helm values and redeploy via Deploybot. Production Nginx is fixed at 1 replica.

### Database Operations

> Not applicable. No relational database is used. S3 object writes are performed by the cron job via upload scripts.

## Troubleshooting

### Pod Not Running
- **Symptoms**: `kubectl get pods` shows non-Running state
- **Cause**: Image pull error, resource exhaustion, or bad `mainContainerCommand`
- **Resolution**:
  ```bash
  kubectl get pods -o wide
  kubectl logs pod/<pod_name> -c main
  kubectl describe pods <pod_name>
  ```
  If orphaned pods exist after a fix, delete them:
  ```bash
  kubectl delete pod <pod_name>
  ```

### CrashLoopBackOff
- **Symptoms**: Pod restarts repeatedly, `kubectl get pods` shows high RESTARTS count
- **Cause**: Application startup failure or bad initialization command
- **Resolution**: Run the Groupon crashloopbackoff diagnostic tool:
  ```bash
  curl --silent --output /tmp/crashloopbackoff https://raw.github.groupondev.com/CloudSRE/tools/main/bin/crashloopbackoff
  bash /tmp/crashloopbackoff
  ```
  Also check `mainContainerCommand` in the relevant YML config file.

### Terminated Pod
- **Symptoms**: Container exited (with or without error code)
- **Resolution**:
  ```bash
  kubectl get pods -o wide
  kubectl logs <pod_name> -p -c main  # previous container logs
  ```

### 4xx Errors on Sitemap / Robots Requests
- **Symptoms**: Search engines receive 404 for `/robots.txt` or `/sitemap.xml`
- **Cause**: File not present in S3 bucket (cron job failed or not yet run)
- **Resolution**: Check S3 contents from inside the pod:
  ```bash
  aws s3 ls s3://$SEO_LOCAL_PROXY_S3_BUCKET_NAME/
  ```
  If files are missing, manually trigger the cron job (see "Manually Run the Sitemap / Robots.txt Cron Job" above).

### 5xx Errors
- **Symptoms**: Nginx returns 500/502/503/504
- **Cause**: Hybrid Boundary or S3 connectivity failure
- **Resolution**: Check the integration between the Hybrid Boundary and AWS S3. Verify with Production Operations.

### Direct Proxy Verification (bypass routing-service)
```bash
curl -H "Host: www.groupon.com" -H "X-Forwarded-Host: www.groupon.com" \
  https://seo-local-proxy.staging.service.us-central1.gcp.groupondev.com/US/https/robots.txt

curl -H "Host: www.groupon.de" -H "X-Forwarded-Host: www.groupon.de" \
  https://seo-local-proxy.staging.service.eu-west-1.aws.groupondev.com/DE/https/robots.txt
```

### Splunk Log Query
```
index=marketing sourcetype="seo_local_nginx"
```

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | `/robots.txt` or `/sitemap.xml` returning 5xx on all TLDs | Immediate | SEO team on-call via PagerDuty POQLFLJ |
| P2 | Specific country or brand returning 4xx; stale sitemap content | 30 min | SEO team on-call |
| P3 | Cron job execution delay; minor content staleness | Next business day | computational-seo@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| AWS S3 / GCP Cloud Storage | `aws s3 ls s3://$SEO_LOCAL_PROXY_S3_BUCKET_NAME/` from inside pod | No fallback — existing stale files remain until cron succeeds |
| Hybrid Boundary (S3 proxy) | `GET /grpn/healthcheck` on Nginx returns 200 | No fallback — Nginx returns 5xx if HB is down |
| `routing-service` | Verify `https://www.groupon.{tld}/robots.txt` returns 200 end-to-end | No fallback — traffic not routed to Nginx |
| Cron job | Kubernetes CronJob completion status; `/tmp/sitemap_cron.log` | No automated retry — manual one-off job creation required |

## Kubernetes Web Views

| Cluster | URL |
|---------|-----|
| Stable US Central 1 | https://kube-web-view.stable.us-central1.gcp.groupondev.com/clusters/local/namespaces/seo-local-proxy-staging/pods |
| Stable US West 2 | https://kube-web-view.stable.us-west-2.aws.groupondev.com/clusters/local/namespaces/seo-local-proxy-staging/pods |
| Prod US Central 1 | https://kube-web-view.prod.us-central1.gcp.groupondev.com/clusters/local/namespaces/seo-local-proxy-production/pods |
| Prod EU West 1 | https://kube-web-view.prod.eu-west-1.aws.groupondev.com/clusters/local/namespaces/seo-local-proxy-production/pods |
