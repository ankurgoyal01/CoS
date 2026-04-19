---
service: "gcp-tls-certificate-manager"
title: "gcp-tls-certificate-manager Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["gcpTlsCertificateManagerPipeline"]
tech_stack:
  language: "Shell / Groovy"
  framework: "Jenkins Pipeline"
  runtime: "Jenkins (dind_2gb_2cpu agent)"
---

# GCP TLS Certificate Manager Documentation

A GitOps-driven pipeline service that provisions, refreshes, and removes TLS certificates for GCP-hosted Groupon services requiring Hybrid Boundary access to non-GCP internal systems.

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
| Language | Shell (sh) / Groovy |
| Framework | Jenkins Declarative Pipeline |
| Runtime | Jenkins (dind_2gb_2cpu agent node) |
| Build tool | Jenkins (Conveyor CI) |
| Platform | Continuum / GCP Infrastructure |
| Domain | GCP Migration Infrastructure |
| Team | dnd-gcp-migration-infra |
