---
service: "argus"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 3
---

# Flows

Process and flow documentation for Argus.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Alert Sync Flow](alert-sync-flow.md) | batch | CI commit to `master` (changeset-gated) or manual Gradle invocation | Loads YAML alert definitions, renders Wavefront query templates, and creates or updates alerts in Wavefront |
| [Dashboard Sync Flow](dashboard-sync-flow.md) | batch | Manual Gradle invocation or CI build | Queries live Wavefront metrics, assembles dashboard payloads from graph definitions and SLA config, and pushes updated dashboards to Wavefront |
| [Alert Summary Report Flow](alert-summary-report-flow.md) | scheduled | Jenkins `TimerTrigger` (scheduled CI run) or `./gradlew showAlertSummary` | Queries Wavefront for the weekly firing frequency of all known alerts and prints a ranked summary of top-firing alerts to operators |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 3 |

## Cross-Service Flows

All three flows interact exclusively with the external Wavefront SaaS platform. The architecture dynamic view `dynamic-argus-alert-sync-flow` captures the primary Wavefront interactions across all three jobs. See [Architecture Context](../architecture-context.md) for container and component relationships.
