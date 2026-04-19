---
service: "backbeat"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 1
---

# Flows

Process and flow documentation for Backbeat.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Workflow Execution and Callback Flow](workflow-execution.md) | asynchronous | API call to create/signal a workflow | End-to-end lifecycle of a workflow event from API submission through async execution to downstream callback delivery |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The Workflow Execution and Callback Flow spans `continuumBackbeatApiRuntime`, `continuumBackbeatWorkerRuntime`, `continuumBackbeatPostgres`, `continuumBackbeatRedis`, and the external `accountingServiceEndpoint`. It is documented in the Structurizr dynamic view `dynamic-backbeat-workflow-execution`.
