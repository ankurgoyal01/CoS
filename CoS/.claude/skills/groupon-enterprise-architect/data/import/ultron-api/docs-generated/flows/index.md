---
service: "ultron-api"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Ultron API.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| Job Registration | synchronous | Job runner client sends POST request | A job runner client registers a new job run or watermark with Ultron API |
| Job Execution Monitoring | synchronous | Operator queries job instance history or status | An operator or system retrieves job instance state and execution history |
| Watchdog Alerting | scheduled | Quartz scheduler fires a watchdog trigger | The scheduler checks for overdue jobs and dispatches alert emails to stakeholders |
| Permission Management | synchronous | Operator manages groups, users, roles, or memberships | An operator creates or updates groups, adds users, or assigns roles via the API or UI |

> Flow detail files are pending generation.

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

- **Job Registration** is initiated by `jobRunnerClients_4c7b` (stub-only in federated model) calling into `continuumUltronApi`
- **Watchdog Alerting** calls `smtpEmailService_2d1e` (stub-only in federated model) via the Email Manager component

> Cross-service dynamic views are not yet defined in the federated architecture model (`views/dynamics.dsl` is empty).
