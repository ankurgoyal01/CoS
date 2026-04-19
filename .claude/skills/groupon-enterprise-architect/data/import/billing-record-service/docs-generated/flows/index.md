---
service: "billing-record-service"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Billing Record Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Create Billing Record](create-billing-record.md) | synchronous | POST from checkout service | Validates, persists, and caches a new purchaser payment instrument record |
| [Authorize Billing Record](authorize-billing-record.md) | synchronous | PUT from checkout service | Transitions a billing record from INITIATED to AUTHORIZED after payment verification |
| [Deactivate Billing Record](deactivate-billing-record.md) | synchronous | PUT from checkout or user action | Deactivates a billing record and optionally deletes the PCI token |
| [GDPR Individual Rights Request Erasure](gdpr-irr-erasure.md) | event-driven | Message Bus event from Regulatory Consent Log Service | Scrubs PII from all billing records for a purchaser and publishes completion event |
| [Orders Migration](orders-migration.md) | synchronous / batch | POST trigger or batch process | Migrates legacy billing records from the Orders system into BRS |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

- The **Create Billing Record** flow is initiated by `continuumCheckoutReloadedService` and spans into the PCI-API for token storage. Architecture dynamic view: `dynamic-billing-record-create`.
- The **GDPR IRR Erasure** flow is initiated by the Regulatory Consent Log Service via `messageBus` and crosses into PCI-API for token deletion.
- The **Orders Migration** flow reads from the Orders data source (`continuumOrdersService` legacy data) to backfill billing records.
