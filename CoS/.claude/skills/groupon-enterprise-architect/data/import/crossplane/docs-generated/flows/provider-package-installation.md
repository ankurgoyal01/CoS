---
service: "crossplane"
title: "Provider Package Installation"
generated: "2026-03-03"
type: flow
flow_name: "provider-package-installation"
flow_type: asynchronous
trigger: "Platform team applies a Provider resource (pkg.crossplane.io/v1) to the cluster"
participants:
  - "Platform team"
  - "crossplaneController"
  - "packageManager"
  - "docker.groupondev.com container registry"
  - "crossplaneRbacManager"
  - "rbacReconciler"
architecture_ref: "crossplaneControllerComponents"
---

# Provider Package Installation

## Summary

This flow describes how a Crossplane provider package (such as `provider-gcp-storage` or `upbound-provider-family-gcp`) is installed into the cluster. The platform team applies a `Provider` manifest to Kubernetes. The Crossplane Package Manager pulls the OCI package image from the internal registry, validates it, installs the provider's CRDs into the cluster, and starts the provider controller Deployment. The RBAC Manager then provisions the required ClusterRoles and ClusterRoleBindings for the new provider.

## Trigger

- **Type**: api-call (Kubernetes resource creation)
- **Source**: Platform team runs `kubectl apply -f providers-gcp-prod.yaml` (or equivalent per-environment file)
- **Frequency**: On-demand — during initial setup, provider upgrades, or environment onboarding

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Platform team | Applies the `Provider` resource manifest | n/a (operator) |
| Crossplane Controller | Detects new `Provider` resource | `crossplaneController` |
| Package Manager | Pulls provider OCI image, installs CRDs, starts provider Deployment | `packageManager` |
| Internal container registry (`docker.groupondev.com`) | Serves provider OCI package image | Internal Groupon registry |
| Crossplane RBAC Manager | Provisions RBAC resources for the installed provider | `crossplaneRbacManager` |
| RBAC Reconciler | Creates ClusterRoles and ClusterRoleBindings for provider permissions | `rbacReconciler` |

## Steps

1. **Apply Provider manifest**: Platform team applies a `Provider` resource, e.g.:
   - `name: provider-gcp-storage`, `spec.package: docker.groupondev.com/upbound/provider-gcp-storage:v1`
   - `spec.packagePullPolicy: IfNotPresent`, `spec.revisionActivationPolicy: Automatic`, `spec.revisionHistoryLimit: 1`
   - `spec.runtimeConfigRef.name: skip-probe` (references `DeploymentRuntimeConfig`)
   - From: Platform team
   - To: Kubernetes API server
   - Protocol: Kubernetes API (kubectl apply)

2. **Package Manager detects new Provider**: The `packageManager` component inside `crossplaneController` receives a watch event for the new `Provider` resource.
   - From: Kubernetes API server (watch)
   - To: `packageManager`
   - Protocol: Kubernetes informer

3. **Pull OCI package from registry**: The `packageManager` pulls the provider package OCI image from `docker.groupondev.com/upbound/provider-gcp-storage:v1`. The package cache (`/cache`, emptyDir `20Mi`) stores the pulled layers.
   - From: `packageManager`
   - To: `docker.groupondev.com` (internal registry)
   - Protocol: OCI / HTTPS

4. **Install provider CRDs**: The `packageManager` extracts provider CRDs from the package and applies them to the Kubernetes API server, registering `storage.gcp.upbound.io/v1beta1` (and related) resource kinds.
   - From: `packageManager`
   - To: Kubernetes API server
   - Protocol: Kubernetes API (CRD apply)

5. **Create provider Deployment**: The `packageManager` creates a `Deployment` for the provider controller pod, applying the `DeploymentRuntimeConfig` named `skip-probe` (sets annotation `com.groupon.conveyor.policies/skip-probes: "true"`).
   - From: `packageManager`
   - To: Kubernetes API server
   - Protocol: Kubernetes API

6. **RBAC Manager provisions ClusterRoles**: The `rbacReconciler` inside `crossplaneRbacManager` detects the new provider and creates ClusterRoles scoped to the provider's permissions, aggregated under `crossplane:allowed-provider-permissions`.
   - From: `rbacReconciler`
   - To: Kubernetes API server
   - Protocol: Kubernetes API (RBAC resources)

7. **Provider starts and becomes ready**: The provider controller pod starts, connects to the GCP credentials via `ProviderConfig`, and sets `HEALTHY: True` and `INSTALLED: True` on the `Provider` resource status.
   - From: Provider pod
   - To: Kubernetes API server (status update)
   - Protocol: Kubernetes API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Registry unreachable or image not found | `packageManager` sets `INSTALLED: False` on `Provider` with error message; retries | Provider not installed; platform team must verify registry availability and image tag |
| CRD installation conflict (existing version) | Kubernetes rejects CRD apply if incompatible; `packageManager` reports conflict | Provider upgrade may fail; manual CRD cleanup may be required |
| `DeploymentRuntimeConfig` named `skip-probe` missing | Provider Deployment created without the annotation; Conveyor probe policies may affect provider pod | Provider pod may fail Conveyor's liveness checks; apply the `DeploymentRuntimeConfig` first |
| Provider pod crashes on startup | Kubernetes restarts the pod; `HEALTHY: False` condition set on `Provider` | Provider not functional; check pod logs for initialization errors |

## Sequence Diagram

```
Platform Team     Kubernetes API     packageManager     docker.groupondev.com     rbacReconciler
     |                  |                 |                      |                      |
     |--apply Provider-->|                 |                      |                      |
     |                  |--watch event--->|                      |                      |
     |                  |                 |--pull OCI image------>|                      |
     |                  |                 |<--OCI package---------|                      |
     |                  |                 |--apply provider CRDs->|                      |
     |                  |                 |--create provider Deployment----------------->|
     |                  |                 |                      |--provision ClusterRoles|
     |                  |<--Provider INSTALLED: True (status)----|                      |
```

## Related

- Architecture component view: `crossplaneControllerComponents`, `crossplaneRbacManagerComponents`
- Related flows: [RBAC Provisioning for Providers](rbac-provisioning-for-providers.md), [GCS Bucket Claim Provisioning](gcs-bucket-claim-provisioning.md)
