---
service: "message2ledger"
title: "Scheduled Reconciliation Replay"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "scheduled-reconciliation-replay"
flow_type: scheduled
trigger: "Quartz scheduler fires on a periodic schedule"
participants:
  - "continuumMessage2LedgerService"
  - "continuumMessage2LedgerMysql"
  - "edw"
  - "continuumAccountingService"
architecture_ref: "dynamic-m2l-message-to-ledger-flow"
---

# Scheduled Reconciliation Replay

## Summary

The scheduled reconciliation replay flow is a background batch process driven by the Quartz scheduler (version 1.8.3). On each scheduled invocation, the Processing Orchestrator queries the EDW (Enterprise Data Warehouse) via JDBC to identify order or inventory messages that should have been processed but are missing or in error state in the local MySQL database. Identified messages are re-enqueued for processing through the standard ledger pipeline, providing automated gap recovery without operator intervention.

## Trigger

- **Type**: schedule
- **Source**: Quartz scheduler (periodic cron-based job within the Async Task Processor)
- **Frequency**: Periodic; specific cron expression to be confirmed in service repository configuration

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Quartz Scheduler | Fires the reconciliation job on schedule | Component of `continuumMessage2LedgerService` (Async Task Processor) |
| Processing Orchestrator | Executes reconciliation logic; queries EDW; re-enqueues messages | `m2l_processingOrchestrator` (component of `continuumMessage2LedgerService`) |
| Persistence Layer | Reads current message state; writes newly re-enqueued message records | `m2l_persistence` (component of `continuumMessage2LedgerService`) |
| message2ledger MySQL | Source of truth for current processed message state | `continuumMessage2LedgerMysql` |
| EDW | Read-only source for reconciliation datasets; identifies expected ledger entries | `edw` |
| Inventory Enrichment Client | Enriches re-enqueued messages as needed | `m2l_inventoryEnrichment` (component of `continuumMessage2LedgerService`) |
| Accounting Integration Client | Posts re-processed ledger entries | `m2l_accountingIntegration` (component of `continuumMessage2LedgerService`) |
| Accounting Service | Receives the re-posted ledger entries | `continuumAccountingService` |

## Steps

1. **Fires reconciliation job**: The Quartz scheduler triggers the reconciliation task in the Processing Orchestrator according to the configured schedule.
   - From: Quartz Scheduler
   - To: `m2l_processingOrchestrator`
   - Protocol: direct (in-process Quartz job dispatch)

2. **Queries EDW for reconciliation datasets**: The Processing Orchestrator connects to EDW via JDBC and queries for records that indicate expected ledger entries within the reconciliation window.
   - From: `m2l_processingOrchestrator`
   - To: `edw`
   - Protocol: JDBC

3. **Reads current message state from MySQL**: The Processing Orchestrator cross-references EDW results against the local `messages` and `attempts` tables to identify gaps (missing, failed, or unprocessed messages).
   - From: `m2l_processingOrchestrator`
   - To: `continuumMessage2LedgerMysql` (via `m2l_persistence`)
   - Protocol: JDBI/MySQL

4. **Re-enqueues identified messages**: For each identified gap, the Processing Orchestrator creates or updates message records in MySQL and enqueues new processing attempts via the KillBill Queue.
   - From: `m2l_processingOrchestrator`
   - To: `continuumMessage2LedgerMysql` (via `m2l_persistence`)
   - Protocol: JDBI/MySQL

5. **Processes enrichment and ledger post**: Each re-enqueued message is processed through the standard pipeline — enrichment via Inventory Enrichment Client (if inventory event) and ledger post via Accounting Integration Client.
   - From: `m2l_processingOrchestrator`
   - To: `m2l_inventoryEnrichment`, `m2l_accountingIntegration`, `continuumAccountingService`
   - Protocol: direct / HTTP/JSON

6. **Stores processing outcomes**: Final success or failure status is written back to `attempts` and `messages` in MySQL.
   - From: `m2l_accountingIntegration`
   - To: `continuumMessage2LedgerMysql` (via `m2l_persistence`)
   - Protocol: JDBI/MySQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| EDW JDBC connection failure | Reconciliation job fails gracefully; no messages re-enqueued | Next scheduled run retries; no data loss |
| EDW query timeout | Job aborted for current run | Retried on next scheduled cycle |
| MySQL read failure during gap analysis | Job fails for current run | Retried on next scheduled cycle |
| Individual message processing failure after re-enqueue | Attempt marked failed; standard Quartz retry applies | Automatic retry; escalates to operator if max retries exceeded |
| Duplicate detection — message already succeeded | Processing Orchestrator skips re-enqueue based on attempt state | No duplicate ledger entries posted |

## Sequence Diagram

```
QuartzScheduler        -> m2l_processingOrchestrator: Fires reconciliation job (scheduled)
m2l_processingOrchestrator -> edw:                   Queries reconciliation datasets (JDBC)
edw                    --> m2l_processingOrchestrator: Returns expected ledger entry records
m2l_processingOrchestrator -> m2l_persistence:       Reads current message and attempt state
m2l_persistence        --> m2l_processingOrchestrator: Returns current state
m2l_processingOrchestrator -> m2l_persistence:       Re-enqueues identified gap messages
m2l_processingOrchestrator -> m2l_inventoryEnrichment: Requests inventory details (if applicable)
m2l_processingOrchestrator -> m2l_accountingIntegration: Requests costs and posts ledger entries
m2l_accountingIntegration -> continuumAccountingService: Fetches costs and posts ledger payload
continuumAccountingService --> m2l_accountingIntegration: 200 OK
m2l_accountingIntegration -> m2l_persistence:        Persists processing outcomes and statuses
```

## Related

- Architecture dynamic view: `dynamic-m2l-message-to-ledger-flow`
- Related flows: [Manual Message Replay](manual-message-replay.md), [Admin Retry Orchestration](admin-retry-orchestration.md), [Order to Ledger Processing](order-to-ledger-processing.md)
