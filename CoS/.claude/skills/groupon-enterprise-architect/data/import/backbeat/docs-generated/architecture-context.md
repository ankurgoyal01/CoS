---
service: "backbeat"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumBackbeatApiRuntime, continuumBackbeatWorkerRuntime, continuumBackbeatPostgres, continuumBackbeatRedis]
---

# Architecture Context

## System Context

Backbeat runs as a subsystem within `continuumSystem`. It exposes a Rack/Grape HTTP API consumed by internal Continuum services (primarily Accounting) to submit workflow events and receive callbacks. The API runtime writes workflow state to PostgreSQL and enqueues asynchronous execution jobs into Redis. A Sidekiq worker runtime dequeues those jobs, executes workflow event logic, updates state, and posts HTTP callbacks back to the originating client. Operational metrics flow outward to the shared Metrics Stack; daily digest emails flow through the SMTP Relay.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Backbeat API Runtime | `continuumBackbeatApiRuntime` | Service | Ruby, Rack, Grape | — | Rack/Grape web process exposing workflow APIs and orchestrating state transitions |
| Backbeat Worker Runtime | `continuumBackbeatWorkerRuntime` | Service | Ruby, Sidekiq | — | Sidekiq worker process scheduling and executing asynchronous workflow events |
| Backbeat Postgres | `continuumBackbeatPostgres` | Database | PostgreSQL | — | Primary relational datastore for workflows, nodes, users, and status changes |
| Backbeat Redis | `continuumBackbeatRedis` | Cache | Redis | — | Queueing and cache backend for Sidekiq jobs and transient runtime state |

## Components by Container

### Backbeat API Runtime (`continuumBackbeatApiRuntime`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Web API (`bbWebApi`) | Grape API endpoints for workflows, activities, debug, heartbeat, health, and Sidekiq stats | Ruby, Grape |
| Workflow Engine (`bbWorkflowEngine`) | Core orchestration logic in `Backbeat::Server` and workflow event dispatch | Ruby |
| State Manager (`bbStateManager`) | Validates and applies workflow/node state transitions | Ruby |
| Persistence Models (`bbPersistenceModels`) | ActiveRecord models and query helpers for workflows, nodes, and users | Ruby, ActiveRecord |
| Client Adapter (`bbClientAdapter`) | HTTP callback client that posts activities, decisions, and notifications to downstream services | Ruby, HTTParty |

### Backbeat Worker Runtime (`continuumBackbeatWorkerRuntime`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Async Worker (`bbAsyncWorker`) | Sidekiq worker deserializing node references and executing scheduled events | Ruby, Sidekiq |
| Workflow Events (`bbWorkflowEvents`) | Event handlers progressing workflow execution and retries | Ruby |
| Schedulers (`bbScheduler`) | Scheduling strategies for immediate, delayed, and retry execution | Ruby |
| Daily Activity Reporter (`bbDailyActivityReporter`) | Scheduled worker composing and sending daily workflow reports by email | Ruby, Sidekiq |
| External Metrics Reporter (`bbMetricsReporter`) | Metric/error event publisher backed by Sonoma and InfluxDB clients | Ruby, InfluxDB Client |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumBackbeatApiRuntime` | `continuumBackbeatPostgres` | Stores and queries workflow state with ActiveRecord | ActiveRecord / SQL |
| `continuumBackbeatApiRuntime` | `continuumBackbeatRedis` | Reads Sidekiq and queue telemetry for middleware and health endpoints | Redis |
| `continuumBackbeatWorkerRuntime` | `continuumBackbeatPostgres` | Loads and updates workflow/node state for event execution | ActiveRecord / SQL |
| `continuumBackbeatWorkerRuntime` | `continuumBackbeatRedis` | Consumes and manages Sidekiq queues and scheduled jobs | Redis |
| `continuumBackbeatWorkerRuntime` | `metricsStack` | Publishes operational metrics and errors | InfluxDB/Sonoma |
| `bbWorkflowEngine` | `bbStateManager` | Uses guarded state transitions | Direct (in-process) |
| `bbWorkflowEngine` | `bbPersistenceModels` | Reads and writes workflow graph state | Direct (in-process) |
| `bbWorkflowEngine` | `bbClientAdapter` | Triggers activity/decision callbacks | Direct (in-process) |
| `bbScheduler` | `bbAsyncWorker` | Schedules asynchronous event execution | Direct (in-process) |
| `bbAsyncWorker` | `bbWorkflowEvents` | Dispatches event handlers | Direct (in-process) |
| `bbWorkflowEvents` | `bbStateManager` | Transitions node and workflow statuses | Direct (in-process) |
| `bbWorkflowEvents` | `bbClientAdapter` | Notifies downstream clients on errors and completions | Direct (in-process) |
| `bbMetricsReporter` | `metricsStack` | Writes custom metrics and error telemetry | InfluxDB/Sonoma |

> Relationships to `accountingServiceEndpoint` and `smtpRelayEndpoint` are stub-only — those targets are not present in the current federated model.

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-continuum`
- Component (API Runtime): `components-continuum-backbeat-api-runtime`
- Component (Worker Runtime): `components-continuum-backbeat-worker-runtime`
- Dynamic (Workflow Execution): `dynamic-backbeat-workflow-execution`
