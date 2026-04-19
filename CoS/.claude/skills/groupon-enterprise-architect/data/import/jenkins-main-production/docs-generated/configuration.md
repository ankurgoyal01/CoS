---
service: "cloud-jenkins-main"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, jcasc-yaml, aws-secrets-manager, groovy-init-scripts]
---

# Configuration

## Overview

Cloud Jenkins Main is configured through four layers: (1) environment variables injected by Terraform/Terragrunt at deploy time, (2) JCasC YAML files (`jenkins-config/casc/*.yaml`) loaded by the Configuration as Code plugin at startup, (3) AWS Secrets Manager secrets interpolated into JCasC using the `${/path/to/secret}` syntax, and (4) Groovy init hook scripts (`jenkins-config/init.groovy.d/`) that perform imperative configuration beyond JCasC's declarative scope. The entire configuration bundle is packaged into a versioned Docker image and mounted into the controller container at startup.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `ENV` | Deployment environment (`staging` or `production`); gates Wavefront events and node registration | yes | — | Terraform |
| `STACK` | Stack name (`main`); gates Wavefront events and mobile node registration | yes | — | Terraform |
| `STACK_NAME` | Terraform local stack name | yes | `main` | `terraform/environment.hcl` |
| `SERVICE` | AWS resource tag value (`cloud-jenkins-main`) | yes | — | Terraform |
| `AWS_REGION` | AWS region for EC2 agent provisioning (`us-west-2`) | yes | — | Terraform |
| `AWS_SUBNETS` | Comma-separated subnet IDs for EC2 agent launch | yes | — | Terraform |
| `ATOM` | Deployment revision identifier; used in agent EC2 tags | yes | `notavailable` | Terraform |
| `OWNER` | Owner email tag (`cicd@groupon.com`); used in agent EC2 tags | yes | — | Terraform |
| `TEAM` | Team name tag (`cicd`); used in agent EC2 tags | yes | — | Terraform |
| `COMPONENT` | Component tag (`jenkins`); used in Wavefront event tags | yes | — | Terraform |
| `VPC` | VPC identifier; used in Wavefront event tags | yes | — | Terraform |
| `AD_ENV` | Active Directory environment suffix; used in RBAC role name interpolation | yes | — | Terraform |
| `AGENT_INSTANCE_PROFILE_ARN` | IAM instance profile ARN for EC2 agents | yes | — | Terraform |
| `AGENT_SG_NAME` | Security group name for EC2 agents | yes | — | Terraform |
| `NUM_AVAILABLE_DEFAULT_AGENTS` | Minimum number of spare default EC2 agents kept warm | yes | — | Terraform |
| `NUM_OCQ_AGENTS` | Minimum number of OCQ EC2 agents kept running | yes | — | Terraform |
| `JENKINS_URL` | Jenkins controller URL (used by smoke tests) | yes | — | Smoke test environment |
| `METRICS_KEY` | Jenkins metrics API key (used by smoke tests) | yes | — | Smoke test environment |

