---
service: "deploybot"
title: "Webhook-Triggered Deployment"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "webhook-triggered-deployment"
flow_type: event-driven
trigger: "GitHub push event received at POST /request/webhook"
participants:
  - "GitHub"
  - "deploybotApi"
  - "deploybotOrchestrator"
  - "deploybotValidator"
  - "deploybotExecutor"
  - "deploybotNotifier"
  - "deploybotAudit"
  - "externalDeploybotDatabase_43aa"
  - "Kubernetes API / Docker Engine"
  - "Jira"
  - "externalS3Bucket_4b6c"
  - "Slack"
  - "PEST"
architecture_ref: "dynamic-deploybot-webhook-deploy"
---

# Webhook-Triggered Deployment

## Summary

This is the primary deployment flow. A developer pushes commits to a GitHub repository; GitHub sends a push event webhook to deploybot. deploybot parses the `.deploy_bot.yml` configuration from the pushed branch, runs the full validation pipeline (build checks, manual approval gates, ProdCAT, GPROD, image validation), executes the deployment via Kubernetes or Docker, and then finalizes by closing Jira SOX tickets, archiving logs to S3, publishing PEST lifecycle events, and sending Slack notifications.

## Trigger

- **Type**: event
- **Source**: GitHub push webhook to `POST /request/webhook`
- **Frequency**: On every qualifying push to a tracked branch per `.deploy_bot.yml` configuration

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GitHub | Push event source; provides `.deploy_bot.yml` and commit status | external |
| `deploybotApi` | Receives webhook, validates HMAC signature, parses payload | `deploybotApi` |
| `deploybotOrchestrator` | Manages deployment lifecycle state machine | `deploybotOrchestrator` |
| `deploybotValidator` | Runs all validation gates before execution | `deploybotValidator` |
| `deploybotExecutor` | Executes deployment on Kubernetes or Docker | `deploybotExecutor` |
| `deploybotNotifier` | Sends Slack, Jira, and PEST notifications | `deploybotNotifier` |
| `deploybotAudit` | Records SOX audit log entries | `deploybotAudit` |
| MySQL | Persists deployment state and audit records | `externalDeploybotDatabase_43aa` |
| Kubernetes API / Docker Engine | Executes the actual deployment workload | external |
| Jira | Receives SOX logbook ticket create/close | external |
| AWS S3 | Receives archived deployment log | `externalS3Bucket_4b6c` |
| Slack | Receives deployment stage notifications | external |
| PEST | Receives lifecycle events | external |

## Steps

1. **Receives push webhook**: GitHub POSTs a push event to `POST /request/webhook` with `X-Hub-Signature` header.
   - From: `GitHub`
   - To: `deploybotApi`
   - Protocol: HTTPS webhook

2. **Validates HMAC signature**: `deploybotApi` verifies the `X-Hub-Signature` header to authenticate the webhook payload.
   - From: `deploybotApi`
   - To: `deploybotApi` (internal validation)
   - Protocol: internal

3. **Reads `.deploy_bot.yml`**: `deploybotApi` fetches the `.deploy_bot.yml` configuration from the pushed branch via GitHub REST API to determine deployment targets and settings.
   - From: `deploybotApi`
   - To: `GitHub`
   - Protocol: REST (HTTPS)

4. **Creates deployment record**: `deploybotOrchestrator` writes a new deployment request to MySQL with status `queued`.
   - From: `deploybotOrchestrator`
   - To: `externalDeploybotDatabase_43aa`
   - Protocol: MySQL / GORM

5. **Publishes deploy_queued notification**: `deploybotNotifier` sends a Slack `deploy_queued` message with project, environment, deployer, and commit SHA.
   - From: `deploybotNotifier`
   - To: Slack
   - Protocol: REST (HTTPS)

6. **Creates SOX Jira logbook ticket**: `deploybotAudit` creates a Jira logbook ticket for the deployment, satisfying SOX audit requirements.
   - From: `deploybotAudit`
   - To: Jira
   - Protocol: REST (HTTPS)

