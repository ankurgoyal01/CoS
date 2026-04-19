---
service: "message2ledger"
title: "Inventory Unit Update Processing"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "inventory-unit-update-processing"
flow_type: event-driven
trigger: "InventoryUnits.Updated.Vis or InventoryUnits.Updated.Tpis MBus event received (NA or EMEA)"
participants:
  - "messageBus"
  - "continuumMessage2LedgerService"
  - "continuumMessage2LedgerMysql"
  - "continuumVoucherInventoryApi"
  - "continuumThirdPartyInventoryService"
  - "continuumAccountingService"
architecture_ref: "dynamic-m2l-message-to-ledger-flow"
---

# Inventory Unit Update Processing

## Summary

This flow describes how message2ledger handles an inventory unit update event. When an event arrives on `InventoryUnits.Updated.Vis` or `InventoryUnits.Updated.Tpis` (NA or EMEA), the service persists the raw message, enriches the subject with unit and product details from the appropriate inventory API (VIS or TPIS), and then fetches costs and posts a ledger entry to the Accounting Service. The enrichment step is what distinguishes this flow from the order-to-ledger flow: inventory events require an additional call to the Inventory Enrichment Client before ledger posting.

## Trigger

- **Type**: event
- **Source**: MBus topic `InventoryUnits.Updated.Vis` (NA/EMEA) or `InventoryUnits.Updated.Tpis` (NA/EMEA)
- **Frequency**: Per inventory unit update event; volume driven by inventory change rate

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MBus | Delivers the inventory unit update event | `messageBus` |
| MBus Ingress | Receives and persists the raw event envelope | `m2l_mbusIngress` (component of `continuumMessage2LedgerService`) |
| Processing Orchestrator | Schedules and executes the async processing attempt | `m2l_processingOrchestrator` (component of `continuumMessage2LedgerService`) |
| Inventory Enrichment Client | Calls VIS or TPIS API to fetch unit/product details | `m2l_inventoryEnrichment` (component of `continuumMessage2LedgerService`) |
| Accounting Integration Client | Fetches cost details and posts the ledger payload | `m2l_accountingIntegration` (component of `continuumMessage2LedgerService`) |
| Persistence Layer | Stores message envelope, attempt state, and final outcome | `m2l_persistence` (component of `continuumMessage2LedgerService`) |
| message2ledger MySQL | Durable store for message, attempt, and status records | `continuumMessage2LedgerMysql` |
| VIS (continuumVoucherInventoryApi) | Provides voucher/VIS unit and product details | `continuumVoucherInventoryApi` |
| TPIS (continuumThirdPartyInventoryService) | Provides TPIS unit and product details | `continuumThirdPartyInventoryService` |
| Accounting Service | Provides cost details; receives and stores the ledger entry | `continuumAccountingService` |

## Steps

1. **Receives inventory unit update event**: MBus delivers an event from `InventoryUnits.Updated.Vis` or `InventoryUnits.Updated.Tpis` (NA or EMEA) to the MBus Ingress component.
   - From: `messageBus`
   - To: `m2l_mbusIngress`
   - Protocol: JMS/MBus

2. **Persists message envelope**: MBus Ingress writes the raw event payload and metadata to the `messages` table.
   - From: `m2l_mbusIngress`
   - To: `continuumMessage2LedgerMysql` (via `m2l_persistence`)
   - Protocol: JDBI/MySQL

3. **Enqueues processing attempt**: MBus Ingress notifies the Processing Orchestrator to schedule an async attempt.
   - From: `m2l_mbusIngress`
   - To: `m2l_processingOrchestrator`
   - Protocol: direct (in-process KillBill Queue enqueue)

4. **Loads processing state**: Processing Orchestrator reads message and attempt state from MySQL.
   - From: `m2l_processingOrchestrator`
   - To: `continuumMessage2LedgerMysql` (via `m2l_persistence`)
   - Protocol: JDBI/MySQL

