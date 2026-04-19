---
service: "mbus-sigint-configuration-v2"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for the MBus Sigint Configuration Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Change Request Lifecycle](change-request-lifecycle.md) | synchronous + scheduled | API call (POST /change-request) | Full workflow from change-request creation through test deployment to production promotion |
| [Scheduled Configuration Deployment](scheduled-config-deployment.md) | scheduled | Quartz cron (DeployConfigJob) | Automated Artemis configuration deployment triggered by deploy schedule |
| [Configuration Read for Broker](config-read-for-broker.md) | synchronous | API call (GET /config/deployment) | Artemis broker fetches deployment-ready configuration for a cluster and environment |
| [Jira Ticket Automation](jira-ticket-automation.md) | scheduled + event-driven | Quartz jobs on request state change | Automated Jira ticket creation, linking, and status transitions in sync with request lifecycle |
| [Delete Request Lifecycle](delete-request-lifecycle.md) | synchronous + scheduled | API call (POST /delete-request) | Workflow to remove configuration entries from a cluster via governed delete request |
| [Deploy Schedule Management](deploy-schedule-management.md) | synchronous | API calls (POST/PUT/DELETE /deploy-schedule) | Creating, updating, and refreshing Quartz cron-based deployment schedules |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 2 |
| Mixed (synchronous trigger + scheduled continuation) | 2 |

## Cross-Service Flows

- The **Change Request Lifecycle** flow spans `continuumMbusSigintConfigurationService`, the Jira API, ProdCat API, and the Ansible automation runtime.
- The **Config Read for Broker** flow is initiated by Artemis broker instances querying this service for their active deployment configuration.
- All scheduled flows rely on Quartz jobs co-located within `continuumMbusSigintConfigurationService` with state persisted in `continuumMbusSigintConfigurationDatabase`.
