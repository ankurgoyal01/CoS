---
service: "aws-dns"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "aws-managed"
environments: ["production-us-west-2", "production-us-west-1", "production-eu-west-1"]
---

# Deployment

## Overview

AWS DNS is not a containerized or Kubernetes-managed service. It is an AWS-managed infrastructure deployment provisioned via Terraform. Route53 Resolver Inbound and Outbound Endpoints are created per VPC per region, with ENIs distributed across Availability Zones in application subnets. The Terraform modules are hosted in the AWSLandingZone repository. Deployment follows a blue-green pattern where inactive server pools are upgraded, tested, and then activated by switching Elastic Network Interfaces.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | Not containerized; AWS-managed service |
| Orchestration | AWS Route53 Resolver (managed) | ENIs per AZ per VPC, managed by AWS |
| Provisioning | Terraform | `AWSLandingZone/terraform/modules/dns_infrastructure/` |
| Network interfaces | AWS ENI (Elastic Network Interface) | One ENI per AZ for both Inbound and Outbound endpoints |
| Subnets | AWS VPC Application Subnets | Inbound and Outbound endpoints deployed into app subnets |
| Legacy compute | AWS EC2 m4.large | Used for legacy Bind + Dnsdist instances (pre-Route53 Resolver) |
| Load balancer | None (DNS round-robin via multiple ENI IPs) | On-prem DNS configured with all Inbound ENI IPs; AZ-aware routing for Outbound |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| production-us-west-2 | Primary US production DNS | us-west-2 (3 AZs) | ENI IPs configured in on-prem conditional forwarders |
| production-us-west-1 | Secondary US production DNS | us-west-1 (2 AZs) | ENI IPs configured in on-prem conditional forwarders |
| production-eu-west-1 | EMEA production DNS | eu-west-1 (3 AZs) | ENI IPs configured in on-prem conditional forwarders |

## CI/CD Pipeline

- **Tool**: Manual Terraform deployment via AWSLandingZone repository
- **Config**: `AWSLandingZone/terraform/modules/dns_infrastructure/`
- **Trigger**: Manual — changes require a Logbook Ticket and follow the Groupon Change Policy before deployment

### Pipeline Stages

1. **Plan**: Run `terraform plan` to preview infrastructure changes to Inbound/Outbound endpoint resources
2. **Review**: Engineer reviews plan output and creates a Logbook Ticket per Change Policy
3. **Apply (Inactive)**: Run `terraform apply` targeting the inactive (green) server pool or endpoint configuration
4. **Validate**: Test the inactive endpoints using `dig @<new-instance-ip> config.snc1` or equivalent DNS lookup from a remote host
5. **Switch ENI**: Switch ENIs to activate the updated endpoints (makes green active, blue inactive)
6. **Apply (Formerly Active)**: Repeat Terraform apply on the now-inactive (blue) pool to bring it to the same configuration

### Rollback

Revert changes to the master branch of AWSLandingZone and re-run Terraform apply. ENI switching can reactivate the previous configuration without full reprovisioning.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (Inbound) | Manual — increment ENI count per AZ in Terraform | `count` in Inbound route53_resolver resource block |
| Horizontal (Outbound) | Manual — increment ENI count per AZ in Terraform | `count` in Outbound route53_resolver resource block |
| Vertical (legacy EC2) | Manual instance type upgrade via Terraform | `instance_type` in `instances.tf` (m4.large default) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| Route53 Resolver Inbound ENI | 1 per AZ (minimum) | AWS quota |
| Route53 Resolver Outbound ENI | 1 per AZ (minimum) | AWS quota |
| Throughput per ENI IP | N/A | 10,000 DNS queries/second per ENI IP (AWS limit) |

> Deployment configuration is managed in the AWSLandingZone repository (`github.groupondev.com/production-fabric/AWSLandingZone`), not this repository.
