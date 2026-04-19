---
service: "crossplane"
title: "RBAC Provisioning for Providers"
generated: "2026-03-03"
type: flow
flow_name: "rbac-provisioning-for-providers"
flow_type: event-driven
trigger: "New provider installed or provider CRDs change, detected by the RBAC Manager controller watch"
participants:
  - "crossplaneRbacManager"
  - "rbacReconciler"
  - "crossplaneController"
  - "Kubernetes API server"
architecture_ref: "crossplaneRbacManagerComponents"
---

# RBAC Provisioning for Providers

## Summary

When a new provider is installed (or its CRDs change), the Crossplane RBAC Manager automatically provisions the Kubernetes RBAC resources required for that provider to operate. This includes creating and updating ClusterRoles and ClusterRoleBindings that grant the provider controller pod the necessary permissions to manage its custom resources. This flow is event-driven and runs continuously as part of the RBAC Manager's reconciliation loop.

## Trigger

- **Type**: event (Kubernetes watch — resource change)
- **Source**: Crossplane API Reconciler creates or updates a `Provider` package resource; or the `apiReconciler` generates new XRD-related CRDs that require RBAC coverage.
- **Frequency**: Continuous (reconciliation loop); triggered on provider install, upgrade, or XRD change

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Crossplane RBAC Manager | Watches for provider/CRD changes; drives RBAC reconciliation | `crossplaneRbacManager` |
| RBAC Reconciler | Creates and updates ClusterRoles and ClusterRoleBindings | `rbacReconciler` |
| Crossplane Controller | Installs providers and XRDs that trigger RBAC changes | `crossplaneController` |
| Kubernetes API server | Stores and serves RBAC resources; target of all RBAC writes | `continuumKubernetesCluster` (stub) |

## Steps

1. **Detect provider or CRD change**: The `rbacReconciler` inside `crossplaneRbacManager` receives a Kubernetes watch event for a new or changed `Provider` or `CompositeResourceDefinition` resource.
   - From: Kubernetes API server (informer watch)
   - To: `rbacReconciler`
   - Protocol: Kubernetes informer

2. **Enumerate required RBAC rules**: The `rbacReconciler` calculates the ClusterRole rules required by the installed provider, scoped to the provider's managed resource API groups (e.g., `storage.gcp.upbound.io`).
   - From: `rbacReconciler` (internal logic)
   - To: n/a (in-memory computation)
   - Protocol: Crossplane RBAC engine

3. **Create or update ClusterRoles**: The `rbacReconciler` creates or patches ClusterRoles for:
   - Provider allowed permissions (aggregated under `crossplane:allowed-provider-permissions`)
   - Crossplane system aggregate ClusterRole (label: `rbac.crossplane.io/aggregate-to-crossplane: "true"`)
   - From: `rbacReconciler`
   - To: Kubernetes API server
   - Protocol: Kubernetes API (RBAC)

4. **Create or update ClusterRoleBindings**: The `rbacReconciler` binds the provider's ServiceAccount to the provisioned ClusterRoles, enabling the provider controller pod to interact with its managed resources.
   - From: `rbacReconciler`
   - To: Kubernetes API server
   - Protocol: Kubernetes API (RBAC)

5. **RBAC Manager reports healthy status**: The RBAC Manager updates the `Provider` resource status to reflect that RBAC provisioning is complete. The provider controller pod can now successfully call Kubernetes API endpoints for its CRD resources.
   - From: `rbacReconciler`
   - To: Kubernetes API server (status update on `Provider`)
   - Protocol: Kubernetes API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Insufficient RBAC Manager permissions | `rbacReconciler` logs error and retries; RBAC Manager ClusterRole must include `admissionregistration.k8s.io` and provider API group permissions | RBAC not provisioned; provider controller cannot manage its resources |
| ClusterRole conflict (name collision) | `rbacReconciler` patches the existing ClusterRole; conflict is resolved on next reconciliation | Transient error; automatically resolved |
| Provider removed / XRD deleted | `rbacReconciler` detects deletion event and removes associated ClusterRoles and ClusterRoleBindings | RBAC resources cleaned up; permissions revoked from removed provider |

## Sequence Diagram

```
crossplaneController     Kubernetes API     rbacReconciler (in crossplaneRbacManager)
       |                       |                      |
       |--install Provider---->|                      |
       |                       |--watch event-------->|
       |                       |                      |--calculate required ClusterRoles
       |                       |<--create/patch ClusterRoles--|
       |                       |<--create/patch ClusterRoleBindings--|
       |                       |                      |--update Provider status (RBAC ready)-->|
```

## Related

- Architecture component views: `crossplaneRbacManagerComponents`, `crossplaneControllerComponents`
- Related flows: [Provider Package Installation](provider-package-installation.md)
