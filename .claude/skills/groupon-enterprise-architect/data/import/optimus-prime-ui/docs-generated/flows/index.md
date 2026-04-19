---
service: "optimus-prime-ui"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Optimus Prime UI.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Application Startup and User Profile Load](app-startup.md) | synchronous | Browser page load | Loads user profile, initializes background tasks, and bootstraps all domain stores |
| [ETL Job Authoring and Save](job-authoring.md) | synchronous | User creates or edits a job | User composes a multi-step ETL job in the UI and saves it to the backend |
| [Job Execution Trigger and Run Monitoring](job-execution.md) | synchronous + event-driven | User triggers a job run | User triggers an on-demand job execution; background polling tracks run state to completion |
| [Data Fetcher Run](data-fetcher-run.md) | synchronous + event-driven | User initiates an ad-hoc data fetch | User configures and triggers a one-off DBDATAMOVER step from a database connection to a GoogleSheet or S3 target |
| [Connection Management](connection-management.md) | synchronous | User creates or edits a data connection | User creates, tests, edits, or deletes a named database or file-transfer connection |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous / event-driven | 2 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

All flows that involve data persistence or ETL execution cross from `continuumOptimusPrimeUi` to `continuumOptimusPrimeApi`. The UI does not directly orchestrate the ETL execution engine; it delegates all execution to the API and monitors progress via background polling. See [Architecture Context](../architecture-context.md) for the container-level relationship between `continuumOptimusPrimeUi` and `continuumOptimusPrimeApi`.
