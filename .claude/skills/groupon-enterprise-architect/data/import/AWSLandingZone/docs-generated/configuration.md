---
service: "aws-landing-zone"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["env-vars", "config-files", "jenkins-credentials", "hcl-files"]
---

# Configuration

## Overview

AWS Landing Zone configuration is split across three layers: Jenkins pipeline parameters and credentials (for CI/CD execution), Terragrunt HCL files (per-environment account topology and module selection), and YAML/Python configuration files (CloudFormation account lists and Custodian policy definitions). There are no runtime environment variables in the traditional service sense — all configuration drives infrastructure provisioning jobs.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `TERRAGRUNT_IAM_ROLE` | IAM role ARN for Terragrunt to assume in target account | yes | — | Jenkins pipeline (injected per environment) |
| `HOSTNAME` | Passed into Docker container for identification | yes | — | Jenkins agent (Docker `-e HOSTNAME`) |
| `GPG_PASSPHRASE` | GPG passphrase for decrypting git-crypt encrypted credentials (billing env only) | yes (billing only) | — | Jenkins credential `GPG_PASSPHRASE` (secret text) |
| `GITHUB_USER` | GitHub service account user for doc update commits | conditional | `svc-dcos@groupon.com` | Jenkins credential / env |
| `GITHUB_TOKEN` | GitHub token for doc automation commits | conditional | — | Jenkins credential `svc_dcos_token` |
| `AWS_ACCESS_KEY_ID` | AWS access key for audit scripts using `aws-okta` | yes (audit scripts) | — | `aws-okta exec` |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key for audit scripts using `aws-okta` | yes (audit scripts) | — | `aws-okta exec` |
| `AWS_SESSION_TOKEN` | AWS session token for audit scripts using `aws-okta` | yes (audit scripts) | — | `aws-okta exec` |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `autoPlan` (Jenkinsfile) | Enables automatic terraform plan on PR branch push | `false` | global |
| `autoApply` (Jenkinsfile) | Enables automatic terraform apply on master merge for eligible environments | `true` | global |
| `validateAll` (Jenkinsfile) | Enables terraform validate check for every commit | `false` | global |
| `disable_terrabase` (Jenkinsfile) | Switches from terrabase runner to direct Makefile commands (used for billing env) | `false` | per-environment |

Per-environment `autoApply` overrides (from `Jenkinsfile`):

| Environment | autoApply |
|-------------|-----------|
| `conveyorsandbox`, `edwsandbox`, `gensandbox`, `recreate`, `grpn-mta-dev`, `grpn-netops-dev`, `grpn-logging-dev`, `grpn-security-dev`, `grpn-cstools-dev` | `true` |
| `dev-cloudcore` | `false` (playground — disabled to protect experiments) |
| All stable and prod environments | `false` (manual approval required) |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `Jenkinsfile` | Groovy | CI/CD pipeline definition — environment list, Docker image versions, apply/plan flags |
| `PROJECT.ini` | INI | Service metadata — project name, service name, owner, cloud provider, auth method, compliance settings |
| `.service.yml` | YAML | Service registry metadata — dashboards, PagerDuty, Slack, team, environment base URLs |
| `Config/Landing-Zone-Accounts.yaml` | YAML | Account inventory reference (links to published account-info page) |
| `Config/Pre-exist-accounts.yaml` | YAML | Pre-existing account configuration |
| `CloudFormationBaseline/Accounts/*/` | CloudFormation YAML | Per-account-type baseline stack templates (Global, Billing, SAMLAccount, SecurityAccount, SecurityBase) |
| `CloudCustodian/policies/OneTimeUtility/*.yaml` | YAML | One-time Cloud Custodian policy definitions for remediation runs |
| `Makefile` | Make | Developer workflow targets: `fmt`, `fmt-check`, `pre-commit`, tag management |
| `terraform/envs/` | HCL (Terragrunt) | Per-environment Terragrunt configurations selecting modules and account topology |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `GPG_PASSPHRASE` | Decrypts git-crypt secrets for billing account credential files | Jenkins credentials (secret text) |
| `svc_dcos_token` | GitHub token for automated documentation commit workflow | Jenkins credentials (secret text) |
| `svcdcos-ssh` | SSH key for service account used in documentation automation | Jenkins credentials (SSH) |
| `.git-crypt/keys/` | GPG-encrypted symmetric key protecting sensitive files in repo | git-crypt (GPG key IDs in repo) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

The Jenkinsfile defines a map of environments with per-environment overrides for:
- **Jenkins agent label** — each environment maps to a dedicated Jenkins worker node (e.g., `aws-cloudcore-conveyorsandbox`, `aws-cloudcore-mta-prod`)
- **AWS Account ID** — used to construct the `TERRAGRUNT_IAM_ROLE` ARN
- **autoApply** — sandbox/dev environments apply automatically on master merge; stable/prod require manual dispatch
- **autoPlan** — disabled globally (`false`) for all environments

Terragrunt environment definitions under `terraform/envs/{environment}/` contain per-account HCL files (`account.hcl`, `region.hcl`) that select modules, set variables, and define per-region topology.

Authentication method is configured in `PROJECT.ini` as `AWS_OKTA` with SAML URL `home/amazon_aws/0oa1drin1zvdpxBdo1d8/272`.
