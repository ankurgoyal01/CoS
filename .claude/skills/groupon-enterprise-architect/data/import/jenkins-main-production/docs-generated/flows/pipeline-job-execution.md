---
service: "cloud-jenkins-main"
title: "Pipeline Job Execution"
generated: "2026-03-03"
type: flow
flow_name: "pipeline-job-execution"
flow_type: event-driven
trigger: "GitHub Enterprise push event received by /ghe-seed/ endpoint"
participants:
  - "continuumJenkinsController"
  - "jenkinsPipelineOrchestrator"
  - "githubEnterprise"
  - "cloudPlatform"
  - "artifactory"
  - "loggingStack"
  - "metricsStack"
  - "slack"
architecture_ref: "components-continuumJenkinsController"
---

# Pipeline Job Execution

## Summary

When a developer pushes to a GitHub Enterprise repository, GHE delivers a push webhook to the Jenkins `/ghe-seed/` endpoint. The Conveyor Build Plugin validates the signature, seeds or locates the target pipeline job, and queues a build. The `jenkinsPipelineOrchestrator` checks out source code, provisions an EC2 agent for build execution, runs all declared pipeline stages, publishes artifacts to Artifactory, and ships logs and metrics to the observability stack. A Slack failure alert is sent if the build fails on the default branch.

## Trigger

- **Type**: event (webhook)
- **Source**: GitHub Enterprise push event (`X-Github-Event: push`) delivered to `POST /ghe-seed/`
- **Frequency**: On every repository push or pull-request update; on-demand for manual builds

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GitHub Enterprise | Source of webhook; provides source code via Git clone | `githubEnterprise` |
| Jenkins Main Controller | Receives webhook; orchestrates job queue and agent provisioning | `continuumJenkinsController` |
| Pipeline Orchestrator | Executes Jenkinsfile stages on the provisioned agent | `jenkinsPipelineOrchestrator` |
| AWS (cloudPlatform) | Provisions ephemeral EC2 build agent | `cloudPlatform` |
| Artifactory | Provides build dependencies; receives built artifacts and Docker images | `artifactory` |
| Logging Stack | Receives build logs via Filebeat | `loggingStack` |
| Metrics Stack | Receives pipeline metrics via Telegraf on port 8186 | `metricsStack` |
| Slack | Receives failure alert for master-branch failures | `slack` |

## Steps

1. **Receive push webhook**: GitHub Enterprise sends an HTTP POST to `POST /ghe-seed/` with `X-Github-Event: push` and `X-Hub-Signature` HMAC header.
   - From: `githubEnterprise`
   - To: `continuumJenkinsController`
   - Protocol: HTTPS

2. **Validate webhook signature**: The Conveyor Build Plugin verifies the `X-Hub-Signature` header against the `githubapp-secret` credential. Returns HTTP 400 on invalid payload; returns non-403 on valid request.
   - From: `jenkinsPipelineOrchestrator` (Conveyor Build Plugin)
   - To: Internal signature verifier
   - Protocol: direct (in-process)

3. **Seed or locate pipeline job**: The plugin finds the existing pipeline job or seeds a new one from the repository's Jenkinsfile. Uses the `conveyor-ci-dsl-library` (v1.5, implicit) for job DSL resolution.
   - From: `jenkinsPipelineOrchestrator`
   - To: `githubEnterprise` (reads Jenkinsfile via GHE API)
   - Protocol: HTTPS

4. **Queue build**: The build is enqueued in the Jenkins build queue with the triggering commit ref.
   - From: `jenkinsPipelineOrchestrator`
   - To: Jenkins build queue (in-memory)
   - Protocol: direct

5. **Provision EC2 agent**: The Amazon EC2 plugin selects the appropriate agent template based on the job's `agent { label "..." }` definition and launches an EC2 instance. Agent connects back to the controller on port 50001 (JNLP4-connect) or via SSH.
   - From: `continuumJenkinsController`
   - To: `cloudPlatform` (AWS EC2 API)
   - Protocol: AWS SDK

6. **Clone source repository**: The pipeline's `checkout` step clones the repository from GitHub Enterprise using the `svcdcos-ssh` credential.
   - From: EC2 agent (pipeline step)
   - To: `githubEnterprise`
   - Protocol: Git over HTTPS

7. **Execute pipeline stages**: The `jenkinsPipelineOrchestrator` runs each declared stage from the repository Jenkinsfile on the provisioned agent — compile, test, package, scan, publish as applicable.
   - From: `jenkinsPipelineOrchestrator`
   - To: EC2 agent executors
   - Protocol: JNLP / SSH remoting

8. **Pull build dependencies from Artifactory**: Build steps resolve dependencies (Maven, NPM, Docker images) from Artifactory using NLM credentials.
   - From: EC2 agent (build step)
   - To: `artifactory`
   - Protocol: HTTPS

9. **Push artifacts to Artifactory**: On successful build, compiled artifacts and Docker images are pushed to Artifactory.
   - From: EC2 agent (build step)
   - To: `artifactory`
   - Protocol: HTTPS

10. **Ship logs to logging stack**: Build logs are continuously streamed from the agent to the controller and forwarded via Filebeat to the Logging Stack (index: `filebeat-cicd_cloud_jenkins_main_builds--*`).
    - From: `jenkinsObservabilityEmitter`
    - To: `loggingStack`
    - Protocol: Filebeat / HTTPS

11. **Publish pipeline metrics**: Build duration, result, and stage metrics are published via Telegraf to the Metrics Stack on port 8186.
    - From: `jenkinsObservabilityEmitter`
    - To: `metricsStack`
    - Protocol: HTTP (Telegraf)

12. **Send Slack failure alert (conditional)**: If the build fails and the triggering branch is `master` (i.e. `shouldBeDeployed == true`), a Slack message is posted to `#cj-dev` with job name, ref, and build URL.
    - From: `jenkinsObservabilityEmitter`
    - To: `slack` (`#cj-dev`)
    - Protocol: Slack API (HTTPS)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid webhook signature | HTTP 400 returned; build not triggered | No job execution; webhook sender sees 400 |
| EC2 agent launch timeout (120s default) | Build remains in queue; retry on next available agent | Delayed execution; if persistent, queue grows |
| GitHub clone failure | Pipeline stage fails with FAILURE result | Build marked FAILURE; Slack alert if on master |
| Artifactory pull failure | Build step fails; pipeline aborted | Build marked FAILURE |
| EC2 agent lost mid-build | Build aborted with ABORTED result on next controller startup (S02 hook) | Orphaned build; retrigger manually |

## Sequence Diagram

```
GHE               Controller         EC2Agent        Artifactory     LoggingStack
 |                    |                  |                 |               |
 |--push webhook----->|                  |                 |               |
 |                    |--validate sig--->|                 |               |
 |                    |--queue build---->|                 |               |
 |                    |--launch EC2----->|                 |               |
 |                    |<--agent connect--|                 |               |
 |                    |--checkout SCM--->|                 |               |
 |                    |                  |--git clone----->GHE             |
 |                    |                  |<--source code---|               |
 |                    |                  |--pull deps----->|               |
 |                    |                  |<--dependencies--|               |
 |                    |--run stages----->|                 |               |
 |                    |                  |--push artifacts>|               |
 |                    |                  |--stream logs------------------->|
 |                    |<--build result---|                 |               |
```

## Related

- Architecture dynamic view: `components-continuumJenkinsController`
- Related flows: [EC2 Agent Lifecycle](ec2-agent-lifecycle.md), [Controller Startup and Configuration Load](controller-startup.md)
