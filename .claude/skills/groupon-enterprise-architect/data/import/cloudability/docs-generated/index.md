---
service: "cloudability"
title: "Cloudability Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumCloudabilityMetricsAgent", "continuumCloudabilityProvisioningCli"]
tech_stack:
  language: "Bash"
  framework: "kubectl / curl / jq"
  runtime: "Docker / Kubernetes"
---

# Cloudability Documentation

Groupon's Cloudability integration: provisioning scripts and metrics agent deployment for Kubernetes cloud cost visibility across all Conveyor clusters.

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
| Language | Bash |
| Framework | kubectl / curl / jq |
| Runtime | Docker / Kubernetes |
| Build tool | deploybot |
| Platform | Continuum (Cloud SRE) |
| Domain | Cloud Cost Management |
| Team | CloudSRE |
