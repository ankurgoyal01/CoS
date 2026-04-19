---
service: "netops_awsinfra"
title: "AWS Network (netops_awsinfra) Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumNetopsTerragruntOrchestrator"
    - "continuumNetworkGlobalModule"
    - "continuumDirectConnectModule"
    - "continuumDirectConnectGatewayModule"
    - "continuumTransitGatewayModule"
    - "continuumTransitGatewayAcceptModule"
    - "continuumTransitGatewayAcceptNetopsModule"
    - "continuumTransitGatewayShareModule"
    - "continuumTransitGatewayCrossRegionPeeringCreateModule"
    - "continuumTransitGatewayCrossRegionPeeringAcceptModule"
    - "continuumTransitGatewayCrossRegionRoutesModule"
    - "continuumTransitGatewayDcgAssociationModule"
    - "continuumTransitGatewayVpcAttachmentTaggingModule"
    - "continuumDirectConnectVirtualInterfaceCreateModule"
    - "continuumDirectConnectVirtualInterfaceAcceptModule"
    - "continuumDirectConnectVirtualInterfaceNetopsModule"
    - "continuumDirectConnectTransitInterfaceNetopsModule"
    - "continuumClientVpnEndpointModule"
    - "continuumExternalDnsModule"
    - "continuumTransitGatewayDashboardModule"
    - "continuumDirectConnectDashboardModule"
    - "continuumLegacyDnsModule"
tech_stack:
  language: "HCL (Terraform/Terragrunt)"
  framework: "Terragrunt 0.38.6"
  runtime: "Terraform AWS Provider"
  build_tool: "Make + Terragrunt"
---

# AWS Network (netops_awsinfra) Documentation

Terraform/Terragrunt infrastructure-as-code repository that provisions and manages Groupon's AWS network layer, including Direct Connect connectivity from on-premise datacenters to AWS, Transit Gateway routing across regions and accounts, Client VPN endpoints, and DNS infrastructure.

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
| Language | HCL (Terraform/Terragrunt) |
| Framework | Terragrunt 0.38.6 |
| Runtime | Terraform AWS Provider |
| Build tool | Make + Terragrunt CLI |
| Platform | Continuum (AWS Network Infrastructure) |
| Domain | Network Operations |
| Team | Network Operations (prod-netops@groupon.com) |
