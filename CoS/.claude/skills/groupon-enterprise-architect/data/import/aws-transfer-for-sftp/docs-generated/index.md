---
service: "aws-transfer-for-sftp"
title: "AWS Transfer for SFTP Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumAwsTransferSftpServer"
    - "continuumAwsTransferEdwBucket"
    - "continuumAwsTransferCdeBucket"
    - "continuumAwsTransferCloDistributionBucket"
    - "continuumAwsTransferGoodsBucket"
    - "continuumAwsTransferInfosecBucket"
    - "continuumAwsTransferAugeovoucherBucket"
    - "continuumAwsTransferSachinBucket"
    - "continuumAwsTransferLoggingBucket"
    - "continuumAwsTransferCloudWatchLogs"
tech_stack:
  language: "HCL (Terraform)"
  framework: "Terragrunt 0.18.3"
  runtime: "AWS Transfer Family (managed)"
---

# AWS Transfer for SFTP Documentation

AWS managed SFTP service providing secure file exchange between Groupon internal systems and external partners, backed by per-team S3 buckets with AES-256 encryption, versioning, lifecycle policies, and CloudWatch audit logging.

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
| Language | HCL (Terraform) |
| Framework | Terragrunt 0.18.3 |
| Runtime | AWS Transfer Family (managed service) |
| Build tool | Make + Terragrunt |
| Platform | Continuum / AWS |
| Domain | Security / InfoSec |
| Team | InfoSec (owner: sbhatt) |
