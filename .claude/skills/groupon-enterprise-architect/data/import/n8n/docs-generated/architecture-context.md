---
service: "n8n"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumN8nService, continuumN8nPostgres, continuumN8nTaskRunners]
---

# Architecture Context

## System Context

n8n is a container group within the `continuumSystem` (Continuum Platform), Groupon's core commerce engine. It provides internal workflow automation capabilities for multiple business domains. The service is not exposed to external customers; access is via internal VPN-accessible editor URLs and separately routed webhook/API endpoints. Each deployed instance (default, finance, merchant, llm-traffic, business, playground) operates independently with its own PostgreSQL and Redis Memorystore backends on GCP `us-central1`.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| n8n Service | `continuumN8nService` | Container | n8n | 1.122.3 / 2.x | Workflow automation API and orchestration engine. Hosts the editor UI, REST API, webhook receiver, and workflow engine. |
| n8n PostgreSQL | `continuumN8nPostgres` | Database | PostgreSQL | 16 | Primary data store for workflow definitions, credentials metadata, and execution state. |
| n8n Task Runners | `continuumN8nTaskRunners` | Container | n8n Task Runners | 2.6.4 | External execution workers for JavaScript and Python code nodes. Run as sidecar containers on queue-worker pods. |

## Components by Container

### n8n Service (`continuumN8nService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Workflow Engine (`n8nWorkflowEngine`) | Executes workflows, coordinates triggers (webhook, schedule, manual), and orchestrates node execution across the workflow graph | n8n Core |
| Runner Broker Endpoint (`n8nRunnerBroker`) | Broker HTTP endpoint (port 5679) used by external task runners to fetch task assignments and post execution results | HTTP API |

### n8n PostgreSQL (`continuumN8nPostgres`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Workflow Data Store (`n8nWorkflowDataStore`) | Stores workflow definitions, credentials metadata, execution records, and queue state | PostgreSQL Schema |

### n8n Task Runners (`continuumN8nTaskRunners`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Runner Launcher (`n8nRunnerLauncher`) | Fetches task assignments from the Runner Broker, executes user-authored JavaScript or Python code, and returns results via the broker endpoint | n8n Runner Launcher |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumN8nService` | `continuumN8nPostgres` | Stores workflows and execution state | PostgreSQL (SQL) |
| `continuumN8nTaskRunners` | `continuumN8nService` | Uses broker endpoint for task execution; returns task execution status and output | HTTP (port 5679) |
| `n8nWorkflowEngine` | `n8nWorkflowDataStore` | Reads and writes workflow state | SQL |
| `n8nWorkflowEngine` | `n8nRunnerBroker` | Dispatches runner tasks | HTTP |
| `n8nRunnerLauncher` | `n8nRunnerBroker` | Fetches and acknowledges tasks | HTTP |
| `n8nRunnerLauncher` | `n8nWorkflowDataStore` | Persists task execution updates | SQL |
| `continuumN8nService` | `loggingStack` | Sends logs and diagnostics | Structured Logs |

## Architecture Diagram References

- Container: `containers-continuum-n8n`
- Component (n8n Service): `components-continuum-n8n-service`
- Component (PostgreSQL): `components-continuum-n8n-postgres`
- Component (Task Runners): `components-continuum-n8n-task-runners`
- Dynamic (workflow execution): `dynamic-workflow-execution-flow`
