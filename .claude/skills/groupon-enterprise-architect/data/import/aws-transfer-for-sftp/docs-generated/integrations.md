---
service: "aws-transfer-for-sftp"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 4
internal_count: 0
---

# Integrations

## Overview

AWS Transfer for SFTP depends on four AWS managed services: AWS Transfer Family (the SFTP endpoint itself), Amazon S3 (seven data buckets plus one logging bucket), AWS IAM (role and policy management), and Amazon Route 53 (DNS resolution for the SFTP endpoint). There are no internal Groupon service-to-service HTTP or gRPC dependencies. Upstream consumers are external partners and internal Groupon business units that connect over SFTP.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| AWS Transfer Family | AWS SDK / managed | Managed SFTP endpoint provisioning | yes | `continuumAwsTransferSftpServer` |
| Amazon S3 | S3 API (SFTP/S3 bridge) | Data storage for all transferred files; access log aggregation | yes | `continuumAwsTransferEdwBucket`, `continuumAwsTransferCdeBucket`, `continuumAwsTransferCloDistributionBucket`, `continuumAwsTransferGoodsBucket`, `continuumAwsTransferInfosecBucket`, `continuumAwsTransferAugeovoucherBucket`, `continuumAwsTransferSachinBucket`, `continuumAwsTransferLoggingBucket` |
| AWS IAM | AWS IAM API | Server logging role, per-bucket SFTP user roles, scope-down policies | yes | `awsTransfer_serverLoggingRole`, `awsTransfer_edwBucketSftpUserRole` |
| Amazon CloudWatch Logs | CloudWatch Logs API | SFTP session, authentication, and activity log ingestion | yes | `continuumAwsTransferCloudWatchLogs` |

### AWS Transfer Family Detail

- **Protocol**: AWS managed service; Terraform `aws_transfer_server` resource
- **Base URL / SDK**: Terraform AWS provider (`resource "aws_transfer_server"`)
- **Auth**: `SERVICE_MANAGED` identity provider; SSH keys managed per SFTP user
- **Purpose**: Hosts the managed SFTP endpoint that bridges SSH-based file transfer to S3 object storage
- **Failure mode**: If AWS Transfer Family is unavailable, SFTP clients cannot connect; files cannot be uploaded or downloaded
- **Circuit breaker**: Not applicable (managed service)

### Amazon S3 Detail

- **Protocol**: S3 API (used transparently by AWS Transfer Family); direct S3 API for logging bucket
- **Base URL / SDK**: Terraform AWS provider (`resource "aws_s3_bucket"`)
- **Auth**: IAM roles with per-bucket scope-down policies; `transfer.amazonaws.com` service principal
- **Purpose**: Persistent storage for all SFTP file transfers (seven domain buckets) and aggregated access logs (one logging bucket)
- **Failure mode**: If S3 is unavailable, all file transfers fail; logged to CloudWatch Logs
- **Circuit breaker**: Not applicable (managed service)

### AWS IAM Detail

- **Protocol**: IAM API
- **Base URL / SDK**: Terraform AWS provider (`resource "aws_iam_role"`, `resource "aws_iam_role_policy"`, `resource "aws_iam_policy"`)
- **Auth**: Terraform applies changes using AWS credentials (profile-based via `AWS_PROFILE`)
- **Purpose**: Creates and manages `groupon-transfer-server-iam-role` (CloudWatch logging), per-bucket user roles (`groupon-transfer-user-iam-role-<bucket>`), and scope-down policies restricting each SFTP user to their home directory
- **Failure mode**: If IAM is unavailable during infrastructure apply, Terraform apply fails; runtime file transfers already in progress continue until session expiry
- **Circuit breaker**: Not applicable

### Amazon CloudWatch Logs Detail

- **Protocol**: CloudWatch Logs API (`logs:CreateLogStream`, `logs:DescribeLogStreams`, `logs:CreateLogGroup`, `logs:PutLogEvents`)
- **Base URL / SDK**: Terraform `aws_cloudwatch_log_group` resource; AWS Transfer Family native integration
- **Auth**: `groupon-transfer-server-iam-role` / `groupon-transfer-server-iam-policy`
- **Purpose**: Receives SFTP session and authentication events from the Transfer server; log group `/aws/transfer/<server-id>` retained for 365 days in production
- **Failure mode**: SFTP transfers continue if CloudWatch Logs is temporarily unavailable; log events may be dropped
- **Circuit breaker**: Not applicable

## Internal Dependencies

> No evidence found in codebase. AWS Transfer for SFTP has no internal Groupon service-to-service dependencies. It depends exclusively on AWS managed services.

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| External partners (EDW, CDE, CLO, Goods, InfoSec, Augeovoucher, Sachin) | SFTP (SSH port 22) | Upload and download files via the managed SFTP endpoint |
| Wavefront monitoring | Dashboard / CloudWatch metrics | Visualise transfer activity (`https://groupon.wavefront.com/dashboard/AWS-Transfer`) |

> Upstream SFTP consumers are tracked in the Confluence owners manual and the Gears/ORR documents referenced in `.service.yml`.

## Dependency Health

> AWS managed services (Transfer Family, S3, IAM, CloudWatch Logs) are monitored via the AWS Service Health Dashboard. No application-level health check, retry, or circuit breaker pattern is implemented in this repository. Operational alerts route to `infosec-aws-transfer-service@groupon.pagerduty.com` (PagerDuty service `PLY1VT8`).
