---
service: "crossplane"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: ["dev", "staging", "production"]
---

# Deployment

## Overview

Crossplane is deployed as a Helm chart (`crossplane` chart, version 1.19.1) into the Conveyor Kubernetes cluster. It runs as two Kubernetes Deployments: the `crossplaneController` (core reconciliation engine) and the `crossplaneRbacManager` (RBAC provisioning). Both run in the `crossplane-system` namespace (or the namespace specified at install time). Provider packages (`provider-gcp-storage`, `upbound-provider-family-gcp`) are installed as separate Crossplane-managed deployments. Three environments are configured: dev, staging, and production, each with its own ProviderConfig, Composition, and GCP project binding.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container image | Docker | `docker-conveyor.groupondev.com/crossplane/crossplane:v1.19.1` (internal mirror) |
| Orchestration | Kubernetes | Helm chart deploys `Deployment` resources; `templates/deployment.yaml`, `templates/rbac-manager-deployment.yaml` |
| Provider image (storage) | Docker | `docker.groupondev.com/upbound/provider-gcp-storage:v1` |
| Provider image (family) | Docker | `docker.groupondev.com/upbound/provider-family-gcp:v1.13.0` |
| Package cache | emptyDir | `sizeLimit: 20Mi`; stores cached provider/configuration OCI layers during installation |
| Webhook service | Kubernetes Service | `crossplane-webhooks` on port `9443` (TCP); created when `webhooks.enabled: true` |
| TLS certificates | Kubernetes Secrets | `crossplane-root-ca`, `crossplane-tls-server`, `crossplane-tls-client`; populated by init container |
| Load balancer | None | No external load balancer — all access is Kubernetes-internal via ClusterIP or direct API server calls |

## Environments

| Environment | Purpose | GCP Project | Crossplane Namespace | Composition |
|-------------|---------|-------------|----------------------|-------------|
| dev | Development and testing | `prj-grp-conveyor-dev-7a6c` | `crossplane-staging` | `gcp-bucket-composition-dev` |
| staging | Pre-production validation | `prj-grp-conveyor-stable-251d` | `crossplane-staging` | `gcp-bucket-composition-staging` |
| production | Live production workloads | `prj-grp-conveyor-prod-8dde` | `crossplane-production` | `gcp-bucket-composition-production` |

## CI/CD Pipeline

- **Tool**: Helm (manual apply pattern based on repo structure; no CI/CD pipeline definition file found in the repository)
- **Config**: `values.yaml` (base), `gcp-resources/<env>/crossplane-values.yaml` (per-environment override)
- **Trigger**: Manual (`helm install` / `helm upgrade`) or via platform GitOps tooling

### Pipeline Stages

1. **Install Crossplane**: `kubectl create namespace crossplane-system` then `helm install crossplane --namespace crossplane-system` with the values file for the target environment.
2. **Apply XRD**: `kubectl apply -f gcp-resources/<env>/xrd-bucket.yaml` to register the `XBucket` composite resource definition.
3. **Apply Composition**: `kubectl apply -f gcp-resources/<env>/composition-bucket-<env>.yaml` to register the environment-specific Composition.
4. **Install Providers**: `kubectl apply -f gcp-resources/<env>/providers-gcp-prod.yaml` (or root-level `provider-familiy-gcp.yaml` / `provider-gcp-storage.yaml`) to install the GCP provider packages.
5. **Apply DeploymentRuntimeConfig**: `kubectl apply -f gcp-resources/<env>/deployment-runtime-config.yaml` (staging/prod) to configure the `skip-probe` annotation for provider pods.
6. **Apply ProviderConfig**: `kubectl apply -f gcp-resources/<env>/providerConfig-conveyor-<env>.yaml` to bind GCP credentials to the provider.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Crossplane controller replicas | Manual | `replicas: 1` (`values.yaml`); single instance with leader election enabled |
| RBAC Manager replicas | Manual | `rbacManager.replicas: 1` (`values.yaml`); single instance with leader election enabled |
| Deployment strategy | RollingUpdate | `deploymentStrategy: RollingUpdate` |

## Resource Requirements

### Crossplane Controller

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | `100m` | `500m` |
| Memory | `256Mi` | `1024Mi` |
| Disk | emptyDir `20Mi` (package cache) | `20Mi` |

### RBAC Manager

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | `100m` | `100m` |
| Memory | `256Mi` | `512Mi` |
| Disk | None | None |

## Security

Both the Crossplane Controller and RBAC Manager pods run with hardened security contexts:

| Setting | Value |
|---------|-------|
| `runAsUser` | `65532` (non-root) |
| `runAsGroup` | `65532` |
| `allowPrivilegeEscalation` | `false` |
| `readOnlyRootFilesystem` | `true` |
| `hostNetwork` | `false` |

Provider pods are deployed with the `DeploymentRuntimeConfig` named `skip-probe`, which sets the `com.groupon.conveyor.policies/skip-probes: "true"` annotation to disable Conveyor platform probe enforcement for provider containers.
