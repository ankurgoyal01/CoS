---
service: "n8n"
title: "Webhook-Triggered Workflow Execution"
generated: "2026-03-03"
type: flow
flow_name: "webhook-triggered-workflow-execution"
flow_type: synchronous
trigger: "Inbound HTTP request to /webhook/* or /webhook-test/*"
participants:
  - "continuumN8nService"
  - "n8nWorkflowEngine"
  - "continuumN8nPostgres"
  - "n8nWorkflowDataStore"
architecture_ref: "dynamic-workflow-execution-flow"
---

# Webhook-Triggered Workflow Execution

## Summary

An external or internal system sends an HTTP request to the n8n webhook endpoint, activating the matching workflow for synchronous or asynchronous execution. The n8n Service receives the request, looks up the workflow definition in PostgreSQL, executes the workflow graph, and optionally returns a response to the caller. This is the primary mechanism for event-driven workflow automation where external systems act as triggers.

## Trigger

- **Type**: api-call (inbound HTTP)
- **Source**: Any external or internal system that has been configured to POST or GET the webhook URL for the target n8n instance (e.g., `https://n8n-api.groupondev.com/webhook/<workflow-id>`)
- **Frequency**: On-demand, per webhook event

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| External/Internal caller | Initiates the webhook trigger | — |
| n8n Service | Receives the HTTP request and routes it to the workflow engine | `continuumN8nService` |
| Workflow Engine | Loads the workflow definition, validates the trigger, and orchestrates node execution | `n8nWorkflowEngine` |
| n8n PostgreSQL | Provides the workflow definition and receives the execution record | `continuumN8nPostgres` |
| Workflow Data Store | Stores and retrieves workflow definitions and execution records | `n8nWorkflowDataStore` |

## Steps

1. **Receive Webhook Request**: The caller sends an HTTP GET or POST request to `https://n8n-api.<instance>.groupondev.com/webhook/<workflow-id>`.
   - From: External/Internal caller
   - To: `continuumN8nService` (via GKE ingress, webhook URL domain)
   - Protocol: HTTPS

2. **Load Workflow Definition**: The Workflow Engine queries the Workflow Data Store for the workflow definition matching the webhook path.
   - From: `n8nWorkflowEngine`
   - To: `n8nWorkflowDataStore` (within `continuumN8nPostgres`)
   - Protocol: SQL (PostgreSQL)

3. **Create Execution Record**: An initial execution record is created in PostgreSQL with status `running`.
   - From: `n8nWorkflowEngine`
   - To: `n8nWorkflowDataStore`
   - Protocol: SQL (PostgreSQL)

4. **Execute Workflow Graph**: The Workflow Engine processes each node in the workflow in sequence/parallel as configured, passing data between nodes. If a Code node is encountered, the execution is delegated to the external runner (see [Code Node Task Execution](code-node-task-execution.md)).
   - From: `n8nWorkflowEngine`
   - To: Various workflow nodes (internal)
   - Protocol: direct (in-process)

5. **Persist Execution Result**: On workflow completion or error, the execution record is updated in PostgreSQL with the final status, output data, and timestamps.
   - From: `n8nWorkflowEngine`
   - To: `n8nWorkflowDataStore`
   - Protocol: SQL (PostgreSQL)

6. **Return Response**: For synchronous workflows, the HTTP response (configured in the Respond to Webhook node) is returned to the caller.
   - From: `continuumN8nService`
   - To: External/Internal caller
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No matching workflow found | 404 returned immediately | Caller receives 404; no execution record created |
| Workflow execution error | Error recorded in execution record; workflow error path nodes execute if configured | Caller receives error response or 500; execution record status set to `error` |
| Payload exceeds `N8N_PAYLOAD_SIZE_MAX` (1024 MB) | Request rejected | Caller receives 413; no execution started |
| PostgreSQL unavailable | Workflow cannot be loaded or execution record cannot be written | Request fails; 500 returned to caller |

## Sequence Diagram

```
Caller -> continuumN8nService: POST /webhook/<id> (HTTPS)
continuumN8nService -> n8nWorkflowEngine: Route to webhook handler
n8nWorkflowEngine -> n8nWorkflowDataStore: SELECT workflow WHERE webhook_path = <path>
n8nWorkflowDataStore --> n8nWorkflowEngine: Workflow definition
n8nWorkflowEngine -> n8nWorkflowDataStore: INSERT execution record (status=running)
n8nWorkflowEngine -> n8nWorkflowEngine: Execute workflow graph (nodes)
n8nWorkflowEngine -> n8nWorkflowDataStore: UPDATE execution record (status=success|error)
n8nWorkflowEngine --> continuumN8nService: Execution result
continuumN8nService --> Caller: HTTP response (200 with output or error)
```

## Related

- Architecture dynamic view: `dynamic-workflow-execution-flow`
- Related flows: [Queue-Mode Workflow Execution](queue-mode-workflow-execution.md), [Code Node Task Execution](code-node-task-execution.md)
