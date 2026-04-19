---
service: "aws-transfer-for-sftp"
title: "Infrastructure Provisioning"
generated: "2026-03-03"
type: flow
flow_name: "infrastructure-provisioning"
flow_type: batch
trigger: "Operator invokes a Make target (e.g., make production/us-west-2/APPLY) to provision or update infrastructure"
participants:
  - "continuumAwsTransferSftpServer"
  - "continuumAwsTransferEdwBucket"
  - "continuumAwsTransferLoggingBucket"
  - "continuumAwsTransferCloudWatchLogs"
architecture_ref: "components-continuum-aws-transfer-sftp-server"
---

# Infrastructure Provisioning

## Summary

The infrastructure provisioning flow describes how Terraform and Terragrunt create or update the AWS Transfer for SFTP infrastructure stack across environments. An operator runs a Make target that triggers Terragrunt to resolve module dependencies, plan changes, and apply them in the correct order: logging bucket first, then data buckets, then the SFTP server. All Terraform state is stored remotely in S3 with DynamoDB locking to prevent concurrent modifications.

## Trigger

- **Type**: manual
- **Source**: Operator executing `make <environment>/us-west-2/APPLY` (or `plan`, `validate`) from the `envs/` directory
- **Frequency**: On demand; when infrastructure changes are needed (new bucket, IAM policy update, retention change, etc.)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator | Executes Make targets; holds AWS credentials via `AWS_PROFILE` | (external actor) |
| Terragrunt (0.18.3) | Resolves module dependency graph; invokes Terraform per module | (tooling) |
| Terraform AWS provider | Provisions `aws_transfer_server`, `aws_s3_bucket`, `aws_iam_role`, `aws_cloudwatch_log_group` resources | (tooling) |
| S3 State Bucket | Stores Terraform remote state (`grpn-InfoSec::AWSTransferForSFTP-state-{account_id}`) | (AWS managed) |
| DynamoDB Lock Table | Prevents concurrent Terraform applies (`grpn-InfoSec::AWSTransferForSFTP-lock-table-{account_id}`) | (AWS managed) |
| AWS Transfer SFTP Server | Target resource: SFTP endpoint + IAM logging role + CloudWatch log group | `continuumAwsTransferSftpServer` |
| SFTP Access Logging Bucket | Target resource: centralised S3 access logging bucket | `continuumAwsTransferLoggingBucket` |
| Domain S3 Buckets | Target resources: per-team data buckets + IAM roles/policies | `continuumAwsTransferEdwBucket`, `continuumAwsTransferCdeBucket`, etc. |

## Steps

1. **Set Environment**: Operator sets `AWS_PROFILE` (AWS credentials) and `TF_VAR_PROJECTNAME=InfoSec::AWSTransferForSFTP` environment variables.
   - From: Operator workstation
   - To: Shell environment
   - Protocol: Shell variable assignment

2. **Invoke Make Target**: Operator runs `make <env>/us-west-2/APPLY` from the `envs/` directory.
   - From: Operator
   - To: Makefile (`envs/Makefile`)
   - Protocol: Make

3. **Resolve Module Dependencies**: Terragrunt reads the dependency graph from `terraform.tfvars` files and determines execution order: `s3logging` -> `s3storage` -> `Server`.
   - From: Terragrunt
   - To: Module `terraform.tfvars` files
   - Protocol: Terragrunt dependency resolution

4. **Acquire Remote State Lock**: Terraform acquires a lock on the DynamoDB lock table before modifying any module.
   - From: Terraform
   - To: DynamoDB (`grpn-InfoSec::AWSTransferForSFTP-lock-table-{account_id}`)
   - Protocol: AWS DynamoDB API

5. **Apply s3logging Module**: Terraform creates or updates the centralised logging bucket (`{env}-groupon-transfer-s3-bucket-log`) with AES-256 encryption, `log-delivery-write` ACL, 365-day lifecycle, and public access blocking.
   - From: Terraform
   - To: Amazon S3 (`continuumAwsTransferLoggingBucket`)
   - Protocol: AWS S3 API

6. **Apply s3storage Module**: Terraform creates or updates all domain data buckets (EDW, CDE, CLO Distribution, Goods, InfoSec, Augeovoucher, Sachin) with AES-256 encryption, versioning, lifecycle rules, access logging to the logging bucket, public access blocking, and per-bucket IAM user roles and scope-down policies.
   - From: Terraform
   - To: Amazon S3, AWS IAM (`continuumAwsTransferEdwBucket` etc.)
   - Protocol: AWS S3 API, AWS IAM API

7. **Apply Server Module**: Terraform creates or updates the `aws_transfer_server` (identity provider: `SERVICE_MANAGED`), attaches `groupon-transfer-server-iam-role`, and creates the CloudWatch log group `/aws/transfer/{server-id}` with 365-day retention.
   - From: Terraform
   - To: AWS Transfer Family, AWS IAM, Amazon CloudWatch Logs (`continuumAwsTransferSftpServer`, `continuumAwsTransferCloudWatchLogs`)
   - Protocol: AWS Transfer Family API, IAM API, CloudWatch Logs API

8. **Write State to S3**: After each module apply, Terraform writes the updated state file to S3 (`grpn-InfoSec::AWSTransferForSFTP-state-{account_id}/path/terraform.tfstate`, encrypted).
   - From: Terraform
   - To: S3 state bucket
   - Protocol: AWS S3 API

9. **Release Lock**: Terraform releases the DynamoDB lock.
   - From: Terraform
   - To: DynamoDB
   - Protocol: AWS DynamoDB API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| DynamoDB lock already held | Terraform waits and retries; fails after timeout | Apply blocked until lock is released; operator must investigate stale lock |
| IAM permission denied during apply | Terraform fails the apply with error | Resources partially applied; operator must fix IAM permissions and re-apply |
| S3 state write failure | Terraform reports error; state may be stale | Operator must reconcile state before next apply (`terraform state pull/push`) |
| Module dependency failure | Terragrunt aborts downstream modules | Only the failed module and its dependants are not applied |

## Sequence Diagram

```
Operator -> Makefile: make production/us-west-2/APPLY
Makefile -> Terragrunt: terragrunt apply-all envs/production/us-west-2
Terragrunt -> DynamoDB: Acquire state lock
DynamoDB --> Terragrunt: Lock acquired
Terragrunt -> Terraform (s3logging): apply
Terraform (s3logging) -> Amazon S3: Create/update logging bucket
Terraform (s3logging) -> S3 State Bucket: Write state
Terragrunt -> Terraform (s3storage): apply (after s3logging succeeds)
Terraform (s3storage) -> Amazon S3: Create/update domain buckets
Terraform (s3storage) -> AWS IAM: Create/update user roles and policies
Terraform (s3storage) -> S3 State Bucket: Write state
Terragrunt -> Terraform (Server): apply (after s3storage succeeds)
Terraform (Server) -> AWS Transfer Family: Create/update aws_transfer_server
Terraform (Server) -> AWS IAM: Create/update server logging role and policy
Terraform (Server) -> CloudWatch Logs: Create log group with 365-day retention
Terraform (Server) -> S3 State Bucket: Write state
Terragrunt -> DynamoDB: Release lock
Terragrunt --> Operator: Apply complete
```

## Related

- Architecture component view: `components-continuum-aws-transfer-sftp-server`
- Related flows: [SFTP File Upload to S3](sftp-file-upload.md)
- Deployment documentation: [Deployment](../deployment.md)
- Configuration documentation: [Configuration](../configuration.md)
