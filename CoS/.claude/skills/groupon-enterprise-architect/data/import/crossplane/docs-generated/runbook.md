---
service: "crossplane"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Port `8081` (readyz) on `crossplaneController` pod | tcp (startupProbe) | `periodSeconds: 2` | `failureThreshold: 30` (60 seconds total) |
| Kubernetes `status.conditions` on `Provider` resources | Kubernetes API | Continuous (controller reconciliation loop) | Provider-managed |
| Kubernetes `status.conditions` on `Bucket` / `XBucket` resources | Kubernetes API | Continuous (controller reconciliation loop) | Provider-managed |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Prometheus metrics (port `8080`) | counter/gauge/histogram | Crossplane controller and RBAC Manager metrics (Go runtime, reconciliation counts, error rates) | Disabled by default (`metrics.enabled: false`); must be enabled and scraped by Prometheus |

> Prometheus metrics are disabled by default in all environments (`metrics.enabled: false`). Enable by setting `metrics.enabled: true` in the Helm values and ensuring a Prometheus scrape config targets port `8080` with path `/metrics`.

### Dashboards

> No evidence found in codebase. Operational procedures to be defined by service owner.

### Alerts

> No evidence found in codebase. Operational procedures to be defined by service owner.

## Common Operations

### Install or Upgrade Crossplane

```bash
helm install crossplane \
  --namespace crossplane-system \
  --create-namespace \
  docker-conveyor.groupondev.com/crossplane/crossplane \
  -f gcp-resources/<env>/crossplane-values.yaml
```

For upgrades:

```bash
helm upgrade crossplane crossplane-stable/crossplane \
  --namespace crossplane-system \
  -f gcp-resources/<env>/crossplane-values.yaml
```

### Restart Service

To safely restart the Crossplane controller:

```bash
kubectl rollout restart deployment/crossplane -n crossplane-system
```

To restart the RBAC Manager:

```bash
kubectl rollout restart deployment/crossplane-rbac-manager -n crossplane-system
```

Leader election ensures a new pod takes over within seconds.

### Scale Up / Down

Crossplane uses single-replica deployments with leader election. Changing `replicas` in `values.yaml` and re-applying via Helm is the supported method:

```bash
helm upgrade crossplane crossplane-stable/crossplane \
  --namespace crossplane-system \
  --set replicas=2
```

Note: multiple replicas require leader election to be enabled (`leaderElection: true`), which is the default.

### Apply a New XRD or Composition

```bash
kubectl apply -f gcp-resources/<env>/xrd-bucket.yaml
kubectl apply -f gcp-resources/<env>/composition-bucket-<env>.yaml
```

### Install or Update a Provider

```bash
kubectl apply -f gcp-resources/<env>/providers-gcp-prod.yaml
```

Monitor provider health:

```bash
kubectl get providers
kubectl describe provider provider-gcp-storage
```

### Apply a Bucket Claim (Application Team)

```bash
kubectl apply -f gcp-resources/<env>/gcs-bucket-claim-<env>.yaml -n <namespace>
```

Check claim status:

```bash
kubectl get bucket -n <namespace>
kubectl describe bucket <bucket-name> -n <namespace>
```

### Database Operations

> Not applicable. Crossplane does not own a database. All state is stored in Kubernetes etcd.

## Troubleshooting

### Provider Not Ready

- **Symptoms**: `kubectl get providers` shows `HEALTHY: False` or `INSTALLED: False`.
- **Cause**: Provider image pull failure (registry unavailable or image tag not found); invalid `DeploymentRuntimeConfig`; insufficient RBAC permissions.
- **Resolution**: Check provider pod logs (`kubectl logs -n crossplane-system -l pkg.crossplane.io/provider=provider-gcp-storage`); verify image availability at `docker.groupondev.com/upbound/provider-gcp-storage:v1`; confirm `DeploymentRuntimeConfig` named `skip-probe` exists.

### Bucket Claim Stuck in Pending / Not Ready

- **Symptoms**: `kubectl get bucket -n <namespace>` shows `READY: False` for an extended period.
- **Cause**: Missing or invalid Composition reference; ProviderConfig not found or has invalid credentials; GCP API quota exceeded; Crossplane controller pod down.
- **Resolution**: Check `kubectl describe bucket <name> -n <namespace>` for events and conditions; verify the `compositionRef.name` matches a deployed Composition; check ProviderConfig status (`kubectl describe providerconfig gcp-provider-<env>`); inspect controller logs (`kubectl logs -n crossplane-system -l app=crossplane`).

### Invalid GCP Credentials

- **Symptoms**: `ProviderConfig` status shows authentication errors; managed resource conditions show `Synced: False` with a GCP auth error.
- **Cause**: Kubernetes Secret (`sa-conveyor-<env>`) missing, corrupted, or service account key expired.
- **Resolution**: Verify the Secret exists in the correct namespace (`kubectl get secret sa-conveyor-<env> -n crossplane-<env>`); rotate the GCP service account key and update the Secret; check GCP IAM console for key validity.

### Webhook Admission Failures

- **Symptoms**: `kubectl apply` for Crossplane resources fails with admission webhook errors.
- **Cause**: `crossplane-webhooks` Service unreachable; TLS certificate Secrets (`crossplane-tls-server`, `crossplane-tls-client`) missing or expired.
- **Resolution**: Check the webhook service (`kubectl get svc crossplane-webhooks -n crossplane-system`); inspect TLS Secrets; restart the Crossplane controller deployment to regenerate certs via the init container.

### Package Cache Full

- **Symptoms**: Provider installation fails; init container logs show disk space errors.
- **Cause**: Package cache `emptyDir` volume (`sizeLimit: 20Mi`) exhausted during large provider package installation.
- **Resolution**: Increase `packageCache.sizeLimit` in Helm values and re-deploy; or switch to a PVC-backed cache via `packageCache.pvc`.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Crossplane controller down — no new GCS buckets can be provisioned | Immediate | Cloud Core / Conveyor platform team |
| P2 | Provider unhealthy — existing buckets unaffected but new claims not reconciling | 30 min | Cloud Core team |
| P3 | Single bucket claim stuck or failed | Next business day | Application team + Cloud Core |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| GCP Storage API | Check `kubectl get managed` for `Synced: True` on `storage.gcp.upbound.io/v1beta1 Bucket` resources; check provider pod logs | Existing GCS buckets remain functional; new provisioning halts until API recovers |
| `docker.groupondev.com` registry | `kubectl get providers` — `INSTALLED: True` confirms package pull succeeded | Crossplane cannot install/upgrade providers; existing running providers are unaffected |
| Kubernetes API server | Crossplane pod liveness — if Kubernetes API is unavailable Crossplane cannot reconcile | Crossplane halts all reconciliation; resumes automatically when API server recovers |
