---
service: "Netsuite"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [http-webhook, snaplogic-pipeline]
---

# Events

## Overview

The NetSuite customizations do not use a traditional message broker (no Kafka, RabbitMQ, or SQS). Instead, asynchronous event-like communication is implemented through two patterns:

1. **SnapLogic pipeline triggers** — NetSuite Suitelets POST directly to SnapLogic scheduled-task URLs to launch integration pipelines. These fire-and-forget HTTP calls act as event notifications.
2. **Callback responses** — Scheduled scripts that push OTP/PO data to downstream services (GLS, PO Manager) receive an HTTP response acknowledging receipt; they retry up to 5 times with a 10-second pause between attempts.

There is no internal publish/subscribe system. NetSuite User Event Scripts fire synchronously on record lifecycle events (beforeSubmit, afterSubmit) within the NetSuite platform.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| SnapLogic: `GrouponProd/projects/Banking/JPM NS2 Send to ACH` | ACH payment batch submission | Finance user submits selected payment files via JPM Suitelet | `Folder` (File Cabinet folder ID), `Email` (user email) |
| SnapLogic: `GrouponProd/projects/Kyriba/Kyriba outbound parent Trigger` | Kyriba outbound file capture | Finance user submits Kyriba Outbound Suitelet | none (trigger-only) |
| SnapLogic: `GrouponProd/projects/Kyriba/Kyriba NS2 Inbound Kickoff` | Kyriba inbound file submission | Finance user submits Kyriba Inbound Suitelet, selecting subsidiary | Subsidiary selection |
| SnapLogic: `GrouponProd/projects/Reconciliation/NS2 Refresh Balance Trigger` | NS2 reconciliation balance pull | Finance user submits NS Reconciliation Pull Suitelet | none (trigger-only) |
| GLS invoicing service callback URL (via `custscript_gls_url_*`) | OTP purchase order data | Scheduled script `GG_sched_push_ds_otp_gls` on timed interval | `purchaseOrders[]` with PO header, vendor, and line items (JSON) |
| PO Manager EMEA callback URL (via `custscript_push_emea_*`) | EMEA OTP purchase order data | Scheduled script `GG_emea_sched_push_otp_pomgr` on timed interval | `purchaseOrders[]` with PO header, vendor, and line items (JSON) |

### OTP Purchase Order Push Detail

- **Topic**: GLS invoicing callback URL (configured in script parameters)
- **Trigger**: Scheduled script runs periodically; queries purchase orders modified since last successful run using `customrecord_poes_auto_ctrl` control record
- **Payload**: JSON array of `purchaseOrders` objects containing `po` (header fields), `vendor` (address/contact), and `items` (line item details including quantity, rate, VAT, dimensions)
- **Consumers**: GLS invoicing service (Drop-Ship OTPs), PO Manager (EMEA OTPs)
- **Guarantees**: At-least-once; up to 5 retry attempts with 10-second intervals. Terminates and sets error state after 5 consecutive failures.

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| NetSuite record lifecycle: `vendorbill` beforeSubmit | Bill create/edit | `beforeSubmit_goodsAPAcctChng`, `beforeSubmit_verifyNewInvoiceNumber`, `beforeSubmit_NAHeaderTaxCoupa` | Validates AP account currency, detects duplicate invoice numbers, distributes Coupa header tax across expense lines |
| NetSuite record lifecycle: `vendorbill` afterSubmit | Bill create/edit/delete | `afterSubmit_vendorBillNumbering` | Sets transaction ID from invoice number, updates parent PO bill total and billed quantities |
| NetSuite record lifecycle: `purchaseorder` afterSubmit | PO create/edit | PO UI button scripts | Enables parent PO processing actions |
| SnapLogic inbound webhook (Kyriba) | Kyriba cash position / payment status | BMG h2h inbound scheduled script | Books reconciliation transactions from Kyriba data |

### NetSuite User Event Detail

- **Handler**: SuiteScript User Event scripts triggered by NetSuite platform on record save
- **Idempotency**: Controlled by `stType` parameter (`create`, `edit`, `delete`) — create-only validation guards prevent duplicate processing
- **Error handling**: Scripts throw `nlapiCreateError` with custom codes; NetSuite rolls back the transaction and displays the error to the user
- **Processing order**: Synchronous, within the NetSuite save transaction

## Dead Letter Queues

> No evidence found in codebase. No formal DLQ mechanism exists. Failed scheduled script runs are tracked in the `customrecord_poes_auto_ctrl` control record (`custrecord_poes_auto_ctrl_running_chk` flag) and require manual reset after the maximum retry threshold is exceeded.
