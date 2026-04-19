---
service: "aws-dns"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumRoute53InboundEndpoint"
    - "continuumRoute53OutboundEndpoint"
    - "continuumVpcResolver"
    - "continuumPrivateHostedZones"
    - "continuumAppSubnets"
---

# Architecture Context

## System Context

AWS DNS sits at the networking boundary between Groupon's on-premises data centres (snc1, sac1, dub1 colos) and AWS VPCs. It is a critical Tier 1 infrastructure service that provides bidirectional hybrid DNS resolution. On-premises workloads rely on the Inbound Endpoint to resolve AWS-hosted domain names; AWS workloads rely on the Outbound Endpoint to resolve on-premises domain names. Both endpoint types are deployed per-VPC, per-AZ using AWS Elastic Network Interfaces managed by the AWSLandingZone Terraform module. The service integrates with `continuumOnPremDns`, `continuumDirectConnect`, `continuumInternetGateway`, and `continuumAwsEc2Workloads` as external stubs in the central architecture model.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Route53 Resolver Inbound Endpoint | `continuumRoute53InboundEndpoint` | DNS Resolver | AWS Route53 Resolver | AWS managed | Inbound resolver endpoint deployed per VPC across AZs; receives DNS queries originating from on-prem DNS |
| Route53 Resolver Outbound Endpoint | `continuumRoute53OutboundEndpoint` | DNS Resolver | AWS Route53 Resolver | AWS managed | Outbound resolver endpoint deployed per VPC across AZs; forwards VPC DNS queries to on-prem DNS |
| AmazonProvidedDNS (.2 Resolver) | `continuumVpcResolver` | DNS Resolver | AWS AmazonProvidedDNS | AWS managed | VPC-local Amazon-provided resolver that handles private hosted zone lookups and forwards matching queries via outbound rules |
| Route53 Private Hosted Zones | `continuumPrivateHostedZones` | Data Store | AWS Route53 Private Hosted Zone | AWS managed | Private hosted zones containing internal AWS domain records resolved by AmazonProvidedDNS |
| Application Subnets | `continuumAppSubnets` | Network | AWS VPC Subnet | AWS managed | Application subnets where inbound and outbound Route53 resolver endpoints are deployed |

## Components by Container

### Route53 Resolver Inbound Endpoint (`continuumRoute53InboundEndpoint`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Inbound ENI Endpoints (`continuumInboundEniEndpoints`) | One or more ENI IPs spread across AZs accepting inbound DNS from on-prem DNS | Route53 Resolver ENI |
| AZ Health Selection (`continuumInboundAzHealthSelection`) | Selects healthy endpoint ENIs so traffic continues during AZ failure scenarios | Route53 Resolver Control Plane |
| Inbound Query Forwarder (`continuumInboundQueryForwarder`) | Forwards inbound DNS queries from endpoint ENIs to AmazonProvidedDNS (.2 Resolver) | Route53 Resolver Data Plane |

### Route53 Resolver Outbound Endpoint (`continuumRoute53OutboundEndpoint`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Outbound Rule Matcher (`continuumOutboundRuleMatcher`) | Matches DNS queries against outbound forwarding rules including catch-all behavior | Route53 Resolver Rules |
| Outbound ENI Endpoints (`continuumOutboundEniEndpoints`) | Per-AZ ENI IPs used to send outbound DNS queries toward on-prem DNS targets | Route53 Resolver ENI |
| Outbound Query Forwarder (`continuumOutboundForwarder`) | Forwards rule-matched DNS requests to on-prem DNS VIPs over hybrid connectivity | Route53 Resolver Data Plane |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumRoute53InboundEndpoint` | `continuumVpcResolver` | Forwards inbound DNS queries | DNS (UDP/TCP port 53) |
| `continuumVpcResolver` | `continuumPrivateHostedZones` | Resolves private hosted zone records | DNS internal |
| `continuumVpcResolver` | `continuumRoute53OutboundEndpoint` | Forwards rule-matched outbound DNS queries | DNS (UDP/TCP port 53) |
| `continuumRoute53InboundEndpoint` | `continuumAppSubnets` | Deployed in application subnets | N/A (network placement) |
| `continuumRoute53OutboundEndpoint` | `continuumAppSubnets` | Deployed in application subnets | N/A (network placement) |
| `continuumInboundEniEndpoints` | `continuumInboundAzHealthSelection` | Provides inbound DNS traffic from ENIs | DNS |
| `continuumInboundAzHealthSelection` | `continuumInboundQueryForwarder` | Routes only through healthy AZ ENI endpoints | DNS |
| `continuumOutboundRuleMatcher` | `continuumOutboundEniEndpoints` | Selects outbound endpoint ENIs for matched queries | DNS |
| `continuumOutboundEniEndpoints` | `continuumOutboundForwarder` | Provides egress path for outbound DNS traffic | DNS |

## Architecture Diagram References

- Component (Inbound): `components-inbound-endpoint`
- Component (Outbound): `components-outbound-endpoint`
- Dynamic flows: See `flows/hybrid-dns-flows.dsl` (disabled in federation; see [Flows](flows/index.md))
