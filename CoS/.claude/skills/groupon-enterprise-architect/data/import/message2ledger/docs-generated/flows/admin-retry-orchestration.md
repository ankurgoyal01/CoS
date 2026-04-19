---
service: "message2ledger"
title: "Admin Retry Orchestration"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "admin-retry-orchestration"
flow_type: synchronous
trigger: "POST /admin/messages/retry/{id}"
participants:
  - "continuumMessage2LedgerService"
  - "continuumMessage2LedgerMysql"
  - "continuumAccountingService"
architecture_ref: "dynamic-m2l-message-to-ledger-flow"
---

# Admin Retry Orchestration

## Summary

The admin retry orchestration flow enables Finance Engineering operators to manually trigger a retry for a specific message that has failed processing, using the `/admin/messages/retry/{id}` endpoint. The Replay and Retry API component reads the current attempt history for the message, resets or creates a new attempt record, and instructs the Processing Orchestrator to re-run the full processing pipeline for that message. This flow is used for targeted incident remediation when a specific message has exhausted automatic retries or requires out-of-band investigation.

## Trigger

- **Type**: api-call
- **Source**: Finance Engineering operator via POST `/admin/messages/retry/{id}`
- **Frequency**: On-demand; used during incident response and manual remediation

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator | Issues the retry request via the admin API | — |
| Replay and Retry API | Receives the retry request; reads attempt history; triggers orchestrator | `m2l_replayAndRetryApi` (component of `continuumMessage2LedgerService`) |
| Processing Orchestrator | Re-executes the processing pipeline for the specified message | `m2l_processingOrchestrator` (component of `continuumMessage2LedgerService`) |
| Inventory Enrichment Client | Re-fetches unit/product details if the message is an inventory event | `m2l_inventoryEnrichment` (component of `continuumMessage2LedgerService`) |
| Accounting Integration Client | Re-fetches costs and re-posts the ledger payload | `m2l_accountingIntegration` (component of `continuumMessage2LedgerService`) |
| Persistence Layer | Reads attempt history; writes updated attempt state and outcome | `m2l_persistence` (component of `continuumMessage2LedgerService`) |
| message2ledger MySQL | Durable store for message and attempt records | `continuumMessage2LedgerMysql` |
| Accounting Service | Receives the re-posted ledger entry | `continuumAccountingService` |

## Steps

1. **Receives retry request**: The operator sends POST `/admin/messages/retry/{id}` where `{id}` is the message identifier in MySQL.
   - From: Operator
   - To: `m2l_replayAndRetryApi`
   - Protocol: REST/HTTP

2. **Reads message and attempt history**: The Replay and Retry API loads the message record and all previous attempt records for the specified `{id}` from MySQL to validate eligibility and understand current state.
   - From: `m2l_replayAndRetryApi`
   - To: `continuumMessage2LedgerMysql` (via `m2l_persistence`)
   - Protocol: JDBI/MySQL

3. **Triggers retry via Processing Orchestrator**: The Replay and Retry API instructs the Processing Orchestrator to create a new processing attempt and re-run the pipeline for the message.
   - From: `m2l_replayAndRetryApi`
   - To: `m2l_processingOrchestrator`
   - Protocol: direct

4. **Loads and updates processing state**: The Processing Orchestrator reads the message payload and writes a new attempt record to MySQL.
   - From: `m2l_processingOrchestrator`
   - To: `continuumMessage2LedgerMysql` (via `m2l_persistence`)
   - Protocol: JDBI/MySQL

5. **Requests inventory details (if applicable)**: For inventory event types, the Processing Orchestrator calls the Inventory Enrichment Client to re-fetch unit/product details.
   - From: `m2l_processingOrchestrator`
   - To: `m2l_inventoryEnrichment`
   - Protocol: direct

6. **Fetches cost details**: Accounting Integration Client calls the Accounting Service to retrieve current cost data for the subject.
   - From: `m2l_accountingIntegration`
   - To: `continuumAccountingService`
   - Protocol: HTTP/JSON (retrofit2)

7. **Posts ledger payload**: Accounting Integration Client sends the enriched, decorated ledger payload to the Accounting Service.
   - From: `m2l_accountingIntegration`
   - To: `continuumAccountingService`
   - Protocol: HTTP/JSON (retrofit2)

8. **Persists processing outcome**: Accounting Integration Client writes the final result (success or failure) to `attempts` and `messages` in MySQL.
   - From: `m2l_accountingIntegration`
   - To: `continuumMessage2LedgerMysql` (via `m2l_persistence`)
   - Protocol: JDBI/MySQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Message ID not found | HTTP 404 returned to operator | No retry attempt created |
| Message already in successful state | API may reject or allow idempotent repost (behaviour to be confirmed by service owner) | Operator informed; no duplicate if idempotent |
| Accounting Service unavailable during retry | New attempt marked failed in MySQL | Operator can re-issue retry after dependency recovers; or Quartz scheduler picks it up on next cycle |
| Inventory API unavailable | Attempt marked failed | Operator retries after dependency recovers |
| Retry succeeds | Attempt marked successful in MySQL | Ledger entry posted; message processing complete |

## Sequence Diagram

```
Operator               -> m2l_replayAndRetryApi:      POST /admin/messages/retry/{id}
m2l_replayAndRetryApi  -> m2l_persistence:            Reads message and attempt history
m2l_persistence        --> m2l_replayAndRetryApi:     Returns message and attempt records
m2l_replayAndRetryApi  -> m2l_processingOrchestrator: Triggers replay/retry flows
m2l_processingOrchestrator -> m2l_persistence:       Loads and updates processing state
m2l_processingOrchestrator -> m2l_inventoryEnrichment: Requests inventory details (if inventory event)
m2l_processingOrchestrator -> m2l_accountingIntegration: Requests costs and posts ledger entries
m2l_accountingIntegration -> continuumAccountingService: Fetches cost details (HTTP/JSON)
continuumAccountingService --> m2l_accountingIntegration: Returns cost data
m2l_accountingIntegration -> continuumAccountingService: Posts ledger payload (HTTP/JSON)
continuumAccountingService --> m2l_accountingIntegration: 200 OK
m2l_accountingIntegration -> m2l_persistence:        Persists processing outcomes and statuses
m2l_replayAndRetryApi  --> Operator:                  HTTP 200 (retry accepted)
```

## Related

- Architecture dynamic view: `dynamic-m2l-message-to-ledger-flow`
- Related flows: [Manual Message Replay](manual-message-replay.md), [Scheduled Reconciliation Replay](scheduled-reconciliation-replay.md), [Order to Ledger Processing](order-to-ledger-processing.md)
