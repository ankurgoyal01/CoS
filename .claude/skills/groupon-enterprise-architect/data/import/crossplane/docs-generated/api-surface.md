---
service: "crossplane"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: ["kubernetes-api"]
auth_mechanisms: ["kubernetes-rbac"]
---

# API Surface

## Overview

Crossplane does not expose a traditional HTTP REST or gRPC service API. Its public interface is entirely Kubernetes-native: application teams and platform engineers interact with it by creating, updating, and deleting Kubernetes custom resources. The primary consumer-facing API surface is the `gcp-storages.groupon.com/v1alpha1` group, which exposes `Bucket` (claim) and `XBucket` (composite) resource kinds for GCS bucket provisioning. Administrative interactions with the package manager (installing providers and configurations) use the `pkg.crossplane.io/v1` API group.

## Kubernetes Custom Resource APIs

### Consumer API — GCS Bucket Provisioning

| API Group | Version | Kind | Scope | Purpose |
|-----------|---------|------|-------|---------|
| `gcp-storages.groupon.com` | `v1alpha1` | `Bucket` | Namespaced | Application-namespace claim for a GCS bucket. |
| `gcp-storages.groupon.com` | `v1alpha1` | `XBucket` | Cluster | Composite resource backing a `Bucket` claim. |

**`Bucket` claim spec fields:**

| Field | Type | Required | Values | Purpose |
|-------|------|----------|--------|---------|
| `spec.parameters.name` | string | yes | any | Desired GCS bucket name (patched into the managed resource). |
| `spec.location` | string | yes | `US`, `EU` | GCP storage location. Validated by `oneOf` pattern in XRD schema. |
| `spec.labels.service` | string | yes | any | GCS object label — identifies the owning service. |
| `spec.labels.owner` | string | yes | any | GCS object label — identifies the owner team. |
| `spec.labels.env` | string | no | `dev`, `staging`, `production` | Optional environment label. |
| `spec.labels.primary_contact` | string | no | any | Optional contact label. |
| `spec.compositionRef.name` | string | yes | `gcp-bucket-composition-dev`, `gcp-bucket-composition-staging`, `gcp-bucket-composition-production` | Selects the per-environment Composition. |

### Platform Admin API — Provider and Composition Management

| API Group | Version | Kind | Scope | Purpose |
|-----------|---------|------|-------|---------|
| `pkg.crossplane.io` | `v1` | `Provider` | Cluster | Installs a provider package from a registry. |
| `pkg.crossplane.io` | `v1beta1` | `DeploymentRuntimeConfig` | Cluster | Configures provider pod runtime settings (e.g., `skip-probe` annotation). |
| `apiextensions.crossplane.io` | `v1` | `CompositeResourceDefinition` | Cluster | Defines the XRD schema (`xbuckets.gcp-storages.groupon.com`). |
| `apiextensions.crossplane.io` | `v1` | `Composition` | Cluster | Maps XBucket composites to `storage.gcp.upbound.io/v1beta1 Bucket` managed resources. |
| `gcp.upbound.io` | `v1beta1` | `ProviderConfig` | Cluster | Binds GCP project credentials to the provider per environment. |

### Webhook Endpoint

| Port | Protocol | Purpose |
|------|----------|---------|
| `9443` | HTTPS (TCP) | Kubernetes admission webhook — validates and mutates Crossplane resources before persistence. Served by the `webhookServer` component inside `crossplaneController`. |

### Readiness Endpoint

| Port | Protocol | Purpose |
|------|----------|---------|
| `8081` | HTTP (TCP) | Readiness/startup probe (`readyz`) for the Crossplane controller pod. |

## Request/Response Patterns

### Common headers

Interactions are Kubernetes API calls. Standard `kubectl` authentication headers apply (Bearer token, certificate-based auth). No custom HTTP headers are documented.

### Error format

Errors are surfaced as Kubernetes resource `status.conditions` on the relevant custom resource (e.g., `XBucket`, `Bucket`). The `Ready` condition type is propagated from the managed resource up to the composite and then to the claim via `ToCompositeFieldPath` patches.

### Pagination

Kubernetes API list pagination applies via `continue` token on `kubectl get` calls. No custom pagination is defined.

## Rate Limits

> No rate limiting configured. Rate limiting is governed by Kubernetes API server admission controls.

## Versioning

All XRD-defined APIs are versioned via the `versions` field in `xbuckets.gcp-storages.groupon.com`. Currently only `v1alpha1` is served and referenceable (`served: true`, `referenceable: true`). Provider APIs (`storage.gcp.upbound.io/v1beta1`) follow upbound's versioning scheme.

## OpenAPI / Schema References

The XRD for `xbuckets.gcp-storages.groupon.com` embeds an OpenAPI v3 schema defined in `gcp-resources/dev/xrd-bucket.yaml` (identical across environments). The schema enforces `required: [location, labels]` and validates `location` with `oneOf` patterns (`US`, `EU`).
