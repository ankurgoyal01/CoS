---
service: "aws-landing-zone"
title: "Landing Zone Change Deployment"
generated: "2026-03-03"
type: flow
flow_name: "landing-zone-change-deployment"
flow_type: event-driven
trigger: "GitHub merge event to master branch"
participants:
  - "githubEnterprise"
  - "continuumLandingZoneCiCd"
  - "continuumLandingZoneTerraform"
  - "continuumLandingZoneCloudFormationBaseline"
  - "continuumLandingZoneCloudCustodian"
  - "awsOrganizationsControlPlane"
  - "awsIamService"
  - "awsRoute53Service"
  - "awsCloudFormationService"
architecture_ref: "dynamic-landing-zone-change-flow"
---

# Landing Zone Change Deployment

## Summary

This is the primary delivery flow for all AWS infrastructure changes managed by the Landing Zone. When a pull request is merged to the master branch, GitHub Enterprise sends a webhook event to Jenkins, which validates the changes and applies them to the appropriate AWS accounts. Sandbox and dev accounts receive automatic applies; stable and production accounts require manual pipeline dispatch with environment selection.

## Trigger

- **Type**: event
- **Source**: GitHub Enterprise webhook — merge commit pushed to `master` branch of `production-fabric/AWSLandingZone`
- **Frequency**: On-demand (per PR merge); also triggered manually from Jenkins UI for stable/prod environments

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GitHub Enterprise | Sends merge event webhook | `githubEnterprise` |
| CI/CD Pipeline | Orchestrates all validation and apply stages | `continuumLandingZoneCiCd` |
| Landing Zone Terraform | Runs Terragrunt plan and apply for account infrastructure | `continuumLandingZoneTerraform` |
| CloudFormation Baseline | Deploys or updates baseline account stacks | `continuumLandingZoneCloudFormationBaseline` |
| Cloud Custodian Policies | Applies updated governance policy package | `continuumLandingZoneCloudCustodian` |
| AWS Organizations | Receives SCP and org unit updates | `awsOrganizationsControlPlane` |
| AWS IAM | Receives user, role, and policy updates | `awsIamService` |
| AWS Route 53 | Receives DNS record and zone updates | `awsRoute53Service` |
| AWS CloudFormation | Deploys or updates baseline StackSets | `awsCloudFormationService` |

## Steps

1. **Receive merge event**: GitHub Enterprise sends a webhook to Jenkins when a PR is merged to master.
   - From: `githubEnterprise`
   - To: `continuumLandingZoneCiCd`
   - Protocol: GitHub webhook (HTTP)

2. **Detect Terraform module changes**: Jenkins checks `git diff` between the merge commit and origin/master for any changes under `terraform/modules/`.
   - From: `continuumLandingZoneCiCd` (`pipelineOrchestration`)
   - To: `pipelineOrchestration` (internal)
   - Protocol: Git / shell

3. **CloudFormation format check**: Jenkins runs `cfn-lint ./CloudFormationBaseline/**/*.yaml` via the `accounts-terrabase-ci:0.1.7` Docker image to validate all CloudFormation templates.
   - From: `continuumLandingZoneCiCd`
   - To: `continuumLandingZoneCloudFormationBaseline`
   - Protocol: Docker / cfn-lint

4. **Terraform validate** (conditional): If Terraform module changes are detected and `validateAll` is enabled, Terragrunt validates the `recreate` environment by assuming role `grpn-all-landingzone-tf-admin` in account `778785420119`.
   - From: `continuumLandingZoneCiCd`
   - To: `continuumLandingZoneTerraform`
   - Protocol: Docker / Terragrunt

5. **Parallel Terragrunt apply** (auto-apply environments): For each sandbox/dev environment with `autoApply: true`, Jenkins checks out the repo on the environment's labeled worker node, constructs `TERRAGRUNT_IAM_ROLE=arn:aws:iam::{account_id}:role/grpn-all-landingzone-tf-admin`, then runs `validate`, `apply`, and `clear-cache` via the terrabase Docker image.
   - From: `continuumLandingZoneCiCd`
   - To: `continuumLandingZoneTerraform`
   - Protocol: Docker / Terragrunt / AWS SDK

