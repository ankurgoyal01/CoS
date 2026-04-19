---
service: "nifi-3pip"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /nifi-api/system-diagnostics` (NiFi startup probe) | http | 10s | — (failureThreshold: 30, initialDelay: 60s) |
| `GET /nifi-api/system-diagnostics` (NiFi readiness probe) | http | 10s | — (failureThreshold: 3) |
| `GET /nifi-api/system-diagnostics` (NiFi liveness probe) | http | 15s | — (failureThreshold: 5) |
| `GET /nifi-api/controller/cluster` (health-check.sh) | http | On-demand (Kubernetes exec probe or manual) | 15s (`OP_NIFI_PROBE_MAX_TIMEOUT`) |
| `echo 'ruok' \| nc -w 2 localhost 2181 \| grep imok` (ZooKeeper readiness) | exec | 30s | 5s |
| `echo 'ruok' \| nc -w 2 localhost 2181 \| grep imok` (ZooKeeper liveness) | exec | 30s | 5s |

## Monitoring

### Metrics

> No evidence found in codebase of custom metric instrumentation beyond what Apache NiFi exposes natively. NiFi exposes internal metrics (queue sizes, processor throughput, JVM heap) via the NiFi UI and `/nifi-api/system-diagnostics`.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `/nifi-api/system-diagnostics` HTTP response | gauge | System health indicator used by all Kubernetes probes | Non-200 response triggers probe failure |
| `/nifi-api/controller/cluster` node status | gauge | Per-node cluster connection status; must be `CONNECTED` | Non-CONNECTED status triggers health-check.sh failure |
| ZooKeeper `ruok` response | gauge | ZooKeeper four-letter-word health command | Missing `imok` response triggers probe failure |

### Dashboards

> No evidence found in codebase of specific dashboard configurations. Operational procedures to be defined by service owner.

### Alerts

> No evidence found in codebase of configured alert definitions. Operational procedures to be defined by service owner.

## Common Operations

### Restart Service

To restart a NiFi node pod in Kubernetes:

```shell
kubectl rollout restart statefulset/nifi-3pip--nifi--default -n nifi-3pip-<environment>
```

To restart a specific pod (e.g., pod 0):
```shell
kubectl delete pod nifi-3pip--nifi--default-0 -n nifi-3pip-<environment>
```

The StatefulSet will recreate the pod. NiFi's FlowFile repository on the persistent volume ensures in-flight records are resumed on restart.

To restart ZooKeeper:
```shell
kubectl rollout restart statefulset/nifi-3pip--zookeeper--default -n nifi-3pip-<environment>
```

> Note: Restarting all ZooKeeper nodes simultaneously will cause NiFi cluster coordination to fail. Restart one ZooKeeper pod at a time and wait for it to rejoin the ensemble before proceeding.

### Scale Up / Down

NiFi and ZooKeeper are currently configured with a fixed replica count of 3. Changing replica counts requires updating `minReplicas`/`maxReplicas` in the Helm values files (`.meta/deployment/cloud/components/nifi/common.yml` or the environment-specific override) and redeploying via the CI/CD pipeline or DeployBot.

> ZooKeeper ensemble size changes require careful coordination (quorum must be maintained). Consult ZooKeeper documentation before scaling.

### Database Operations

> NiFi does not manage a directly owned relational database. If PostgreSQL-connected NiFi processors need to be managed (e.g., after schema changes in a target database), update the relevant DBCPConnectionPool controller service in the NiFi UI and restart affected processor groups. No database migration tooling is present in this repository.

## Troubleshooting

### NiFi Node Not Joining Cluster

- **Symptoms**: `health-check.sh` reports a non-`CONNECTED` node status; NiFi UI shows node as disconnected.
- **Cause**: ZooKeeper is unreachable, cluster election has not completed (election wait: 5 min), or network connectivity issue between NiFi nodes on port 8082.
- **Resolution**: (1) Verify ZooKeeper pods are running and passing their `ruok` probe. (2) Check `NIFI_ZK_CONNECT_STRING` is set to `nifi-3pip--zookeeper:2181`. (3) Check headless service DNS resolution for NiFi cluster protocol (port 8082). (4) Review NiFi logs: `kubectl logs <nifi-pod> -n nifi-3pip-<env>`.

### NiFi Startup Probe Failing

- **Symptoms**: Pod stuck in `Init` or not becoming Ready; Kubernetes reports startup probe failure.
- **Cause**: NiFi takes time to initialize (startup probe allows up to 300s: 30 failures x 10s period after 60s initial delay). Usually caused by large FlowFile/provenance repositories on startup, or ZooKeeper not yet available.
- **Resolution**: (1) Check if ZooKeeper ensemble is healthy first. (2) Allow the full 300s startup window before intervening. (3) Review pod logs for errors: `kubectl logs <nifi-pod> -n nifi-3pip-<env>`.

### ZooKeeper Ensemble Not Forming

- **Symptoms**: ZooKeeper pods not Ready; NiFi nodes cannot coordinate.
- **Cause**: ZooKeeper ensemble requires a quorum (at least 2 of 3 nodes). If the `setup.sh` ConfigMap script fails to determine `ZOO_SERVER_ID` from the pod hostname, ZooKeeper will not start.
- **Resolution**: (1) Verify all 3 ZooKeeper pods have correctly numbered hostnames. (2) Check that `DEPLOY_SERVICE`, `DEPLOY_COMPONENT`, `DEPLOY_INSTANCE`, and `DEPLOY_NAMESPACE` environment variables are set. (3) Check pod logs: `kubectl logs <zk-pod> -n nifi-3pip-<env>`.

### Sensitive Props Key Warning

- **Symptoms**: Startup logs or configuration review reveals `NIFI_SENSITIVE_PROPS_KEY` is still set to the placeholder value `MY_SECRET_TO_BE_FIXED_d37!84b8@6`.
- **Cause**: The key has not been rotated to a production secret.
- **Resolution**: Replace `NIFI_SENSITIVE_PROPS_KEY` with a securely generated key, store it in a Kubernetes Secret, and reference it in the Helm values. Rotate before any production use.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | NiFi cluster fully down — all 3 nodes unavailable | Immediate | 3pip-cbe-eng@groupon.com |
| P2 | NiFi cluster degraded — 1-2 nodes disconnected | 30 min | 3pip-cbe-eng@groupon.com |
| P3 | Minor impact — single processor failure or slow throughput | Next business day | 3pip-cbe-eng@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| ZooKeeper (`zookeeper`) | `echo 'ruok' \| nc -w 2 localhost 2181 \| grep imok` from any NiFi pod; or check ZooKeeper pod readiness in Kubernetes | No fallback — ZooKeeper is required for cluster coordination. NiFi nodes will not join the cluster without ZooKeeper quorum. |
| GCP Kubernetes cluster | Kubernetes pod status via `kubectl get pods -n nifi-3pip-<env>` | No fallback at application level — infrastructure concern. |
| PostgreSQL (external) | Via NiFi UI: inspect DBCPConnectionPool controller service status | NiFi processor group will fail; other unrelated flows continue running. |
