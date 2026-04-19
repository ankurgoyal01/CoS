---
service: "transporter-itier"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Kubernetes liveness probe (ITier default) | http | Managed by Conveyor Cloud | Managed by Conveyor Cloud |
| Kubernetes readiness probe (ITier default) | http | Managed by Conveyor Cloud | Managed by Conveyor Cloud |

> Specific probe paths and intervals are managed by the ITier framework defaults within the Conveyor Cloud platform. Consult the Conveyor Cloud dashboard for pod health status.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Pod crash loop | gauge | Number of container restarts indicating a crash loop | Alert: SEVERE — Transporter Itier Pods In Crash Loop (Grafana alert `cei6x4atb7thcb`) |
| HTTP error rate | counter | Rate of non-2xx responses from the ITier server | Check Wavefront dashboard |
| Memory usage | gauge | JVM/Node heap usage; max-old-space-size set to 1024MB | Limit: 3072Mi |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Conveyor Cloud (primary) | Grafana | https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/goto/7emfFWiDg |
| Application metrics | Wavefront | https://groupon.wavefront.com/dashboard/transporter-itier |
| Production US Logs | Kibana (ELK) | https://prod-kibana-unified.us-central1.logging.prod.gcp.groupondev.com/app/r/s/mEbjM |
| Staging US Logs | Kibana (ELK) | https://stable-kibana-unified.us-central1.logging.stable.gcp.groupondev.com/app/r/s/XS9rU |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| SEVERE - Transporter Itier Pods In Crash Loop | Pod restart count exceeds threshold | critical | Investigate Conveyor Cloud dashboard for pod health; check application logs in Kibana for crash details. See resolution steps below. |

- **PagerDuty service**: https://groupon.pagerduty.com/services/PLUGT8Z
- **Alert email**: sfint-dev-alerts@groupon.com
- **Slack**: `#salesforce-integration` (`salesforce-integration` channel)
- **Google Chat**: `AAAAViiQs_Q`

## Common Operations

### Restart Service

Pods can be restarted via the Conveyor Cloud Kubernetes dashboard or via Napistrano:

```
npx nap --cloud deploy --artifact <current-artifact> staging us-central1
```

Alternatively, delete pods directly in Kubernetes and let the deployment controller recreate them:

```
kubectl -n transporter-itier-production delete pod <pod-name>
```

### Scale Up / Down

Replica counts are controlled by Napistrano deploy config. To temporarily scale:

```
kubectl -n transporter-itier-production scale deployment transporter-itier --replicas=<N>
```

Maximum replicas are capped at 3 per region by Napistrano configuration. To change limits permanently, update `.deploy-configs/<env>-<region>.yml` and redeploy.

### Database Operations

> Not applicable — this service is stateless and owns no database.

## Troubleshooting

### Pods in Crash Loop
- **Symptoms**: Alert fires; pods show `CrashLoopBackOff` in Kubernetes; requests fail with 502/503 from Hybrid Boundary
- **Cause**: Application startup failure (misconfigured secrets file path, missing env vars, OOM) or runtime crash
- **Resolution**:
  1. Check Kibana production logs for stack traces
  2. Check `NODE_OPTIONS` and memory limits in deploy config
  3. Verify the secrets file is accessible at the configured path (`config.secret.pathToSecret`)
  4. Roll back if a recent deploy introduced the issue: see Rollback section in [Deployment](deployment.md)

### Upload Fails with "Error occurred in sending file to Itier server"
- **Symptoms**: Browser shows upload error; `/jtier-upload-proxy` returns non-200
- **Cause**: transporter-jtier is unavailable, unreachable, or returning an error on `/v0/upload`
- **Resolution**:
  1. Check jtier health via its VIP: `http://transporter-jtier.production.service`
  2. Review jtier logs for upstream errors
  3. Verify `DEPLOY_ENV` is set correctly so the proxy resolves the correct jtier host

### Users Redirected to Salesforce Login Loop
- **Symptoms**: User repeatedly redirected to Salesforce OAuth login without being granted access
- **Cause**: jtier `/validUser` or `/auth` returning failure; Salesforce OAuth credentials invalid; secrets file misconfigured
- **Resolution**:
  1. Confirm Salesforce Connected App credentials are valid and not expired
  2. Check secrets file path and Base64-encoded values for `TRANSPORTER_ITIER_SF_CLIENT_ID` and `TRANSPORTER_ITIER_SF_CLIENT_SECRET`
  3. Check jtier logs for `/auth` endpoint errors
  4. Verify `connectedApp.redirectUri` matches the URI registered in Salesforce

### Job List Page Shows No Data
- **Symptoms**: `/` page loads but shows no upload jobs
- **Cause**: jtier `/getUploads` returning empty or error
- **Resolution**:
  1. Check jtier service health
  2. Check Kibana logs for jtier client errors on the `transporter-jtier-client` trace source

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — employees cannot perform Salesforce bulk operations | Immediate | Salesforce Integration team (sfint-dev-alerts@groupon.com), PagerDuty PLUGT8Z |
| P2 | Degraded — uploads failing or job list unavailable | 30 min | Salesforce Integration team |
| P3 | Minor impact — read-only SF data view unavailable | Next business day | Salesforce Integration team |

Jira Ops: https://groupondev.atlassian.net/jira/ops/teams/og-9ceb0ec2-446a-4ac3-bc4e-85f4e40ca5ca

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| transporter-jtier | HTTP GET `http://transporter-jtier.production.service/v0/validUser?user=healthcheck` | No fallback — service is non-functional without jtier |
| Salesforce OAuth | Browser redirect to Salesforce login URL succeeds | No fallback — unauthenticated users cannot access the service |
