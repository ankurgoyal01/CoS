---
service: "janus-web-cloud"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Janus Web Cloud.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Alert Notification](alert-notification.md) | scheduled + synchronous | Quartz schedule or manual API call to `POST /janus/api/v1/alert/{id}/send` | Evaluates alert threshold expressions against Elasticsearch metrics and dispatches email notifications to configured recipients |
| [Replay Orchestration](replay-orchestration.md) | scheduled + asynchronous | API call to `POST /replay/`; jobs executed by Quartz | Accepts a replay request, persists and splits it into jobs, schedules execution via Quartz, and tracks completion status |
| [Metadata Management](metadata-management.md) | synchronous | REST API calls to `/events/*`, `/attributes/*`, `/contexts/*`, `/annotations/*`, `/destinations/*`, `/avro/*`, `/promote/*` | Provides full CRUD lifecycle management for all Janus metadata entities and Avro schema registry entries |
| [GDPR Report Generation](gdpr-report-generation.md) | synchronous | API call to `POST /gdpr/` | Queries Bigtable/HBase for GDPR-relevant event data scoped to a subject and assembles a report response |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

The Alert Notification flow and Replay Orchestration flow interact with external systems (`elasticSearch`, `smtpRelay`, and the stubbed GDOOP resource manager) that are part of the broader Continuum platform. These cross-service interactions are captured in the central architecture dynamic view `dynamic-alert-notification-flow`. See [Architecture Context](../architecture-context.md) for C4 container-level relationship details.
