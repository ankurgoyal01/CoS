---
service: "message2ledger"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumMessage2LedgerService, continuumMessage2LedgerMysql]
---

# Architecture Context

## System Context

message2ledger lives inside the `continuumSystem` (Continuum Platform — Groupon's core commerce engine). It acts as a bridge between the commerce event bus and the Accounting Service: it subscribes to MBus order and inventory topics, enriches each event by calling inventory and cost APIs, and posts the resulting ledger records downstream. The service has no inbound user-facing traffic; all processing is event-driven or triggered via internal admin endpoints.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| message2ledger Service | `continuumMessage2LedgerService` | Service | Java 11, JTier, Dropwizard | 5.14.0 | Consumes order/inventory events, enriches payloads, and posts ledger entries |
| message2ledger MySQL | `continuumMessage2LedgerMysql` | Database | MySQL | 5.7 | Operational datastore and queue state for messages, attempts, and replay metadata |

## Components by Container

### message2ledger Service (`continuumMessage2LedgerService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| MBus Ingress (`m2l_mbusIngress`) | Consumes order and inventory bus topics and persists raw messages | MBusListener, OrdersMessageProcessor, InventoryMessageProcessor |
| Processing Orchestrator (`m2l_processingOrchestrator`) | Schedules and executes asynchronous processing attempts and retries | QueueManager, OrderTask, InventoryTask |
| Inventory Enrichment Client (`m2l_inventoryEnrichment`) | Fetches unit/product details from voucher, VIS, TPIS, and GLive inventory APIs | InventoryClient |
| Accounting Integration Client (`m2l_accountingIntegration`) | Fetches cost details and posts decorated payloads to ledger endpoints | CostClient, LedgerClient |
| Replay and Retry API (`m2l_replayAndRetryApi`) | Admin endpoints for replay, retry, republish, and lifecycle investigation | ReplayMessageController, RetryMessageController, RepublishOrderMessageController, UnitLifeCycleController |
| Persistence Layer (`m2l_persistence`) | Stores messages, attempts, subjects, activity, and replay records | Message2LedgerDao, JDBI |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumMessage2LedgerService` | `messageBus` | Subscribes to order and inventory lifecycle events | JMS/MBus |
| `continuumMessage2LedgerService` | `continuumMessage2LedgerMysql` | Reads/writes messages, attempts, subjects, and replay state | JDBI/MySQL |
| `continuumMessage2LedgerService` | `continuumVoucherInventoryApi` | Fetches voucher and VIS unit/product details | HTTP/JSON |
| `continuumMessage2LedgerService` | `continuumThirdPartyInventoryService` | Fetches TPIS unit/product details | HTTP/JSON |
| `continuumMessage2LedgerService` | `continuumAccountingService` | Fetches cost details and posts ledger payloads | HTTP/JSON |
| `continuumMessage2LedgerService` | `continuumOrdersService` | Republishes missing order messages | HTTP/JSON |
| `continuumMessage2LedgerService` | `edw` | Queries reconciliation datasets for automated replay | JDBC |
| `m2l_mbusIngress` | `m2l_persistence` | Stores inbound message envelopes and metadata | direct |
| `m2l_mbusIngress` | `m2l_processingOrchestrator` | Enqueues processing attempts | direct |
| `m2l_processingOrchestrator` | `m2l_inventoryEnrichment` | Requests inventory details for payable subjects | direct |
| `m2l_processingOrchestrator` | `m2l_accountingIntegration` | Requests costs and posts ledger entries | direct |
| `m2l_processingOrchestrator` | `m2l_persistence` | Loads and updates processing state | direct |
| `m2l_replayAndRetryApi` | `m2l_processingOrchestrator` | Triggers replay/retry flows | direct |
| `m2l_replayAndRetryApi` | `m2l_persistence` | Reads message and attempt history | direct |
| `m2l_accountingIntegration` | `m2l_persistence` | Persists processing outcomes and statuses | direct |

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-continuum`
- Component: `components-continuum-message2-ledger-service`
- Dynamic flow: `dynamic-m2l-message-to-ledger-flow`
