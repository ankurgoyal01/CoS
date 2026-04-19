---
service: "deploybot"
title: "Deployment Finalization"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deployment-finalization"
flow_type: synchronous
trigger: "Deployment execution completes (success or failure)"
participants:
  - "deploybotOrchestrator"
  - "deploybotNotifier"
  - "deploybotAudit"
  - "Jira"
  - "externalS3Bucket_4b6c"
  - "PEST"
  - "Slack"
  - "externalDeploybotDatabase_43aa"
architecture_ref: "dynamic-deploybot-finalization"
---

# Deployment Finalization

## Summary

After deployment execution completes — whether successfully or with a failure — deploybot runs a structured finalization sequence. The finalization phase is responsible for satisfying all SOX compliance requirements and notifying all stakeholders: it closes the Jira SOX logbook ticket with the final outcome, archives the full deployment log to AWS S3, publishes a `deploy_complete` lifecycle event to PEST, and sends a final Slack notification (`deploy_completed` or `deploy_failed`). All finalization steps are attempted regardless of deployment outcome.

## Trigger

- **Type**: api-call (internal)
- **Source**: `deploybotOrchestrator` after `deploybotExecutor` returns execution result
- **Frequency**: Once per deployment (on every completion, success or failure)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `deploybotOrchestrator` | Triggers finalization; updates final deployment state in MySQL | `deploybotOrchestrator` |
| `deploybotNotifier` | Coordinates all external notification and archival actions | `deploybotNotifier` |
| `deploybotAudit` | Closes SOX Jira logbook ticket | `deploybotAudit` |
| Jira | Receives ticket closure with outcome and log URL | external |
| AWS S3 | Receives archived deployment log upload | `externalS3Bucket_4b6c` |
| PEST | Receives `deploy_complete` lifecycle event | external |
| Slack | Receives `deploy_completed` or `deploy_failed` notification | external |
| MySQL | Updated with final deployment status and archival URL | `externalDeploybotDatabase_43aa` |

## Steps

1. **Receives execution result**: `deploybotOrchestrator` receives the execution outcome (success or failure with exit code) from `deploybotExecutor`.
   - From: `deploybotExecutor`
   - To: `deploybotOrchestrator`
   - Protocol: direct

2. **Updates final deployment state**: `deploybotOrchestrator` writes the final status (`complete` or `failed`) and execution metadata to MySQL.
   - From: `deploybotOrchestrator`
   - To: `externalDeploybotDatabase_43aa`
   - Protocol: MySQL / GORM

3. **Archives deployment log to S3**: `deploybotNotifier` uploads the full deployment log output to `externalS3Bucket_4b6c`, generating a durable archive URL.
   - From: `deploybotNotifier`
   - To: `externalS3Bucket_4b6c`
   - Protocol: AWS SDK (HTTPS)

4. **Closes SOX Jira logbook ticket**: `deploybotAudit` updates the Jira ticket created at deployment start, setting the outcome (success/failure) and attaching the S3 log archive URL.
   - From: `deploybotAudit`
   - To: Jira
   - Protocol: REST (HTTPS)

5. **Publishes deploy_complete event to PEST**: `deploybotNotifier` publishes a `deploy_complete` event containing deployment key, project, environment, final status, and duration.
   - From: `deploybotNotifier`
   - To: PEST
   - Protocol: REST (HTTPS) / Event bus

6. **Sends Slack final notification**: `deploybotNotifier` sends a `deploy_completed` or `deploy_failed` Slack message including project, environment, duration, deployer, and S3 log URL.
   - From: `deploybotNotifier`
   - To: Slack
   - Protocol: REST (HTTPS)

7. **Records finalization metadata in MySQL**: `deploybotNotifier` stores the S3 log URL and Jira ticket closure reference back to MySQL for future query via `GET /v1/deployments/{org}/{project}`.
   - From: `deploybotNotifier`
   - To: `externalDeploybotDatabase_43aa`
   - Protocol: MySQL / GORM

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| S3 log upload fails | Error logged; finalization continues | Log not archived; Jira ticket may lack log URL; deployment status still updated |
| Jira ticket closure fails | Error logged; finalization continues | SOX audit gap; must be manually remediated by compliance team |
| PEST event publish fails | Error logged; finalization continues | Downstream consumers miss lifecycle event; deployment status still updated |
| Slack notification fails | Error logged; finalization continues | Engineers not notified; deployment status still updated |
| Multiple finalization failures | All failures logged; MySQL state update is last resort | Partial finalization; operator must review logs and remediate manually |

## Sequence Diagram

```
deploybotExecutor     --> deploybotOrchestrator: Execution result (success/failed, exit code)
deploybotOrchestrator -> MySQL:                  UPDATE deploy_request (status=complete/failed)
deploybotOrchestrator -> deploybotNotifier:      Trigger finalization
deploybotNotifier     -> S3:                     PUT deployment log archive
S3                    --> deploybotNotifier:      S3 archive URL
deploybotAudit        -> Jira:                   Close SOX logbook ticket (outcome, log URL)
deploybotNotifier     -> PEST:                   deploy_complete event
deploybotNotifier     -> Slack:                  deploy_completed/deploy_failed message
deploybotNotifier     -> MySQL:                  UPDATE with log URL and Jira ticket ref
```

## Related

- Architecture dynamic view: `dynamic-deploybot-finalization`
- Related flows: [Webhook-Triggered Deployment](webhook-triggered-deployment.md), [Container Deployment Execution](container-deployment-execution.md), [Deployment Promotion](deployment-promotion.md)
