---
service: "netops_awsinfra"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
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
---

# Architecture Context

## System Context

`netops_awsinfra` sits within the `continuumSystem` software system and is classified as a network infrastructure platform under the Continuum umbrella. It operates entirely as infrastructure-as-code — there is no running application service. The `continuumNetopsTerragruntOrchestrator` acts as the top-level deployment engine, executing all Terraform modules against the AWS control plane (`cloudPlatform`) across 28+ AWS accounts and 7 AWS regions. Observability data from Transit Gateways and Direct Connect links is surfaced to `observabilityPlatform` via CloudWatch dashboards.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| NetOps Terragrunt Orchestrator | `continuumNetopsTerragruntOrchestrator` | Orchestrator | Terragrunt + Terraform | Executes all network infrastructure stacks per account, region, and environment under `envs/` |
| Network Global Module | `continuumNetworkGlobalModule` | Infrastructure | Terraform Module | Provisions AWS Network Manager global network, sites, devices, and links |
| Direct Connect Module | `continuumDirectConnectModule` | Infrastructure | Terraform Module | Provisions `aws_dx_connection` resources at colocation facilities |
| Direct Connect Gateway Module | `continuumDirectConnectGatewayModule` | Infrastructure | Terraform Module | Provisions `aws_dx_gateway` resources for BGP peering |
| Transit Gateway Module | `continuumTransitGatewayModule` | Infrastructure | Terraform Module | Provisions `aws_ec2_transit_gateway` per region with RAM share and Network Manager registration |
| Transit Gateway Accept Module | `continuumTransitGatewayAcceptModule` | Infrastructure | Terraform Module | Accepts TGW RAM share and creates VPC attachments and routes in workload accounts |
| Transit Gateway Accept NetOps Module | `continuumTransitGatewayAcceptNetopsModule` | Infrastructure | Terraform Module | Creates NetOps-side TGW VPC attachments and prefix list/route configuration |
| Transit Gateway Share Module | `continuumTransitGatewayShareModule` | Infrastructure | Terraform Module | Shares TGW to target account principals via `aws_ram_principal_association`; writes `tgw_data.yml` |
| TGW Cross-Region Peering Create Module | `continuumTransitGatewayCrossRegionPeeringCreateModule` | Infrastructure | Terraform Module | Creates `aws_ec2_transit_gateway_peering_attachment` for cross-region TGW links |
| TGW Cross-Region Peering Accept Module | `continuumTransitGatewayCrossRegionPeeringAcceptModule` | Infrastructure | Terraform Module | Accepts `aws_ec2_transit_gateway_peering_attachment_accepter` on the remote region side |
| TGW Cross-Region Routes Module | `continuumTransitGatewayCrossRegionRoutesModule` | Infrastructure | Terraform Module | Manages managed prefix lists and TGW prefix list references for cross-region routing |
| TGW-DCG Association Module | `continuumTransitGatewayDcgAssociationModule` | Infrastructure | Terraform Module | Associates Direct Connect Gateways with Transit Gateways via `aws_dx_gateway_association` |
| TGW VPC Attachment Tagging Module | `continuumTransitGatewayVpcAttachmentTaggingModule` | Infrastructure | Terraform Module | Applies `aws_ec2_tag` resources to TGW VPC attachments for operational metadata |
| DX Virtual Interface Create Module | `continuumDirectConnectVirtualInterfaceCreateModule` | Infrastructure | Terraform Module | Creates hosted private Direct Connect virtual interfaces (`aws_dx_hosted_private_virtual_interface`) |
| DX Virtual Interface Accept Module | `continuumDirectConnectVirtualInterfaceAcceptModule` | Infrastructure | Terraform Module | Accepts hosted private Direct Connect virtual interfaces (`aws_dx_hosted_private_virtual_interface_accepter`) |
| DX Virtual Interface NetOps Module | `continuumDirectConnectVirtualInterfaceNetopsModule` | Infrastructure | Terraform Module | Creates private Direct Connect virtual interfaces for NetOps-managed links (`aws_dx_private_virtual_interface`) |
| DX Transit Interface NetOps Module | `continuumDirectConnectTransitInterfaceNetopsModule` | Infrastructure | Terraform Module | Creates transit virtual interfaces for NetOps TGW connectivity (`aws_dx_transit_virtual_interface`) |
| Client VPN Endpoint Module | `continuumClientVpnEndpointModule` | Infrastructure | Terraform Module | Provisions AWS Client VPN endpoint resources |
| External DNS Module | `continuumExternalDnsModule` | Infrastructure | Terragrunt Stack | Deploys regional external DNS infrastructure stacks for NetOps environments |
| Transit Gateway Dashboard Module | `continuumTransitGatewayDashboardModule` | Observability | Terraform Module | Provisions `aws_cloudwatch_dashboard` for TGW health and traffic metrics |
| Direct Connect Dashboard Module | `continuumDirectConnectDashboardModule` | Observability | Terraform Module | Provisions `aws_cloudwatch_dashboard` for Direct Connect link monitoring |
| Legacy DNS Module | `continuumLegacyDnsModule` | Infrastructure | Terraform Module | Provisions DNS EC2 instances (Amazon Linux 2), security groups, ALB, and Route53 `A` records |

## Components by Container

### NetOps Terragrunt Orchestrator (`continuumNetopsTerragruntOrchestrator`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Terragrunt Configuration Graph (`continuumNetopsTerragruntOrchestratorConfig`) | Defines account/region/environment directory structure under `envs/` and module source pointers via `terragrunt.hcl` files | HCL |
| Execution Pipeline (`continuumNetopsTerragruntOrchestratorExecutor`) | Runs `terragrunt run-all plan/apply` against targeted module stacks; switches AWS profiles per account | Terragrunt CLI |

