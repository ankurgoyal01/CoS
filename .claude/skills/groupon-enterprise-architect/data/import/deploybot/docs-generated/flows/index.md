---
service: "deploybot"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 8
---

# Flows

Process and flow documentation for deploybot.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Webhook-Triggered Deployment](webhook-triggered-deployment.md) | event-driven | GitHub push webhook | GitHub push event received, `.deploy_bot.yml` parsed, validation pipeline run, deployment executed, finalization performed |
| [Deployment Validation Pipeline](deployment-validation-pipeline.md) | synchronous | Deployment request (webhook or API) | All validation gates evaluated in sequence and concurrently before deployment execution is permitted |
| [Container Deployment Execution](container-deployment-execution.md) | synchronous | Validated deployment request | Deploy container workload via Kubernetes or Docker, stream logs, capture exit status |
| [Deployment Finalization](deployment-finalization.md) | synchronous | Deployment execution complete | Close Jira SOX ticket, archive logs to S3, publish PEST events, send Slack notifications |
| [Deployment Promotion](deployment-promotion.md) | synchronous | Manual promote action via web UI | Promote a successfully deployed artifact to the next environment in the promotion chain |
| [Manual API Deploy](manual-api-deploy.md) | synchronous | POST /v1/request API call | Programmatic deployment request without GitHub webhook; follows same validation and execution path |
| [Config Validation Only](config-validation-only.md) | synchronous | POST /v1/validate API call | Validates `.deploy_bot.yml` configuration file without executing a deployment |
| [Headless Automated Deployment](headless-automated-deployment.md) | event-driven | Automated system trigger (no human approval) | Automated deployment flow that bypasses manual authorization gates |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 5 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 0 |
| Mixed (sync trigger, async side-effects) | 1 |

## Cross-Service Flows

- **Webhook-Triggered Deployment** spans: GitHub (trigger), deploybotService (orchestration), Kubernetes/Docker (execution), Jira (audit), S3 (archival), Slack (notification), PEST (lifecycle events). See `dynamic-deploybot-webhook-deploy`.
- **Deployment Validation Pipeline** spans: deploybotService, GitHub REST API (commit status), Conveyor CI (maintenance window), ProdCAT (production readiness). See `dynamic-deploybot-validation`.
- **Deployment Promotion** spans: deploybotService, Artifactory (image promotion), Jira, Slack. See `dynamic-deploybot-promotion`.
