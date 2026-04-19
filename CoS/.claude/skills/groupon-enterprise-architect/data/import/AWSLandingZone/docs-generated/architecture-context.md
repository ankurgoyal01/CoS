---
service: "aws-landing-zone"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumLandingZoneTerraform"
    - "continuumLandingZoneCloudFormationBaseline"
    - "continuumLandingZoneCloudCustodian"
    - "continuumLandingZoneCiCd"
    - "continuumLandingZoneDocsPortal"
---

# Architecture Context

## System Context

AWS Landing Zone sits within the `continuumSystem` (Continuum Platform) as the infrastructure governance layer. It is not a runtime service — it is a delivery system for AWS infrastructure configuration. Engineers across all teams interact with it by submitting pull requests. On merge to master, the Jenkins pipeline (`continuumLandingZoneCiCd`) automatically applies Terraform changes to sandbox and dev accounts, while staging and production accounts require manual pipeline dispatch. The Landing Zone owns the VPCs, IAM identities, DNS zones, and SCPs that all other Groupon AWS workloads depend on.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| CI/CD Pipeline | `continuumLandingZoneCiCd` | CI/CD | Jenkins + Make + Scripts | 0.1.7 (terrabase) / 0.13.2 (terraform-ci) | Jenkins-driven delivery workflow that validates and applies approved infrastructure changes |
| Landing Zone Terraform | `continuumLandingZoneTerraform` | Infrastructure-as-Code | Terragrunt / Terraform | compliance v0.4 | Terragrunt/Terraform modules and environment definitions managing AWS accounts, IAM, networking, and governance guardrails |
| CloudFormation Baseline | `continuumLandingZoneCloudFormationBaseline` | Infrastructure-as-Code | AWS CloudFormation + Python | — | Baseline account templates and StackSet deployment logic for core account bootstrap and shared roles |
| Cloud Custodian Policies | `continuumLandingZoneCloudCustodian` | Governance | Cloud Custodian + Python | c7n | Cloud Custodian policy definitions and runners used for continuous governance and remediation |
| Landing Zone Documentation | `continuumLandingZoneDocsPortal` | Documentation | Markdown + Jekyll | — | Operational docs, runbooks, and generated architecture guidance for engineers and operators |

## Components by Container

### CI/CD Pipeline (`continuumLandingZoneCiCd`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `pipelineOrchestration` | Jenkinsfile and CI definitions that coordinate validation and apply stages | Jenkins Pipeline |
| `releaseAutomation` | Release and deployment helper scripts in bin/release-automation and CI package metadata | Shell + Python |

### Landing Zone Terraform (`continuumLandingZoneTerraform`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `terraformModuleCatalog` | Reusable modules under `terraform/modules` implementing baseline, IAM, DNS, networking, and governance capabilities | Terraform modules |
| `terraformEnvironmentDefinitions` | Terragrunt environment configurations under `terraform/envs` selecting modules, variables, and per-account topology | Terragrunt |
| `terraformComplianceTests` | Behavior and policy checks for IAM and infrastructure expectations | Gherkin + scripts |
| `terraformAutomationScripts` | Operational scripts in `terraform/bin` and `bin/` for account operations, reporting, and deployment support | Shell + Python |

### CloudFormation Baseline (`continuumLandingZoneCloudFormationBaseline`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `cloudFormationStackTemplates` | Account baseline templates and role definitions under `CloudFormationBaseline/Accounts` and `Prerequisites` | CloudFormation YAML |
| `cloudFormationDeployScript` | Python deployment utility (`CloudformationDeploy.py`) that packages templates and orchestrates StackSet deployments via S3 bucket `grpn-stackset-admin` | Python |

### Cloud Custodian Policies (`continuumLandingZoneCloudCustodian`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `custodianPolicies` | Cloud Custodian policy definitions under `CloudCustodian/policies/` for one-time and recurring governance controls | YAML |
| `custodianExecutionRunner` | Execution entrypoints (`RunCustodianPolicy.py`) and support scripts that apply policy scans and remediations | Python |

### Landing Zone Documentation (`continuumLandingZoneDocsPortal`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `docsContent` | Runbooks, onboarding guides, and troubleshooting content | Markdown |
| `documentationGenerator` | Scripts and make targets that assemble and publish documentation artifacts (e.g., `bin/create-dynamic-docs/update-docs.sh`) | Make + shell |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `githubEnterprise` | `continuumLandingZoneCiCd` | Sends pull request and merge events to | GitHub webhook |
| `jenkinsController` | `continuumLandingZoneCiCd` | Hosts and executes | Jenkins internal |
| `continuumLandingZoneCiCd` | `continuumLandingZoneTerraform` | Runs terragrunt plan and apply for | Shell / Docker |
| `continuumLandingZoneCiCd` | `continuumLandingZoneCloudFormationBaseline` | Runs deployment workflows for | Shell / Docker |
| `continuumLandingZoneCiCd` | `continuumLandingZoneCloudCustodian` | Applies policy package updates for | Shell / Docker |
| `continuumLandingZoneTerraform` | `awsOrganizationsControlPlane` | Manages organization units and SCP policies in | AWS SDK (Terraform) |
| `continuumLandingZoneTerraform` | `awsIamService` | Manages users, roles, boundaries, and policies in | AWS SDK (Terraform) |
| `continuumLandingZoneTerraform` | `awsRoute53Service` | Provisions DNS infrastructure in | AWS SDK (Terraform) |
| `continuumLandingZoneCloudFormationBaseline` | `awsCloudFormationService` | Deploys baseline stacks through | AWS CloudFormation API |
| `continuumLandingZoneCloudCustodian` | `awsIamService` | Scans and remediates policy drift in | AWS SDK (Cloud Custodian) |
| `continuumLandingZoneDocsPortal` | `continuumLandingZoneTerraform` | Publishes usage guidance for | Reference |
| `continuumLandingZoneDocsPortal` | `continuumLandingZoneCloudFormationBaseline` | Publishes baseline and onboarding guides for | Reference |

## Architecture Diagram References

- Dynamic view: `dynamic-landing-zone-change-flow`
- Component view (Terraform): `components-terraform`
- Component view (CloudFormation): `components-cloudformation`
- Component view (Custodian): `components-custodian`
- Component view (CI/CD): `components-cicd`
- Component view (Docs): `components-docs`
