---
service: "aws-backups"
title: "Terraform Module Deployment"
generated: "2026-03-03"
type: flow
flow_name: "terraform-module-deployment"
flow_type: batch
trigger: "Manual operator runs make plan then make APPLY from envs/ directory"
participants:
  - "continuumBackupServiceRole"
  - "continuumBackupVault"
  - "continuumGdsBackupVault"
  - "continuumDeadboltBackupVault"
  - "continuumBackupPolicies"
  - "continuumGdsBackupPolicies"
  - "continuumDeadboltBackupPolicies"
  - "awsIamService"
  - "awsBackupApi"
  - "awsKmsApi"
  - "awsSnsApi"
  - "awsOrganizationsControlPlane"
architecture_ref: "dynamic-PolicyAttachmentFlow"
---

# Terraform Module Deployment

## Summary

This flow describes how an Infrastructure Engineering operator deploys or updates the aws-backups Terraform modules to AWS accounts. The operator uses GNU Make targets wrapping Terragrunt to plan and apply infrastructure changes. Modules must be applied in dependency order: service role first, then vaults, then backup policies. All applies are manual — there is no automated CI/CD pipeline.

## Trigger

- **Type**: manual
- **Source**: Infrastructure Engineering operator running `make <account>/<region>/<module>/APPLY` from the `envs/` directory
- **Frequency**: On-demand (when a new account, region, or module configuration change is required)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator (IE Team) | Initiates plan and apply | — |
| Terragrunt + GNU Make | Orchestrates module resolution and Terraform execution | — |
| `continuumBackupServiceRole` | First module applied; creates `grpn-backup-service-role` IAM role | `continuumBackupServiceRole` |
| `continuumGdsBackupVault` or `continuumDeadboltBackupVault` | Second module applied; creates vaults, KMS keys, SNS topics | `continuumGdsBackupVault`, `continuumDeadboltBackupVault` |
| `continuumGdsBackupPolicies` or `continuumDeadboltBackupPolicies` | Third module applied; creates org backup policies in billing account | `continuumGdsBackupPolicies`, `continuumDeadboltBackupPolicies` |
| AWS IAM service | Receives IAM role and policy creation requests | `awsIamService` |
| AWS Backup API | Receives vault, vault policy, vault lock, region opt-in, and vault notification creation requests | `awsBackupApi` |
| AWS KMS | Receives KMS key and alias creation requests | `awsKmsApi` |
| AWS SNS | Receives SNS topic, subscription, and policy creation requests | `awsSnsApi` |
| AWS Organizations control plane | Receives org policy creation and account attachment requests | `awsOrganizationsControlPlane` |

## Steps

1. **Resolve module source**: Operator runs `make grpn-prod/global/backup_service_role/plan`
   - From: Operator shell
   - To: `envs/.terraform-tooling/bin/module-ref` script
   - Protocol: shell script execution; resolves Terraform module source path for `backup_service_role`

2. **Run terraform plan**: Terragrunt executes `terraform plan` with account/region inputs from the HCL hierarchy
   - From: Terragrunt
   - To: AWS IAM API
   - Protocol: AWS SDK; outputs diff of resources to be created/modified/destroyed

3. **Operator reviews plan output**: Operator inspects the plan; confirms expected changes

4. **Apply backup_service_role**: Operator runs `make grpn-prod/global/backup_service_role/APPLY`
   - From: Terragrunt
   - To: `awsIamService`
   - Protocol: AWS SDK; creates `aws_iam_role` (`grpn-backup-service-role`), `aws_iam_policy` (backup and restore custom policies), and `aws_iam_role_policy_attachment` resources

5. **Apply vault module**: Operator runs `make grpn-prod/us-west-2/gds_vault/plan` then `APPLY`
   - From: Terragrunt
   - To: `awsKmsApi` (creates KMS keys and aliases), `awsBackupApi` (creates source and target vaults, vault policies, vault lock if enabled, region opt-in settings), `awsSnsApi` (creates SNS topic, subscription, and vault notification binding)
   - Protocol: AWS SDK
   - Note: Terragrunt declares a dependency on the `backup_service_role` module; apply fails if role does not exist

6. **Apply backup policies module**: Operator runs `make grpn-billing/us-west-2/gds_prod_backup_policies/plan` then `APPLY`
   - From: Terragrunt (using `grpn-all-crossaccount-backup-admin` role in `grpn-billing`)
   - To: `awsOrganizationsControlPlane`
   - Protocol: AWS SDK; creates `aws_organizations_policy` with `BACKUP_POLICY` JSON content, then `aws_organizations_policy_attachment` to bind to source account IDs

7. **Verify application**: Operator uses AWS Console (`grpn-all-general-ro-backup` read-only role) or Wavefront dashboard to confirm vaults are present, policies are attached, and backup region settings are enabled

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| AWS API rate limit exceeded during apply | Terraform retries with exponential backoff | Apply eventually succeeds; no data loss |
| Missing IAM permission for `grpn_all_backup_provisioner` role | Terraform plan fails with access denied error | Operator must request permission update in AWSLandingZone repo; retry after permission update |
| Vault Lock already activated on target vault (WORM) | Terraform cannot destroy or modify vault lock within the lock window | Operator must wait until changeable window expires (30 days for GDS, 60 days for Deadbolt); escalate if urgent |
| Module dependency not yet applied | Terragrunt dependency check fails with missing output error | Apply `backup_service_role` first, then retry vault module |
| Org policy JSON syntax error in `backup_policies` | `aws_organizations_policy` resource fails to create | Fix HCL inputs generating the JSON; run plan again to verify |

## Sequence Diagram

```
Operator -> Terragrunt: make grpn-prod/global/backup_service_role/plan
Terragrunt -> module-ref: resolve module source path
module-ref --> Terragrunt: module source path
Terragrunt -> awsIamService: terraform plan (dry-run)
awsIamService --> Terragrunt: plan output (resources to create)
Operator -> Terragrunt: make grpn-prod/global/backup_service_role/APPLY
Terragrunt -> awsIamService: create aws_iam_role + aws_iam_policy + attachments
awsIamService --> Terragrunt: role ARN confirmed
Operator -> Terragrunt: make grpn-prod/us-west-2/gds_vault/APPLY
Terragrunt -> awsKmsApi: create KMS keys and aliases
Terragrunt -> awsBackupApi: create source + target vaults, vault policies, vault lock, region opt-in
Terragrunt -> awsSnsApi: create SNS topic, subscription, vault notification binding
Operator -> Terragrunt: make grpn-billing/us-west-2/gds_prod_backup_policies/APPLY
Terragrunt -> awsOrganizationsControlPlane: create aws_organizations_policy (BACKUP_POLICY JSON)
Terragrunt -> awsOrganizationsControlPlane: create aws_organizations_policy_attachment to grpn-prod
awsOrganizationsControlPlane --> Terragrunt: policy and attachment confirmed
```

## Related

- Architecture dynamic view: `dynamic-PolicyAttachmentFlow`
- Related flows: [Policy Attachment Flow](policy-attachment.md), [Scheduled Backup Job](scheduled-backup-job.md)
