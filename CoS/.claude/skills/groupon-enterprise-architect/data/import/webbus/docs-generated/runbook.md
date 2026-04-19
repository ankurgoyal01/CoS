---
service: "webbus"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/healthcheck` | HTTP — returns plain text `ok` | Kubernetes readiness probe: every 10s | 60s |
| `GET /heartbeat.txt` | HTTP — returns content of `heartbeat.txt` | Load balancer heartbeat (interval not configured in code) | — |
| `GET /status` | HTTP JSON — returns `{ "sha": "<git-sha>" }` | Service Portal polling | — |

Kubernetes probe configuration (from `common.yml`):
- **Readiness**: delay 20s, period 10s, timeout 60s
- **Liveness**: delay 20s, period 10s, timeout 60s

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Pod crash loop | gauge | Detects pods stuck in `CrashLoopBackOff` | Alert: "SEVERE - Webbus Pods In Crash Loop" — see Grafana |
| Message Bus pending count | gauge | Number of pending messages queued in Salesforce awaiting delivery | Alert triggered if count exceeds configured threshold in Salesforce |
| Request latency | histogram | Per-request latency tracked via Wavefront | SLA: < 2s per 6 MB payload (~80 messages) |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Webbus Production | Wavefront | `https://groupon.wavefront.com/dashboard/webbus` |
| Production us-west-1 | Wavefront | `https://groupon.wavefront.com/u/SF0YybFwFB?t=groupon` |
| Staging us-west-1 | Wavefront | `https://groupon.wavefront.com/u/qChmKWjctm?t=groupon` |
| Production Message Bus | Wavefront | `https://groupon.wavefront.com/u/V9VMyc78pD?t=groupon` |
| Staging Message Bus | Wavefront | `https://groupon.wavefront.com/u/ctwbhvsCr9?t=groupon` |
| Conveyor Cloud | Grafana (prod) | `https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/goto/7ckDdWiDR` |
| Prod Kibana | Kibana | `https://prod-kibana-unified.us-central1.logging.prod.gcp.groupondev.com/app/r/s/F7vQW` |
| Staging Kibana | Kibana | `https://stable-kibana-unified.us-central1.logging.stable.gcp.groupondev.com/app/r/s/ULl2N` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Webbus Pods In Crash Loop | Pods enter `CrashLoopBackOff` state | Critical | Check Kibana logs for crash reason; escalate to Salesforce Integration on-call |
| Message Bus Pending Count High | Salesforce pending message count exceeds threshold | Warning | Check Message Bus connectivity from Webbus pods; throttle Salesforce delivery if needed |

Alert contacts:
- Email: `sfint-dev-alerts@groupon.com`
- PagerDuty: `https://groupon.pagerduty.com/services/P07G73H`
- Slack: `#salesforce-integration`
- Google Chat: `AAAAViiQs_Q`

## Common Operations

### Restart Service

```bash
# Authenticate with Kubernetes
kubectl cloud-elevator auth

# Switch to the target cluster context
kubectl config use-context webbus-production-us-central1

# Restart all pods
kubectl rollout restart deployment/webbus--app--default -n webbus-production

# Verify pods are running
kubectl get pods -n webbus-production
```

### Scale Up / Down

Scaling is managed by the Kubernetes HPA. To change replica counts temporarily:

```bash
# Check current HPA status
kubectl get hpa -n webbus-production

# Scale manually (overrides HPA temporarily)
kubectl scale deployment/webbus--app--default --replicas=<N> -n webbus-production
```

For permanent scaling changes, update `minReplicas`/`maxReplicas` in the appropriate `.meta/deployment/cloud/components/app/<env>.yml` file and redeploy.

**Immediate overload response**: Throttle message delivery in Salesforce.
**Short-term**: Increase capacity by adding pod instances via DeployBot.
**Long-term**: Update code to send messages concurrently (currently single-threaded).

### Database Operations

> Not applicable — Webbus is stateless and owns no database.

### View Logs

```bash
# Follow main container logs
kubectl logs <pod-name> main -n webbus-production

# Follow log-tail sidecar
kubectl logs <pod-name> main-log-tail -n webbus-production

# Access pod shell
kubectl exec -it <pod-name> --container main -- /bin/bash -n webbus-production
```

Log files within the container:
- `log/webbus/webbus.log` — application-level JSON logs
- `log/messagebus/messagebus.log` — STOMP client logs
- `log/thin/thin.log` — Thin HTTP server logs

## Troubleshooting

### Webbus Pods in Crash Loop
- **Symptoms**: `kubectl get pods` shows pods in `CrashLoopBackOff`; Grafana alert fires.
- **Cause**: Configuration error (missing env vars, bad credentials), Ruby load error, or unhandled exception at startup.
- **Resolution**: Check Kibana for startup exception stack traces. Verify `WEBBUS_MESSAGEBUS_USER` and `WEBBUS_MESSAGEBUS_PASSWORD` secrets are correctly mounted. Rollback to last stable version via DeployBot if needed.

### Messages Not Being Delivered to Message Bus
- **Symptoms**: Salesforce reports high pending message count; `POST /v2/messages/` returns `400` with message bodies.
- **Cause**: Message Bus cluster is unreachable or returning errors; STOMP credentials may have changed.
- **Resolution**: Check `log/messagebus/messagebus.log` for STOMP connection errors. Verify Message Bus cluster health using the Wavefront Message Bus dashboard. Check that `WEBBUS_MESSAGEBUS_USER`/`WEBBUS_MESSAGEBUS_PASSWORD` match the current credentials.

### Invalid Client ID Returning 404
- **Symptoms**: Salesforce receives `404` responses instead of publishing messages.
- **Cause**: `client_id` value has changed or `config/clients.yml` has not been updated for the target environment. Note: 404 is intentionally returned for invalid client IDs to prevent enumeration.
- **Resolution**: Verify the `client_id` Salesforce is sending matches an entry in `config/clients.yml` for the active environment. Deploy an updated `clients.yml` if needed.

### Unrecognised Topic Rejected
- **Symptoms**: Messages are returned to Salesforce as failures; errors indicate topic is not in the whitelist.
- **Cause**: Salesforce is publishing to a topic not listed in `config/messagebus.yml` destinations.
- **Resolution**: Add the new topic to `config/messagebus.yml` under the `message_bus_destinations` alias and deploy. See README for guidance.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Webbus completely down — Salesforce events not reaching Message Bus | Immediate | Salesforce Integration on-call via PagerDuty P07G73H |
| P2 | Elevated error rate — partial message delivery failures | 30 min | `sfint-dev-alerts@groupon.com` / Slack `#salesforce-integration` |
| P3 | Minor impact / single region degradation | Next business day | `sfint-dev@groupon.com` |

Emergency escalation plan: See the [emergency escalation spreadsheet](https://docs.google.com/a/groupon.com/spreadsheet/ccc?key=0AslbvioNiXOadG1DcEFGeHNHYkU4eTFOMldSQ1BCcFE&usp=sharing#gid=8).

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Message Bus | Check `log/messagebus/messagebus.log` for STOMP errors; check Wavefront Message Bus dashboard | Failed messages returned synchronously to Salesforce for redelivery |
| Kubernetes cluster | `kubectl get pods -n webbus-production` | Redeploy via DeployBot; rollback to previous image |
