---
service: "goods-shipment-service"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

The Goods Shipment Service publishes asynchronous messages to the Groupon internal message bus (Mbus) using `jtier-messagebus-client`. Two separate Mbus destinations are used: one for shipment status notifications and one for order fulfilment notifications. The service does not consume any async events; all inbound status updates arrive either via the Aftership webhook (HTTP) or through active polling of carrier APIs.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `goodsShipmentNotification` | ShipmentMessage | Shipment enters a notification state (SHIPPED, OUT_FOR_DELIVERY, DELIVERED, REJECTED, NOT_DELIVERED) | `shipmentUuid`, `lineItemId`, `orderLineItemUuid`, `carrier`, `trackingNumber`, `status`, `shippedOn`, `deliveredOn`, `events` |
| `orderFulfillmentNotification` | OrderFulfillmentNotificationPayload | Admin endpoint POST `/admin/shipments/sendOrderFulfillment` or internal trigger by order UUID | `orderUuid`, list of shipments with carrier and fulfilment data |

### ShipmentMessage Detail

- **Topic**: `goodsShipmentNotification` (Mbus destination ID: `goodsShipmentNotification`)
- **Trigger**: A shipment record transitions into a notification state — one of `SHIPPED`, `OUT_FOR_DELIVERY`, `DELIVERED`, `REJECTED`, or `NOT_DELIVERED`. Triggered by carrier refresh jobs, Aftership webhook processing, or manual admin endpoints.
- **Payload**: JSON-serialised `ShipmentMessage` (message version 1). Key fields on the nested `shipment` object: `shipmentUuid`, `lineItemId`, `orderLineItemUuid`, `carrier`, `trackingNumber`, `serviceType`, `reportedOn`, `shippedOn`, `outForDeliveryOn`, `deliveredOn`, `notDeliveredOn`, `expectedDeliveryDate`, `statusDate`, `zip`, `country`, `status`, `rawStatus`, `events` (carrier event history as JSON), `poId`, `shipmentType`, `emailStatus`, `updatedOn`, `channelCountry`, `carrierSourceType`, `voucherUuids`
- **Consumers**: Downstream services that react to shipment status changes (tracked in the central architecture model)
- **Guarantees**: at-least-once (Mbus delivery semantics)

### OrderFulfillmentNotificationPayload Detail

- **Topic**: `orderFulfillmentNotification` (Mbus destination ID: `orderFulfillmentNotification`)
- **Trigger**: POST `/admin/shipments/sendOrderFulfillment` with one or more `orderUuids`, or internal programmatic call for a specific order UUID.
- **Payload**: JSON-serialised `OrderFulfillmentNotificationPayload` containing order UUID and associated shipment list with carrier and fulfilment details.
- **Consumers**: Order fulfilment systems that require shipment aggregation per order (tracked in the central architecture model)
- **Guarantees**: at-least-once (Mbus delivery semantics)

## Consumed Events

> No evidence found in codebase. This service does not consume any asynchronous events. All inbound data arrives over REST (Aftership webhooks or synchronous carrier API polling).

## Dead Letter Queues

> No evidence found in codebase. No DLQ configuration was observed in the source.
