---
service: "minio"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /minio/health/ready` | http | 10s (after 10s initial delay) | 5s (failure threshold: 3) |
| `GET /minio/health/live` | http | 10s (after 20s initial delay) | 5s (failure threshold: 3) |

Both probes are configured on port 9000. The readiness probe controls whether the pod receives traffic; the liveness probe controls whether the pod is restarted by Kubernetes.

## Monitoring

### Metrics

> No evidence found in codebase. No custom metrics exporters or monitoring configuration are defined in this repository. MinIO exposes Prometheus-compatible metrics natively at `/minio/v2/metrics/cluster` and `/minio/v2/metrics/node`, but no scrape configuration is present here.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| MinIO readiness probe failures | gauge | Number of consecutive readiness probe failures | 3 (Kubernetes default restart) |
| MinIO liveness probe failures | gauge | Number of consecutive liveness probe failures | 3 (Kubernetes default restart) |

### Dashboards

> Operational procedures to be defined by service owner.

### Alerts

> Operational procedures to be defined by service owner.

## Common Operations

### Restart Service

To safely restart MinIO:
1. Use DeployBot to trigger a re-deploy of the target environment, or
2. Use `kubectl rollout restart deployment/minio -n minio-{environment}` on the target Kubernetes cluster using the appropriate Kubernetes context (e.g., `minio-gcp-production-us-central1` for GCP US production)
3. Verify readiness by polling `GET /minio/health/ready` until it returns HTTP 200

### Scale Up / Down

Scaling is managed through Kubernetes HPA:
1. To temporarily scale beyond HPA limits, use `kubectl scale deployment/minio --replicas={N} -n minio-{environment}`
2. For permanent scaling changes, update the `minReplicas` / `maxReplicas` values in the appropriate environment YAML file (e.g., `.meta/deployment/cloud/components/minio/production-us-central1.yml`) and re-deploy
3. EMEA production environments support up to 15 replicas; US environments support up to 2 in the current configuration

### Database Operations

Not applicable. MinIO does not use a relational database. Object data is stored directly on the `/home/shared` filesystem volume. No migrations or backfills apply.

## Troubleshooting

### Service Not Ready (readiness probe failing)
- **Symptoms**: Kubernetes marks pod as not ready; `GET /minio/health/ready` returns non-200 or times out
- **Cause**: MinIO process has not finished initializing the data directory at `/home/shared`, or the data volume is unavailable/corrupted
- **Resolution**: Check pod logs (`kubectl logs -n minio-{env} <pod>`) for startup errors; verify the volume mount is accessible; check available disk space on the node

### Service Restarting (liveness probe failing)
- **Symptoms**: Kubernetes repeatedly restarts the MinIO pod; increasing restart count visible in `kubectl get pods -n minio-{env}`
- **Cause**: MinIO process has hung or crashed; possible causes include out-of-memory (OOM kill), disk I/O errors, or data corruption
- **Resolution**: Check pod events (`kubectl describe pod -n minio-{env} <pod>`); review logs for OOM or I/O errors; consider increasing memory limit if OOM is observed (current limit: 500Mi)

### Object Upload Failure (clients receiving 5xx)
- **Symptoms**: S3 PUT requests return 503 or 500 errors
- **Cause**: All replicas are unavailable, HPA has not yet scaled up, or disk is full
- **Resolution**: Check pod count and readiness; verify disk space on `/home/shared`; check HPA status (`kubectl get hpa -n minio-{env}`)

### Authentication Errors (clients receiving 403)
- **Symptoms**: S3 requests return `AccessDenied` or `InvalidAccessKeyId`
- **Cause**: Client is using incorrect access key or secret key
- **Resolution**: Verify client credentials match the `MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD` values from the secrets submodule; rotate secrets if compromised via the `minio-secrets` repository

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down (all replicas unavailable) | Immediate | Conveyor Cloud team + Platform SRE |
| P2 | Degraded performance or elevated error rates | 30 min | Conveyor Cloud team |
| P3 | Single replica down, HPA maintaining capacity | Next business day | Conveyor Cloud team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `/home/shared` volume | Check disk space and I/O availability on the node | None — MinIO requires the volume to function |
| Kubernetes HPA | `kubectl get hpa -n minio-{env}` | Manually scale with `kubectl scale` |
| Docker image registry (docker-conveyor.groupondev.com) | N/A (deploy-time only) | Use last successfully deployed image version |