### Transit Gateway Module (`continuumTransitGatewayModule`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Terraform Configuration (`continuumTransitGatewayModuleConfig`) | Defines TGW, RAM share, and Network Manager registration resources | HCL |
| TGW Provisioner (`continuumTransitGatewayModuleProvisioner`) | Applies `aws_ec2_transit_gateway`, `aws_ram_resource_share`, `aws_ram_resource_association`, `aws_networkmanager_transit_gateway_registration` | Terraform AWS Provider |

### Transit Gateway Accept Module (`continuumTransitGatewayAcceptModule`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Terraform Configuration (`continuumTransitGatewayAcceptModuleConfig`) | Defines TGW share acceptance, VPC attachment, managed prefix list, and route table entries | HCL |
| TGW Accept Provisioner (`continuumTransitGatewayAcceptModuleProvisioner`) | Applies `aws_ram_resource_share_accepter`, `aws_ec2_transit_gateway_vpc_attachment`, `aws_ec2_managed_prefix_list`, `aws_route` | Terraform AWS Provider |

### Direct Connect Dashboard Module (`continuumDirectConnectDashboardModule`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Terraform Configuration (`continuumDirectConnectDashboardModuleConfig`) | Defines DX dashboard widgets, metrics queries, and connection mappings | HCL |
| Direct Connect Dashboard Provisioner (`continuumDirectConnectDashboardModuleProvisioner`) | Applies `aws_cloudwatch_dashboard` for Direct Connect observability | Terraform AWS Provider |

### Legacy DNS Module (`continuumLegacyDnsModule`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Terraform Configuration (`continuumLegacyDnsModuleConfig`) | Defines DNS EC2 instances (Amazon Linux 2, kernel 5.10), security groups, ALB, listener, target groups, Route53 records | HCL |
| Legacy DNS Provisioner (`continuumLegacyDnsModuleProvisioner`) | Applies compute, networking, and Route53 DNS resources | Terraform AWS Provider |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumNetopsTerragruntOrchestrator` | `continuumNetworkGlobalModule` | Deploys | Terragrunt CLI |
| `continuumNetopsTerragruntOrchestrator` | `continuumDirectConnectModule` | Deploys | Terragrunt CLI |
| `continuumNetopsTerragruntOrchestrator` | `continuumDirectConnectGatewayModule` | Deploys | Terragrunt CLI |
| `continuumNetopsTerragruntOrchestrator` | `continuumTransitGatewayModule` | Deploys | Terragrunt CLI |
| `continuumNetopsTerragruntOrchestrator` | `continuumTransitGatewayAcceptModule` | Deploys | Terragrunt CLI |
| `continuumNetopsTerragruntOrchestrator` | `continuumTransitGatewayShareModule` | Deploys | Terragrunt CLI |
| `continuumNetopsTerragruntOrchestrator` | `continuumTransitGatewayCrossRegionPeeringCreateModule` | Deploys | Terragrunt CLI |
| `continuumNetopsTerragruntOrchestrator` | `continuumTransitGatewayDashboardModule` | Deploys | Terragrunt CLI |
| `continuumNetworkGlobalModule` | `cloudPlatform` | Provisions network manager resources in | AWS API |
| `continuumDirectConnectModule` | `cloudPlatform` | Provisions direct connect resources in | AWS API |
| `continuumDirectConnectGatewayModule` | `cloudPlatform` | Provisions direct connect gateway resources in | AWS API |
| `continuumTransitGatewayModule` | `cloudPlatform` | Provisions transit gateway resources in | AWS API |
| `continuumTransitGatewayAcceptModule` | `cloudPlatform` | Provisions account attachment and routing resources in | AWS API |
| `continuumTransitGatewayShareModule` | `cloudPlatform` | Shares resources via | AWS RAM API |
| `continuumTransitGatewayCrossRegionPeeringCreateModule` | `cloudPlatform` | Creates peering attachments in | AWS API |
| `continuumTransitGatewayCrossRegionPeeringAcceptModule` | `cloudPlatform` | Accepts peering attachments in | AWS API |
| `continuumTransitGatewayCrossRegionRoutesModule` | `cloudPlatform` | Manages route and prefix resources in | AWS API |
| `continuumTransitGatewayDcgAssociationModule` | `cloudPlatform` | Associates gateways in | AWS API |
| `continuumTransitGatewayVpcAttachmentTaggingModule` | `cloudPlatform` | Applies TGW attachment tags in | AWS API |
| `continuumDirectConnectVirtualInterfaceCreateModule` | `cloudPlatform` | Creates hosted private virtual interfaces in | AWS API |
| `continuumDirectConnectVirtualInterfaceAcceptModule` | `cloudPlatform` | Accepts hosted private virtual interfaces in | AWS API |
| `continuumClientVpnEndpointModule` | `cloudPlatform` | Provisions VPN endpoint resources in | AWS API |
| `continuumExternalDnsModule` | `cloudPlatform` | Provisions DNS resources in | AWS API |
| `continuumLegacyDnsModule` | `cloudPlatform` | Provisions DNS EC2/LB/Route53 resources in | AWS API |
| `continuumTransitGatewayDashboardModule` | `observabilityPlatform` | Exposes TGW telemetry to | CloudWatch Dashboards |
| `continuumDirectConnectDashboardModule` | `observabilityPlatform` | Exposes DX telemetry to | CloudWatch Dashboards |
| `continuumTransitGatewayDashboardModule` | `continuumTransitGatewayModule` | Visualizes metrics for | — |
| `continuumDirectConnectDashboardModule` | `continuumDirectConnectModule` | Visualizes metrics for | — |

## Architecture Diagram References

- Container: `containers-netops-awsinfra`
- Component views defined per module under `views/components/`