6. **Terraform applies SCP and org updates**: Terragrunt applies changes to AWS Organizations — updates organization units and Service Control Policies.
   - From: `continuumLandingZoneTerraform`
   - To: `awsOrganizationsControlPlane`
   - Protocol: AWS SDK (Terraform provider)

7. **Terraform applies IAM updates**: Terragrunt applies changes to users, roles, permission boundaries, and policies.
   - From: `continuumLandingZoneTerraform`
   - To: `awsIamService`
   - Protocol: AWS SDK (Terraform provider)

8. **Terraform applies DNS updates**: Terragrunt applies Route 53 zone and record changes.
   - From: `continuumLandingZoneTerraform`
   - To: `awsRoute53Service`
   - Protocol: AWS SDK (Terraform provider)

9. **CloudFormation baseline deployment**: Jenkins runs `CloudformationDeploy.py` which packages templates to S3 bucket `grpn-stackset-admin` and deploys StackSets for affected account types (Global, Billing, SAMLAccount, SecurityAccount, SecurityBase).
   - From: `continuumLandingZoneCiCd`
   - To: `continuumLandingZoneCloudFormationBaseline` → `awsCloudFormationService`
   - Protocol: Python / AWS CLI / CloudFormation API

10. **Custodian policy update**: Jenkins applies updated Cloud Custodian policy packages via `RunCustodianPolicy.py` to target accounts.
    - From: `continuumLandingZoneCiCd`
    - To: `continuumLandingZoneCloudCustodian`
    - Protocol: Python / c7n

11. **Post-build notification** (on failure): If any `apply` stage fails, Jenkins sends a Slack alert to `#cloudcoreteam-notify` with repo name, affected environments, and Jenkins build URL.
    - From: `continuumLandingZoneCiCd`
    - To: Slack `#cloudcoreteam-notify`
    - Protocol: Slack API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Terraform apply fails | Error caught in Jenkins try/catch; environment added to `TF_APPLY_FAILED_ENVS` list | Slack alert sent post-build; other environments continue in parallel |
| Terraform state locked | Pipeline provides `unlock` action option | Engineer re-runs pipeline with `unlock` action for affected environment |
| cfn-lint format check fails | Pipeline stage fails; build marked as failure | PR cannot be deployed until lint errors are fixed |
| Docker image pull fails | Jenkins step fails | Build fails; engineer re-triggers pipeline |
| IAM role assumption fails | Terragrunt errors with authentication failure | Build fails for that environment; engineer investigates role trust policy |

## Sequence Diagram

```
GitHub Enterprise -> CI/CD Pipeline: Merge event (webhook)
CI/CD Pipeline -> CI/CD Pipeline: Detect Terraform module changes
CI/CD Pipeline -> CloudFormation Baseline: cfn-lint format check
CI/CD Pipeline -> Landing Zone Terraform: Terragrunt validate (if module change)
CI/CD Pipeline -> Landing Zone Terraform: Terragrunt apply (parallel, auto environments)
Landing Zone Terraform -> AWS Organizations: Apply SCP and org unit updates
Landing Zone Terraform -> AWS IAM: Apply IAM role/policy updates
Landing Zone Terraform -> AWS Route 53: Apply DNS record updates
CI/CD Pipeline -> CloudFormation Baseline: Deploy StackSets via CloudformationDeploy.py
CloudFormation Baseline -> AWS CloudFormation: Update account baseline stacks
CI/CD Pipeline -> Cloud Custodian Policies: Apply policy package updates
CI/CD Pipeline --> Slack #cloudcoreteam-notify: Alert on apply failure
```

## Related

- Architecture dynamic view: `dynamic-landing-zone-change-flow`
- Related flows: [New Account Baseline Bootstrap](new-account-baseline-bootstrap.md), [IAM Role Provisioning](iam-role-provisioning.md)
