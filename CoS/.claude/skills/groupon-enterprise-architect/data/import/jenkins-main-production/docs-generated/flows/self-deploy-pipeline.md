---
service: "cloud-jenkins-main"
title: "Self-Deploy Pipeline"
generated: "2026-03-03"
type: flow
flow_name: "self-deploy-pipeline"
flow_type: event-driven
trigger: "Push to master branch of jenkins-main-production repository"
participants:
  - "continuumJenkinsController"
  - "jenkinsPipelineOrchestrator"
  - "githubEnterprise"
  - "cloudPlatform"
  - "slack"
architecture_ref: "components-continuumJenkinsController"
---

# Self-Deploy Pipeline

## Summary

Cloud Jenkins Main manages its own infrastructure and configuration using the pipeline defined in its own `Jenkinsfile`. When a push is made to the `master` branch of the `jenkins-main-production` repository, the production Jenkins controller runs a multi-stage pipeline that unlocks encrypted secrets, validates Terraform modules, runs integration tests, generates an execution plan, and (for master-branch pushes) applies all infrastructure changes via Terragrunt. This bootstrapped self-deployment pattern means the controller is responsible for deploying itself. Pull request builds run through validation and planning stages only, without applying changes.

## Trigger

- **Type**: event (webhook + branch gate)
- **Source**: Push to `master` branch of `jenkins-main-production` GitHub Enterprise repository; `GITHUB_BRANCH == "master"` and `GITHUB_PULL_REQUEST == null`
- **Frequency**: On every master-branch merge; PRs also trigger (plan only)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GitHub Enterprise | Source repository; delivers push webhook to controller | `githubEnterprise` |
| Jenkins Main Controller | Executes the self-deploy pipeline via `jenkinsPipelineOrchestrator` | `continuumJenkinsController` |
| Pipeline Orchestrator | Runs Jenkinsfile stages on the `aws-rapt-internal-prod` agent node | `jenkinsPipelineOrchestrator` |
| AWS (cloudPlatform) | Target of Terraform apply; provides EC2 agent (`aws-rapt-internal-prod`) | `cloudPlatform` |
| Slack | Receives failure notification to `#cj-dev` on master-branch failure | `slack` |

## Steps

1. **Receive push webhook**: GitHub Enterprise delivers a push event to `/ghe-seed/`. The controller queues the `jenkins-main-production` pipeline build.
   - From: `githubEnterprise`
   - To: `continuumJenkinsController`
   - Protocol: HTTPS webhook

2. **Assign to agent**: The pipeline is assigned to the `aws-rapt-internal-prod` agent node (a central infra agent in the production AWS account).
   - From: `jenkinsPipelineOrchestrator`
   - To: `cloudPlatform` (EC2 infra agent)
   - Protocol: JNLP

3. **Prepare — Unlock git-crypt**: The pipeline imports the GPG key using credentials `cloud-jenkins-gpg-key`, `cloud-jenkins-gpg-owner-trust`, `cloud-jenkins-gpg-pass`, and `cloud-jenkins-gpg-keygrip`. After importing the key and configuring the GPG agent, `git crypt unlock` decrypts sensitive files in the repository. Terraform modules are then initialised with `make init`.
   - From: `jenkinsPipelineOrchestrator`
   - To: `continuumJenkinsController` (credentials store) and local filesystem
   - Protocol: direct / shell

4. **Validate**: `make validate-all` runs `terraform validate` across all Terraform modules to verify HCL syntax, provider schemas, and resource configurations.
   - From: `jenkinsPipelineOrchestrator`
   - To: `cloudPlatform` (Terraform provider API calls for schema validation)
   - Protocol: AWS SDK (read-only)

5. **Integration tests**: `make integration-test` verifies module configurations against live AWS APIs (e.g. checking that referenced AMIs, subnets, security groups exist and are accessible).
   - From: `jenkinsPipelineOrchestrator`
   - To: `cloudPlatform` (AWS API — read-only)
   - Protocol: AWS SDK

6. **TF Plan**: The pipeline acquires the distributed lock `cloud-jenkins-main-prod-tf` (via Jenkins lockable resources) and runs `make plan-all`. Terragrunt generates a Terraform execution plan for all modules, storing it for inspection. Plan is read-only — no AWS resources are modified.
   - From: `jenkinsPipelineOrchestrator`
   - To: `cloudPlatform` (AWS API — read-only plan)
   - Protocol: AWS SDK

7. **Apply (master only)**: If `shouldBeDeployed == true` (master branch, not a PR), `make apply-all` is executed via `aws-okta exec internal-prod/admin`. Terragrunt applies infrastructure changes — updating EC2 task definitions, rolling out the new config image, refreshing security groups, EFS mount targets, etc.
   - From: `jenkinsPipelineOrchestrator`
   - To: `cloudPlatform` (AWS API — write)
   - Protocol: AWS SDK (via `aws-okta`)

8. **Post-failure Slack alert (conditional)**: If any stage fails on the master branch, a Slack message is sent to `#cj-dev` with job name, ref, and build URL, colour `danger`.
   - From: `jenkinsPipelineOrchestrator` (post block)
   - To: `slack` (`#cj-dev`)
   - Protocol: Slack API (HTTPS)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| GPG key import failure (Prepare) | Pipeline fails immediately; Slack alert sent on master | No infrastructure change; operator must fix GPG credentials |
| `make validate-all` failure | Pipeline fails at Validate stage; no plan or apply | No infrastructure change; fix HCL errors and re-push |
| Integration test failure | Pipeline fails; no plan or apply | No infrastructure change |
| Terraform state lock conflict | `cloud-jenkins-main-prod-tf` lock prevents concurrent runs (`disableConcurrentBuilds()`); pipeline waits or fails | Resolve via DynamoDB lock table (see runbook) |
| `make apply-all` failure (Terraform error) | Pipeline fails; Slack alert; partial apply may leave AWS resources in transitional state | Re-run `make apply-all` after resolving the error |
| PR build (not master) | `shouldBeDeployed == false`; TF Plan runs but apply is skipped | Safe preview of infrastructure changes; no Slack alert |

## Sequence Diagram

```
GHE               Controller         Agent(aws-rapt)   AWS              Slack
 |                    |                  |               |                |
 |--push master------>|                  |               |                |
 |                    |--assign agent--->|               |                |
 |                    |                  |--git crypt unlock              |
 |                    |                  |--make init--->|                |
 |                    |                  |--validate---->|                |
 |                    |                  |--integration tests-->|          |
 |                    |--acquire lock--->|               |                |
 |                    |                  |--make plan--->|                |
 |                    |                  |--make apply-->| (master only)  |
 |                    |<--result---------|               |                |
 |                    |                  | (on failure)                   |
 |                    |--slackSend------------------------------>#cj-dev  |
```

## Related

- Architecture dynamic view: `components-continuumJenkinsController`
- Related flows: [Controller Startup and Configuration Load](controller-startup.md), [Pipeline Job Execution](pipeline-job-execution.md)
