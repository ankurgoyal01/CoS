---
service: "aws-landing-zone"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 6
internal_count: 3
---

# Integrations

## Overview

AWS Landing Zone integrates with six external AWS services as its primary management targets, plus three internal Groupon platform systems that drive its delivery pipeline. All integration is outbound — the Landing Zone calls AWS APIs to enforce desired state; no external system calls back into the Landing Zone at runtime.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| AWS Organizations / Control Plane | AWS SDK (Terraform) | Manages organization units, accounts, and SCP policies | yes | `awsOrganizationsControlPlane` |
| AWS IAM | AWS SDK (Terraform + Custodian) | Manages users, roles, permission boundaries, and policies | yes | `awsIamService` |
| AWS Route 53 | AWS SDK (Terraform) | Provisions DNS zones and records for all Groupon AWS accounts | yes | `awsRoute53Service` |
| AWS CloudFormation | AWS CloudFormation API | Deploys and manages baseline account stacks via StackSets | yes | `awsCloudFormationService` |
| AWS CloudTrail | AWS SDK (CloudFormation) | Enables multi-region audit logging (`GRPNCloudTrail`) per account | yes | — |
| AWS IAM Access Analyzer | AWS CloudFormation | Enables IAM Access Analyzer per account via `EnableAnalyzer.yaml` stacks | yes | — |

### AWS Organizations / Control Plane Detail

- **Protocol**: AWS SDK via Terraform provider
- **Auth**: IAM role assumption — `grpn-all-landingzone-tf-admin` in each target account; TERRAGRUNT_IAM_ROLE injected by Jenkins pipeline
- **Purpose**: Manages the organizational unit hierarchy, creates and configures member accounts, and applies SCPs to restrict actions in member accounts
- **Failure mode**: Terraform plan/apply fails; pipeline reports error to Slack `#cloudcoreteam-notify`

### AWS IAM Detail

- **Protocol**: AWS SDK via Terraform provider and Cloud Custodian
- **Auth**: Federated via Okta SAML (`arn:aws:iam::930442592328:saml-provider/Groupon-SAML`); headless pipeline uses assumed role `grpn-all-landingzone-tf-admin`
- **Purpose**: Creates and manages all IAM users, roles (e.g., `Groupon-Admin`, `Groupon-ReadOnly`, `Okta-Idp-cross-account-role`), permission boundaries, and managed policies; Cloud Custodian scans for drift and remediates
- **Failure mode**: Drift not immediately corrected; Cloud Custodian next run detects and remediates

### AWS Route 53 Detail

- **Protocol**: AWS SDK via Terraform provider
- **Auth**: IAM role assumption via Terragrunt
- **Purpose**: Provisions all Groupon DNS infrastructure — zones and records across us-west-1, us-west-2, eu-west-1
- **Failure mode**: DNS changes not applied until next successful pipeline run

### AWS CloudFormation Detail

- **Protocol**: AWS CloudFormation API (via `CloudformationDeploy.py` and Jenkins pipeline)
- **Auth**: IAM role `AWSCloudFormationStackSetAdministrationRole` assumes `AWSCloudFormationStackSetExecutionRole` in target accounts
- **Purpose**: Deploys baseline stacks to five account types: Global, Billing, SAMLAccount, SecurityAccount, SecurityBase; each stack enables IAM baselines, CloudTrail, and IAM Access Analyzer
- **Failure mode**: Stack deployment fails; manual remediation via AWS console or re-run of deploy script

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| GitHub Enterprise | Webhook | Sends PR and merge events that trigger the Jenkins pipeline | `githubEnterprise` |
| Jenkins Controller | Jenkins internal | Hosts and executes the CI/CD pipeline across labeled worker nodes | `jenkinsController` |
| Docker Registry (`docker.groupondev.com`) | Docker pull | Provides CI container images `cloudcore/accounts-terraform-ci:0.13.2` and `cloudcore/accounts-terrabase-ci:0.1.7` | — |

## Consumed By

> Upstream consumers are tracked in the central architecture model.

All Groupon engineering teams consume resources created by the Landing Zone (VPCs, subnets, IAM roles, DNS records). They reference Landing Zone outputs via the `landing_zone_data` Terraform data module rather than calling the Landing Zone service directly.

## Dependency Health

- **Terraform apply failures**: Reported to Slack `#cloudcoreteam-notify` channel with environment and job link
- **IAM drift**: Cloud Custodian runs detect and remediate drift; CloudWatch log group `GRPNCloudTrailLogs` captures all IAM API calls for audit
- **No circuit breakers configured**: AWS API calls rely on Terraform/Terragrunt retry semantics; lock management via `unlock` pipeline action for stuck state files
