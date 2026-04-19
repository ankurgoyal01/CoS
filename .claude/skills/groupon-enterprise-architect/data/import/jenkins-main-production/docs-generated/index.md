---
service: "cloud-jenkins-main"
title: "Cloud Jenkins Main Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumJenkinsController", "continuumJenkinsAgentCleanupLambda"]
tech_stack:
  language: "Groovy / HCL"
  framework: "Jenkins Configuration as Code (JCasC)"
  runtime: "Jenkins (AWS ECS / EC2)"
---

# Cloud Jenkins Main Documentation

Production Jenkins CI/CD platform for Groupon's Continuum ecosystem, providing pipeline orchestration, EC2 agent provisioning, and automated stale-agent cleanup.

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
| Language | Groovy / HCL |
| Framework | Jenkins Configuration as Code (JCasC) |
| Runtime | Jenkins on AWS EC2 |
| Build tool | Terragrunt / Terraform |
| Platform | Continuum |
| Domain | CI/CD Infrastructure |
| Team | CICD (cicd@groupon.com) |
