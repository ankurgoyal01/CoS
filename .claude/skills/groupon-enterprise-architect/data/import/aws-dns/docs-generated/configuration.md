---
service: "aws-dns"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["terraform", "on-prem-dns-config"]
---

# Configuration

## Overview

AWS DNS is a managed infrastructure service with no application-level configuration files or environment variables. All configuration is expressed as Terraform infrastructure-as-code in the AWSLandingZone repository (`terraform/modules/dns_infrastructure/`). The key configuration objects are Route53 Resolver endpoint resources (Inbound and Outbound), ENI count per AZ, forwarding rules, and on-premises DNS conditional forwarding configuration (managed in the ns_config repository).

## Environment Variables

> No evidence found in codebase. AWS DNS is a managed infrastructure service and does not run application code with environment variables.

## Feature Flags

> No evidence found in codebase. No feature flags are used by this service.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `terraform/modules/dns_infrastructure/servers/instances.tf` | HCL (Terraform) | EC2 instance type configuration for legacy Bind+Dnsdist setup; used when scaling up capacity |
| `terraform/modules/dns_infrastructure/README.md` | Markdown | Deployment instructions and Terraform resource documentation |
| `src/config/templates/conditional.forwarders.erb` (ns_config repo) | ERB template | On-premises DNS conditional forwarding rules that point to Inbound Endpoint ENI IPs |

> Note: The Terraform module is located in the AWSLandingZone repository (`github.groupondev.com/production-fabric/AWSLandingZone`), not this repository. This repository is the documentation and architecture model repository for the aws-dns service.

## Secrets

> No evidence found in codebase. AWS DNS endpoints are managed by IAM roles and VPC security groups. No application-level secrets or API keys are required.

## Per-Environment Overrides

- **Production (AWS us-west-2)**: Three AZs (AZ1, AZ2, AZ3), one Inbound Endpoint with 3 ENIs, one Outbound Endpoint with 3 ENIs. Monitored from sac1 and snc1 colos.
- **Production (AWS us-west-1)**: Two AZs (AZ1, AZ2) with corresponding Inbound and Outbound endpoints. Monitored from sac1 and snc1 colos.
- **Production (AWS eu-west-1)**: Three AZs (AZ1, AZ2, AZ3) with corresponding Inbound and Outbound endpoints. Monitored from dub1 colo.
- Route53 Resolver is region-specific, so separate Inbound and Outbound endpoints are launched and maintained per VPC per region.

### Scaling Configuration

| Component | Terraform Parameter | Current Value | Notes |
|-----------|-------------------|---------------|-------|
| Inbound Endpoint ENI count per AZ | `count` in route53_resolver Inbound resource block | 1 (per AZ) | Increment to add capacity |
| Outbound Endpoint ENI count per AZ | `count` in route53_resolver Outbound resource block | 1 (per AZ) | Increment to add capacity |
| EC2 instance type (legacy) | `instance_type` in `instances.tf` | m4.large | Increase for legacy Bind/Dnsdist scaling |
