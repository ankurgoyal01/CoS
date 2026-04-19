---
service: "aws-landing-zone"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for AWS Landing Zone.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Landing Zone Change Deployment](landing-zone-change-deployment.md) | event-driven | GitHub merge event to master | Full pipeline: PR merged, Jenkins validates and applies Terraform/CloudFormation changes across target AWS accounts |
| [New Account Baseline Bootstrap](new-account-baseline-bootstrap.md) | manual | Engineer submits PR with new account definition | Provisions a new AWS account with CloudFormation baseline stacks, IAM roles, CloudTrail, and IAM Access Analyzer |
| [IAM Role Provisioning](iam-role-provisioning.md) | event-driven | PR merged with IAM module change | Terraform applies new or updated IAM role/policy definitions to target accounts |
| [Cloud Custodian Governance Remediation](custodian-governance-remediation.md) | event-driven / manual | CloudTrail event (Lambda mode) or manual `custodian run` | Detects and remediates policy drift (IAM key deactivation, S3 public access removal, security group remediation) |
| [Infrastructure Audit](infrastructure-audit.md) | manual | Engineer runs audit script | Scans all accounts for IAM users, role assignments, access key ages, and unauthorized account IDs |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 3 |
| Batch / Scheduled | 0 |
| Manual / On-demand | 2 |

## Cross-Service Flows

The Landing Zone Change Deployment flow is the primary cross-service flow, spanning GitHub Enterprise, Jenkins, and multiple AWS control planes (Organizations, IAM, Route 53, CloudFormation). It is documented in the architecture dynamic view `dynamic-landing-zone-change-flow`.

All consumer services that deploy to AWS interact with Landing Zone outputs (VPCs, IAM roles) but do not trigger Landing Zone flows directly.
