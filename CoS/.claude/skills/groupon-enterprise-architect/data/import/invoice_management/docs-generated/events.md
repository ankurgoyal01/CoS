---
service: "invoice_management"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

invoice_management is a significant consumer of Groupon's Message Bus (mbus). It consumes five event streams from the Goods platform to drive invoice creation, receiver management, and shipment tracking. The service uses `mbus-client` 1.2.7 to subscribe to these topics. No outbound events are published by this service; all external notifications are sent synchronously (via Rocketman for email, NetSuite for financial data).

## Published Events

> No evidence found in codebase. This service does not publish any async events to the Message Bus.

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| PO events topic | Purchase Order event | PO Event Consumer | Creates invoice record in PostgreSQL; triggers invoice creation workflow |
| Receiver events topic | Receiver event | Receiver Event Consumer | Creates receiver record in PostgreSQL |
| SRS topic | Sales order update | SRS Event Consumer | Updates invoice state based on sales order changes |
| GMO topic | Marketplace item shipped | GMO Event Consumer | Creates marketplace invoice record |
| STS topic | Shipment tracking update | STS Event Consumer | Updates shipment status on related invoice or PO |

### Purchase Order (PO) Event Detail

- **Topic**: PO events topic (Groupon Message Bus)
- **Handler**: PO Event Consumer component in `goodsInvoiceAggregator`; creates new invoice records from PO data and persists to `continuumInvoiceManagementPostgres`
- **Idempotency**: > No evidence found in codebase.
- **Error handling**: > No evidence found in codebase. Standard mbus-client retry and dead-letter behaviour assumed.
- **Processing order**: unordered

### Receiver Event Detail

- **Topic**: Receiver events topic (Groupon Message Bus)
- **Handler**: Receiver Event Consumer; creates receiver records in `continuumInvoiceManagementPostgres` for vendor tracking
- **Idempotency**: > No evidence found in codebase.
- **Error handling**: > No evidence found in codebase.
- **Processing order**: unordered

### SRS (Sales Order Update) Event Detail

- **Topic**: SRS topic (Groupon Message Bus)
- **Handler**: SRS Event Consumer; updates existing invoice records when the corresponding sales order status changes
- **Idempotency**: > No evidence found in codebase.
- **Error handling**: > No evidence found in codebase.
- **Processing order**: unordered

### GMO (Marketplace Item Shipped) Event Detail

- **Topic**: GMO topic (Groupon Message Bus)
- **Handler**: GMO Event Consumer; creates marketplace invoice from shipment confirmation
- **Idempotency**: > No evidence found in codebase.
- **Error handling**: > No evidence found in codebase.
- **Processing order**: unordered

### STS (Shipment Tracking) Event Detail

- **Topic**: STS topic (Groupon Message Bus)
- **Handler**: STS Event Consumer; updates shipment status fields on the relevant invoice or PO record
- **Idempotency**: > No evidence found in codebase.
- **Error handling**: > No evidence found in codebase.
- **Processing order**: unordered

## Dead Letter Queues

> No evidence found in codebase. Dead letter queue configuration is managed by the mbus-client 1.2.7 library and the central Message Bus platform. Contact the Message Bus platform team for DLQ details per topic.
