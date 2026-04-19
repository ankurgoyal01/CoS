---
service: "cloud-ui"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Cloud UI.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Application Creation](application-creation.md) | synchronous | User submits new application form | Creates an application record with multi-component configuration and organization linkage |
| [GitOps Deployment](gitops-deployment.md) | synchronous | User triggers deployment from application detail page | Renders Helm values, commits config to Git, advances deployment phase, and polls Jenkins to completion |
| [Deployment Status Polling](deployment-status-polling.md) | synchronous | UI polls on a timer after triggering GitOps sync | Queries deployment phase, polls Jenkins for build progress, and constructs Deploybot URL when ready |
| [Helm Chart Rendering](helm-chart-rendering.md) | synchronous | User opens component config editor or previews manifests | Fetches chart metadata from Artifactory and renders Kubernetes manifests via Helm SDK |
| [Application Config Update](application-config-update.md) | synchronous | User edits component settings and saves | Updates environment-specific component configuration and persists to PostgreSQL |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 5 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The GitOps Deployment flow is the primary cross-service flow. It is documented in the Structurizr architecture dynamic view `dynamic-gitops-deployment-flow` and spans `continuumCloudUi`, `continuumCloudBackendApi`, `continuumCloudBackendPostgres`, the external Git repository, `jenkinsController`, and Deploybot. See [GitOps Deployment](gitops-deployment.md) for the full step-by-step description.
