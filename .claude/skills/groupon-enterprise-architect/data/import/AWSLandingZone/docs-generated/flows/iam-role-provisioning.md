---
service: "aws-landing-zone"
title: "IAM Role Provisioning"
generated: "2026-03-03"
type: flow
flow_name: "iam-role-provisioning"
flow_type: event-driven
trigger: "PR merged with IAM Terraform module or environment change"
participants:
  - "githubEnterprise"
  - "continuumLandingZoneCiCd"
  - "continuumLandingZoneTerraform"
  - "awsIamService"
architecture_ref: "dynamic-landing-zone-change-flow"
---

# IAM Role Provisioning

## Summary

All IAM users, roles, permission boundaries, and policies at Groupon can only be created or modified by opening a pull request in the AWSLandingZone repository. This flow covers the end-to-end process: from an engineer submitting a PR with an IAM change, through peer review by Cloud Core (and co-owners where applicable), to automated Terraform application in the target account(s). This is the enforcement mechanism for Groupon's policy that manual IAM changes in stable and production accounts are not permitted.

## Trigger

- **Type**: event
- **Source**: PR merged to master with changes to `terraform/modules/base_environment/iam/` or environment-level IAM HCL files
- **Frequency**: On-demand (per IAM change request)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Engineer | Submits PR with IAM change | — |
| GitHub Enterprise | Hosts PR, notifies reviewers, sends merge webhook | `githubEnterprise` |
| CI/CD Pipeline | Validates and orchestrates Terraform apply | `continuumLandingZoneCiCd` |
| Landing Zone Terraform | Applies IAM role/policy changes to AWS | `continuumLandingZoneTerraform` |
| AWS IAM | Receives and persists the IAM configuration | `awsIamService` |

## Steps

1. **Submit IAM change PR**: Engineer opens a pull request with new or modified Terraform HCL under `terraform/modules/base_environment/iam/roles/` (or relevant subpath). For DND roles, co-owners from `@production-fabric/cloud-d-d` are automatically requested; for security roles, `@production-fabric/cloud-security-team` is requested per `CODEOWNERS`.
   - From: Engineer
   - To: `githubEnterprise`
   - Protocol: GitHub PR

2. **Pre-commit validation**: Engineer runs `make pre-commit` locally, which validates Terraform formatting (`terraform fmt -check`) and file newline compliance before pushing.
   - From: Engineer
   - To: `continuumLandingZoneTerraform` (local)
   - Protocol: Make / Terraform CLI

3. **PR review**: Cloud Core team (and co-owners per CODEOWNERS) review the IAM change for security and compliance. The team targets a 2-business-day turnaround.
   - From: Reviewer
   - To: `githubEnterprise`
   - Protocol: GitHub review

4. **Merge triggers pipeline**: PR is approved and merged to master. GitHub Enterprise sends a webhook event to Jenkins.
   - From: `githubEnterprise`
   - To: `continuumLandingZoneCiCd`
   - Protocol: GitHub webhook

5. **Terraform validate**: Jenkins detects the module change and runs `terragrunt validate` on the `recreate` environment (if `validateAll` is enabled).
   - From: `continuumLandingZoneCiCd`
   - To: `continuumLandingZoneTerraform`
   - Protocol: Docker / Terragrunt

6. **Terragrunt plan and apply (dev/sandbox)**: For environments with `autoApply: true`, Jenkins runs `terragrunt validate`, `terragrunt apply`, and `clear-cache` on labeled EC2 worker nodes, assuming role `grpn-all-landingzone-tf-admin`.
   - From: `continuumLandingZoneCiCd`
   - To: `continuumLandingZoneTerraform`
   - Protocol: Docker / Terragrunt

7. **Terraform updates IAM in AWS**: Terragrunt applies the IAM change — creates/updates roles, managed policies, permission boundaries, or users in the target account.
   - From: `continuumLandingZoneTerraform` (`terraformEnvironmentDefinitions` → `terraformModuleCatalog`)
   - To: `awsIamService`
   - Protocol: AWS SDK (Terraform IAM provider)

8. **Manual apply for stable/prod** (separate trigger): Cloud Core engineer triggers the Jenkins pipeline manually for stable and production environments, selects target environments, sets action to `APPLY`, and monitors the run.
   - From: `continuumLandingZoneCiCd`
   - To: `continuumLandingZoneTerraform` → `awsIamService`
   - Protocol: Jenkins UI dispatch / AWS SDK

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Terraform format check fails (pre-commit) | `make pre-commit` exits non-zero | Engineer fixes formatting before pushing |
| CODEOWNERS review not obtained | PR blocked by GitHub branch protection | PR cannot merge without required approvals |
| IAM policy exceeds AWS limits | Terraform apply fails with AWS error | Engineer reduces policy scope; re-submits PR |
| Role already exists with conflicting config | Terraform plan shows diff; apply may fail if manual drift exists | Cloud Custodian detects drift; engineer imports existing resource or removes drift |
| Apply fails in stable/prod | Jenkins reports failure to Slack `#cloudcoreteam-notify` | Cloud Core investigates; re-runs with corrected config |

## Sequence Diagram

```
Engineer -> GitHub Enterprise: Open PR with IAM Terraform change
GitHub Enterprise -> Cloud Core / Co-owners: Request review notification
Cloud Core -> GitHub Enterprise: Approve and merge PR
GitHub Enterprise -> CI/CD Pipeline: Merge event webhook
CI/CD Pipeline -> Landing Zone Terraform: Terragrunt validate
CI/CD Pipeline -> Landing Zone Terraform: Terragrunt apply (dev/sandbox auto)
Landing Zone Terraform -> AWS IAM: Create/update roles, policies, boundaries
Landing Zone Terraform --> CI/CD Pipeline: Apply result
CI/CD Pipeline --> Slack #cloudcoreteam-notify: Alert on failure (if any)
```

## Related

- Architecture dynamic view: `dynamic-landing-zone-change-flow`
- Related flows: [Landing Zone Change Deployment](landing-zone-change-deployment.md), [Cloud Custodian Governance Remediation](custodian-governance-remediation.md)
