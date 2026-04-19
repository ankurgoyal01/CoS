---
service: "command-center"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Command Center.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Tool Request Processing](tool-request-processing.md) | synchronous + asynchronous | Operator submits a tool action via the web UI | Validates a tool request, persists it, schedules a background job, and returns acknowledgment to the operator |
| [Background Job Execution](background-job-execution.md) | asynchronous | Delayed Job worker dequeues a job | Worker dequeues a job, executes downstream API mutations, and records the outcome |
| [Erasure Workflow](erasure-workflow.md) | event-driven | MBus delivers an erasure event | Worker receives an erasure event and executes data removal workflows against platform services |
| [Report Artifact Generation](report-artifact-generation.md) | batch | Background job produces output records | Worker generates a CSV report artifact and uploads it to S3; web records the artifact reference |
| [Workflow Notification](workflow-notification.md) | asynchronous | Tool job reaches a terminal state | Mailer sends a workflow status or failure notification email to the requesting operator |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 1 |
| Asynchronous (event-driven / job-driven) | 3 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

The [Tool Request Processing](tool-request-processing.md) flow spans `continuumCommandCenterWeb`, `continuumCommandCenterWorker`, `continuumCommandCenterMysql`, `continuumDealManagementApi`, `continuumVoucherInventoryService`, and `salesForce`. This flow is documented in the architecture dynamic view `dynamic-cmdcenter-tool-request-processing`.

The [Erasure Workflow](erasure-workflow.md) is triggered by events from `messageBus` and involves `continuumCommandCenterWorker` coordinating with downstream platform services to fulfill data erasure obligations.
