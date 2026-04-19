---
service: "n8n"
title: "Code Node Task Execution (External Runner)"
generated: "2026-03-03"
type: flow
flow_name: "code-node-task-execution"
flow_type: synchronous
trigger: "Workflow engine reaches a JavaScript or Python Code node during execution"
participants:
  - "n8nWorkflowEngine"
  - "n8nRunnerBroker"
  - "continuumN8nTaskRunners"
  - "n8nRunnerLauncher"
architecture_ref: "dynamic-workflow-execution-flow"
---

# Code Node Task Execution (External Runner)

## Summary

When a workflow reaches a Code node (JavaScript or Python), the n8n Workflow Engine delegates execution to an external task runner rather than executing user code in-process. The Workflow Engine posts the task to the Runner Broker Endpoint (port 5679). An n8n Runner Launcher (running as a sidecar container on the queue-worker pod) fetches the task, executes it in a sandboxed environment with controlled module access, and returns the result. This architecture isolates arbitrary user code from the main n8n process and supports both JavaScript and Python execution environments.

## Trigger

- **Type**: Internal workflow event — the workflow engine encounters a Code node
- **Source**: `n8nWorkflowEngine` (within a running workflow execution)
- **Frequency**: Per Code node encountered during workflow execution

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Workflow Engine | Identifies the Code node and posts the task to the broker | `n8nWorkflowEngine` |
| Runner Broker Endpoint | HTTP API on port 5679 that queues and routes tasks to runners | `n8nRunnerBroker` |
| n8n Task Runners (sidecar) | Houses the Runner Launcher; runs as a sidecar container on each queue-worker pod | `continuumN8nTaskRunners` |
| Runner Launcher | Fetches tasks from the broker, spawns the appropriate language runtime, executes user code, and posts results back | `n8nRunnerLauncher` |

## Steps

1. **Code Node Encountered**: During workflow graph execution, the Workflow Engine identifies a Code node (type: JavaScript or Python) and prepares the task payload (code string, input data, execution context).
   - From: `n8nWorkflowEngine`
   - To: `n8nRunnerBroker`
   - Protocol: HTTP (port 5679, internal loopback `127.0.0.1`)

2. **Task Posted to Broker**: The Workflow Engine POSTs the task to the Runner Broker Endpoint. The broker authenticates the request using `N8N_RUNNERS_AUTH_TOKEN`.
   - From: `n8nWorkflowEngine`
   - To: `n8nRunnerBroker` (port 5679)
   - Protocol: HTTP

3. **Runner Launcher Fetches Task**: The Runner Launcher polls or long-polls the broker for available tasks (timeout: `N8N_RUNNERS_TASK_REQUEST_TIMEOUT=120` seconds).
   - From: `n8nRunnerLauncher`
   - To: `n8nRunnerBroker`
   - Protocol: HTTP

4. **Execute User Code in Sandbox**: The Runner Launcher launches the appropriate runtime:
   - **JavaScript**: Node.js process with `--disallow-code-generation-from-strings --disable-proto=delete`. Allowed built-ins: `crypto`. Allowed external modules: `moment`. Health check: port 5681.
   - **Python**: Python venv process with full stdlib access (`N8N_RUNNERS_STDLIB_ALLOW=*`) and external packages (`N8N_RUNNERS_EXTERNAL_ALLOW=*`). Available packages: `psycopg[binary,pool]`. Health check: port 5682.
   - From: `n8nRunnerLauncher`
   - To: JavaScript or Python runner process (in-sidecar)
   - Protocol: direct (subprocess)

5. **Return Task Result**: The Runner Launcher posts the execution result (output data or error) back to the Runner Broker Endpoint.
   - From: `n8nRunnerLauncher`
   - To: `n8nRunnerBroker`
   - Protocol: HTTP

6. **Broker Returns Result to Workflow Engine**: The Workflow Engine receives the task result from the broker and passes it as input to the next node in the workflow graph.
   - From: `n8nRunnerBroker`
   - To: `n8nWorkflowEngine`
   - Protocol: HTTP (response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Task request timeout (>120s) | Broker cancels the task (`N8N_RUNNERS_TASK_REQUEST_TIMEOUT=120`) | Workflow node fails with timeout error; execution record records error |
| Runner sidecar unavailable | Broker has no runner to accept the task | Workflow execution fails at the Code node; error recorded |
| User code throws an exception | Runner captures the exception and returns an error payload | Workflow enters error path if configured; execution status set to `error` |
| Disallowed module access | Sandbox restrictions block the import | User code fails; error returned to workflow |
| Auth token mismatch | Broker rejects the runner connection | Runner cannot fetch tasks; Code nodes fail with connection error |

## Sequence Diagram

```
n8nWorkflowEngine -> n8nRunnerBroker: POST /task (code + input data, auth token) [port 5679]
n8nRunnerLauncher -> n8nRunnerBroker: GET /task (poll for work) [port 5679]
n8nRunnerBroker --> n8nRunnerLauncher: Task payload
n8nRunnerLauncher -> JavaScriptRunner|PythonRunner: Execute user code (sandboxed)
JavaScriptRunner|PythonRunner --> n8nRunnerLauncher: Output data or error
n8nRunnerLauncher -> n8nRunnerBroker: POST /task/result [port 5679]
n8nRunnerBroker --> n8nWorkflowEngine: Task result (output for next node)
```

## Related

- Architecture dynamic view: `dynamic-workflow-execution-flow`
- Related flows: [Queue-Mode Workflow Execution](queue-mode-workflow-execution.md)
- Runner configuration: `n8n-task-runners.json`, `extras.txt`
