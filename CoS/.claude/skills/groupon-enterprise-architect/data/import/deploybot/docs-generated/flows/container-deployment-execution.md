---
service: "deploybot"
title: "Container Deployment Execution"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "container-deployment-execution"
flow_type: synchronous
trigger: "Deployment validation passes; deploybotOrchestrator invokes deploybotExecutor"
participants:
  - "deploybotOrchestrator"
  - "deploybotExecutor"
  - "deploybotInitExec"
  - "Kubernetes API"
  - "Docker Engine"
  - "externalDeploybotDatabase_43aa"
architecture_ref: "dynamic-deploybot-execution"
---

# Container Deployment Execution

## Summary

After all validation gates pass, deploybot executes the actual deployment by launching a container on either Kubernetes or Docker (determined by the `.deploy_bot.yml` configuration). The container runs the deployment command (Capistrano, UberDeploy, Napistrano, or a Kubernetes rollout) against the target environment. Log output is streamed in real time and made available via the web UI. On completion, the exit code determines success or failure and is returned to the orchestrator.

## Trigger

- **Type**: api-call (internal)
- **Source**: `deploybotOrchestrator` calls `deploybotExecutor` after validation passes
- **Frequency**: Once per validated deployment request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `deploybotOrchestrator` | Triggers execution; receives result | `deploybotOrchestrator` |
| `deploybotExecutor` | Selects execution target; launches and monitors container | `deploybotExecutor` |
| `deploybotInitExec` | Provides SSH key and Kubernetes auth setup before the main container starts | `deploybotInitExec` |
| Kubernetes API | Runs deployment as a Kubernetes Job or Pod | external |
| Docker Engine | Runs deployment as a Docker container (legacy) | external |
| MySQL | Updated with execution status; log references stored | `externalDeploybotDatabase_43aa` |

## Steps

1. **Receives execution request**: `deploybotOrchestrator` passes the validated deployment request to `deploybotExecutor`, including target environment and execution mode (Kubernetes or Docker).
   - From: `deploybotOrchestrator`
   - To: `deploybotExecutor`
   - Protocol: direct

2. **Determines execution target**: `deploybotExecutor` reads the execution mode from `.deploy_bot.yml` — Kubernetes (K8s job/pod) or Docker (container).
   - From: `deploybotExecutor`
   - To: `deploybotExecutor` (internal config lookup)
   - Protocol: internal

3. **Verifies init container readiness** (Kubernetes path): `deploybotInitExec` init container has already configured SSH keys and Kubernetes service account auth for the deployment namespace.
   - From: `deploybotInitExec`
   - To: Kubernetes API
   - Protocol: client-go (HTTPS)

4. **Launches deployment container** (Kubernetes path): `deploybotExecutor` submits a Kubernetes Job or Pod spec to the Kubernetes API, referencing the validated Docker image from Artifactory.
   - From: `deploybotExecutor`
   - To: Kubernetes API
   - Protocol: client-go (HTTPS)

5. **Launches deployment container** (Docker path): `deploybotExecutor` starts a Docker container with the deployment image and command on the target Docker host (legacy Docker Swarm on snc1/sac1).
   - From: `deploybotExecutor`
   - To: Docker Engine
   - Protocol: Docker API

6. **Streams deployment logs**: `deploybotExecutor` streams stdout/stderr from the running container and makes them available via `GET /deployments/{key}/log` for real-time viewing.
   - From: Kubernetes API or Docker Engine
   - To: `deploybotExecutor` → `deploybotApi`
   - Protocol: client-go log streaming or Docker log stream

7. **Monitors execution**: `deploybotExecutor` watches the container/pod until it terminates; captures exit code.
   - From: `deploybotExecutor`
   - To: Kubernetes API or Docker Engine
   - Protocol: client-go watch or Docker events

8. **Records execution result**: `deploybotExecutor` writes execution outcome (success or failure with exit code) to MySQL and returns result to `deploybotOrchestrator`.
   - From: `deploybotExecutor`
   - To: `externalDeploybotDatabase_43aa`, `deploybotOrchestrator`
   - Protocol: MySQL / GORM; direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Kubernetes API unreachable | Execution fails immediately | Deployment marked failed; finalization still runs |
| Docker Engine unreachable | Execution fails immediately | Deployment marked failed; finalization still runs |
| Container exits with non-zero code | Exit code captured; deployment marked failed | Finalization runs with failed status |
| Log stream interrupted | Partial logs captured; deployment continues | Logs may be incomplete; execution outcome still recorded |
| Deployment killed via POST /deployments/{key}/kill | Running container terminated by operator | Deployment marked killed; finalization runs |
| Container image pull failure | Pod/container fails to start | Deployment marked failed; error visible in log stream |

## Sequence Diagram

```
deploybotOrchestrator -> deploybotExecutor:   Execute deployment (key, target, image, command)
deploybotExecutor     -> deploybotExecutor:   Determine execution mode (K8s or Docker)
deploybotExecutor     -> Kubernetes API:      Submit Job/Pod spec with deploy image
Kubernetes API        -> Docker/Container:    Pull image and start container
Docker/Container      -> deploybotExecutor:   Stream stdout/stderr logs
deploybotExecutor     -> deploybotApi:        Expose log stream on GET /deployments/{key}/log
Docker/Container      --> Kubernetes API:     Container exits (exit code)
Kubernetes API        --> deploybotExecutor:  Pod terminated (exit code)
deploybotExecutor     -> MySQL:               UPDATE deploy_request (status, exit_code)
deploybotExecutor     --> deploybotOrchestrator: Execution result (success/failed)
```

## Related

- Architecture dynamic view: `dynamic-deploybot-execution`
- Related flows: [Webhook-Triggered Deployment](webhook-triggered-deployment.md), [Deployment Finalization](deployment-finalization.md), [Deployment Validation Pipeline](deployment-validation-pipeline.md)
