---
service: "n8n"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/healthz` (port 5678) | http | 10s (Kubernetes default) | 600s (increased to avoid pod restarts during heavy load) |
| `/healthz/readiness` (port 5678) | http | 10s | 15s initial delay |
| `/healthz` (port 5680) — n8n-runners sidecar | http | 10s (periodSeconds) | 5s initial delay |

> Note: The liveness probe timeout is set to 600 seconds (`timeoutSeconds: 600`) across all instances to prevent pod restarts due to probe timeouts during large workflow executions. This was observed as a known issue.

## Monitoring

### Metrics

All n8n instances expose Prometheus metrics (`N8N_METRICS=true`). The following label dimensions are enabled:

| Metric / Label | Type | Description | Alert Threshold |
|----------------|------|-------------|----------------|
| `n8n_scaling_mode_queue_jobs_waiting` | gauge | Number of workflow jobs waiting in the Bull queue (per instance) | 10 (triggers KEDA scale-out for default queue-worker) |
| Workflow execution metrics (by `workflow_name`, `workflow_id`) | counter/histogram | Execution counts and durations per workflow | Operational procedures to be defined by service owner. |
| API metrics (by path, method, status code) | counter | HTTP request volume and error rates | Operational procedures to be defined by service owner. |
| Cache metrics | gauge | n8n internal cache hit/miss rates | Operational procedures to be defined by service owner. |
| Message event bus metrics | counter | Internal event bus activity | Operational procedures to be defined by service owner. |
| Node type metrics (by `node_type`) | counter | Node execution counts by type | Operational procedures to be defined by service owner. |
| Credential type metrics (by `credential_type`) | counter | Credential usage by type | Operational procedures to be defined by service owner. |
| Queue metrics (Bull) | gauge/counter | Queue depth, active jobs, completed jobs, failed jobs | Operational procedures to be defined by service owner. |

### Dashboards

> No evidence found in codebase. Dashboard links are not defined in the repository. Check the Groupon internal monitoring platform (e.g., Grafana) for n8n dashboards using the Prometheus metrics above.

### Alerts

> Operational procedures to be defined by service owner. No alerting rules found in the repository. Suggested alert conditions based on configuration:

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Queue backlog high | `n8n_scaling_mode_queue_jobs_waiting > 10` sustained for 5m (KEDA threshold) | warning | Check queue-worker pod count; verify workers are healthy; check Redis connectivity |
| Pod liveness failure | Pod restarts due to liveness probe timeout | critical | Check for long-running workflow executions; consider increasing `timeoutSeconds` further |
| Worker not ready | Readiness probe failing | critical | Check Redis queue health (`QUEUE_HEALTH_CHECK_ACTIVE`); verify PostgreSQL connectivity |
| Runner sidecar down | `/healthz` on port 5680 failing | warning | Restart the queue-worker pod; check runner sidecar logs |

## Common Operations

### Restart Service

1. Identify the target instance and component (e.g., `default` worker, `finance` queue-worker).
2. Use Conveyor Cloud or `kubectl` to trigger a rolling restart of the StatefulSet or Deployment in the appropriate namespace (`n8n-production` or `n8n-staging`).
3. Confirm the readiness probe at `/healthz/readiness` returns 200 before routing traffic.
4. For StatefulSet pods (`OrderedReady` policy), only one pod restarts at a time.

### Scale Up / Down

Queue-worker pods auto-scale via KEDA based on Bull queue depth. For manual override:
1. The default queue-worker uses custom metrics scaling: `n8n_scaling_mode_queue_jobs_waiting{n8n_instance="default",namespace="n8n-production"}` with threshold 10.
2. To temporarily adjust scaling, update the KEDA ScaledObject or the HPA min/max replica counts in the Kustomize overlay for the target environment.
3. Business/finance/merchant/llm-traffic queue-workers use KEDA ScaledObjects with a 120-second scaleDown stabilization window.

### Database Operations

n8n applies schema migrations automatically on startup via its built-in migration runner. To run migrations:
1. Deploy a new version of the n8n image; migrations run as part of application startup.
2. Monitor pod logs for migration completion before the readiness probe passes.
3. The `finance` and `merchant` StatefulSets use an `initContainer` (`volume-permission-fix`) that runs `chown -R 1000:1000 /home/node/.n8n` before startup.

## Troubleshooting

### Pod Restarts Due to Liveness Probe Timeout
- **Symptoms**: Pod shows `Restarting` state; logs show liveness probe timeout
- **Cause**: Long-running workflows cause the n8n process to become temporarily unresponsive during heavy execution load
- **Resolution**: The liveness probe `timeoutSeconds` is already set to 600s. If restarts persist, investigate which workflows are causing the spike; consider breaking them into smaller sub-workflows.

### Queue Workers Not Processing Jobs
- **Symptoms**: Workflow executions stuck in `waiting` state; queue depth growing
- **Cause**: Queue-worker pods are not consuming from the Bull queue; possible Redis connectivity issue or worker crash
- **Resolution**: Check queue-worker pod health in the `n8n-production` namespace; verify Redis Memorystore connectivity; check `QUEUE_HEALTH_CHECK_ACTIVE` readiness probe status.

### Runner Sidecar Code Node Failures
- **Symptoms**: JavaScript or Python code nodes fail with timeout or connection errors
- **Cause**: The `n8n-runners` sidecar container is down, or the broker endpoint at `http://127.0.0.1:5679` is unreachable
- **Resolution**: Check sidecar health at port 5680; verify `N8N_RUNNERS_AUTH_TOKEN` secret is correctly mounted; restart the pod.

### Community Package Installation Failing
- **Symptoms**: Workflows using community packages fail with module not found errors
- **Cause**: `N8N_REINSTALL_MISSING_PACKAGES=true` enables auto-reinstall, but network access or the persistent volume may be unavailable
- **Resolution**: Verify the persistent volume at `/home/node/.n8n` is mounted and writable; check pod logs for npm install errors.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — all workflow executions failing | Immediate | Platform Engineering |
| P2 | Degraded — specific instance or queue-worker failing | 30 min | Platform Engineering |
| P3 | Minor impact — single workflow failing, no system-wide effect | Next business day | Workflow owner / Platform Engineering |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| PostgreSQL (`continuumN8nPostgres`) | n8n startup fails if PostgreSQL is unreachable; check pod logs for DB connection errors | No fallback — service cannot start without PostgreSQL |
| Redis Memorystore | Queue health check at `/healthz/readiness` reports unhealthy if Redis is unreachable | No fallback — queue mode requires Redis; workflows cannot be dispatched to workers |
| n8n-runners sidecar | `/healthz` on port 5680 (periodSeconds: 10) | Code node executions fail; other node types (HTTP, webhook, schedule) continue to work |
