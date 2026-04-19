---
service: "aws-dns"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Infrastructure / DNS"
platform: "AWS (Hybrid)"
team: "Infrastructure Engineering"
status: active
tech_stack:
  language: "N/A"
  language_version: "N/A"
  framework: "AWS Route53 Resolver"
  framework_version: "AWS managed"
  runtime: "AWS managed service"
  runtime_version: "N/A"
  build_tool: "Terraform"
  package_manager: "N/A"
---

# AWS DNS Overview

## Purpose

AWS DNS provides hybrid DNS resolution for Groupon's infrastructure, bridging on-premises data centres and AWS VPCs using AWS Route53 Resolver. It manages both inbound DNS queries (on-prem hosts resolving AWS-hosted domain names) and outbound DNS queries (AWS workloads resolving on-prem domain names). The service replaces a previous home-grown Bind + Dnsdist solution running on EC2 instances, eliminating instance management overhead by leveraging AWS-managed Route53 Resolver endpoints.

## Scope

### In scope

- Inbound DNS resolution: forwarding DNS queries originating from on-premises to AWS Route53 Private Hosted Zones via Route53 Resolver Inbound Endpoints.
- Outbound DNS resolution: forwarding DNS queries originating from AWS VPC workloads to on-premises DNS servers via Route53 Resolver Outbound Endpoints.
- Multi-AZ Elastic Network Interface (ENI) deployment per VPC for high availability.
- Per-VPC Inbound and Outbound endpoint lifecycle management via Terraform (AWSLandingZone).
- Conditional forwarding configuration on-premises (on-prem DNS forwards AWS domain queries to Inbound Endpoint IPs).
- Outbound catch-all rule forwarding from AmazonProvidedDNS to on-premises DNS VIPs.
- Monitoring DNS resolution latency from on-premises colos (sac1, snc1, dub1) via Nagios/Monitord checks.

### Out of scope

- Public external DNS management (e.g., Groupon.com public zones — handled by external Route53 public hosted zones).
- On-premises internal DNS server configuration (managed separately by the ns_config repo).
- VPC-internal service discovery (handled by Route53 private hosted zones and AmazonProvidedDNS natively).
- SSL/TLS certificate management.

## Domain Context

- **Business domain**: Infrastructure / DNS
- **Platform**: AWS (Hybrid on-premises + AWS)
- **Upstream consumers**: On-premises DNS servers (snc1, sac1, dub1 colos), AWS EC2 workloads within VPCs, dns-sla-monitor hosts
- **Downstream dependencies**: AmazonProvidedDNS (.2 Resolver IP), Route53 Private Hosted Zones, on-premises DNS VIPs, AWS Direct Connect, VPC Internet Gateway

## Stakeholders

| Role | Description |
|------|-------------|
| Service Owner | blopulisa (Infrastructure Engineering) |
| Team Members | basingh, blopulisa |
| Team | Infrastructure Engineering (infrastructure-engineering@groupon.com) |
| On-call | dns@groupon.pagerduty.com, #cloud-sre-support Slack |
| Mailing List | infrastructure-engineering@groupon.com |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Infrastructure-as-Code | Terraform | N/A (AWSLandingZone repo) | `docs/OwnersManual.md`, `docs/OwnersManualNew.md` |
| DNS Resolver | AWS Route53 Resolver | AWS managed | `docs/architechture.md` |
| Network Interface | AWS ENI (Elastic Network Interface) | AWS managed | `docs/architechture.md` |
| Compute (legacy, replaced) | AWS EC2 m4.large | N/A | `docs/OwnersManual.md` |

### Key Libraries

> Not applicable. AWS DNS is a managed infrastructure service with no application code. Configuration is managed via Terraform in the AWSLandingZone repository.
