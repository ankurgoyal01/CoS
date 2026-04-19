---
service: "crossplane"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["crossplaneController", "crossplaneRbacManager"]
---

# Architecture Context

## System Context

Crossplane runs inside the Continuum Platform (`continuumSystem`) as a cluster-scoped infrastructure controller within the Conveyor Kubernetes cluster (`continuumKubernetesCluster`). It bridges the Kubernetes API with GCP cloud services. Application teams in their own namespaces (e.g., `panoptikon-dev`, `panoptikon-staging`, `panoptikon-production`) submit declarative `Bucket` claims to the `gcp-storages.groupon.com/v1alpha1` API. The Crossplane controller reconciles those claims against the actual GCP Storage API by translating them through Compositions backed by the `upbound/provider-gcp-storage` provider. The RBAC Manager ensures that provider-specific service accounts and ClusterRoles are correctly maintained.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Crossplane Controller | `crossplaneController` | Kubernetes Controller | Kubernetes Controller | 1.19.1 | Crossplane core controller deployment installed via the Helm chart. Reconciles CRDs and managed resources, manages package installations, and serves the webhook endpoint. |
| Crossplane RBAC Manager | `crossplaneRbacManager` | Kubernetes Controller | Kubernetes Controller | 1.19.1 | RBAC manager deployment that provisions and manages RBAC resources (ClusterRoles, ClusterRoleBindings) for Crossplane providers. |

## Components by Container

### Crossplane Controller (`crossplaneController`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Reconciler (`apiReconciler`) | Watches Crossplane CRDs and managed resources; reconciles desired state with actual GCP resources. | Kubernetes Controller |
| Package Manager (`packageManager`) | Installs and upgrades provider, configuration, and function packages from the Groupon internal registry (`docker-conveyor.groupondev.com`). | Package Manager |
| Webhook Server (`webhookServer`) | Validates and mutates Crossplane resources when webhooks are enabled (port 9443). Enabled by default via `webhooks.enabled: true`. | Webhook |

### Crossplane RBAC Manager (`crossplaneRbacManager`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| RBAC Reconciler (`rbacReconciler`) | Creates and updates Kubernetes RBAC resources (ClusterRoles, ClusterRoleBindings) required by installed providers and composite resource definitions. | Kubernetes Controller |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `crossplaneController` | `continuumKubernetesCluster` | Watches and reconciles managed resources via the Kubernetes API. | Kubernetes API |
| `crossplaneRbacManager` | `continuumKubernetesCluster` | Manages RBAC resources via the Kubernetes API. | Kubernetes API |
| `crossplaneController` | GCP Storage API | Provisions and reconciles GCS buckets through the `provider-gcp-storage` provider. | GCP REST API (via provider) |
| Application namespaces | `crossplaneController` | Submit `Bucket` claims (`gcp-storages.groupon.com/v1alpha1`) to trigger GCS bucket provisioning. | Kubernetes API |

> Note: relationships to `continuumKubernetesCluster` are defined as stubs in the local DSL (`architecture/models/relations.dsl`) because the target container is not part of the federated model for this repository.

## Architecture Diagram References

- Component view (Crossplane Controller): `crossplaneControllerComponents`
- Component view (RBAC Manager): `crossplaneRbacManagerComponents`
