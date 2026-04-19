---
service: "aws-backups"
title: "Policy Attachment"
generated: "2026-03-03"
type: flow
flow_name: "policy-attachment"
flow_type: batch
trigger: "Manual operator Terraform apply in grpn-billing management account"
participants:
  - "continuumBackupPolicies"
  - "continuumGdsBackupPolicies"
  - "continuumDeadboltBackupPolicies"
  - "continuumBackupServiceRole"
  - "continuumGdsBackupVault"
  - "continuumDeadboltBackupVault"
  - "awsOrganizationsControlPlane"
architecture_ref: "dynamic-PolicyAttachmentFlow"
---

# Policy Attachment

## Summary

This flow describes how AWS Organizations backup policies are generated and attached to source accounts via the `grpn-billing` management account. Backup policy modules (`backup_policies`, `gds_backup_policies`, `deadbolt_backup_policies`) build `BACKUP_POLICY` JSON documents from Terragrunt input variables, create `aws_organizations_policy` resources in `grpn-billing`, and then attach them to specific source account IDs. Once attached, AWS Organizations propagates the policy down to the member accounts, where it takes effect as an active AWS Backup plan.

## Trigger

- **Type**: manual (Terraform apply)
- **Source**: Operator running `make grpn-billing/<region>/<policy_module>/APPLY`
- **Frequency**: On-demand — when backup schedules, lifecycle rules, selection tags, source/target accounts, or vault ARNs change

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `continuumGdsBackupPolicies` | Builds and applies GDS org backup policy; references copytarget vault ARN and service role ARN | `continuumGdsBackupPolicies` |
| `continuumDeadboltBackupPolicies` | Builds and applies Deadbolt org backup policy; references target vault ARN and service role ARN | `continuumDeadboltBackupPolicies` |
| `continuumBackupPolicies` | Builds and applies generic org backup policy | `continuumBackupPolicies` |
| `continuumBackupServiceRole` | Provides `grpn-backup-service-role` ARN embedded in backup plan selection | `continuumBackupServiceRole` |
| `continuumGdsBackupVault` | Provides GDS copytarget vault ARN for `copy_actions` in GDS policy | `continuumGdsBackupVault` |
| `continuumDeadboltBackupVault` | Provides Deadbolt target vault ARN for `copy_actions` in Deadbolt policy | `continuumDeadboltBackupVault` |
| AWS Organizations control plane | Receives and stores `BACKUP_POLICY` objects; distributes them to member accounts | `awsOrganizationsControlPlane` |

## Steps

1. **Build BACKUP_POLICY JSON**: Policy Template Builder component generates the `BACKUP_POLICY` document from Terragrunt input variables
   - From: HCL templatefile / heredoc in Terraform module
   - To: `aws_organizations_policy` resource definition
   - Inputs: `vault_name`, `backup_target_account`, `backup_target_region` (if cross-region), `backup_rules_schedule_expression`, lifecycle days, `backup_selections_tags_key`, `backup_selections_tags_value`, `grpn-backup-service-role` ARN

2. **Create Organizations Policy**: Terraform creates `aws_organizations_policy` resource (type `BACKUP_POLICY`) in the `grpn-billing` management account
   - From: `continuumGdsBackupPolicies` (or `continuumDeadboltBackupPolicies`)
   - To: `awsOrganizationsControlPlane`
   - Protocol: AWS SDK (Terraform provider)
   - Note: Terraform uses the `grpn-all-crossaccount-backup-admin` IAM role to manage policies in the management account

3. **Attach policy to source accounts**: Terraform creates `aws_organizations_policy_attachment` resources, binding the policy to each configured source account ID
   - From: `continuumGdsBackupPolicies` (or `continuumDeadboltBackupPolicies`)
   - To: `awsOrganizationsControlPlane`
   - Protocol: AWS SDK
   - GDS prod example: attaches to account `497256801702` (`grpn-prod`)
   - Deadbolt prod example: attaches to account `274116055752` (`grpn-security-prod`)

4. **AWS Organizations propagates policy**: AWS Organizations asynchronously propagates the attached backup policy to the member account, where it becomes an active AWS Backup plan
   - From: `awsOrganizationsControlPlane`
   - To: Member account AWS Backup service
   - Protocol: AWS internal (Organizations policy distribution)

5. **AWS Backup registers backup plan**: The AWS Backup service in the source account reads the propagated policy and registers it as an active backup plan, ready to execute on the configured schedule

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid `BACKUP_POLICY` JSON syntax | `aws_organizations_policy` resource fails to create with API validation error | Fix HCL input variables; re-run plan and apply |
| Source account ID does not exist in org | `aws_organizations_policy_attachment` fails with not-found error | Verify account ID in `backup_source_accounts` Terragrunt input |
| `grpn-all-crossaccount-backup-admin` role has insufficient permissions | Terraform apply fails with access denied | Update role permissions in AWSLandingZone repo; retry |
| Policy already at maximum for account | Organizations API returns limit exceeded | Review and consolidate policies; contact AWS support if needed |

## Sequence Diagram

```
Operator -> Terragrunt: make grpn-billing/us-west-2/gds_prod_backup_policies/APPLY
Terragrunt -> GdsPolicyTemplateBuilder: render BACKUP_POLICY JSON (schedule, lifecycle, tags, vault ARN, role ARN)
GdsPolicyTemplateBuilder --> Terragrunt: BACKUP_POLICY JSON document
Terragrunt -> awsOrganizationsControlPlane: CreatePolicy (type=BACKUP_POLICY, content=JSON)
awsOrganizationsControlPlane --> Terragrunt: policy_id
Terragrunt -> awsOrganizationsControlPlane: AttachPolicy (policy_id, target=497256801702 grpn-prod)
awsOrganizationsControlPlane --> Terragrunt: attachment confirmed
awsOrganizationsControlPlane -> grpn-prod AWS Backup: propagate backup policy
grpn-prod AWS Backup --> awsOrganizationsControlPlane: policy applied as active backup plan
```

## Related

- Architecture dynamic view: `dynamic-PolicyAttachmentFlow`
- Related flows: [Terraform Module Deployment](terraform-module-deployment.md), [Scheduled Backup Job](scheduled-backup-job.md)
