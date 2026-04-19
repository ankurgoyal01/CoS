---
service: "ein_project"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for ProdCat (ein_project) — Production Change Approval Tool.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Change Request Creation and Approval](change-request-creation-approval.md) | synchronous | API call from deployment tooling or engineer | Accepts, validates, and approves or rejects a deployment change request against policies, JIRA, and region locks |
| [Change Validation Policy Check](change-validation-policy-check.md) | synchronous | API call (`POST /api/check/`) | Runs the full policy validation pipeline without persisting a change record — used for pre-flight checks |
| [Scheduled Logbook Closure](scheduled-logbook-closure.md) | scheduled | Database cron worker (rq-scheduler) | Periodically auto-closes failed or abandoned deployment tickets in JIRA |
| [Incident Monitor and Region Lock](incident-monitor-region-lock.md) | scheduled | Database cron worker (rq-scheduler) | Polls PagerDuty and JSM for active incidents and applies or lifts region deployment locks accordingly |
| [DeployBot Override Detection](deploybot-override-detection.md) | event-driven | Incoming change request flagged as override | Detects when a deployment tool submits a change request with an override flag, logs the event, and notifies stakeholders |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

- The [Change Request Creation and Approval](change-request-creation-approval.md) flow spans ProdCat, JIRA Cloud, JSM, Service Portal, and Google Chat — referenced in the central architecture as `dynamic-change-request`.
- The [Scheduled Logbook Closure](scheduled-logbook-closure.md) and [Incident Monitor and Region Lock](incident-monitor-region-lock.md) flows span ProdCat, JIRA Cloud, and PagerDuty/JSM — referenced in the central architecture as `dynamic-background-jobs`.