> IMPORTANT: No actual secret values are documented here. All secret references use AWS Secrets Manager paths.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `noUsageStatistics: true` | Disables Jenkins usage statistics reporting | true | global |
| `buildWrapperEnabled: true` | Enables SonarQube build wrapper globally | true | global |
| `activeJobsScanEnabled: true` | Enables active jobs scanning in the CCI Pipeline plugin | true | global |
| `jenkinsfileCheck: true` | Enables Jenkinsfile validation in the Conveyor Build plugin | true | global |
| `manageHooks: false` | Disables automatic GitHub webhook management by Jenkins | false | global |
| `disableConcurrentBuilds()` | Set in `Jenkinsfile`; prevents concurrent self-deploy runs | — | pipeline |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `jenkins-config/casc/general.yaml` | YAML | Core Jenkins settings: agent port 50001, SAML security realm, markup formatter, JNLP4 protocol, EXCLUSIVE master mode |
| `jenkins-config/casc/authorization.yaml` | YAML | RBAC role definitions: admin, superuser, user, anonymous, conveyor_admin, relevance, service_mesh_admin, cassh_provisioner_admin, cloudcore_admin |
| `jenkins-config/casc/cloud-default.yaml` | YAML | Amazon EC2 cloud configuration: all agent template types (m5.xlarge, m6g.xlarge, m5.large, m5.2xlarge, m5.8xlarge, c5d.4xlarge, m5.metal, OCQ) |
| `jenkins-config/casc/cloud-central-agents.yaml` | YAML | Central infra agent cloud configuration: separate EC2 cloud for multi-account infra agent templates |
| `jenkins-config/casc/cloud-infra.yaml` | YAML | Additional infrastructure-specific EC2 cloud configuration |
| `jenkins-config/casc/credentials.yaml` | YAML | All credential definitions (secrets resolved from AWS Secrets Manager at runtime) |
| `jenkins-config/casc/jobs.yaml` | YAML | Seed job definitions for the `000-jenkins-tests` canary folder |
| `jenkins-config/casc/security.yaml` | YAML | Groovy script approval signatures list |
| `jenkins-config/casc/tool.yaml` | YAML | Tool installations: Git at `/usr/bin/git`, SonarQube Scanner 3.2.0.1227 |
| `jenkins-config/casc/unclassified.yaml` | YAML | Plugin-level configuration: build discarder (180 days), Slack notifier, SMTP mailer, global shared libraries, SonarQube server, Telegraf metrics host |
| `jenkins-config/init.groovy.d/S01AddWavefrontEvent.groovy` | Groovy | Posts `cloud_jenkins_main_start` event to Wavefront on startup |
| `jenkins-config/init.groovy.d/S02CleanJobs.groovy` | Groovy | Aborts all builds running on EC2 agents at controller restart |
| `jenkins-config/init.groovy.d/S04WavefrontEventClose.groovy` | Groovy | Closes the open Wavefront startup event after init completes |
| `jenkins-config/init.groovy.d/S05AwsDeviceFarm.groovy` | Groovy | Configures AWS Device Farm plugin for mobile testing |
| `jenkins-config/init.groovy.d/S06AndroidNodes.groovy` | Groovy | Registers static Android automation SSH agents (distbuild-docker hosts in SNC1) |
| `jenkins-config/init.groovy.d/S07MacOSNodes.groovy` | Groovy | Registers static macOS JNLP agents for iOS build/test/submission |
| `jenkins-config/init.groovy.d/S08CreateEc2CanaryJobs.groovy` | Groovy | Creates `cloud-jenkins/ec2-canary` pipeline jobs for all cross-account agent label canaries |
| `jenkins-config/boot-failure.groovy.d/S01WavefrontEventClose.groovy` | Groovy | Closes the open Wavefront event on boot failure |
| `jenkins-config/other/logging.properties` | Properties | Java logging configuration for the controller |
| `terraform/environment.hcl` | HCL | Terragrunt locals: region, env, stack_name, service, component, team, owner, atom |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `${/jenkins/okta/saml_url}` | Okta SAML SSO URL for controller location and logout | AWS Secrets Manager |
| `${/jenkins/okta/saml_metadata}` | Okta SAML IdP metadata XML | AWS Secrets Manager |
| `${/jenkins/svc_dcos/ghe_token}` | GitHub Enterprise API access token for `svc-dcos` user | AWS Secrets Manager |
| `${/jenkins/svc_dcos/ssh_key}` | SSH private key for `svc-dcos` GitHub access | AWS Secrets Manager |
| `${/jenkins/svc_dcos/ssh_passphrase}` | SSH passphrase for `svc-dcos` key | AWS Secrets Manager |
| `${/jenkins/githubapp_pem}` | GitHub App PEM key for Conveyor Build Plugin | AWS Secrets Manager |
| `${/jenkins/githubapp_webhook_secret}` | GitHub App webhook HMAC secret | AWS Secrets Manager |
| `${/jenkins/githubapp_id}` | GitHub App installation ID | AWS Secrets Manager |
| `${/plugins/slack/token}` | Slack bot token for notifications | AWS Secrets Manager |
| `${/plugins/metrics/token}` | Metrics endpoint API key | AWS Secrets Manager |
| `${/jenkins/sonarqube/url}` | SonarQube server URL | AWS Secrets Manager |
| `${/plugins/amazonEC2/agent-ami}` | Default EC2 agent AMI ID | AWS Secrets Manager |
| `${/plugins/amazonEC2/graviton-agent-ami}` | Graviton EC2 agent AMI ID | AWS Secrets Manager |
| `${/plugins/amazonEC2/agent-ami-infra}` | Infra agent AMI ID | AWS Secrets Manager |
| `${/jenkins/private_keys/ec2_agent}` | SSH private key for EC2 agent connections | AWS Secrets Manager |
| `${/jenkins/deploybot/username}` | Deploybot API username | AWS Secrets Manager |
| `${/jenkins/deploybot/password}` | Deploybot API password | AWS Secrets Manager |
| `${/jenkins/aws/internal_prod_access_key}` + `secret_key` | IAM credentials for grpn-internal-prod account | AWS Secrets Manager |
| `${/jenkins/aws/internal_stable_access_key}` + `secret_key` | IAM credentials for grpn-internal-stable account | AWS Secrets Manager |
| `${/jenkins/nlm/npm-username}`, `npm-password-base64`, `npm-email`, `gh-token` | NLM Artifactory NPM credentials | AWS Secrets Manager |
| `${/jenkins/mobile/builduser_ssh_password_for_android}` | SSH password for Android build containers | AWS Secrets Manager |
| `${/jenkins/ldap_svc_conveyor_ci_pass}` | LDAP password for svc_conveyor-ci | AWS Secrets Manager |
| `${/jenkins/svc_harness/svc_harness_token}` | Harness integration token | AWS Secrets Manager |
| `cloud-jenkins-gpg-key`, `cloud-jenkins-gpg-pass`, etc. | GPG key for `git-crypt` unlock of encrypted config | Jenkins credential store (used in `Jenkinsfile`) |

> Secret values are NEVER documented. Only names and purposes are listed here.

## Per-Environment Overrides

- **Staging** (`ENV=staging`): Deployed to `http://jenkins-main-staging.stable-internal.us-west-2.aws.groupondev.com`; Wavefront events and mobile node registration are active (same gates as production).
- **Production** (`ENV=production`): Deployed to `http://jenkins-main-production.prod-internal.us-west-2.aws.groupondev.com` / `https://cloud-jenkins.groupondev.com`; all features active.
- Groovy init scripts `S01`, `S04`, `S06`, `S07` check `ENV` and `STACK` at runtime and skip their logic for any non-main or non-staging/production environments.
