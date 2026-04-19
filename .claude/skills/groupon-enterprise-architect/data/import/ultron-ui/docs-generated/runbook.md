---
service: "ultron-ui"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /heartbeat` | http | Kubernetes liveness probe interval (configured in Helm) | Kubernetes probe timeout (configured in Helm) |

## Monitoring

### Metrics

> Operational procedures to be defined by service owner. No metrics instrumentation details are discoverable from the inventory.

### Dashboards

> Operational procedures to be defined by service owner. Dashboard links are not available in the inventory.

### Alerts

> Operational procedures to be defined by service owner. Alert configurations are not available in the inventory.

## Common Operations

### Restart Service

1. Identify the Kubernetes deployment for `ultron-ui` in the target cluster (staging or production).
2. Issue a rolling restart via Deploybot or `kubectl rollout restart deployment/ultron-ui -n <namespace>`.
3. Monitor pod readiness using `kubectl get pods -n <namespace> -w`.
4. Confirm the `/heartbeat` endpoint returns HTTP 200 on the new pods before considering the restart complete.

### Scale Up / Down

1. Adjust the replica count in the Deploybot / Helm configuration for the target environment.
2. Apply the updated configuration via Deploybot deployment.
3. Verify the desired replica count with `kubectl get deployment ultron-ui -n <namespace>`.

### Database Operations

> Not applicable — this service is stateless and owns no data stores. Database operations are the responsibility of `continuumUltronApi`.

## Troubleshooting

### UI returns errors for all job operations

- **Symptoms**: All requests to `/groups`, `/job/*`, `/instance/*`, `/resource/all` return error responses or time out
- **Cause**: `continuumUltronApi` is unavailable or returning errors
- **Resolution**: Check the health and logs of `continuumUltronApi`. Verify the `ULTRON_API_URL` environment variable is correctly set in the Ultron UI deployment. Confirm network connectivity between the Kubernetes pod and the Ultron API service endpoint.

### Operators cannot log in (LDAP authentication failures)

- **Symptoms**: Login attempts fail with authentication errors
- **Cause**: LDAP server is unreachable, or `LDAP_BIND_DN` / `LDAP_BIND_PASSWORD` secrets are incorrect or expired
- **Resolution**: Verify the `LDAP_URL`, `LDAP_BIND_DN`, and `LDAP_BIND_PASSWORD` environment variables in the deployment. Confirm the LDAP service is healthy. Rotate secrets if credentials have expired.

### `/heartbeat` returns non-200

- **Symptoms**: Kubernetes liveness probe fails; pod restarts
- **Cause**: Play Framework application has crashed or is in an unresponsive state
- **Resolution**: Inspect pod logs (`kubectl logs <pod-name> -n <namespace>`). Check JVM heap exhaustion (`JAVA_OPTS` heap settings). Restart the pod if needed.

### Play application fails to start

- **Symptoms**: Pod enters `CrashLoopBackOff`; logs show startup exception
- **Cause**: Missing required environment variable (`ULTRON_API_URL`, `APPLICATION_SECRET`, LDAP config), or misconfigured `conf/application.conf`
- **Resolution**: Verify all required environment variables are present in the pod spec. Review startup logs for the specific missing or invalid configuration key.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — operators cannot access job orchestration UI | Immediate | dnd-ingestion team |
| P2 | Degraded — partial functionality unavailable (e.g., specific job actions failing) | 30 min | dnd-ingestion team |
| P3 | Minor impact — cosmetic issues, non-critical errors | Next business day | dnd-ingestion team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumUltronApi` | Verify the Ultron API service health endpoint; check pod status in its Kubernetes namespace | No fallback — all data-bearing operations are unavailable until the API recovers |
| LDAP server | Attempt an LDAP bind using the configured credentials from within the cluster | No fallback — operator authentication is unavailable until LDAP recovers |
