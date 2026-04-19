---
service: "message2ledger"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 2
internal_count: 5
---

# Integrations

## Overview

message2ledger integrates with seven downstream systems: the MBus event bus (consumed, not published), three inventory APIs (VIS, TPIS, GLive) for enrichment, the Accounting Service for cost lookup and ledger posting, the Orders Service for missing-message republish, and EDW for reconciliation data. All downstream HTTP calls are made via retrofit2. MBus subscription uses mbus-client (JMS). EDW is accessed via JDBC. The service has no known direct API consumers; all inbound traffic is event-driven.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| MBus | JMS/MBus | Source of order and inventory events consumed by the service | yes | `messageBus` |
| EDW | JDBC | Read-only queries for reconciliation datasets used in automated replay | no | `edw` |

### MBus Detail

- **Protocol**: JMS/MBus
- **Base URL / SDK**: mbus-client library
- **Auth**: Internal JMS broker credentials (managed via JTier configuration)
- **Purpose**: Delivers `Orders.TransactionalLedgerEvents` and `InventoryUnits.Updated.Vis/Tpis` events (NA and EMEA) to the MBus Ingress component
- **Failure mode**: If MBus is unavailable, inbound event delivery stops; already-persisted messages in MySQL are unaffected and continue to be processed by the async queue
- **Circuit breaker**: No evidence found

### EDW Detail

- **Protocol**: JDBC
- **Base URL / SDK**: JDBC connection (managed via JTier datasource configuration)
- **Auth**: Internal database credentials
- **Purpose**: Queried read-only during scheduled reconciliation replay to identify messages that should be replayed based on EDW-side state
- **Failure mode**: Reconciliation replay job fails gracefully; no ledger entries are lost; next scheduled run retries
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| continuumVoucherInventoryApi (VIS) | HTTP/JSON | Fetches voucher and VIS unit/product details for event enrichment | `continuumVoucherInventoryApi` |
| continuumThirdPartyInventoryService (TPIS) | HTTP/JSON | Fetches TPIS unit/product details for event enrichment | `continuumThirdPartyInventoryService` |
| continuumGLiveInventoryService (GLive) | HTTP/JSON | Fetches GLive unit/product details for event enrichment (commented out in model; status unclear) | `continuumGLiveInventoryService` |
| continuumAccountingService | HTTP/JSON | Fetches cost details and posts decorated ledger payloads | `continuumAccountingService` |
| continuumOrdersService | HTTP/JSON | Republishes missing order messages during manual republish flow | `continuumOrdersService` |

### continuumVoucherInventoryApi (VIS) Detail

- **Protocol**: HTTP/JSON
- **Base URL / SDK**: retrofit2 HTTP client
- **Auth**: Internal service credentials
- **Purpose**: Called by `m2l_inventoryEnrichment` to retrieve unit and product details for voucher/VIS-type inventory events before posting to ledger
- **Failure mode**: Processing attempt fails and is rescheduled by the async queue; retried automatically
- **Circuit breaker**: No evidence found

### continuumThirdPartyInventoryService (TPIS) Detail

- **Protocol**: HTTP/JSON
- **Base URL / SDK**: retrofit2 HTTP client
- **Auth**: Internal service credentials
- **Purpose**: Called by `m2l_inventoryEnrichment` when processing `InventoryUnits.Updated.Tpis` events
- **Failure mode**: Processing attempt fails and is rescheduled; retried automatically
- **Circuit breaker**: No evidence found

### continuumAccountingService Detail

- **Protocol**: HTTP/JSON
- **Base URL / SDK**: retrofit2 HTTP client
- **Auth**: Internal service credentials
- **Purpose**: Called by `m2l_accountingIntegration` to (1) fetch cost details for the subject being processed and (2) post the enriched ledger payload
- **Failure mode**: Processing attempt fails; rescheduled via async queue; final status recorded in MySQL
- **Circuit breaker**: No evidence found

### continuumOrdersService Detail

- **Protocol**: HTTP/JSON
- **Base URL / SDK**: retrofit2 HTTP client
- **Auth**: Internal service credentials
- **Purpose**: Called during the manual message republish flow to request re-delivery of a missing order message from the Orders Service
- **Failure mode**: Republish request fails; operator is notified; manual intervention required
- **Circuit breaker**: No evidence found

## Consumed By

> Upstream consumers are tracked in the central architecture model. message2ledger does not expose public-facing APIs; it is consumed internally by Finance Engineering operators via admin endpoints.

## Dependency Health

Retry and rescheduling for all HTTP dependencies is handled by the KillBill Queue-backed Async Task Processor: failed processing attempts are re-enqueued with backoff until a configurable maximum retry count is reached. There is no evidence of circuit breaker patterns or bulkheads in the architecture sources. See [Runbook](runbook.md) for dependency health check guidance.
