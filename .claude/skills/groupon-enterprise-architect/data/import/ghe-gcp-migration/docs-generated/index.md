---
service: "ghe-gcp-migration"
title: "ghe-gcp-migration Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumGcpVpc"
    - "continuumGcpSubnet"
    - "continuumGcpFirewallRules"
    - "continuumNginxVm"
    - "continuumGithubVm"
    - "continuumGithubExternalDisk"
    - "continuumGithubInstanceGroup"
    - "continuumGithubAutoscaler"
    - "continuumHttpLoadBalancer"
    - "continuumSshLoadBalancer"
tech_stack:
  language: "HCL (Terraform)"
  framework: "Terraform 5.25.0 (Google Provider)"
  runtime: "Terraform CLI"
---

# GHE GCP Migration Documentation

Terraform infrastructure-as-code that provisions a GitHub Enterprise (GHE) instance on Google Cloud Platform, replacing the previous on-premise or alternative-cloud GHE hosting.

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
| Language | HCL (Terraform) |
| Framework | hashicorp/google provider 5.25.0 |
| Runtime | Terraform CLI |
| Build tool | Terraform |
| Platform | Continuum / GCP |
| Domain | Developer Infrastructure |
| Team | github |