7. **Runs validation pipeline**: `deploybotValidator` evaluates all configured validation gates (build check, concurrent deployment check, dependent environment check, GPROD, ProdCAT, manual approval, pull validation). See [Deployment Validation Pipeline](deployment-validation-pipeline.md).
   - From: `deploybotOrchestrator`
   - To: `deploybotValidator`
   - Protocol: direct

8. **Transitions to executing state**: On validation success, `deploybotOrchestrator` updates deployment status to `executing` in MySQL and publishes `deploy_start` to PEST.
   - From: `deploybotOrchestrator`
   - To: `externalDeploybotDatabase_43aa`, PEST
   - Protocol: MySQL / GORM; REST (HTTPS)

9. **Publishes deploy_started notification**: `deploybotNotifier` sends Slack `deploy_started` message.
   - From: `deploybotNotifier`
   - To: Slack
   - Protocol: REST (HTTPS)

10. **Executes deployment**: `deploybotExecutor` launches the deployment container on Kubernetes or Docker, runs the deploy command, and streams logs back. See [Container Deployment Execution](container-deployment-execution.md).
    - From: `deploybotExecutor`
    - To: Kubernetes API or Docker Engine
    - Protocol: client-go (HTTPS) or Docker API

11. **Finalizes deployment**: On execution completion, `deploybotOrchestrator` triggers finalization. See [Deployment Finalization](deployment-finalization.md).
    - From: `deploybotOrchestrator`
    - To: `deploybotNotifier`, `deploybotAudit`, S3, Jira, Slack, PEST
    - Protocol: multiple

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid HMAC signature | Return HTTP 401 to GitHub; no deployment created | Webhook rejected; no deployment queued |
| Missing or invalid `.deploy_bot.yml` | Return error; deployment marked failed | No deployment queued; Slack notification with error |
| Validation gate failure | Deployment blocked in `validating` state | Deployment waits or fails; operator can authorize or kill |
| Execution failure (non-zero exit code) | Deployment marked `failed`; finalization still runs | Jira ticket closed as failed; S3 log archived; Slack `deploy_failed` sent |
| Jira ticket creation failure | Logged; deployment continues | SOX audit gap; must be manually remediated |
| S3 log upload failure | Logged; deployment outcome unaffected | Logs not archived; deployment marked complete/failed normally |
| Slack notification failure | Logged; deployment continues | Notifications suppressed; deployment proceeds |

## Sequence Diagram

```
GitHub             -> deploybotApi:          POST /request/webhook (X-Hub-Signature)
deploybotApi       -> GitHub:                GET .deploy_bot.yml (REST API)
deploybotApi       -> deploybotOrchestrator: Dispatch deployment request
deploybotOrchestrator -> MySQL:              INSERT deploy_request (status=queued)
deploybotOrchestrator -> deploybotNotifier:  Notify deploy_queued
deploybotNotifier  -> Slack:                 deploy_queued message
deploybotAudit     -> Jira:                  Create SOX logbook ticket
deploybotOrchestrator -> deploybotValidator: Run validation pipeline
deploybotValidator --> deploybotOrchestrator: Validation passed
deploybotOrchestrator -> MySQL:              UPDATE status=executing
deploybotOrchestrator -> PEST:               deploy_start event
deploybotNotifier  -> Slack:                 deploy_started message
deploybotOrchestrator -> deploybotExecutor:  Execute deployment
deploybotExecutor  -> Kubernetes/Docker:     Launch deploy container
Kubernetes/Docker  --> deploybotExecutor:    Execution complete (exit code)
deploybotExecutor  --> deploybotOrchestrator: Execution result
deploybotOrchestrator -> MySQL:              UPDATE status=complete/failed
deploybotOrchestrator -> PEST:               deploy_complete event
deploybotAudit     -> Jira:                  Close SOX logbook ticket
deploybotNotifier  -> S3:                    Archive deployment log
deploybotNotifier  -> Slack:                 deploy_completed/deploy_failed message
```

## Related

- Architecture dynamic view: `dynamic-deploybot-webhook-deploy`
- Related flows: [Deployment Validation Pipeline](deployment-validation-pipeline.md), [Container Deployment Execution](container-deployment-execution.md), [Deployment Finalization](deployment-finalization.md), [Manual API Deploy](manual-api-deploy.md)
