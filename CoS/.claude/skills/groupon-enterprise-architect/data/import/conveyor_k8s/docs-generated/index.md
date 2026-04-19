---
service: "conveyor_k8s"
title: "conveyor_k8s Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers:
    - "conveyorK8sPipelines"
    - "conveyorK8sTerraformEks"
    - "conveyorK8sTerraformGke"
    - "conveyorK8sAnsiblePlaybooks"
    - "conveyorK8sAmiBaking"
    - "conveyorK8sPipelineUtils"
tech_stack:
  language: "Go 1.24"
  framework: "cobra CLI"
  runtime: "Docker / Alpine 3.18"
---

# Conveyor K8s Documentation

Conveyor K8s is Groupon's Kubernetes cluster lifecycle automation platform, providing pipeline-driven provisioning, configuration, promotion, and decommission of EKS and GKE clusters across all environments.

## Contents

| Document | Description |
|----------|-------------|
| [Overview](overview.md) | Service identity, purpose, domain context, tech stack |
| [Architecture Context](architecture-context.md) | Containers, components, C4 references |
| [API Surface](api-surface.md) | Endpoints, contracts, protocols |
| [Events](events.md) | Async messages published and consumed |
| [Data Stores](data-stores.md) | Databases, caches, storage |
| [Integrations](integrations.md) | External and internal dependencies |
| [Configuration](configuration.md) | Environment, flags, secrets |
| [Flows](flows/index.md) | Process and flow documentation |
| [Deployment](deployment.md) | Infrastructure and environments |
| [Runbook](runbook.md) | Operations, monitoring, troubleshooting |

## Quick Facts

| Property | Value |
|----------|-------|
| Language | Go 1.24 |
| Framework | cobra (CLI), Ansible, Terraform/Terragrunt |
| Runtime | Docker (Alpine 3.18), Packer 1.6.5 |
| Build tool | Make + Docker |
| Platform | Continuum (Conveyor Cloud) |
| Domain | Platform Engineering / Kubernetes Infrastructure |
| Team | Conveyor Cloud |
