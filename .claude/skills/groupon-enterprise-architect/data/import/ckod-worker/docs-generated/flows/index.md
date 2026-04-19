---
service: "ckod-worker"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for CKOD Worker.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| SLA Processing | scheduled | APScheduler cron/interval trigger | Scheduler-driven SLA initialization and update loop across Keboola, Optimus Prime, and MDS pipeline flows |
| Pipeline Monitoring | scheduled | APScheduler cron trigger | Evaluates run records for failures, warnings, and long-running executions; raises alerts and opens incidents |
| Incident Management | event-driven | SLA violation or monitoring alert detected internally | Creates, updates, and transitions Jira and JSM incident tickets; sends Google Chat notifications |
| AI Deployment Operations | scheduled | Short-interval APScheduler trigger (agent polling) | Polls CKOD UI for pending agent tasks; invokes Vertex AI reasoning-engine sessions for deployment automation |

> Flow detail files are pending generation.

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 3 |

## Cross-Service Flows

The SLA processing flow is the canonical cross-service flow captured in the architecture model. The dynamic view `dynamic-sla-processing-flow` describes how `cwScheduler` drives `cwSlaOrchestration` through database reads and external API calls, ultimately delivering outputs to the `cwMonitoring` pipeline.

All four flows ultimately depend on the `cwExternalClients` and `cwDatabaseAccess` shared components, making them highly interconnected at the implementation level.
