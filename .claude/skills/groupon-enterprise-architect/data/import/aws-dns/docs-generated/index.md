---
service: "aws-dns"
title: "AWS DNS Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumRoute53InboundEndpoint"
    - "continuumRoute53OutboundEndpoint"
    - "continuumVpcResolver"
    - "continuumPrivateHostedZones"
    - "continuumAppSubnets"
tech_stack:
  language: "N/A (managed infrastructure)"
  framework: "AWS Route53 Resolver"
  runtime: "AWS managed service"
---

# AWS DNS Documentation

AWS infrastructure managing DNS resolution for Groupon's Hybrid (on-premises + AWS) environment using AWS Route53 Resolver Inbound and Outbound Endpoints.

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
| Language | N/A (managed infrastructure) |
| Framework | AWS Route53 Resolver |
| Runtime | AWS managed service |
| Build tool | Terraform |
| Platform | AWS (Hybrid) |
| Domain | Infrastructure / DNS |
| Team | Infrastructure Engineering |
