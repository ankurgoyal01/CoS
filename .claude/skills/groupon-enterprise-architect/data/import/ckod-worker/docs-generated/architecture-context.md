---
service: "ckod-worker"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumCkodWorker, continuumCkodMySql]
---

# Architecture Context

## System Context

CKOD Worker is a background worker running within the Continuum platform. It has no inbound HTTP interface; all activity is scheduler-driven. It integrates with a wide set of external SaaS platforms (Jira, JSM, Keboola, Google Chat, Vertex AI) and internal Continuum databases (Service Portal, Optimus Prime) to continuously monitor data operations health and automate incident and deployment management. The `continuumCkodUi` serves as the operational front-end; CKOD Worker polls its API for agent tasks and executes them via Vertex AI.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| CKOD Worker | `continuumCkodWorker` | Worker | Python, APScheduler | — | Scheduled Python worker that orchestrates SLA lifecycle jobs, monitoring, deployment checks, and notification workflows |
| CKOD Database | `continuumCkodMySql` | Database | MySQL | — | Primary relational data store for SLA definitions, job runs, and operational state |

## Components by Container

### CKOD Worker (`continuumCkodWorker`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Job Scheduler (`cwScheduler`) | Registers cron/interval jobs and executes workers with execution tracking wrappers | APScheduler |
| SLA Orchestration (`cwSlaOrchestration`) | Initiates and updates SLA entries for Keboola, RM, OP, and MDS flows | Python modules |
| Monitoring and Alerting (`cwMonitoring`) | Evaluates failures, warnings, and long-running runs, then raises alerts | Python modules |
| Deployment Operations (`cwDeploymentOps`) | Runs deployment approval checks, completion checks, and deployment window notifications | Python modules |
| Agent Polling (`cwAgentPolling`) | Polls CKOD UI API and invokes Vertex AI reasoning-engine sessions for automation | Python modules |
| Data Sync and Enrichment (`cwDataSync`) | Synchronizes Keboola runs, updates metadata, and ingests cost/authorization data | Python modules |
| Database Access Layer (`cwDatabaseAccess`) | MySQL/PostgreSQL adapters and query methods used by worker modules | Python database adapters |
| External Service Clients (`cwExternalClients`) | Jira/JSM/Keboola/Google Chat/Telemetry client wrappers | Python HTTP clients |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumCkodWorker` | `continuumCkodMySql` | Reads/writes SLA and pipeline tracking tables | MySQL |
| `continuumCkodWorker` | `servicePortal` | Reads users, groups, and memberships for authorization rebuilds | MySQL |
| `continuumCkodWorker` | `optimusPrime` | Reads Optimus Prime job runs for SLA calculations | PostgreSQL |
| `continuumCkodWorker` | `continuumJiraService` | Creates/updates/transitions tickets for incidents and deployment approvals | HTTPS |
| `continuumCkodWorker` | `jsmOps` | Fetches on-call data, incident details, and sends heartbeats | HTTPS |
| `continuumCkodWorker` | `keboola` | Fetches project metadata, storage details, pipeline run status, and execution details | HTTPS |
| `continuumCkodWorker` | `googleChat` | Sends operational and deployment notifications | HTTPS webhook |
| `continuumCkodWorker` | `vertexAi` | Invokes reasoning-engine sessions and stream queries | Google Cloud API |
| `continuumCkodWorker` | `continuumCkodUi` | Polls agent tasks and deployment context | HTTPS |
| `cwScheduler` | `cwSlaOrchestration` | Triggers scheduled SLA jobs and backfill routines | direct |
| `cwScheduler` | `cwMonitoring` | Triggers monitoring and healthcheck jobs | direct |
| `cwScheduler` | `cwDeploymentOps` | Triggers deployment lifecycle checks and notifications | direct |
| `cwScheduler` | `cwDataSync` | Triggers synchronization, enrichment, and retention jobs | direct |
| `cwScheduler` | `cwAgentPolling` | Runs short-interval agent polling workflow | direct |
| `cwSlaOrchestration` | `cwDatabaseAccess` | Reads and writes SLA definitions and run states | direct |
| `cwSlaOrchestration` | `cwExternalClients` | Queries pipeline/job APIs and opens incidents | direct |
| `cwMonitoring` | `cwDatabaseAccess` | Reads run records and writes monitoring status | direct |
| `cwMonitoring` | `cwExternalClients` | Emits metrics and sends operational alerts | direct |
| `cwDeploymentOps` | `cwDatabaseAccess` | Reads deployment tracking data | direct |
| `cwDeploymentOps` | `cwExternalClients` | Transitions tickets and sends deployment notifications | direct |
| `cwAgentPolling` | `cwExternalClients` | Uses CKOD UI, Jira/JSM, and Vertex AI endpoints | direct |
| `cwDataSync` | `cwDatabaseAccess` | Persists synchronized pipeline and cost data | direct |
| `cwDataSync` | `cwExternalClients` | Reads Keboola APIs and emits telemetry | direct |

## Architecture Diagram References

- Component: `components-ckod-worker`
- Dynamic flow: `dynamic-sla-processing-flow`
