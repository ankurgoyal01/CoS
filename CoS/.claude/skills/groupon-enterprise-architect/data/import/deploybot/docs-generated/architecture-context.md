---
service: "deploybot"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "deploybotService"
  containers: [deploybotService, deploybotInitExec, deploybotGitInfo, deploybotLogImporter, deploybotFakeJira]
---

# Architecture Context

## System Context

deploybot sits within Groupon's Release Engineering platform as the central deployment orchestration hub. Engineers and automated systems submit deployment requests (via GitHub webhook or direct API call); deploybot validates, executes, and records each deployment. It depends on GitHub for source repository metadata and CI status, Okta for authentication on protected operations, Kubernetes and Docker for workload execution, and a set of supporting services (Jira, Slack, S3, PEST, Artifactory, ProdCAT, Service Portal, Conveyor CI) for audit, notification, and readiness enforcement.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| deploybot Application Server | `deploybotService` | Application | Go + Gorilla Mux | 1.23.12 / 1.6.2 | Main HTTP server handling all webhook, API, and UI requests; orchestrates the full deployment lifecycle |
| Init Container | `deploybotInitExec` | Init Container | Shell / Go | — | Handles SSH key setup and Kubernetes auth initialization before the main container starts |
| Git Info Utility | `deploybotGitInfo` | Utility | Go | — | Fetches and exposes git commit metadata used during deployment |
| Log Importer | `deploybotLogImporter` | Utility | Go | — | Imports deployment logs for archival and post-processing |
| Fake Jira Stub | `deploybotFakeJira` | Test Stub | Go | — | Local Jira test stub used in development and local environments |

## Components by Container

### deploybot Application Server (`deploybotService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `deploybotApi` | Handles all inbound HTTP requests: webhooks, REST API calls, and web UI endpoints | Go / Gorilla Mux |
| `deploybotOrchestrator` | Manages deployment lifecycle and state transitions from queued through finalized | Go |
| `deploybotValidator` | Runs all validation gates: build checks, manual approval, ProdCAT, image, GPROD, pull | Go |
| `deploybotExecutor` | Executes deployments via Kubernetes API or Docker Engine | Go / client-go |
| `deploybotNotifier` | Dispatches Slack messages, creates/closes Jira tickets, publishes PEST events | Go |
| `deploybotAudit` | Records SOX-compliant audit log entries and Jira logbook management | Go |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `deploybotService` | Slack | Sends deployment notifications (queued, started, completed, failed, overridden) | REST (HTTPS) |
| `deploybotService` | Artifactory | Validates and promotes deployment images | REST (HTTPS) |
| `deploybotService` | Service Portal | Looks up service metadata | REST (HTTPS) |
| `deploybotService` | `externalDeploybotDatabase_43aa` | Reads/writes deployment state, audit logs, configs | MySQL / GORM |
| `deploybotService` | `externalS3Bucket_4b6c` | Archives deployment logs | AWS SDK (HTTPS) |
| `deploybotService` | GitHub | Receives push webhooks; queries commit status | Webhook + REST |
| `deploybotService` | Jira | Creates and closes SOX logbook tickets | REST (HTTPS) |
| `deploybotService` | Okta | Authenticates OAuth2/OIDC sessions for protected actions | OIDC (HTTPS) |
| `deploybotService` | ProdCAT | Checks production readiness gates | REST (HTTPS) |
| `deploybotService` | PEST | Publishes deploy_start and deploy_complete lifecycle events | Event bus |
| `deploybotService` | Conveyor CI | Queries maintenance windows and CI build status | REST (HTTPS) |
| `deploybotService` | Kubernetes API | Deploys and monitors Kubernetes workloads | client-go (HTTPS) |
| `deploybotService` | Docker Engine | Executes legacy container deployments | Docker API |

## Architecture Diagram References

- System context: `contexts-deploybot`
- Container: `containers-deploybot`
- Component: `components-deploybotService`
