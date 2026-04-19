---
service: "gazebo"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Gazebo (Writers' App).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Editorial Copy Creation](editorial-copy-creation.md) | synchronous | User action — editor saves or publishes deal copy | Editor creates or edits deal copy, validation runs, content is saved to MySQL, and a copy change event is published to Message Bus |
| [Task Management](task-management.md) | event-driven | Message Bus event or manual editorial action | Tasks are created from MBus events or manually, claimed by editors, completed, and a completion event is emitted |
| [Message Bus Event Processing](message-bus-event-processing.md) | asynchronous | Incoming Message Bus event | MBus consumer receives deal, opportunity, task, and notification events and dispatches them to the appropriate handler for MySQL updates |
| [Salesforce Data Sync](salesforce-data-sync.md) | scheduled | Cron job on configured schedule | Scheduled job queries Salesforce via Restforce, retrieves opportunity and deal data, and writes updated records to MySQL |
| [Merchandising Checklist Validation](merchandising-checklist-validation.md) | synchronous | User action — editor works through quality checklist | Editor completes merchandising quality checklist items; validation enforces all required items are checked before deal copy can be published |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

- The [Editorial Copy Creation](editorial-copy-creation.md) flow crosses into `mbusSystem_18ea34` when the copy change event is published, and may trigger downstream consumers in other Continuum services.
- The [Task Management](task-management.md) flow originates in upstream producers (e.g., Salesforce pipeline, goods workflow) that publish to `mbusSystem_18ea34` before Gazebo picks up the task.
- The [Message Bus Event Processing](message-bus-event-processing.md) flow receives events from `continuumDealCatalogService`, `salesForce`, and other Continuum services via the shared `mbusSystem_18ea34` broker.
- The [Salesforce Data Sync](salesforce-data-sync.md) flow depends on `salesForce` as a cross-service external dependency.

Cross-service dynamic views are referenced in [Architecture Context](../architecture-context.md).
