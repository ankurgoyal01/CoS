---
service: "aws-transfer-for-sftp"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for AWS Transfer for SFTP.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [SFTP File Upload to S3](sftp-file-upload.md) | synchronous | SFTP client `put` command | External partner or internal system uploads a file through the SFTP endpoint; the file is stored in the target domain S3 bucket |
| [SFTP File Download from S3](sftp-file-download.md) | synchronous | SFTP client `get` command | Authorised SFTP user downloads a file from their S3 home directory |
| [SFTP to EDW Transfer Flow](sftp-to-edw-flow.md) | synchronous | SFTP client file upload | File transfer from external partner to EDW bucket with full audit trail; modelled as architecture dynamic view |
| [Infrastructure Provisioning](infrastructure-provisioning.md) | batch | Manual Make target invocation | Terraform/Terragrunt provisions or updates SFTP server, IAM roles, and S3 buckets |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

- The SFTP to EDW Transfer Flow is documented as an architecture dynamic view: `dynamic-aws-transfer-sftp-to-edw` (see `structurizr/import/aws-transfer-for-sftp/architecture/views/dynamics/sftp-to-edw-flow.dsl`).
- Downstream EDW data processing flows (consuming files from `continuumAwsTransferEdwBucket`) are owned by the EDW platform and are not documented in this repository.
