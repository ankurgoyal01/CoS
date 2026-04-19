---
service: "cloud-jenkins-main"
title: "Controller Startup and Configuration Load"
generated: "2026-03-03"
type: flow
flow_name: "controller-startup"
flow_type: scheduled
trigger: "EC2 instance start on deployment or redeployment"
participants:
  - "continuumJenkinsController"
  - "jenkinsConfigLoader"
  - "jenkinsPipelineOrchestrator"
  - "jenkinsObservabilityEmitter"
  - "metricsStack"
  - "cloudPlatform"
architecture_ref: "components-continuumJenkinsController"
---

# Controller Startup and Configuration Load

## Summary

When the Jenkins controller EC2 instance starts (either via a fresh deployment or a rolling update), a versioned Docker configuration image is mounted into the container. The Configuration as Code plugin loads all JCasC YAML files, followed by a sequence of numbered Groovy init hook scripts. These scripts post a Wavefront startup event, abort any builds that were running on ephemeral EC2 agents at the time of restart, register static mobile build nodes, create EC2 canary pipeline jobs, and close the Wavefront startup event when init is complete.

## Trigger

- **Type**: schedule / deployment
- **Source**: AWS EC2 instance start, triggered by Terraform `make apply-all` or manual redeployment
- **Frequency**: On each deployment or unexpected restart

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Jenkins Main Controller | Hosts and executes the startup sequence | `continuumJenkinsController` |
| Configuration Loader | Reads and applies JCasC YAML and Groovy hooks from the mounted config image | `jenkinsConfigLoader` |
| Pipeline Orchestrator | Becomes available for job execution after init completes | `jenkinsPipelineOrchestrator` |
| Observability Emitter | Posts lifecycle events and metrics | `jenkinsObservabilityEmitter` |
| Wavefront (metricsStack) | Receives the `cloud_jenkins_main_start` event | `metricsStack` |
| AWS (cloudPlatform) | Provides the EC2 instance; hosts AWS Secrets Manager for secret resolution | `cloudPlatform` |

## Steps

1. **Mount configuration image volumes**: The Docker config image (Alpine 3.15) is mounted, making `casc/`, `init.groovy.d/`, `boot-failure.groovy.d/`, and `other/` available to the controller container.
   - From: `continuumJenkinsController` (container runtime)
   - To: Filesystem volumes
   - Protocol: Docker volume mount

2. **Resolve secrets from AWS Secrets Manager**: The Configuration as Code plugin reads all `${/path/to/secret}` references in JCasC YAML and fetches their values from AWS Secrets Manager.
   - From: `jenkinsConfigLoader`
   - To: `cloudPlatform` (AWS Secrets Manager)
   - Protocol: AWS SDK (HTTPS)

3. **Apply JCasC YAML configuration**: The Configuration as Code plugin processes all YAML files in `casc/` — general settings, authorization, EC2 cloud templates, credentials, tool installations, shared libraries, plugin configs.
   - From: `jenkinsConfigLoader`
   - To: `continuumJenkinsController` (in-memory configuration)
   - Protocol: direct (in-process)

4. **S01 — Post Wavefront startup event**: The first Groovy init script posts a `cloud_jenkins_main_start` event to the Wavefront API, recording service, region, env, atom, and component tags. Active only when `ENV` is `staging` or `production` and `STACK` is `main`.
   - From: `jenkinsObservabilityEmitter`
   - To: `metricsStack` (`https://groupon.wavefront.com/api/v2/event`)
   - Protocol: HTTPS POST

5. **S02 — Abort builds on EC2 agents**: All builds running on EC2 (AWS) agents are interrupted with `ABORTED` status and reason "Build aborted due to Jenkins controller restart". This prevents orphaned builds from resuming on terminated ephemeral agents.
   - From: `jenkinsPipelineOrchestrator`
   - To: Running EC2 executors (in-memory)
   - Protocol: direct (in-process)

6. **S04 — Close Wavefront startup event**: After init completes, the Wavefront event opened in S01 is closed by posting to `/api/v2/event/{id}/close`.
   - From: `jenkinsObservabilityEmitter`
   - To: `metricsStack`
   - Protocol: HTTPS POST

7. **S05 — Configure AWS Device Farm**: The Device Farm plugin is configured for mobile testing pipelines.
   - From: `jenkinsConfigLoader`
   - To: `continuumJenkinsController` (plugin configuration)
   - Protocol: direct (in-process)

8. **S06 — Register Android automation nodes**: Static SSH agents for Android build containers (`distbuild-docker{4-11}-dev` hosts, 20 containers each) are registered in Jenkins. Active only for main staging/production stacks.
   - From: `jenkinsConfigLoader`
   - To: `continuumJenkinsController` (node registry)
   - Protocol: direct (in-process)

9. **S07 — Register macOS build nodes**: Static JNLP agents for iOS build, test, submission, and pro nodes (`distbuild-osx-coremobile-*`) are registered. Active for main staging/production stacks.
   - From: `jenkinsConfigLoader`
   - To: `continuumJenkinsController` (node registry)
   - Protocol: direct (in-process)

10. **S08 — Create EC2 canary pipeline jobs**: The `cloud-jenkins/ec2-canary` folder and per-label canary pipeline jobs are created via Job DSL for all cross-account agent labels.
    - From: `jenkinsConfigLoader`
    - To: `jenkinsPipelineOrchestrator` (job registry)
    - Protocol: direct (in-process)

11. **Controller enters NORMAL_OP**: The controller is now ready to accept jobs; the smoke test suite polls `wait_for_normal_op(25)` until this state is reached.
    - From: `continuumJenkinsController`
    - To: Smoke test client / build queue
    - Protocol: Jenkins HTTP API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| JCasC YAML parse error | Controller fails to start; `boot-failure.groovy.d/S01WavefrontEventClose.groovy` fires to close the open Wavefront event | Controller does not accept jobs; redeploy required |
| AWS Secrets Manager secret missing | JCasC secret interpolation fails; controller startup aborted | Missing credentials; redeploy after adding secrets |
| Wavefront API unreachable (S01) | HTTP error logged; startup event not recorded | No operational impact; init continues |
| EC2 agent abort failure (S02) | Individual executor interrupt logged; init continues | Some builds may remain in inconsistent state; will time out |
| macOS / Android node registration failure | Exception in Groovy init; may halt remaining init steps | Investigate controller logs; static nodes will not be available |

## Sequence Diagram

```
Terraform         Controller       ConfigLoader      SecretsManager    Wavefront
    |                 |                 |                  |               |
    |--apply-all----->|                 |                  |               |
    |                 |--mount config-->|                  |               |
    |                 |                |--resolve secrets->|               |
    |                 |                |<--secret values---|               |
    |                 |                |--apply JCasC----->|               |
    |                 |--S01 init------>|                  |               |
    |                 |                |--POST event--------------------->>|
    |                 |--S02 init------>|                  |               |
    |                 |                |--abort EC2 builds-|               |
    |                 |--S04 init------>|                  |               |
    |                 |                |--close event-------------------->>|
    |                 |--S06/S07/S08--->|                  |               |
    |                 |                |--register nodes--|               |
    |                 |--NORMAL_OP----->|                  |               |
```

## Related

- Architecture dynamic view: `components-continuumJenkinsController`
- Related flows: [Pipeline Job Execution](pipeline-job-execution.md), [Self-Deploy Pipeline](self-deploy-pipeline.md)
