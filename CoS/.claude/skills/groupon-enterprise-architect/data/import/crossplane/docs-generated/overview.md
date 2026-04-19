---
service: "crossplane"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Infrastructure Platform"
platform: "Continuum / Conveyor"
team: "Cloud Core / Conveyor"
status: active
tech_stack:
  language: "YAML"
  language_version: "Kubernetes DSL"
  framework: "Crossplane"
  framework_version: "1.19.1"
  runtime: "Kubernetes"
  runtime_version: "v1.16.0+"
  build_tool: "Helm"
  package_manager: "Helm"
---

# Crossplane Overview

## Purpose

Crossplane is an open-source Kubernetes add-on that enables Groupon platform teams to assemble GCP cloud infrastructure from declarative Kubernetes manifests. It exposes higher-level self-service APIs (Composite Resource Definitions) that allow application teams to request infrastructure resources (such as GCS buckets) through standard Kubernetes claims without needing direct cloud provider access. Crossplane bridges the Kubernetes control plane and GCP, reconciling the desired state declared in manifests against actual cloud resources.

## Scope

### In scope

- Installing and running the Crossplane core controller (`crossplaneController`) in the Conveyor Kubernetes cluster.
- Managing the Crossplane RBAC Manager (`crossplaneRbacManager`) to provision RBAC resources for installed providers.
- Defining Composite Resource Definitions (XRDs) for GCS buckets (`XBucket` / `xbuckets.gcp-storages.groupon.com`).
- Providing per-environment Compositions (`gcp-bucket-composition-dev`, `gcp-bucket-composition-staging`, `gcp-bucket-composition-production`) that translate XBucket claims into provider-specific `storage.gcp.upbound.io/v1beta1 Bucket` managed resources.
- Installing GCP providers (`provider-gcp-storage`, `upbound-provider-family-gcp`) from the Groupon internal container registry.
- Managing ProviderConfig resources per environment that bind GCP project credentials to the provider.
- Exposing Bucket claim resources (kind: `Bucket`, group: `gcp-storages.groupon.com/v1alpha1`) to application namespaces so teams can self-service GCS bucket creation.

### Out of scope

- Application-level data storage logic (handled by consuming services).
- GCP IAM role and permissions management beyond Kubernetes RBAC (managed separately).
- Provisioning non-storage GCP resources (no evidence of database or networking compositions).
- Crossplane function pipelines (function packages list is empty across all environments).

## Domain Context

- **Business domain**: Infrastructure Platform — cloud resource lifecycle management.
- **Platform**: Continuum / Conveyor Kubernetes cluster.
- **Upstream consumers**: Application namespaces (e.g., `panoptikon-dev`, `panoptikon-staging`, `panoptikon-production`) that submit `Bucket` claims against the `gcp-storages.groupon.com/v1alpha1` API.
- **Downstream dependencies**: GCP Storage API (via `upbound/provider-gcp-storage`); GCP credentials stored as Kubernetes Secrets per environment.

## Stakeholders

| Role | Description |
|------|-------------|
| Platform / Cloud Core team | Owns and operates the Crossplane installation, provider upgrades, and XRD/Composition definitions. |
| Application team engineers | Consumers who submit `Bucket` claims to provision GCS buckets for their services. |
| Conveyor platform | Hosts the Kubernetes cluster where Crossplane runs; enforces the `com.groupon.conveyor.policies/skip-probes` annotation policy. |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Helm chart | Crossplane | 1.19.1 | `Chart.yaml` (`appVersion: 1.19.1`, `version: 1.19.1`) |
| Container image | `docker-conveyor.groupondev.com/crossplane/crossplane` | 1.19.1 (default appVersion) | `values.yaml` (`image.repository`) |
| GCP provider (family) | `upbound/provider-family-gcp` | v1.13.0 | `provider-familiy-gcp.yaml`, `gcp-resources/prod/providers-gcp-prod.yaml` |
| GCP provider (storage) | `upbound/provider-gcp-storage` | v1 | `provider-gcp-storage.yaml`, `gcp-resources/prod/providers-gcp-prod.yaml` |
| Orchestration | Kubernetes | v1.16.0+ | `README.md` |
| Package manager | Helm | v3.0.0+ | `README.md` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `upbound/provider-family-gcp` | v1.13.0 | infra-provider | GCP provider family base; supplies GCP authentication and shared CRDs |
| `upbound/provider-gcp-storage` | v1 | infra-provider | GCS storage managed resource controller; reconciles `storage.gcp.upbound.io/v1beta1 Bucket` |
| Crossplane Core (`crossplane/crossplane`) | 1.19.1 | controller-runtime | API reconciler, package manager, webhook server |
| Crossplane RBAC Manager | 1.19.1 | rbac | Provisions and manages ClusterRoles for installed providers |
| Helm (`crossplane-stable` chart) | 1.19.1 | deployment | Chart-based installation and upgrade of all Crossplane components |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
