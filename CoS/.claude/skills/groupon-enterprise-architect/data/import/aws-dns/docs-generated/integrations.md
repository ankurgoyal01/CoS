---
service: "aws-dns"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 4
internal_count: 4
---

# Integrations

## Overview

AWS DNS integrates with four external AWS-managed systems and four internal Groupon infrastructure components. The service acts as the central DNS resolution bridge, with the Inbound Endpoint accepting traffic from on-premises DNS servers and the Outbound Endpoint forwarding traffic to on-premises DNS VIPs. All connectivity traverses AWS Direct Connect and VPC Internet Gateway as the hybrid network fabric.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| AWS Route53 Private Hosted Zones | DNS internal | Authoritative zone records for AWS-hosted domain names | yes | `continuumPrivateHostedZones` |
| AmazonProvidedDNS (.2 Resolver) | DNS | VPC-local resolver that routes queries between inbound/outbound endpoints and Route53 | yes | `continuumVpcResolver` |
| AWS Direct Connect | Network | Private hybrid connectivity path between on-premises colos and AWS VPCs | yes | `continuumDirectConnect` (stub) |
| VPC Internet Gateway | Network | Entry and exit point for inbound/outbound DNS traffic traversing the VPC boundary | yes | `continuumInternetGateway` (stub) |

### AWS Route53 Private Hosted Zones Detail

- **Protocol**: DNS (internal AWS)
- **Base URL / SDK**: AWS managed; accessed by AmazonProvidedDNS at VPC .2 resolver IP
- **Auth**: IAM / VPC association (private zones are VPC-associated)
- **Purpose**: Holds DNS records for internal AWS domain names resolved during inbound DNS flows
- **Failure mode**: If Route53 Private Hosted Zones are unavailable, inbound DNS lookups for AWS-hosted names will fail with SERVFAIL
- **Circuit breaker**: Not applicable (AWS-managed service with built-in redundancy)

### AmazonProvidedDNS (.2 Resolver) Detail

- **Protocol**: DNS (UDP/TCP port 53)
- **Base URL / SDK**: `<VPC CIDR base + .2>` — standard AWS VPC DNS resolver address
- **Auth**: VPC network boundary
- **Purpose**: Acts as the central DNS routing hub within each VPC; forwards queries to Outbound Endpoint when they match outbound forwarding rules; resolves from Route53 Private Hosted Zones for inbound queries
- **Failure mode**: If unavailable, all VPC-internal DNS resolution fails; also breaks both inbound and outbound hybrid DNS flows
- **Circuit breaker**: Not applicable (AWS-managed service)

### AWS Direct Connect Detail

- **Protocol**: Network (BGP / private virtual interface)
- **Base URL / SDK**: N/A
- **Auth**: AWS BGP peering, on-premises router config
- **Purpose**: Provides private connectivity path between on-premises colos and AWS VPC for DNS query transit
- **Failure mode**: Direct Connect failure breaks both inbound (on-prem forwarding to Inbound Endpoint) and outbound (Outbound Endpoint to on-prem DNS) flows; DNS queries time out
- **Circuit breaker**: Not applicable; no software circuit breaker — availability depends on AWS Direct Connect SLA

### VPC Internet Gateway Detail

- **Protocol**: Network
- **Base URL / SDK**: N/A
- **Auth**: VPC route table and Network ACL rules
- **Purpose**: Entry and exit point for hybrid DNS traffic crossing the VPC boundary (inbound DNS enters VPC via IGW; outbound DNS exits VPC via IGW toward Direct Connect)
- **Failure mode**: IGW issues break inbound and outbound DNS flows; DNS queries time out
- **Circuit breaker**: Not applicable

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| On-premises DNS (snc1, sac1, dub1) | DNS (UDP/TCP 53) | Forwards AWS-domain queries to Inbound Endpoint IPs; receives outbound DNS queries from Outbound Endpoint | `continuumOnPremDns` (stub) |
| Application Subnets | Network placement | Hosts Inbound and Outbound Endpoint ENIs within VPC | `continuumAppSubnets` |
| dns_internal | DNS | Internal DNS dependency as declared in service.yml | `.service.yml` |
| aws-landing-zone / aws_network | Terraform/Network | Infrastructure provisioning and network foundation for endpoint deployment | `.service.yml` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| On-premises DNS servers (snc1, sac1, dub1 colos) | DNS (UDP/TCP 53) | Forward AWS-domain conditional DNS queries to Inbound Endpoint ENI IPs |
| AWS EC2 workloads (all VPCs) | DNS (UDP/TCP 53) | Resolve on-premises domain names via AmazonProvidedDNS which routes through Outbound Endpoint |
| dns-sla-monitor{1,2,3}.{sac1,snc1,dub1} | DNS (UDP/TCP 53) | Latency and availability monitoring of all Route53 Resolver endpoints |

> Upstream consumers are tracked in the central architecture model. Additional consumers may exist that are not visible from this repository.

## Dependency Health

- Monitord/Nagios checks run from `dns-sla-monitor{1,2,3}.{sac1,snc1,dub1}` hosts, querying Route53 Resolver endpoint IPs and measuring latency. These checks cover both Inbound and Outbound flows end-to-end.
- Wavefront alerts are configured for each AZ-level endpoint (see [Runbook](runbook.md) for alert names and links).
- No software-level circuit breakers or retry logic — all resilience is provided by multi-AZ ENI distribution. When one AZ's ENI is unavailable, on-premises DNS stops forwarding to that AZ's IP and continues to the remaining healthy AZs.
