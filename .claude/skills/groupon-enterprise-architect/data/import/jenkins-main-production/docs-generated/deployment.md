---
service: "cloud-jenkins-main"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "ec2"
environments: ["staging", "production"]
---

# Deployment

## Overview

Cloud Jenkins Main deploys its configuration as a versioned Docker image (Alpine Linux 3.15 base) that mounts JCasC YAML, Groovy init scripts, and logging properties into the Jenkins controller container at runtime. The controller itself runs on AWS EC2 within the `grpn-internal-prod` AWS account (744390875592) in `us-west-2`. Infrastructure provisioning and updates are fully managed by Terraform modules via Terragrunt. The self-deploy pipeline runs on this same Jenkins instance (bootstrapped); deployments to master are gated behind a PR + `shouldBeDeployed` flag.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Config image | Docker (Alpine 3.15) | `jenkins-config/Dockerfile`; copies `casc/`, `init.groovy.d/`, `boot-failure.groovy.d/`, `other/` into image volumes |
| Smoke test image | Docker | `smoke-tests/Dockerfile`; Python-based smoke test runner |
| Orchestration | AWS EC2 (via Amazon EC2 plugin) | Controller runs on EC2; ephemeral agents provisioned on-demand via Amazon EC2 plugin |
| Persistent storage | AWS EFS | Jenkins home directory (`JENKINS_HOME`) mounted from EFS for data persistence |
| Infrastructure as code | Terraform + Terragrunt | `terraform/environments/`; Terragrunt orchestrates multi-module apply; state in S3 + DynamoDB |
| State backend | AWS S3 + DynamoDB | S3 bucket `rapt-cloud-jenkins-787676117833`; DynamoDB for state locking |
| DNS / routing | Internal VPC routing | `prod-internal.us-west-2.aws.groupondev.com` (internal); `cloud-jenkins.groupondev.com` (external) |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| staging | Pre-production validation of configuration changes | us-west-2 (grpn-internal-stable) | `http://jenkins-main-staging.stable-internal.us-west-2.aws.groupondev.com` |
| production | Live CI/CD platform for all engineering teams | us-west-2 (grpn-internal-prod, 744390875592) | `http://jenkins-main-production.prod-internal.us-west-2.aws.groupondev.com` / `https://cloud-jenkins.groupondev.com` |

## CI/CD Pipeline

- **Tool**: Jenkins (self-hosted — this service deploys itself)
- **Config**: `Jenkinsfile`
- **Trigger**: On push to master (when `!isPR && ref == "master"`); PR builds run plan-only without applying

### Pipeline Stages

1. **Prepare**: Unlocks `git-crypt` encrypted secrets using GPG credentials, then initialises Terragrunt modules (`make init`)
2. **Validate**: Runs `make validate-all` across all Terraform modules to check HCL syntax and provider schemas
3. **Integration tests**: Runs `make integration-test` to verify module configurations against live AWS APIs
4. **TF Plan**: Acquires lock `cloud-jenkins-main-prod-tf` and runs `make plan-all` to generate a Terraform execution plan
5. **Apply** (master-branch only, implicit via `shouldBeDeployed`): Runs `make apply-all` via `aws-okta exec internal-prod/admin` to provision/update AWS resources and roll out the new configuration image

> Post-failure: Sends a Slack message to `#cj-dev` if the pipeline fails on master.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| EC2 agent pool (default x86) | Auto-provisioning (Amazon EC2 plugin) | Min spare: `NUM_AVAILABLE_DEFAULT_AGENTS`; Max: 200 instances (m5.xlarge); Idle timeout: 60 min |
| EC2 agent pool (Graviton) | Auto-provisioning | Min spare: 0; Max: 100 (m6g.xlarge); Idle timeout: 60 min |
| EC2 agent pool (m5.2xlarge) | Auto-provisioning | Min spare: `NUM_AVAILABLE_DEFAULT_AGENTS`; Max: 200; Idle timeout: 60 min |
| EC2 agent pool (m5.8xlarge) | Auto-provisioning | Min spare: 0; Max: 10; Idle timeout: 0 min (terminate immediately when idle) |
| EC2 agent pool (multitenant m5.large) | Auto-provisioning | Min: 0; Max: 10; 4 executors; 40 max uses; Idle timeout: 15 min |
| EC2 agent pool (itier-multitenant) | Auto-provisioning | Min: 0; Max: 50; 4 executors; 40 max uses; Idle timeout: 15 min |
| EC2 agent pool (mobile-android bare metal m5.metal) | Auto-provisioning | Min: 0; Max: 10; 250GB EBS; Launch timeout: 900s |
| EC2 agent pool (OCQ m5.xlarge) | Auto-provisioning | Min: `NUM_OCQ_AGENTS`; Max: 1; Idle timeout: 60 min |
| EC2 agent pool (C5D.4xlarge merchant/Flutter) | Auto-provisioning | Min: 0; Max: 12; Idle timeout: 1 min |
| Static macOS nodes | Manual (Groovy init) | ~40+ macOS build/test/submission machines registered via JNLP |
| Static Android nodes | Manual (Groovy init) | distbuild-docker hosts (hosts 4-11, containers 1-20) registered via SSH |
| Controller | Single instance | Not horizontally scaled; EFS provides data persistence |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| Controller CPU | Not specified — managed by EC2 instance type | — |
| Controller Memory | Not specified — managed by EC2 instance type | — |
| Controller Disk | EFS (elastic, auto-expanding) | Backed up via AWS Backup |
| EC2 agent (default, m5.xlarge) | 4 vCPU, 16 GB RAM | 1 executor; ephemeral EBS; max 1 use |
| EC2 agent (m5.8xlarge) | 32 vCPU, 128 GB RAM | 1 executor; ephemeral EBS; max 1 use |

> Agent AMI versions are resolved at runtime from `${/plugins/amazonEC2/agent-ami}` in AWS Secrets Manager.
