---
service: "hybrid-boundary"
title: "Hybrid Boundary Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumHybridBoundary"
  containers:
    - "continuumHybridBoundaryEdgeProxy"
    - "continuumHybridBoundaryAgent"
    - "continuumHybridBoundaryLambdaApi"
    - "continuumHybridBoundaryLambdaRrdns"
    - "continuumHybridBoundaryLambdaIterator"
    - "continuumHybridBoundaryApiGateway"
    - "continuumHybridBoundaryServiceRegistryTable"
    - "continuumHybridBoundaryStepFunctions"
    - "continuumHybridBoundaryDns"
tech_stack:
  language: "Go 1.18, Python 3.9"
  framework: "Envoy xDS (go-control-plane v0.11.1)"
  runtime: "AWS Lambda, EC2 (Alpine Docker)"
---

# Hybrid Boundary Documentation

Infrastructure for managing edge proxies and service-to-service routing across on-prem and AWS environments, using Envoy as the data plane and a Go control plane agent.

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
| Language | Go 1.18, Python 3.9 |
| Framework | Envoy xDS (go-control-plane v0.11.1) |
| Runtime | AWS Lambda, EC2 (Alpine Docker) |
| Build tool | Make, Jenkins (Packer/Terraform) |
| Platform | Continuum (AWS) |
| Domain | Cloud Routing / Service Mesh |
| Team | Cloud Routing (cloud-routing@groupon.com) |