5. **Requests inventory details**: Processing Orchestrator calls the Inventory Enrichment Client to fetch unit and product details for the payable subject. For `InventoryUnits.Updated.Vis` events the call goes to `continuumVoucherInventoryApi`; for `InventoryUnits.Updated.Tpis` events the call goes to `continuumThirdPartyInventoryService`.
   - From: `m2l_processingOrchestrator`
   - To: `m2l_inventoryEnrichment`
   - Protocol: direct

6. **Fetches unit details from VIS or TPIS**: Inventory Enrichment Client calls the appropriate inventory API.
   - From: `m2l_inventoryEnrichment`
   - To: `continuumVoucherInventoryApi` (VIS events) or `continuumThirdPartyInventoryService` (TPIS events)
   - Protocol: HTTP/JSON (retrofit2)

7. **Fetches cost details**: Accounting Integration Client calls the Accounting Service to retrieve cost data for the enriched subject.
   - From: `m2l_accountingIntegration`
   - To: `continuumAccountingService`
   - Protocol: HTTP/JSON (retrofit2)

8. **Posts ledger payload**: Accounting Integration Client sends the fully enriched and decorated ledger payload to the Accounting Service.
   - From: `m2l_accountingIntegration`
   - To: `continuumAccountingService`
   - Protocol: HTTP/JSON (retrofit2)

9. **Stores final processing status**: Accounting Integration Client writes the outcome (success or failure) to the `attempts` and `messages` tables.
   - From: `m2l_accountingIntegration`
   - To: `continuumMessage2LedgerMysql` (via `m2l_persistence`)
   - Protocol: JDBI/MySQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MBus delivery failure | MBus broker retries; JMS acknowledgement withheld until persisted | Message re-delivered |
| MySQL write failure on ingress | MBus delivery not acknowledged; re-delivered by broker | No data loss |
| VIS / TPIS API unavailable | Attempt marked failed; Quartz reschedules with backoff | Automatic retry |
| Accounting Service unavailable | Attempt marked failed; Quartz reschedules | Automatic retry |
| Max retries exceeded | Message remains in error state | Operator investigation via `/admin/messages`; manual retry via `/admin/messages/retry/{id}` |

## Sequence Diagram

```
messageBus             -> m2l_mbusIngress:            Delivers InventoryUnits.Updated.Vis/Tpis event
m2l_mbusIngress        -> m2l_persistence:            Stores inbound message envelope and metadata
m2l_mbusIngress        -> m2l_processingOrchestrator: Enqueues processing attempt
m2l_processingOrchestrator -> m2l_persistence:       Loads and updates processing state
m2l_processingOrchestrator -> m2l_inventoryEnrichment: Requests inventory details for payable subject
m2l_inventoryEnrichment -> continuumVoucherInventoryApi: Fetches unit details (VIS events) (HTTP/JSON)
continuumVoucherInventoryApi --> m2l_inventoryEnrichment: Returns unit/product details
m2l_inventoryEnrichment -> continuumThirdPartyInventoryService: Fetches unit details (TPIS events) (HTTP/JSON)
continuumThirdPartyInventoryService --> m2l_inventoryEnrichment: Returns unit/product details
m2l_processingOrchestrator -> m2l_accountingIntegration: Requests costs and posts ledger entries
m2l_accountingIntegration -> continuumAccountingService: Fetches cost details (HTTP/JSON)
continuumAccountingService --> m2l_accountingIntegration: Returns cost data
m2l_accountingIntegration -> continuumAccountingService: Posts ledger payload (HTTP/JSON)
continuumAccountingService --> m2l_accountingIntegration: 200 OK
m2l_accountingIntegration -> m2l_persistence:        Persists processing outcome and status
```

## Related

- Architecture dynamic view: `dynamic-m2l-message-to-ledger-flow`
- Related flows: [Order to Ledger Processing](order-to-ledger-processing.md), [Admin Retry Orchestration](admin-retry-orchestration.md), [Manual Message Replay](manual-message-replay.md)
