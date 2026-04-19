---
service: "seer-frontend"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for Seer Frontend.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Code Quality Metrics View](code-quality-metrics-view.md) | synchronous | User navigates to `/quality` | Fetches SonarQube metrics for all services, populates service dropdown, renders code coverage bar chart |
| [Alert Metrics View](alert-metrics-view.md) | synchronous | User navigates to `/alerts` | Fetches OpsGenie team list and weekly alert report, renders alert and auto-resolve charts |
| [Sprint Metrics View](sprint-metrics-view.md) | synchronous | User navigates to `/sprint` | Fetches Jira sprint boards and board sprint report, renders volatility and KTLO/features charts |
| [Incident (SEV) Metrics View](incident-sev-metrics-view.md) | synchronous | User navigates to `/incidents` | Fetches service owner map and incident counts, renders daily and weekly incident charts |
| [Jenkins Build Metrics View](jenkins-build-metrics-view.md) | synchronous | User navigates to `/builds` | Fetches service list and Jenkins build time report, renders daily and weekly build time charts |
| [PR and Deployment Metrics Views](pr-and-deployment-metrics-view.md) | synchronous | User navigates to `/pulls` or `/deployments` | Fetches service list and PR merge time or deployment time report, renders daily and weekly charts |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 6 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

All flows cross from the browser (SPA) to the `seer-service` backend (`seerBackendApi_unk_7b2f`). No dynamic views are yet defined in the DSL (`architecture/views/dynamics.dsl` is empty). Data collection from SonarQube, OpsGenie, Jira, Jenkins, and Deploybot is handled entirely by the backend; those cross-service flows are documented in the seer-service documentation.
