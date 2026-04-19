---
service: "netops_awsinfra"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 1
---

# Integrations

## Overview

`netops_awsinfra` integrates primarily with AWS cloud services via the Terraform AWS Provider. All integrations are outbound — the repository provisions infrastructure by calling AWS APIs. There are no inbound integrations. The three primary external AWS service groups are: Direct Connect (physical connectivity), Transit Gateway / EC2 networking, and Network Manager / CloudWatch (observability). One internal integration exists with the CloudCore Landing Zone tooling for remote state management.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| AWS Direct Connect API | AWS SDK / HTTPS | Provision and manage DX connections and virtual interfaces | yes | `continuumDirectConnectModule`, `continuumDirectConnectGatewayModule` |
| AWS EC2 / Transit Gateway API | AWS SDK / HTTPS | Provision TGWs, VPC attachments, peering, route tables, prefix lists, Client VPN | yes | `continuumTransitGatewayModule`, `continuumTransitGatewayAcceptModule` |
| AWS RAM API | AWS SDK / HTTPS | Share TGW resources to other AWS accounts via Resource Access Manager | yes | `continuumTransitGatewayShareModule` |
| AWS CloudWatch API | AWS SDK / HTTPS | Publish TGW and DX monitoring dashboards | no | `continuumTransitGatewayDashboardModule`, `continuumDirectConnectDashboardModule` |
| AWS Route53 API | AWS SDK / HTTPS | Provision Route53 A records for legacy DNS instances | no | `continuumLegacyDnsModule` |
| AWS Network Manager API | AWS SDK / HTTPS | Register TGWs in global network for topology visualization | no | `continuumNetworkGlobalModule` |
| Equinix ECX Colocation | BGP / Direct Connect | Physical DX connection endpoint (`EQC50`) for `us-east-2` links | yes | `continuumDirectConnectModule` |

### AWS Direct Connect API Detail

- **Protocol**: AWS SDK (HTTPS)
- **Base URL / SDK**: Terraform `aws` provider resource `aws_dx_connection`, `aws_dx_gateway`, `aws_dx_hosted_private_virtual_interface`, `aws_dx_private_virtual_interface`, `aws_dx_transit_virtual_interface`
- **Auth**: IAM role `grpn-all-netops-admin` assumed via aws-okta SAML federation
- **Purpose**: Creates and manages dedicated 10 Gbps Direct Connect connections at Equinix ECX (`EQC50`), Direct Connect Gateways (BGP ASN `65312` for prod, `65332` for Teradata), and all virtual interface types
- **Failure mode**: If DX API is unavailable, Terraform apply fails; existing DX infrastructure continues to function independently of the Terraform control plane
- **Circuit breaker**: Not applicable (infrastructure provisioning tool)

### AWS EC2 / Transit Gateway API Detail

- **Protocol**: AWS SDK (HTTPS)
- **Base URL / SDK**: Terraform `aws` provider resources `aws_ec2_transit_gateway`, `aws_ec2_transit_gateway_vpc_attachment`, `aws_ec2_transit_gateway_peering_attachment`, `aws_ec2_managed_prefix_list`, `aws_route`, `aws_ec2_tag`
- **Auth**: IAM role `grpn-all-netops-admin` per account via aws-okta profile (`~/.aws/netops-netops-awsinfra.config`)
- **Purpose**: Creates Transit Gateways per region (prod TGW name: `grpn-netops-TGW`, Teradata TGW: `grpn-netops-teradata-TGW`), VPC attachments in 28+ workload accounts, cross-region peering, and route table configuration
- **Failure mode**: Apply failures leave partial state; Terraform state tracks what was created
- **Circuit breaker**: Not applicable

### AWS RAM API Detail

- **Protocol**: AWS SDK (HTTPS)
- **Base URL / SDK**: Terraform `aws` provider resources `aws_ram_resource_share`, `aws_ram_resource_association`, `aws_ram_principal_association`, `aws_ram_resource_share_accepter`
- **Auth**: IAM role `grpn-all-netops-admin`
- **Purpose**: Shares TGW resources from NetOps account (`455278749095`) to 28+ workload accounts; generates `tgw_data.yml` file for cross-module handoff
- **Failure mode**: If RAM share is not accepted, workload accounts cannot attach VPCs to the TGW
- **Circuit breaker**: Not applicable

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| CloudCore Landing Zone / Terraform Remote State | S3 (AWS SDK) | Stores Terraform state under project `netops::netops_awsinfra` | External to this repo |

## Consumed By

> Upstream consumers are tracked in the central architecture model.

This repository does not expose services to consumers. The network infrastructure it provisions is consumed by all 28+ Groupon AWS accounts that depend on Transit Gateway routing for cross-account and on-premise connectivity. These include accounts such as `grpn-prod`, `grpn-stable`, `grpn-netops`, `grpn-edw-prod`, `grpn-logging-prod`, `vouchercloud-prod`, `giftcloud-prod`, `teradata-vantage`, and others listed in `envs/customers.yml`.

## Dependency Health

Terraform plan is used as a health/drift check mechanism — running `make <path>/plan` against any module reports whether the actual AWS state matches the declared configuration. No automated health check endpoints or circuit breakers are implemented, as this is an IaC orchestration tool rather than a long-running service.
