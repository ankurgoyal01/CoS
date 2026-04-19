---
service: "backbeat"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Workflow Orchestration / Distributed Systems"
platform: "Continuum"
team: "Continuum Platform"
status: active
tech_stack:
  language: "Ruby"
  language_version: ""
  framework: "Grape"
  framework_version: ""
  runtime: "Rack / Sidekiq"
  runtime_version: ""
  build_tool: "Bundler"
  package_manager: "Bundler"
---

# Backbeat Overview

## Purpose

Backbeat is a workflow orchestration engine that manages the lifecycle of multi-step asynchronous workflows within the Continuum platform. It persists workflow and node state in PostgreSQL, schedules asynchronous work through Sidekiq-backed Redis queues, and delivers activity and decision callbacks to downstream services such as the Accounting Service. Backbeat decouples long-running business processes from synchronous request handling by providing durable, retryable, and observable workflow execution.

## Scope

### In scope

- Defining and persisting workflow graphs (workflows, nodes, users) in PostgreSQL
- Scheduling and executing asynchronous workflow events via Sidekiq workers
- Validating and applying guarded workflow and node state transitions
- Posting activity and decision callbacks to downstream client services over HTTP
- Emitting operational metrics and error telemetry to the Metrics Stack
- Generating and delivering daily workflow activity reports via SMTP

### Out of scope

- Business logic for the activities/decisions being orchestrated (owned by consuming services such as Accounting)
- HTTP API gateway concerns (routing, TLS termination) — handled by infrastructure
- Long-term analytics or BI reporting on workflow data

## Domain Context

- **Business domain**: Workflow Orchestration / Distributed Systems
- **Platform**: Continuum
- **Upstream consumers**: Accounting Service (submits workflows and receives callbacks); any Continuum service that requires durable async orchestration
- **Downstream dependencies**: Accounting Service callback endpoint, Metrics Stack, SMTP Relay

## Stakeholders

| Role | Description |
|------|-------------|
| Continuum Platform Team | Service owners; responsible for operation and evolution |
| Accounting Service Team | Primary consumer; relies on activity/decision callbacks |
| Platform SRE | Monitors operational health and handles incidents |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Ruby | — | `architecture/models/components/continuum-backbeat-api-runtime-components.dsl` |
| Framework | Grape | — | `continuumBackbeatApiRuntime` container description |
| Runtime | Rack (API) / Sidekiq (worker) | — | `continuumBackbeatApiRuntime`, `continuumBackbeatWorkerRuntime` container descriptions |
| Build tool | Bundler | — | Ruby standard toolchain |
| Package manager | Bundler | — | Ruby standard toolchain |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Grape | — | http-framework | REST API definition for workflow and debug endpoints |
| ActiveRecord | — | orm | Workflow, node, and user persistence models |
| Sidekiq | — | scheduling | Async job scheduling and execution |
| HTTParty | — | http-client | HTTP callback client for posting activities and decisions |
| InfluxDB Client | — | metrics | Metric and error event publishing to Metrics Stack (Sonoma/InfluxDB) |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
