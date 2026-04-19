---
service: "cloudability"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Kubernetes liveness probe (exec) | exec | Managed by Cloudability agent runtime | Managed by agent runtime |
| Pod restart count via `kubectl -n cloudability-<env> get pods` | manual | On-demand | - |
| Cloudability portal data freshness (`https://app.cloudability.com/#/containers`) | manual | Check after any change (24h delay) | - |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Pod restart count | gauge | Number of container restarts for `cloudability-metrics-agent` pod | Any value above 0 warrants investigation |
| Metric upload success | log-based | `Uploading Metrics` / `Exported metric sample` log entries confirm healthy uploads | Absence of entries over an extended period |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Kubernetes metrics (Cloudability) | Cloudability Portal | `https://app.cloudability.com/#/containers` |
| Cloudability agent metrics | Wavefront | `https://groupon.wavefront.com/u/KRNCKsVKGz?t=groupon` |
| Cloudability SaaS status | Cloudability Status Page | `https://status.cloudability.com/` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Agent pod restarting | Restart count > 0 | warning | Check pod logs; verify ClusterRole and ClusterRoleBinding exist; verify provisioning config matches cluster name |
| No metric uploads | No `Uploading Metrics` log entries for > 1 hour | warning | Check pod status, logs, and Cloudability Status Page |
| Cloudability portal no data | Data not appearing after 24h post-deployment | warning | Verify pod is running; check logs for upload errors; contact Cloudability TAM if needed |

## Common Operations

### Restart Service

```bash
# Identify the pod name
kubectl -n cloudability-<env> get pods

# Delete the pod to trigger a restart (Deployment controller will recreate it)
kubectl -n cloudability-<env> delete pod <pod-name>

# Monitor the new pod
kubectl -n cloudability-<env> get pods -w
```

### Scale Up / Down

> The Cloudability Metrics Agent runs as a single-replica Deployment. Scaling is not applicable — only one agent per cluster is supported by the Cloudability architecture.

### Database Operations

> Not applicable. This service is stateless and does not own any data stores.

### Update Agent Version

1. Run `get_agent_config.sh` on the target cluster context to re-fetch a fresh manifest
2. Update the image tag in the patched manifest in `secrets/conveyor-<context>.yml`
3. Commit and push the secrets submodule update
4. Merge to `main` and allow deploybot to roll out the new version

## Troubleshooting

### Agent Pod Restarting Repeatedly

- **Symptoms**: `RESTARTS` count in `kubectl -n cloudability-<env> get pods` is greater than 0; pod not in `Running` state
- **Cause**: Missing or incorrect ClusterRole/ClusterRoleBinding; incorrect provisioning config or cluster name mismatch
- **Resolution**:
  1. Check pod logs: `kubectl -n cloudability-<env> logs <pod-name>`
  2. Verify ClusterRole exists: `kubectl get clusterrole | grep generic-metrics-agent`
  3. Verify ClusterRoleBinding exists: `kubectl get clusterrolebinding | grep cloudability-metrics-agent`
  4. If missing, re-run the Conveyor `aaa` playbook to restore them
  5. Verify the cluster name in the manifest matches the registered cluster name in Cloudability

### No Data in Cloudability Portal

- **Symptoms**: Container cost data not appearing at `https://app.cloudability.com/#/containers` after 24+ hours
- **Cause**: Agent not running; upload errors; Cloudability ingestion outage
- **Resolution**:
  1. Confirm pod is running: `kubectl -n cloudability-<env> get pods`
  2. Check for upload errors in logs: `kubectl -n cloudability-<env> logs <pod-name>`
  3. Check [Cloudability Status Page](https://status.cloudability.com/) for upstream outages
  4. If no issues found locally, submit a support ticket via the Cloudability portal (upper-right "?" menu → "Submit a ticket")

### Incorrect Provisioning Config / Cluster Name Mismatch

- **Symptoms**: Pod restarts with config errors; cluster not visible in Cloudability portal
- **Cause**: Cluster was re-registered with a different name, or manifest contains stale cluster ID
- **Resolution**:
  1. Run `get_agent_config.sh` to re-register (POST returns 400 if already registered; existing key is preserved)
  2. Fetch updated manifest and apply patches
  3. Update secrets submodule and redeploy

### Cloudability SaaS Outage

- **Symptoms**: Metric upload failures in pod logs; no data in portal
- **Cause**: Upstream Cloudability SaaS disruption
- **Resolution**: Monitor [Cloudability Status Page](https://status.cloudability.com/). No local remediation is possible. Data gaps will appear for the outage window. Contact TAM (Basappa Sagar K S, bsagarks@ibm.com) or Account Rep (Wil Edgar, Wil.Edgar1@ibm.com) for extended outages.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Agent down across all clusters; no cost data flowing | Immediate | CloudSRE |
| P2 | Agent down on specific clusters; partial data gap | 30 min | CloudSRE |
| P3 | Data delayed; minor portal visibility issue | Next business day | CloudSRE |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Cloudability Provisioning API | `curl -s https://api.cloudability.com/v3/containers/provisioning -u "<api-key>:"` | Cannot provision new clusters; existing deployments unaffected |
| Cloudability Ingestion API | Pod log entries: `Exported metric sample ...` | Data gaps in portal; no local fallback |
| Kubernetes API Server | `kubectl -n cloudability-<env> get pods` | Agent cannot collect metrics; pod restarts |
| Cloudability SaaS | [https://status.cloudability.com/](https://status.cloudability.com/) | No local fallback; data gaps until restored |

## Requesting Support from Cloudability

All SRE team members should have access via Launchpad. To submit a ticket:
1. Log into the Cloudability portal from Launchpad
2. Click the "?" (question mark) in the upper-right corner
3. Select "Submit a ticket"

Cloudability / IBM Contacts:
- **TAM**: Basappa Sagar K S — bsagarks@ibm.com
- **Account Rep**: Wil Edgar — Wil.Edgar1@ibm.com
