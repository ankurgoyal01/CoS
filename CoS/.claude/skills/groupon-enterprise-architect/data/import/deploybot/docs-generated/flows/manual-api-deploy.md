---
service: "deploybot"
title: "Manual API Deploy"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "manual-api-deploy"
flow_type: synchronous
trigger: "POST /v1/request with HTTP Basic Auth credentials"
participants:
  - "deploybotApi"
  - "deploybotOrchestrator"
  - "deploybotValidator"
  - "deploybotExecutor"
  - "deploybotNotifier"
  - "deploybotAudit"
  - "externalDeploybotDatabase_43aa"
  - "Jira"
  - "externalS3Bucket_4b6c"
  - "Slack"
  - "PEST"
architecture_ref: "dynamic-deploybot-manual-api"
---

# Manual API Deploy

## Summary

The manual API deploy flow allows CI systems, automation scripts, or engineers to submit a deployment request programmatically without going through a GitHub push webhook. The caller POSTs to `POST /v1/request` with HTTP Basic Auth credentials and a JSON body specifying the project, organization, environment, and deployment parameters. Once accepted, the deployment follows the same validation pipeline and execution path as a webhook-triggered deployment.

## Trigger

- **Type**: api-call
- **Source**: Internal automation, CI system, or engineer via `POST /v1/request` with HTTP Basic Auth
- **Frequency**: On-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Caller (CI / automation / engineer) | Submits deployment request via HTTP | external |
| `deploybotApi` | Authenticates request and dispatches to orchestrator | `deploybotApi` |
| `deploybotOrchestrator` | Manages deployment lifecycle | `deploybotOrchestrator` |
| `deploybotValidator` | Runs validation pipeline | `deploybotValidator` |
| `deploybotExecutor` | Executes deployment on Kubernetes or Docker | `deploybotExecutor` |
| `deploybotNotifier` | Sends Slack, Jira, PEST notifications | `deploybotNotifier` |
| `deploybotAudit` | Creates and closes SOX Jira logbook ticket | `deploybotAudit` |
| MySQL | Persists deployment state | `externalDeploybotDatabase_43aa` |
| Jira | Receives SOX logbook ticket | external |
| AWS S3 | Receives archived log | `externalS3Bucket_4b6c` |
| Slack | Receives deployment notifications | external |
| PEST | Receives lifecycle events | external |

## Steps

1. **Receives API deployment request**: Caller POSTs to `POST /v1/request` with HTTP Basic Auth header and JSON body containing project, org, environment, and deployment parameters.
   - From: Caller
   - To: `deploybotApi`
   - Protocol: REST (HTTPS)

2. **Authenticates caller**: `deploybotApi` validates HTTP Basic Auth credentials.
   - From: `deploybotApi`
   - To: `deploybotApi` (internal credential check)
   - Protocol: internal

3. **Parses deployment parameters**: `deploybotApi` reads the JSON body to extract project, org, environment, commit reference, and any override flags.
   - From: `deploybotApi`
   - To: `deploybotApi`
   - Protocol: internal

4. **Creates deployment record**: `deploybotOrchestrator` writes a new deployment request to MySQL with status `queued`.
   - From: `deploybotOrchestrator`
   - To: `externalDeploybotDatabase_43aa`
   - Protocol: MySQL / GORM

5. **Returns accepted response to caller**: `deploybotApi` returns HTTP 202 Accepted with the deployment key so the caller can poll status via `GET /v1/deployments/{org}/{project}` or the web UI.
   - From: `deploybotApi`
   - To: Caller
   - Protocol: REST (HTTPS)

6. **Sends deploy_queued Slack notification**: `deploybotNotifier` notifies Slack that the deployment has been queued.
   - From: `deploybotNotifier`
   - To: Slack
   - Protocol: REST (HTTPS)

7. **Creates SOX Jira logbook ticket**: `deploybotAudit` creates a Jira logbook ticket for the deployment.
   - From: `deploybotAudit`
   - To: Jira
   - Protocol: REST (HTTPS)

8. **Runs validation pipeline**: `deploybotValidator` evaluates all configured validation gates. See [Deployment Validation Pipeline](deployment-validation-pipeline.md).
   - From: `deploybotOrchestrator`
   - To: `deploybotValidator`
   - Protocol: direct

9. **Executes deployment**: `deploybotExecutor` runs the deployment on the configured target. See [Container Deployment Execution](container-deployment-execution.md).
   - From: `deploybotExecutor`
   - To: Kubernetes API or Docker Engine
   - Protocol: client-go (HTTPS) or Docker API

10. **Finalizes deployment**: `deploybotOrchestrator` runs the finalization sequence. See [Deployment Finalization](deployment-finalization.md).
    - From: `deploybotOrchestrator`
    - To: `deploybotNotifier`, `deploybotAudit`, S3, Jira, Slack, PEST
    - Protocol: multiple

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid HTTP Basic Auth credentials | Return HTTP 401 | Request rejected; no deployment created |
| Malformed request body | Return HTTP 400 | Request rejected; no deployment created |
| Validation gate failure | Deployment blocked in `validating` state | Caller polls status; operator intervenes or deployment times out |
| Execution failure | Deployment marked failed; finalization runs | SOX ticket closed as failed; Slack deploy_failed sent |

## Sequence Diagram

```
Caller             -> deploybotApi:           POST /v1/request (Basic Auth, JSON body)
deploybotApi       -> deploybotApi:           Validate credentials + parse body
deploybotApi       -> deploybotOrchestrator:  Dispatch deployment request
deploybotOrchestrator -> MySQL:               INSERT deploy_request (status=queued)
deploybotApi       --> Caller:                202 Accepted (deployment key)
deploybotNotifier  -> Slack:                  deploy_queued message
deploybotAudit     -> Jira:                   Create SOX logbook ticket
deploybotOrchestrator -> deploybotValidator:  Run validation pipeline
deploybotValidator --> deploybotOrchestrator: Validation passed
deploybotOrchestrator -> deploybotExecutor:   Execute deployment
deploybotExecutor  -> Kubernetes/Docker:      Launch deploy container
Kubernetes/Docker  --> deploybotExecutor:     Execution complete
deploybotExecutor  --> deploybotOrchestrator: Execution result
deploybotOrchestrator -> MySQL:               UPDATE status=complete/failed
deploybotAudit     -> Jira:                   Close SOX logbook ticket
deploybotNotifier  -> S3:                     Archive deployment log
deploybotNotifier  -> PEST:                   deploy_complete event
deploybotNotifier  -> Slack:                  deploy_completed/deploy_failed message
```

## Related

- Architecture dynamic view: `dynamic-deploybot-manual-api`
- Related flows: [Webhook-Triggered Deployment](webhook-triggered-deployment.md), [Deployment Validation Pipeline](deployment-validation-pipeline.md), [Headless Automated Deployment](headless-automated-deployment.md)
