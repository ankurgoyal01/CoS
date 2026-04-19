---
service: "n8n"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for n8n — Groupon's internal workflow automation platform.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Webhook-Triggered Workflow Execution](webhook-triggered-workflow-execution.md) | synchronous | Inbound HTTP webhook | Receives an external HTTP trigger, activates the corresponding workflow, and returns a response |
| [Queue-Mode Workflow Execution](queue-mode-workflow-execution.md) | asynchronous | Any workflow trigger (schedule, webhook, manual, API) | Enqueues a workflow execution job to Redis, dispatches to a queue-worker pod, and records the result in PostgreSQL |
| [Code Node Task Execution (External Runner)](code-node-task-execution.md) | synchronous | Workflow engine reaches a JavaScript or Python Code node | Dispatches a sandboxed code execution task to an external runner sidecar and returns the result to the workflow engine |
| [Scheduled Workflow Execution](scheduled-workflow-execution.md) | scheduled | Cron schedule configured in workflow | n8n triggers a workflow at a configured cron schedule, enqueues the job, and processes it via queue workers |
| [Custom Runner Image Build and Release](custom-runner-image-build.md) | event-driven | Push or PR to `main` modifying `Dockerfile.runners` | Builds, tags, and promotes a custom n8n runner Docker image to the Conveyor Cloud registry |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven / queue) | 1 |
| Batch / Scheduled | 1 |
| Event-driven (CI/CD) | 1 |

## Cross-Service Flows

- The [Queue-Mode Workflow Execution](queue-mode-workflow-execution.md) flow spans `continuumN8nService`, Redis Memorystore, and `continuumN8nTaskRunners`. The canonical architecture dynamic view is `dynamic-workflow-execution-flow`.
- The [Code Node Task Execution](code-node-task-execution.md) flow spans `n8nWorkflowEngine`, `n8nRunnerBroker`, and `n8nRunnerLauncher` across the `continuumN8nService` and `continuumN8nTaskRunners` containers.
