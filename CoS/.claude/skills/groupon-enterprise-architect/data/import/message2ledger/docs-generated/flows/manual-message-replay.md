---
service: "message2ledger"
title: "Manual Message Replay"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "manual-message-replay"
flow_type: synchronous
trigger: "POST /messages (contract replay) or operator action via admin API"
participants:
  - "continuumMessage2LedgerService"
  - "continuumMessage2LedgerMysql"
  - "continuumOrdersService"
  - "continuumAccountingService"
architecture_ref: "dynamic-m2l-message-to-ledger-flow"
---

# Manual Message Replay

## Summary

The manual message replay flow allows Finance Engineering operators or automated callers to inject or re-submit a message through the full ledger processing pipeline without requiring a new MBus event. The `/messages` endpoint supports contract replay (used during migration scenarios or gap recovery), while `/admin/messages` (POST/PUT) allows direct message record creation or update. Once a message is present in MySQL, it is processed through the same enrichment and ledger-posting steps as a live MBus-triggered event.

## Trigger

- **Type**: api-call
- **Source**: Operator or calling service via POST `/messages` (contract replay) or POST/PUT `/admin/messages`
- **Frequency**: On-demand; used for recovery, migration, and incident remediation

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator / calling service | Initiates replay by posting to the API | — |
| Replay and Retry API | Receives the replay request and interacts with persistence and orchestrator | `m2l_replayAndRetryApi` (component of `continuumMessage2LedgerService`) |
| Processing Orchestrator | Schedules the async processing attempt for the replayed message | `m2l_processingOrchestrator` (component of `continuumMessage2LedgerService`) |
| Inventory Enrichment Client | Fetches unit/product details if needed by the replayed event type | `m2l_inventoryEnrichment` (component of `continuumMessage2LedgerService`) |
| Accounting Integration Client | Fetches costs and posts the ledger payload | `m2l_accountingIntegration` (component of `continuumMessage2LedgerService`) |
| Persistence Layer | Reads and writes message and attempt state | `m2l_persistence` (component of `continuumMessage2LedgerService`) |
| message2ledger MySQL | Durable store for message and attempt records | `continuumMessage2LedgerMysql` |
| Orders Service | Optionally contacted to republish a missing order message | `continuumOrdersService` |
| Accounting Service | Receives the posted ledger entry | `continuumAccountingService` |

## Steps

1. **Receives replay request**: An operator or calling service sends a POST to `/messages` (contract replay) or POST/PUT to `/admin/messages` with the message payload to replay.
   - From: Operator / calling service
   - To: `m2l_replayAndRetryApi`
   - Protocol: REST/HTTP

2. **Reads message and attempt history**: The Replay and Retry API reads existing message and attempt records from MySQL to determine replay eligibility and current state.
   - From: `m2l_replayAndRetryApi`
   - To: `continuumMessage2LedgerMysql` (via `m2l_persistence`)
   - Protocol: JDBI/MySQL

3. **Persists or updates message record**: The Replay and Retry API writes the new or updated message record to MySQL.
   - From: `m2l_replayAndRetryApi`
   - To: `continuumMessage2LedgerMysql` (via `m2l_persistence`)
   - Protocol: JDBI/MySQL

4. **Triggers replay processing**: The Replay and Retry API instructs the Processing Orchestrator to schedule a new processing attempt for the message.
   - From: `m2l_replayAndRetryApi`
   - To: `m2l_processingOrchestrator`
   - Protocol: direct

5. **Optionally republishes via Orders Service**: If the replay scenario requires re-fetching the original order event, the service calls the Orders Service to republish the missing order message.
   - From: `continuumMessage2LedgerService`
   - To: `continuumOrdersService`
   - Protocol: HTTP/JSON (retrofit2)

6. **Processes enrichment and ledger post**: The Processing Orchestrator runs the same enrichment and ledger-posting steps as a live event (see [Order to Ledger Processing](order-to-ledger-processing.md) or [Inventory Unit Update Processing](inventory-unit-update-processing.md)).
   - From: `m2l_processingOrchestrator`
   - To: `m2l_inventoryEnrichment`, `m2l_accountingIntegration`, `continuumAccountingService`
   - Protocol: direct / HTTP/JSON

7. **Stores processing outcome**: Final status is written to `attempts` and `messages` tables.
   - From: `m2l_accountingIntegration`
   - To: `continuumMessage2LedgerMysql` (via `m2l_persistence`)
   - Protocol: JDBI/MySQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid replay request | HTTP 4xx returned to caller | No message record created; operator corrects input |
| Orders Service unavailable during republish | HTTP error returned; replay not initiated | Operator retries when Orders Service recovers |
| Processing failure after replay enqueue | Attempt marked failed; Quartz retries | Same retry cycle as live events |
| Max retries exceeded on replayed message | Message in error state in MySQL | Operator uses `/admin/messages/retry/{id}` or re-submits replay |

## Sequence Diagram

```
Operator               -> m2l_replayAndRetryApi:      POST /messages or POST/PUT /admin/messages
m2l_replayAndRetryApi  -> m2l_persistence:            Reads message and attempt history
m2l_replayAndRetryApi  -> m2l_persistence:            Persists or updates message record
m2l_replayAndRetryApi  -> m2l_processingOrchestrator: Triggers replay/retry flows
m2l_processingOrchestrator -> continuumOrdersService: Republishes missing order message (if needed, HTTP/JSON)
continuumOrdersService --> m2l_processingOrchestrator: Acknowledgement
m2l_processingOrchestrator -> m2l_inventoryEnrichment: Requests inventory details (if inventory event)
m2l_processingOrchestrator -> m2l_accountingIntegration: Requests costs and posts ledger entries
m2l_accountingIntegration -> continuumAccountingService: Fetches costs and posts ledger payload
continuumAccountingService --> m2l_accountingIntegration: 200 OK
m2l_accountingIntegration -> m2l_persistence:         Persists processing outcome and status
```

## Related

- Architecture dynamic view: `dynamic-m2l-message-to-ledger-flow`
- Related flows: [Admin Retry Orchestration](admin-retry-orchestration.md), [Scheduled Reconciliation Replay](scheduled-reconciliation-replay.md), [Order to Ledger Processing](order-to-ledger-processing.md)
