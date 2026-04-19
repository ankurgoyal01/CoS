---
service: "deploybot"
title: "Deployment Promotion"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deployment-promotion"
flow_type: synchronous
trigger: "Authorized user POSTs to POST /deployments/{key}/promote/{target}"
participants:
  - "deploybotApi"
  - "deploybotOrchestrator"
  - "deploybotValidator"
  - "deploybotExecutor"
  - "deploybotNotifier"
  - "deploybotAudit"
  - "Artifactory"
  - "Okta"
  - "externalDeploybotDatabase_43aa"
  - "Jira"
  - "externalS3Bucket_4b6c"
  - "Slack"
  - "PEST"
architecture_ref: "dynamic-deploybot-promotion"
---

# Deployment Promotion

## Summary

Promotion allows a successfully deployed artifact to be pushed forward to the next environment in the configured promotion chain (e.g., staging to production). An authorized engineer triggers promotion via the web UI (`POST /deployments/{key}/promote/{target}`). deploybot validates the source deployment was successful, promotes the Docker image in Artifactory to the target environment's registry path, then executes the deployment in the target environment following the same validation and execution pipeline. A new deployment record is created for the promoted deployment.

## Trigger

- **Type**: user-action
- **Source**: Authorized engineer via `POST /deployments/{key}/promote/{target}` web UI endpoint (OAuth2/OIDC protected)
- **Frequency**: On-demand, after a successful deployment in the source environment

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `deploybotApi` | Receives and authenticates promotion request | `deploybotApi` |
| `deploybotOrchestrator` | Orchestrates promotion as a new deployment in the target environment | `deploybotOrchestrator` |
| `deploybotValidator` | Validates source deployment success and target environment readiness | `deploybotValidator` |
| `deploybotExecutor` | Executes the deployment in the target environment | `deploybotExecutor` |
| `deploybotNotifier` | Sends Slack, Jira, PEST notifications for the promoted deployment | `deploybotNotifier` |
| `deploybotAudit` | Creates and closes SOX Jira logbook ticket for the promoted deployment | `deploybotAudit` |
| Artifactory | Source image promoted to target environment's registry path | external |
| Okta | Authenticates the promoting engineer via OAuth2/OIDC | external |
| MySQL | Source deployment record queried; new promoted deployment record created | `externalDeploybotDatabase_43aa` |
| Jira | SOX logbook ticket created and closed for the promoted deployment | external |
| AWS S3 | Promoted deployment log archived | `externalS3Bucket_4b6c` |
| Slack | Promotion notifications sent | external |
| PEST | `deploy_start` and `deploy_complete` events published for the promoted deployment | external |

## Steps

1. **Receives promotion request**: Engineer POSTs to `POST /deployments/{key}/promote/{target}` via the web UI.
   - From: Engineer (browser)
   - To: `deploybotApi`
   - Protocol: REST (HTTPS)

2. **Authenticates engineer via Okta**: `deploybotApi` validates the OAuth2/OIDC session; unauthenticated requests are redirected to Okta login.
   - From: `deploybotApi`
   - To: Okta
   - Protocol: OIDC (HTTPS)

3. **Validates source deployment success**: `deploybotOrchestrator` queries MySQL to confirm the source deployment (identified by `{key}`) completed with status `complete`.
   - From: `deploybotOrchestrator`
   - To: `externalDeploybotDatabase_43aa`
   - Protocol: MySQL / GORM

4. **Promotes Docker image in Artifactory**: `deploybotNotifier` or `deploybotExecutor` calls Artifactory API to copy/promote the deployment image from the source environment's registry path to the target environment's path.
   - From: `deploybotExecutor` or `deploybotNotifier`
   - To: Artifactory
   - Protocol: REST (HTTPS)

5. **Creates new promoted deployment record**: `deploybotOrchestrator` inserts a new deployment record in MySQL for the target environment, linking it to the source deployment key.
   - From: `deploybotOrchestrator`
   - To: `externalDeploybotDatabase_43aa`
   - Protocol: MySQL / GORM

6. **Creates SOX Jira logbook ticket for promoted deployment**: `deploybotAudit` creates a new Jira ticket for the promoted deployment, referencing the source deployment.
   - From: `deploybotAudit`
   - To: Jira
   - Protocol: REST (HTTPS)

7. **Runs validation pipeline for target environment**: `deploybotValidator` runs all applicable validation gates for the target environment (may require additional gates for production). See [Deployment Validation Pipeline](deployment-validation-pipeline.md).
   - From: `deploybotOrchestrator`
   - To: `deploybotValidator`
   - Protocol: direct

8. **Executes promoted deployment**: `deploybotExecutor` deploys the promoted image to the target environment. See [Container Deployment Execution](container-deployment-execution.md).
   - From: `deploybotExecutor`
   - To: Kubernetes API or Docker Engine
   - Protocol: client-go (HTTPS) or Docker API

9. **Finalizes promoted deployment**: `deploybotOrchestrator` runs the finalization sequence for the promoted deployment. See [Deployment Finalization](deployment-finalization.md).
   - From: `deploybotOrchestrator`
   - To: `deploybotNotifier`, `deploybotAudit`, S3, Jira, Slack, PEST
   - Protocol: multiple

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Source deployment not in `complete` status | Promotion rejected; error returned to engineer | Promotion not initiated |
| Unauthenticated promotion request | Redirected to Okta login | Promotion blocked until authenticated |
| Artifactory image promotion fails | Deployment blocked; image not available in target registry | Promoted deployment marked failed before execution |
| Target environment validation failure | Promoted deployment blocked in validating state | Operator must resolve gate or kill |
| Target environment execution failure | Promoted deployment marked failed; finalization runs | Jira ticket closed as failed; Slack deploy_failed sent |

## Sequence Diagram

```
Engineer           -> deploybotApi:           POST /deployments/{key}/promote/{target}
deploybotApi       -> Okta:                   Validate OAuth2/OIDC session
Okta               --> deploybotApi:          Session valid
deploybotApi       -> deploybotOrchestrator:  Trigger promotion
deploybotOrchestrator -> MySQL:               SELECT source deployment (must be complete)
MySQL              --> deploybotOrchestrator: Source deployment confirmed complete
deploybotOrchestrator -> Artifactory:         Promote image to target environment registry
Artifactory        --> deploybotOrchestrator: Image promotion confirmed
deploybotOrchestrator -> MySQL:               INSERT promoted deploy_request (target env, status=queued)
deploybotAudit     -> Jira:                   Create SOX logbook ticket (promoted deploy)
deploybotOrchestrator -> deploybotValidator:  Run validation for target environment
deploybotValidator --> deploybotOrchestrator: Validation passed
deploybotOrchestrator -> deploybotExecutor:   Execute promoted deployment
deploybotExecutor  -> Kubernetes API:         Deploy promoted image
Kubernetes API     --> deploybotExecutor:     Execution complete
deploybotExecutor  --> deploybotOrchestrator: Execution result
deploybotOrchestrator -> MySQL:               UPDATE promoted deploy (status=complete/failed)
deploybotAudit     -> Jira:                   Close promoted deploy SOX ticket
deploybotNotifier  -> S3:                     Archive promoted deploy log
deploybotNotifier  -> PEST:                   deploy_complete event
deploybotNotifier  -> Slack:                  deploy_completed/deploy_failed message
```

## Related

- Architecture dynamic view: `dynamic-deploybot-promotion`
- Related flows: [Webhook-Triggered Deployment](webhook-triggered-deployment.md), [Deployment Validation Pipeline](deployment-validation-pipeline.md), [Deployment Finalization](deployment-finalization.md)
