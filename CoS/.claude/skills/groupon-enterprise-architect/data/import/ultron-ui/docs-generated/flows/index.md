---
service: "ultron-ui"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for Ultron UI.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [View Job List](view-job-list.md) | synchronous | Operator selects a job group in the UI | Loads and displays all jobs belonging to a selected group |
| [Create Job](create-job.md) | synchronous | Operator submits the create-job form | Validates and persists a new job definition via Ultron API |
| [View Job Dependency Graph](view-job-dependency-graph.md) | synchronous | Operator opens the dependency view for a job | Fetches and renders the directed dependency graph for a job |
| [Update Job Instance](update-job-instance.md) | synchronous | Operator updates the status of a running job instance | Submits an instance status update to Ultron API |
| [Monitor Job Performance](monitor-job-performance.md) | synchronous | Operator opens the performance/trend view for a job | Retrieves and displays historical execution trend data for a job |
| [Manage User Groups](manage-user-groups.md) | synchronous | Operator creates, edits, or deletes a job group | Performs CRUD operations on job groups via Ultron API |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 6 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

All six flows cross the boundary from `continuumUltronUiWeb` to `continuumUltronApi`. Each flow originates with an operator action in the browser, passes through the Play controllers (`playControllers`) for LDAP authentication, and is forwarded to the Ultron API backend over HTTP/JSON. See the individual flow files for step-by-step details.
