---
service: "crossplane"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Crossplane.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [GCS Bucket Claim Provisioning](gcs-bucket-claim-provisioning.md) | asynchronous | Application team submits a `Bucket` claim via Kubernetes API | End-to-end flow from claim submission through Composition rendering to GCS bucket creation in GCP |
| [Provider Package Installation](provider-package-installation.md) | asynchronous | Platform team applies a `Provider` resource to the cluster | Flow for installing or upgrading a Crossplane GCP provider package from the internal registry |
| [RBAC Provisioning for Providers](rbac-provisioning-for-providers.md) | event-driven | New provider installed or upgraded | RBAC Manager detects provider installation and provisions required ClusterRoles and ClusterRoleBindings |
| [Crossplane Helm Install and Bootstrap](crossplane-helm-install-and-bootstrap.md) | synchronous | Platform team runs `helm install crossplane` | Bootstrap sequence: init container prepares TLS certs and package configs, core controller starts, webhooks register |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 1 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 0 |
| Event-driven | 1 |

## Cross-Service Flows

- The [GCS Bucket Claim Provisioning](gcs-bucket-claim-provisioning.md) flow spans the application namespace (claim submitter), the `crossplaneController` (reconciler), and GCP Storage API (managed resource target). This flow references the Structurizr relationship `crossplaneController -> continuumKubernetesCluster` (stub) and the external GCP integration.
- The [RBAC Provisioning for Providers](rbac-provisioning-for-providers.md) flow involves both `crossplaneController` and `crossplaneRbacManager`, coordinating through the Kubernetes API.
