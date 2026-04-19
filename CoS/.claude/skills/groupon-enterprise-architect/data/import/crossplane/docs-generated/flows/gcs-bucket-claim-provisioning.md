---
service: "crossplane"
title: "GCS Bucket Claim Provisioning"
generated: "2026-03-03"
type: flow
flow_name: "gcs-bucket-claim-provisioning"
flow_type: asynchronous
trigger: "Application team submits a Bucket claim resource (gcp-storages.groupon.com/v1alpha1) to their Kubernetes namespace"
participants:
  - "Application namespace (claim author)"
  - "crossplaneController"
  - "apiReconciler"
  - "GCP ProviderConfig"
  - "provider-gcp-storage"
  - "GCP Storage API"
architecture_ref: "crossplaneControllerComponents"
---

# GCS Bucket Claim Provisioning

## Summary

This flow describes how an application team requests a new GCS bucket by submitting a `Bucket` claim resource to their Kubernetes namespace. The Crossplane controller detects the new claim, selects the matching Composition based on `compositionRef.name`, renders an `XBucket` composite resource, and delegates provisioning to the `provider-gcp-storage` controller, which calls the GCP Storage API to create the physical bucket. The flow is asynchronous: after the claim is submitted, Crossplane reconciles continuously until the bucket reaches a `Ready` state.

## Trigger

- **Type**: api-call (Kubernetes resource creation)
- **Source**: Application team runs `kubectl apply -f gcs-bucket-claim-<env>.yaml -n <namespace>`
- **Frequency**: On-demand — whenever a new GCS bucket is needed

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Application namespace | Submits the `Bucket` claim resource | n/a (consumer) |
| Crossplane Controller | Detects claim, renders composite, drives reconciliation | `crossplaneController` |
| API Reconciler | Reconciles `Bucket` claim to `XBucket` composite and manages patches | `apiReconciler` |
| ProviderConfig (`gcp-provider-<env>`) | Supplies GCP project ID and credentials to the storage provider | Kubernetes resource |
| provider-gcp-storage controller | Calls GCP Storage API to create/update the managed `Bucket` resource | Installed via `Provider` package |
| GCP Storage API | Creates the physical GCS bucket in the designated GCP project | External — GCP |

## Steps

1. **Submit Bucket claim**: Application team applies a `Bucket` claim manifest to their namespace.
   - From: Application namespace
   - To: Kubernetes API server
   - Protocol: Kubernetes API (kubectl apply)
   - Example: `apiVersion: gcp-storages.groupon.com/v1alpha1`, `kind: Bucket`, with `spec.location`, `spec.labels`, `spec.compositionRef.name: gcp-bucket-composition-<env>`

2. **Claim persisted to etcd**: Kubernetes API server validates the claim against the XRD OpenAPI schema (enforces `required: [location, labels]`, validates `location` against `oneOf: US|EU`) and persists it to etcd.
   - From: Kubernetes API server
   - To: etcd
   - Protocol: Internal Kubernetes

3. **Crossplane detects new claim**: The `apiReconciler` component inside `crossplaneController` receives a watch event for the new `Bucket` resource.
   - From: Kubernetes API server (watch event)
   - To: `apiReconciler`
   - Protocol: Kubernetes informer (watch)

4. **Create XBucket composite resource**: The `apiReconciler` creates a cluster-scoped `XBucket` composite resource, copying fields from the claim's `spec`.
   - From: `apiReconciler`
   - To: Kubernetes API server (etcd)
   - Protocol: Kubernetes API

5. **Select and apply Composition**: The `apiReconciler` resolves the `compositionRef.name` (e.g., `gcp-bucket-composition-dev`) and applies the Composition patches to populate the `XBucket` spec fields (`spec.parameters.name`, `spec.location`, `spec.labels`).
   - From: `apiReconciler`
   - To: `XBucket` resource (in-memory rendering)
   - Protocol: Crossplane patch engine (FromCompositeFieldPath)

6. **Create storage.gcp.upbound.io/v1beta1 Bucket managed resource**: The `apiReconciler` creates the provider-level managed resource (`storage.gcp.upbound.io/v1beta1 Bucket`) with patched values: `spec.forProvider.name`, `spec.forProvider.location`, `spec.forProvider.labels`, `spec.forProvider.storageClass: STANDARD`, `spec.forProvider.uniformBucketLevelAccess: true`, `spec.providerConfigRef.name: gcp-provider-<env>`.
   - From: `apiReconciler`
   - To: Kubernetes API server (etcd)
   - Protocol: Kubernetes API

7. **Provider controller reconciles managed resource**: The `provider-gcp-storage` controller detects the new managed `Bucket` resource and reads credentials from `ProviderConfig` (`gcp-provider-<env>`), which references the Kubernetes Secret `sa-conveyor-<env>`.
   - From: `provider-gcp-storage` controller
   - To: ProviderConfig → Kubernetes Secret
   - Protocol: Kubernetes API

8. **Call GCP Storage API**: The `provider-gcp-storage` controller calls the GCP Storage API to create the GCS bucket with the specified name, location, storage class, and labels.
   - From: `provider-gcp-storage` controller
   - To: GCP Storage API
   - Protocol: GCP REST API (HTTPS)

9. **Update status conditions**: Upon successful creation, the provider controller sets `status.conditions[Ready]=True` on the managed `Bucket` resource. Crossplane propagates this condition back to the `XBucket` composite and then to the namespaced `Bucket` claim via `ToCompositeFieldPath` patches.
   - From: `provider-gcp-storage` controller / `apiReconciler`
   - To: Managed `Bucket` resource → `XBucket` → `Bucket` claim
   - Protocol: Kubernetes API (status update)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Claim schema validation failure | Kubernetes admission webhook rejects the apply before persistence | User receives an error; no resource is created |
| `compositionRef.name` not found | `apiReconciler` sets `Ready: False` on the claim with a descriptive error condition | Claim stays pending; user must correct the `compositionRef` |
| GCP credentials invalid or missing | `provider-gcp-storage` sets `Synced: False` on the managed resource; retries with backoff | Bucket not created; condition propagates to claim as `Ready: False` |
| GCP Storage API returns error (quota, permissions) | Provider controller retries with exponential backoff | Managed resource stays `Synced: False`; status message contains GCP error detail |
| GCP Storage API unavailable | Provider controller continues retry loop until API recovers | Claim remains `Ready: False` until GCP is available; no data loss |

## Sequence Diagram

```
Application Team      Kubernetes API     apiReconciler     provider-gcp-storage     GCP Storage API
      |                     |                  |                    |                      |
      |---apply Bucket----->|                  |                    |                      |
      |                     |--watch event---->|                    |                      |
      |                     |                  |--create XBucket--->|                      |
      |                     |                  |--create managed Bucket resource---------->|
      |                     |                  |                    |---create GCS bucket-->|
      |                     |                  |                    |<--bucket created-------|
      |                     |                  |<--status Ready=True (via patches)---------|
      |<--Bucket claim Ready=True (status)------|                   |                      |
```

## Related

- Architecture component view: `crossplaneControllerComponents`
- Related flows: [Provider Package Installation](provider-package-installation.md), [RBAC Provisioning for Providers](rbac-provisioning-for-providers.md)
