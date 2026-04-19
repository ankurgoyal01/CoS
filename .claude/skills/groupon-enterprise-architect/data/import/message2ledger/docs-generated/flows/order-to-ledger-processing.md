---
service: "message2ledger"
title: "Order to Ledger Processing"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "order-to-ledger-processing"
flow_type: event-driven
trigger: "Orders.TransactionalLedgerEvents MBus event received (NA or EMEA)"
participants:
  - "messageBus"
  - "continuumMessage2LedgerService"
  - "continuumMessage2LedgerMysql"
  - "continuumAccountingService"
architecture_ref: "dynamic-m2l-message-to-ledger-flow"
---

# Order to Ledger Processing

## Summary

This flow describes how message2ledger processes an order transactional ledger event from receipt through to the final ledger entry post. When an order event arrives on the `Orders.TransactionalLedgerEvents` MBus topic (for NA or EMEA), the service persists the raw message, schedules an async processing attempt, fetches cost details from the Accounting Service, and posts a decorated ledger payload. The flow is fully asynchronous after the initial MBus delivery: processing is driven by the Quartz/KillBill Queue Async Task Processor.

## Trigger

- **Type**: event
- **Source**: MBus topic `Orders.TransactionalLedgerEvents` (NA and EMEA regions)
- **Frequency**: Per order event; volume driven by order transaction rate

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MBus | Delivers the order transactional ledger event | `messageBus` |
| MBus Ingress | Receives and persists the raw event envelope | `m2l_mbusIngress` (component of `continuumMessage2LedgerService`) |
| Processing Orchestrator | Schedules and executes the async processing attempt | `m2l_processingOrchestrator` (component of `continuumMessage2LedgerService`) |
| Persistence Layer | Stores message envelope, attempt state, and final outcome | `m2l_persistence` (component of `continuumMessage2LedgerService`) |
| Accounting Integration Client | Fetches cost details and posts the ledger payload | `m2l_accountingIntegration` (component of `continuumMessage2LedgerService`) |
| message2ledger MySQL | Durable store for message, attempt, and status records | `continuumMessage2LedgerMysql` |
| Accounting Service | Provides cost details; receives and stores the ledger entry | `continuumAccountingService` |

## Steps

1. **Receives order event**: MBus delivers an event from `Orders.TransactionalLedgerEvents` (NA or EMEA) to the MBus Ingress component.
   - From: `messageBus`
   - To: `m2l_mbusIngress`
   - Protocol: JMS/MBus

2. **Persists message envelope**: MBus Ingress writes the raw event payload and metadata to the `messages` table.
   - From: `m2l_mbusIngress`
   - To: `continuumMessage2LedgerMysql` (via `m2l_persistence`)
   - Protocol: JDBI/MySQL

3. **Enqueues processing attempt**: MBus Ingress notifies the Processing Orchestrator to schedule an async attempt for this message.
   - From: `m2l_mbusIngress`
   - To: `m2l_processingOrchestrator`
   - Protocol: direct (in-process KillBill Queue enqueue)

4. **Loads processing state**: Processing Orchestrator reads the message record and current attempt state from MySQL to determine the next action.
   - From: `m2l_processingOrchestrator`
   - To: `continuumMessage2LedgerMysql` (via `m2l_persistence`)
   - Protocol: JDBI/MySQL

5. **Fetches cost details**: Accounting Integration Client calls the Accounting Service to retrieve cost data for the order subject.
   - From: `m2l_accountingIntegration`
   - To: `continuumAccountingService`
   - Protocol: HTTP/JSON (retrofit2)

6. **Posts ledger payload**: Accounting Integration Client sends the enriched, decorated ledger payload to the Accounting Service ledger endpoint.
   - From: `m2l_accountingIntegration`
   - To: `continuumAccountingService`
   - Protocol: HTTP/JSON (retrofit2)

7. **Stores final processing status**: Accounting Integration Client writes the outcome (success or failure) back to the `attempts` and `messages` tables.
   - From: `m2l_accountingIntegration`
   - To: `continuumMessage2LedgerMysql` (via `m2l_persistence`)
   - Protocol: JDBI/MySQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MBus delivery failure | MBus broker retries delivery; JMS acknowledgement not sent until message is persisted | Message re-delivered by broker |
| MySQL write failure on ingress | MBus delivery not acknowledged; message re-delivered | No data loss; retry on re-delivery |
| Accounting Service unavailable (cost fetch) | Attempt marked as failed in MySQL; Quartz scheduler re-enqueues with backoff | Automatic retry on next scheduler cycle |
| Accounting Service unavailable (ledger post) | Attempt marked as failed; retry scheduled | Automatic retry; operator can also use `/admin/messages/retry/{id}` |
| Max retries exceeded | Message remains in error state in MySQL | Operator investigation via `/admin/messages`; manual retry or replay |

## Sequence Diagram

```
messageBus            -> m2l_mbusIngress:          Delivers Orders.TransactionalLedgerEvents event
m2l_mbusIngress       -> m2l_persistence:          Stores inbound message envelope and metadata
m2l_mbusIngress       -> m2l_processingOrchestrator: Enqueues processing attempt
m2l_processingOrchestrator -> m2l_persistence:    Loads and updates processing state
m2l_processingOrchestrator -> m2l_accountingIntegration: Requests costs and posts ledger entries
m2l_accountingIntegration -> continuumAccountingService: Fetches cost details (HTTP/JSON)
continuumAccountingService --> m2l_accountingIntegration: Returns cost data
m2l_accountingIntegration -> continuumAccountingService: Posts ledger payload (HTTP/JSON)
continuumAccountingService --> m2l_accountingIntegration: 200 OK
m2l_accountingIntegration -> m2l_persistence:     Persists processing outcome and status
```

## Related

- Architecture dynamic view: `dynamic-m2l-message-to-ledger-flow`
- Related flows: [Inventory Unit Update Processing](inventory-unit-update-processing.md), [Admin Retry Orchestration](admin-retry-orchestration.md), [Manual Message Replay](manual-message-replay.md)
