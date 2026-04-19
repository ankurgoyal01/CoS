---
service: "deploybot"
title: "Headless Automated Deployment"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "headless-automated-deployment"
flow_type: event-driven
trigger: "Automated system trigger (GitHub push webhook or POST /v1/request) with headless/no-approval configuration in .deploy_bot.yml"
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
architecture_ref: "dynamic-deploybot-headless"
---

# Headless Automated Deployment

## Summary

The headless automated deployment flow handles deployments configured in `.deploy_bot.yml` to bypass manual authorization gates. This is used for low-risk environments (such as development) or for services with fully automated pipelines where human approval is not required. The flow follows the same validation and execution path as a standard deployment but skips the `awaiting_authorization` gate, allowing the deployment to proceed to execution automatically once all other validation gates pass.

## Trigger

- **Type**: event (webhook) or api-call
- **Source**: GitHub push webhook to `POST /request/webhook`, or programmatic request to `POST /v1/request`, where the target project/environment has `require_authorization: false` (or equivalent) in `.deploy_bot.yml`
- **Frequency**: On every qualifying push or API request to a headless-configured target

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `deploybotApi` | Receives trigger (webhook or API); authenticates; dispatches | `deploybotApi` |
| `deploybotOrchestrator` | Orchestrates deployment lifecycle without waiting for human approval | `deploybotOrchestrator` |
| `deploybotValidator` | Runs all validation gates except manual authorization | `deploybotValidator` |
| `deploybotExecutor` | Executes deployment on Kubernetes or Docker | `deploybotExecutor` |
| `deploybotNotifier` | Sends Slack, Jira, PEST notifications | `deploybotNotifier` |
| `deploybotAudit` | Creates and closes SOX Jira logbook ticket | `deploybotAudit` |
| MySQL | Persists deployment state | `externalDeploybotDatabase_43aa` |
| Jira | Receives SOX logbook ticket (mandatory for all deployments) | external |
| AWS S3 | Receives archived log | `externalS3Bucket_4b6c` |
| Slack | Receives deployment notifications | external |
| PEST | Receives lifecycle events | external |

## Steps

1. **Receives deployment trigger**: `deploybotApi` receives either a GitHub push webhook or a `POST /v1/request` API call; authenticates the request.
   - From: GitHub webhook or API caller
   - To: `deploybotApi`
   - Protocol: HTTPS webhook or REST (HTTPS)

2. **Reads headless configuration**: `deploybotOrchestrator` reads the `.deploy_bot.yml` for the target project/environment and confirms manual authorization is not required (headless mode).
   - From: `deploybotOrchestrator`
   - To: `deploybotOrchestrator` (config lookup)
   - Protocol: internal

3. **Creates deployment record**: `deploybotOrchestrator` writes the deployment request to MySQL with status `queued`.
   - From: `deploybotOrchestrator`
   - To: `externalDeploybotDatabase_43aa`
   - Protocol: MySQL / GORM

4. **Creates SOX Jira logbook ticket**: `deploybotAudit` creates a Jira logbook ticket — mandatory for all deployments regardless of headless mode.
   - From: `deploybotAudit`
   - To: Jira
   - Protocol: REST (HTTPS)

5. **Sends deploy_queued Slack notification**: `deploybotNotifier` notifies Slack.
   - From: `deploybotNotifier`
   - To: Slack
   - Protocol: REST (HTTPS)

6. **Runs validation pipeline (minus manual gate)**: `deploybotValidator` evaluates all configured validation gates — build checks, concurrent deployment check, dependent environment check, GPROD, ProdCAT, image pull validation, Conveyor maintenance window — but does NOT pause for manual authorization.
   - From: `deploybotOrchestrator`
   - To: `deploybotValidator`
   - Protocol: direct

7. **Transitions to executing without human approval**: `deploybotOrchestrator` transitions deployment directly to `executing` state upon validation success, without waiting for a human to POST to `/authorize`.
   - From: `deploybotOrchestrator`
   - To: `externalDeploybotDatabase_43aa`, PEST
   - Protocol: MySQL / GORM; REST

8. **Publishes deploy_started notification**: `deploybotNotifier` sends Slack `deploy_started`.
   - From: `deploybotNotifier`
   - To: Slack
   - Protocol: REST (HTTPS)

9. **Executes deployment**: `deploybotExecutor` runs the deployment. See [Container Deployment Execution](container-deployment-execution.md).
   - From: `deploybotExecutor`
   - To: Kubernetes API or Docker Engine
   - Protocol: client-go (HTTPS) or Docker API

10. **Finalizes deployment**: `deploybotOrchestrator` runs full finalization. See [Deployment Finalization](deployment-finalization.md).
    - From: `deploybotOrchestrator`
    - To: `deploybotNotifier`, `deploybotAudit`, S3, Jira, Slack, PEST
    - Protocol: multiple

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Validation gate (non-approval) fails | Deployment blocked in `validating` state | Operator must resolve or kill; no human approval gate to bypass |
| Execution failure | Deployment marked failed; finalization runs | Jira ticket closed as failed; Slack deploy_failed sent |
| Misconfiguration (approval actually required) | Validation gate blocks deployment waiting for authorization | Operator must authorize via `/authorize` or reconfigure `.deploy_bot.yml` |
| Jira SOX ticket creation failure | Logged; deployment proceeds | SOX audit gap regardless of headless mode |

## Sequence Diagram

```
GitHub/Caller      -> deploybotApi:           Push webhook or POST /v1/request
deploybotApi       -> deploybotOrchestrator:  Dispatch deployment (headless mode)
deploybotOrchestrator -> deploybotOrchestrator: Confirm no manual auth required
deploybotOrchestrator -> MySQL:               INSERT deploy_request (status=queued)
deploybotAudit     -> Jira:                   Create SOX logbook ticket
deploybotNotifier  -> Slack:                  deploy_queued message
deploybotOrchestrator -> deploybotValidator:  Run validation (skip manual auth gate)
deploybotValidator --> deploybotOrchestrator: Validation passed
deploybotOrchestrator -> MySQL:               UPDATE status=executing (no /authorize needed)
deploybotOrchestrator -> PEST:                deploy_start event
deploybotNotifier  -> Slack:                  deploy_started message
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

- Architecture dynamic view: `dynamic-deploybot-headless`
- Related flows: [Webhook-Triggered Deployment](webhook-triggered-deployment.md), [Manual API Deploy](manual-api-deploy.md), [Deployment Validation Pipeline](deployment-validation-pipeline.md)
