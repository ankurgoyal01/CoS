---
service: "crossplane"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "gcsBuckets"
    type: "gcs"
    purpose: "Cloud object storage provisioned and managed by Crossplane on behalf of application teams"
  - id: "k8sEtcd"
    type: "etcd"
    purpose: "Kubernetes etcd stores all Crossplane CRD state, including XBucket composites and Bucket claims"
---

# Data Stores

## Overview

Crossplane itself is largely stateless as an operator: all configuration and resource state is stored in the Kubernetes API server's etcd backing store via custom resource objects. The primary data storage resource it provisions externally is GCS (Google Cloud Storage) buckets on behalf of application teams. Crossplane holds GCP credentials in Kubernetes Secrets per environment.

## Stores

### Kubernetes etcd (Custom Resource State) (`k8sEtcd`)

| Property | Value |
|----------|-------|
| Type | etcd (via Kubernetes API server) |
| Architecture ref | `continuumKubernetesCluster` |
| Purpose | Persists all Crossplane CRD objects: XBucket composites, Bucket claims, Compositions, XRDs, ProviderConfigs, Provider package state |
| Ownership | shared (managed by Kubernetes cluster infra team) |
| Migrations path | Not applicable — schema changes are managed through XRD version evolution |

#### Key Entities

| Entity / Resource Kind | Purpose | Key Fields |
|------------------------|---------|-----------|
| `xbuckets.gcp-storages.groupon.com` (XBucket) | Cluster-scoped composite resource backing a Bucket claim | `spec.parameters.name`, `spec.location`, `spec.labels`, `status.conditions` |
| `buckets.gcp-storages.groupon.com` (Bucket) | Namespaced claim submitted by an application team | `spec.parameters.name`, `spec.location`, `spec.labels`, `spec.compositionRef.name` |
| `storage.gcp.upbound.io/v1beta1 Bucket` | Provider-managed resource representing the actual GCS bucket | `spec.forProvider.name`, `spec.forProvider.location`, `spec.forProvider.storageClass`, `spec.forProvider.labels` |
| `ProviderConfig` (gcp.upbound.io/v1beta1) | Binds GCP project credentials per environment | `spec.projectID`, `spec.credentials.secretRef` |

#### Access Patterns

- **Read**: Crossplane controllers continuously watch (via Kubernetes informers) all XBucket, Bucket, and Managed Resource objects for state changes.
- **Write**: The API Reconciler writes status updates (conditions, synced state) back to XBucket and Bucket objects; the Package Manager writes Provider package installation status.
- **Indexes**: Standard Kubernetes label selectors; Compositions are selected by `compositionRef.name` on claims.

---

### GCS Buckets (Provisioned Resources) (`gcsBuckets`)

| Property | Value |
|----------|-------|
| Type | gcs (Google Cloud Storage) |
| Architecture ref | External — GCP project `prj-grp-conveyor-dev-7a6c` (dev), `prj-grp-conveyor-stable-251d` (staging), `prj-grp-conveyor-prod-8dde` (production) |
| Purpose | Object storage buckets created on behalf of application teams; owned by consuming services, not by Crossplane itself |
| Ownership | external (GCP) — lifecycle managed via Crossplane |
| Migrations path | Not applicable — buckets are provisioned declaratively; deletion follows Crossplane `deletionPolicy: Delete` |

#### Key Entities

| Entity | Purpose | Key Fields |
|--------|---------|-----------|
| GCS Bucket | Cloud object storage container | `name` (from `spec.parameters.name`), `location` (`US` or `EU`), `storageClass` (`STANDARD`), `uniformBucketLevelAccess: true`, GCS labels |

#### Access Patterns

- **Read**: Application services read objects from the provisioned bucket directly via GCS client libraries (outside of Crossplane).
- **Write**: Crossplane's `provider-gcp-storage` controller creates and updates the bucket resource in GCP when a claim is submitted or modified.

---

### Kubernetes Secrets (GCP Credentials)

| Property | Value |
|----------|-------|
| Type | Kubernetes Secret |
| Purpose | Stores GCP service account credentials consumed by ProviderConfig per environment |
| Ownership | owned (per-environment, managed by platform team) |

| Secret Name | Namespace | Environment |
|-------------|-----------|-------------|
| `sa-conveyor-dev` | `crossplane-staging` | dev |
| `sa-conveyor-staging` | `crossplane-staging` | staging |
| `sa-conveyor-production` | `crossplane-production` | production |

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Package cache (emptyDir) | in-memory/disk | Caches provider/configuration package OCI layers during installation | Session (pod lifetime); `sizeLimit: 20Mi` |

## Data Flows

Crossplane reconciliation reads `Bucket` claim objects from etcd (via Kubernetes watch), creates or updates `XBucket` composites, which in turn drive `storage.gcp.upbound.io/v1beta1 Bucket` managed resources. The provider controller then calls the GCP Storage API to create/update/delete the actual GCS bucket. Status conditions flow in the reverse direction via `ToCompositeFieldPath` patches back to the claim object in etcd.
