---
service: "aws-landing-zone"
title: "New Account Baseline Bootstrap"
generated: "2026-03-03"
type: flow
flow_name: "new-account-baseline-bootstrap"
flow_type: event-driven
trigger: "PR merged with new account definition or CloudFormation baseline change"
participants:
  - "continuumLandingZoneCiCd"
  - "continuumLandingZoneCloudFormationBaseline"
  - "awsCloudFormationService"
  - "awsIamService"
architecture_ref: "dynamic-landing-zone-change-flow"
---

# New Account Baseline Bootstrap

## Summary

When a new AWS account is added to the Landing Zone or when baseline CloudFormation templates are updated, this flow runs to ensure every target account has the required baseline stacks deployed. Baseline stacks configure account-type-specific IAM roles, CloudTrail audit logging, and IAM Access Analyzer. The CloudFormation StackSet pattern enables the admin account to push templates to all member accounts via cross-account IAM role assumption.

## Trigger

- **Type**: event (follows from a PR merge) or manual
- **Source**: PR merged to master with changes to `CloudFormationBaseline/Accounts/`; or manual invocation of `CloudformationDeploy.py`
- **Frequency**: On-demand (per baseline change or new account onboarding)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| CI/CD Pipeline | Detects CFN changes, runs deploy script | `continuumLandingZoneCiCd` |
| CloudFormation Baseline | Packages templates and orchestrates StackSet deployment | `continuumLandingZoneCloudFormationBaseline` |
| AWS CloudFormation | Executes StackSet operations in target accounts | `awsCloudFormationService` |
| AWS IAM | Receives baseline roles (Admin, ReadOnly, Okta cross-account, CloudFormation StackSet roles) | `awsIamService` |

## Steps

1. **Prerequisite: Install execution role**: Before any StackSet deployment, the `AWSCloudFormationStackSetExecutionRole` must exist in each target account. This is deployed once per account using `CloudFormationBaseline/Prerequisites/StackSetExecutionRole.yml`, which grants the administrator account full administrative access to execute StackSet operations.
   - From: `continuumLandingZoneCloudFormationBaseline` (`cloudFormationDeployScript`)
   - To: `awsCloudFormationService`
   - Protocol: AWS CloudFormation API

2. **Package templates**: `CloudformationDeploy.py` iterates over the five account types (`Global`, `Billing`, `SAMLAccount`, `SecurityAccount`, `SecurityBase`) and runs `aws cloudformation package` on each `*LZMaster.yaml`, uploading packaged artifacts to S3 bucket `grpn-stackset-admin`.
   - From: `continuumLandingZoneCloudFormationBaseline` (`cloudFormationDeployScript`)
   - To: S3 bucket `grpn-stackset-admin`
   - Protocol: AWS CLI / S3 API

3. **Deploy Global baseline stack**: Deploys `GlobalLZMaster.yaml` — creates IAM roles (Admin, ReadOnly, etc.) via `IAMCFStack.yaml` with `SAMLAccountID=930442592328` and `RoleNamePrefix=Groupon`; enables IAM Access Analyzer via `EnableAnalyzer.yaml`.
   - From: `awsCloudFormationService`
   - To: `awsIamService`
   - Protocol: CloudFormation StackSet

4. **Deploy Billing baseline stack**: Deploys `BillingLZMaster.yaml` — creates billing-specific IAM roles via `MasterBilling-IAM.yaml`; enables IAM Access Analyzer.
   - From: `awsCloudFormationService`
   - To: `awsIamService`
   - Protocol: CloudFormation StackSet

5. **Deploy SAML Account baseline stack**: Deploys `SAMLAccountLZMaster.yaml` — creates SAML-federated roles via `Baseline-SAML-Roles.yaml` with `SAMLArn=arn:aws:iam::930442592328:saml-provider/Groupon-SAML`; enables IAM Access Analyzer.
   - From: `awsCloudFormationService`
   - To: `awsIamService`
   - Protocol: CloudFormation StackSet

6. **Deploy Security Account baseline stack**: Deploys `SecurityAccountLZMaster.yaml` — creates `Groupon-Admin` and `Okta-Idp-cross-account-role` roles via `BaseRole.yaml`; enables multi-region CloudTrail (`GRPNCloudTrail`) with S3 archive bucket `{account_id}-grpn-cloudtrail-logs` and CloudWatch log group `GRPNCloudTrailLogs` (180-day retention) via `EnableTrail.yaml`.
   - From: `awsCloudFormationService`
   - To: `awsIamService`
   - Protocol: CloudFormation StackSet

7. **Deploy SecurityBase stack**: Deploys `SecurityBaseLZMaster.yaml` — enables IAM Access Analyzer via `Enable-IAM-analyzer.yaml` against security account ID `274116055752`.
   - From: `awsCloudFormationService`
   - To: `awsIamService`
   - Protocol: CloudFormation StackSet

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing `AWSCloudFormationStackSetExecutionRole` in target account | Stack operation fails with access denied | Manual deployment of `StackSetExecutionRole.yml` to target account before retrying |
| cfn-lint validation failure in PR | PR pipeline fails | Engineer fixes lint errors; re-pushes |
| S3 upload fails for `grpn-stackset-admin` | `cloudformation package` command fails | Build fails; engineer checks S3 permissions and retries |
| StackSet deployment failure in a member account | CloudFormation console shows stack operation failure | Manual remediation via AWS console; re-run deploy script |

## Sequence Diagram

```
CI/CD Pipeline -> CloudFormation Baseline: Trigger deploy script
CloudFormation Baseline -> S3 (grpn-stackset-admin): Package and upload templates (5 account types)
CloudFormation Baseline -> AWS CloudFormation: Deploy GlobalLZMaster StackSet
AWS CloudFormation -> AWS IAM: Create Groupon-Admin, Groupon-ReadOnly roles
AWS CloudFormation -> AWS IAM: Enable IAM Access Analyzer
CloudFormation Baseline -> AWS CloudFormation: Deploy BillingLZMaster StackSet
CloudFormation Baseline -> AWS CloudFormation: Deploy SAMLAccountLZMaster StackSet
AWS CloudFormation -> AWS IAM: Create SAML-federated roles
CloudFormation Baseline -> AWS CloudFormation: Deploy SecurityAccountLZMaster StackSet
AWS CloudFormation -> AWS IAM: Create Groupon-Admin, Okta-Idp-cross-account-role
AWS CloudFormation -> AWS CloudTrail: Enable GRPNCloudTrail (multi-region)
CloudFormation Baseline -> AWS CloudFormation: Deploy SecurityBaseLZMaster StackSet
AWS CloudFormation -> AWS IAM: Enable IAM Access Analyzer
```

## Related

- Architecture dynamic view: `dynamic-landing-zone-change-flow`
- Related flows: [Landing Zone Change Deployment](landing-zone-change-deployment.md), [IAM Role Provisioning](iam-role-provisioning.md)
