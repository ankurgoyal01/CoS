---
service: "reporting-service"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

The reporting service participates in the Continuum message bus (MBus) for both publishing and consuming asynchronous events. It publishes `BulkVoucherRedemption` events when a bulk redemption CSV is processed. It consumes four inbound event types: `PaymentNotification` (payment outcomes), `ugc.reviews` (merchant review data), `VatInvoicing` (VAT invoice triggers), and `BulkVoucherRedemption` (loopback/downstream redemption confirmations). All MBus interactions are handled by the `reportingService_mbusConsumers` and `mbusProducer` components within `continuumReportingApiService`.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `mbus` | `BulkVoucherRedemption` | Bulk redemption CSV processed via `POST /bulkredemption/v1/uploadcsvfile` | Voucher IDs, redemption status, merchant ID |

### BulkVoucherRedemption (Published) Detail

- **Topic**: `mbus`
- **Trigger**: A merchant uploads a bulk redemption CSV file; the `reportingService_apiControllers` component delegates to `mbusProducer` to emit the event after CSV parsing and validation
- **Payload**: Voucher identifiers, redemption outcomes, and merchant context (exact schema to be confirmed from service source)
- **Consumers**: Downstream voucher and redemption processing services within Continuum
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `mbus` | `PaymentNotification` | `reportingService_mbusConsumers` | Persists payment event data to `continuumReportingDb`; may trigger reporting workflows via `reportGenerationService` |
| `mbus` | `ugc.reviews` | `reportingService_mbusConsumers` | Persists UGC review data for inclusion in merchant performance reports |
| `mbus` | `VatInvoicing` | `reportingService_mbusConsumers` | Persists VAT invoice data to `continuumVatDb`; triggers VAT report generation |
| `mbus` | `BulkVoucherRedemption` | `reportingService_mbusConsumers` | Persists redemption confirmation data; updates voucher reporting state |

### PaymentNotification Detail

- **Topic**: `mbus`
- **Handler**: `reportingService_mbusConsumers` — persists message data via `reportingService_persistenceDaos` and may trigger report generation via `reportGenerationService`
- **Idempotency**: No evidence found; to be confirmed with service owner
- **Error handling**: No evidence found for DLQ or retry strategy; to be confirmed with service owner
- **Processing order**: unordered

### ugc.reviews Detail

- **Topic**: `mbus`
- **Handler**: `reportingService_mbusConsumers` — persists review data for merchant report enrichment
- **Idempotency**: No evidence found; to be confirmed with service owner
- **Error handling**: No evidence found for DLQ or retry strategy; to be confirmed with service owner
- **Processing order**: unordered

### VatInvoicing Detail

- **Topic**: `mbus`
- **Handler**: `reportingService_mbusConsumers` — persists VAT invoice triggers and coordinates VAT report generation
- **Idempotency**: No evidence found; to be confirmed with service owner
- **Error handling**: No evidence found for DLQ or retry strategy; to be confirmed with service owner
- **Processing order**: unordered

### BulkVoucherRedemption (Consumed) Detail

- **Topic**: `mbus`
- **Handler**: `reportingService_mbusConsumers` — persists redemption data for voucher reporting
- **Idempotency**: No evidence found; to be confirmed with service owner
- **Error handling**: No evidence found for DLQ or retry strategy; to be confirmed with service owner
- **Processing order**: unordered

## Dead Letter Queues

> No evidence found in the architecture model for dead letter queue configuration. DLQ strategy to be confirmed with service owner.
