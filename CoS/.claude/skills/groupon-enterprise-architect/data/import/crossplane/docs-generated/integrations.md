---
service: "crossplane"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 2
internal_count: 2
---

# Integrations

## Overview

Crossplane integrates with two external systems — GCP Storage API (via the `provider-gcp-storage` provider) and GCP's authentication infrastructure (via per-environment service account credentials) — and depends on two internal Groupon systems: the Conveyor Kubernetes cluster (where it runs) and the Groupon internal container registry (`docker-conveyor.groupondev.com` / `docker.groupondev.com`) from which it pulls provider packages.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| GCP Storage API | GCP REST API (via upbound provider SDK) | Creates, updates, and deletes GCS buckets as declared by `storage.gcp.upbound.io/v1beta1 Bucket` managed resources | yes | External — GCP |
| GCP IAM / Authentication | GCP service account credentials (JSON key in Kubernetes Secret) | Authenticates the `provider-gcp-storage` provider to the GCP project per environment | yes | External — GCP |

### GCP Storage API Detail

- **Protocol**: GCP REST API, wrapped by the `upbound/provider-gcp-storage:v1` provider controller.
- **Base URL / SDK**: `docker.groupondev.com/upbound/provider-gcp-storage:v1` (mirrored from `upbound/provider-gcp-storage`).
- **Auth**: GCP service account JSON key referenced by `ProviderConfig` (`spec.credentials.source: Secret`).
- **Purpose**: Reconciles `storage.gcp.upbound.io/v1beta1 Bucket` managed resources against actual GCS buckets in the configured GCP project. Creates buckets with `storageClass: STANDARD`, `uniformBucketLevelAccess: true`, and the specified location and labels.
- **Failure mode**: If the GCP Storage API is unavailable, the provider controller enters a retry/backoff loop. `XBucket` and `Bucket` claim status conditions transition to `Ready: False` until the API recovers.
- **Circuit breaker**: No explicit circuit breaker configured; relies on provider-level retry logic.

### GCP IAM / Authentication Detail

- **Protocol**: GCP service account credentials (JSON key stored in Kubernetes Secret).
- **Base URL / SDK**: GCP IAM (credentials used by upbound provider internally).
- **Auth**: Per-environment Kubernetes Secrets (`sa-conveyor-dev`, `sa-conveyor-staging`, `sa-conveyor-production`) referenced by environment-specific `ProviderConfig` resources.
- **Purpose**: Grants the `provider-gcp-storage` controller permission to manage GCS resources in the designated GCP project per environment.
- **Failure mode**: Invalid or expired credentials cause provider reconciliation to fail; `ProviderConfig` status conditions reflect authentication errors.
- **Circuit breaker**: No explicit circuit breaker; the provider retries on credential errors.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Conveyor Kubernetes Cluster | Kubernetes API (watch/reconcile) | Hosts Crossplane controller and RBAC Manager deployments; provides etcd state storage for all CRD objects | `continuumKubernetesCluster` |
| Groupon internal container registry (`docker-conveyor.groupondev.com`, `docker.groupondev.com`) | OCI / HTTPS | Source for Crossplane controller image and provider package images (`provider-gcp-storage`, `upbound-provider-family-gcp`) | Internal Groupon registry |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Application teams (e.g., `panoptikon` service) | Kubernetes API (`kubectl apply`) | Submit `Bucket` claims (`gcp-storages.groupon.com/v1alpha1`) to provision GCS buckets in their namespace |
| Platform / Cloud Core team | Kubernetes API + Helm | Deploy and upgrade the Crossplane installation; manage providers, XRDs, and Compositions |

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

- The `crossplaneController` deployment uses a startup probe (`tcpSocket` on port `8081`) with `failureThreshold: 30, periodSeconds: 2` to verify readiness before traffic is directed to the pod.
- Provider pods are deployed with `DeploymentRuntimeConfig` name `skip-probe` (annotation `com.groupon.conveyor.policies/skip-probes: "true"`), which disables Conveyor platform probe enforcement for provider deployments.
- Leader election (`leaderElection: true`) is enabled for both the Crossplane controller and the RBAC Manager, ensuring a single active instance processes reconciliation loops at any time.
