---
service: "netops_awsinfra"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for AWS Network (netops_awsinfra).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Transit Gateway Provisioning](transit-gateway-provisioning.md) | batch | Manual engineer action | Creates a new Transit Gateway in a region, registers it with Network Manager, and creates a RAM share |
| [Account TGW Onboarding](account-tgw-onboarding.md) | batch | Manual engineer action | Shares a TGW to a new workload account and creates the VPC attachment on the consumer side |
| [Direct Connect Provisioning](direct-connect-provisioning.md) | batch | Manual engineer action | Provisions a Direct Connect connection, creates a DCG, creates virtual interfaces, and associates DCG with TGW |
| [Cross-Region TGW Peering](cross-region-tgw-peering.md) | batch | Manual engineer action | Creates and accepts cross-region TGW peering attachments and configures routing via managed prefix lists |
| [DNS Infrastructure Provisioning](dns-infrastructure-provisioning.md) | batch | Manual engineer action | Deploys legacy DNS EC2 instances, ALB, and Route53 records, or deploys external DNS Terragrunt stack |
| [CloudWatch Dashboard Deployment](cloudwatch-dashboard-deployment.md) | batch | Manual engineer action | Provisions TGW and Direct Connect CloudWatch dashboards for observability |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled (IaC apply) | 6 |

## Cross-Service Flows

All flows in this repository result in infrastructure changes that affect connectivity for all downstream Groupon AWS accounts. The Transit Gateway and Direct Connect infrastructure provisioned here underpins network reachability for services in `grpn-prod`, `grpn-stable`, `grpn-edw-prod`, `grpn-logging-prod`, and 20+ additional accounts. Cross-account dependency ordering is managed by Terragrunt and the file-based `tgw_data.yml` handoff pattern.
