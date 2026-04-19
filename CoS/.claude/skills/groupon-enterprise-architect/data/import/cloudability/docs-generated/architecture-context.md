---
service: "cloudability"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumCloudabilityMetricsAgent", "continuumCloudabilityProvisioningCli"]
---

# Architecture Context

## System Context

Cloudability sits within the Continuum Platform (`continuumSystem`) as a cloud cost observability integration. The Cloud SRE team operates two logical units: a CLI toolset (`continuumCloudabilityProvisioningCli`) for cluster registration and manifest generation, and a runtime Kubernetes workload (`continuumCloudabilityMetricsAgent`) deployed on every Conveyor cluster. The Metrics Agent continuously reads cluster state from the Kubernetes API and pushes usage samples to Apptio's Cloudability SaaS platform, making Kubernetes resource cost data visible at the namespace and workload level across all Groupon environments.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Cloudability Provisioning CLI | `continuumCloudabilityProvisioningCli` | CLI / Tooling | Bash, curl, jq, kubectl | - | Repository scripts used by Cloud SRE to register clusters and generate/publish Cloudability agent manifests |
| Cloudability Metrics Agent | `continuumCloudabilityMetricsAgent` | Kubernetes Deployment | Docker / Cloudability Metrics Agent | 2.4 | Third-party Cloudability container deployed to Conveyor Kubernetes clusters to collect and export usage metrics |

## Components by Container

### Cloudability Provisioning CLI (`continuumCloudabilityProvisioningCli`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Cluster Registration Client (`clusterRegistrationClient`) | Registers the current Conveyor Kubernetes context as a Cloudability cluster via the provisioning API | Bash + curl |
| Config Fetcher (`configFetcher`) | Fetches generated Cloudability Kubernetes agent manifests for a registered cluster | Bash + curl |
| Manifest Patcher (`manifestPatcher`) | Applies Groupon-specific namespace, RBAC, image, and OPA policy modifications to generated manifests | GNU patch |
| Deployment Executor (`deploymentExecutor`) | Applies patched manifests to target staging or production clusters using kubectl and deploybot workflows | kubectl / deploybot |

### Cloudability Metrics Agent (`continuumCloudabilityMetricsAgent`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Metric Collector (`metricCollector`) | Collects node, pod, namespace, and workload metrics from Kubernetes cluster state and metrics endpoints | Cloudability Metrics Agent |
| Cluster Metadata Collector (`clusterMetadataCollector`) | Gathers cluster identity and inventory metadata used to tag exported samples | Cloudability Metrics Agent |
| Metrics Uploader (`metricsUploader`) | Packages and uploads collected metrics to Cloudability ingestion endpoints | HTTPS Client |
| Agent Health and Probes (`agentHealthChecks`) | Implements runtime liveness and startup checks for Kubernetes deployment health | Probe / Health Logic |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumCloudabilityProvisioningCli` | Cloudability Provisioning API (external) | Registers clusters and fetches generated agent manifests | HTTPS/REST |
| `continuumCloudabilityProvisioningCli` | `continuumCloudabilityMetricsAgent` | Deploys patched agent manifests to target clusters | kubectl apply |
| `continuumCloudabilityMetricsAgent` | Kubernetes API Server (external) | Reads cluster, node, pod, and workload metrics | Kubernetes API |
| `continuumCloudabilityMetricsAgent` | Cloudability Ingestion API (external) | Uploads Kubernetes metric samples | HTTPS |
| `clusterRegistrationClient` | `configFetcher` | Uses provisioned cluster ID to fetch agent config | internal |
| `configFetcher` | `manifestPatcher` | Passes raw Cloudability manifest for local hardening | internal |
| `manifestPatcher` | `deploymentExecutor` | Supplies patched Kubernetes manifest for rollout | internal |
| `metricCollector` | `clusterMetadataCollector` | Combines runtime metrics with cluster metadata | internal |
| `metricCollector` | `metricsUploader` | Sends collected metric samples for export | internal |
| `agentHealthChecks` | `metricCollector` | Verifies metricCollector runtime health | internal |
| `deploymentExecutor` | `metricCollector` | Deploys and runs metric collection workload | internal |

## Architecture Diagram References

- Component view (Provisioning CLI): `components-continuum-cloudability-provisioning-cli`
- Component view (Metrics Agent): `components-continuum-cloudability-metrics-agent`
- Dynamic flow (Agent Provisioning): `dynamic-cloudability-agent-provisioning-flow`
