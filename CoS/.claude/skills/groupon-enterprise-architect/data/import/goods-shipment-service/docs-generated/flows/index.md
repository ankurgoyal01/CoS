---
service: "goods-shipment-service"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for Goods Shipment Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Shipment Creation](shipment-creation.md) | synchronous | POST `/shipments` | Receives and persists new shipment records from upstream fulfilment systems |
| [Carrier Status Refresh](carrier-status-refresh.md) | scheduled | Quartz — Shipment Refresh Job | Polls active carrier APIs for tracking status updates and triggers notifications |
| [Aftership Webhook Processing](aftership-webhook-processing.md) | event-driven | POST `/aftership` (inbound webhook from Aftership) | Validates, parses, and processes inbound Aftership webhook events; updates shipment status and dispatches notifications |
| [Aftership Tracking Registration](aftership-tracking-registration.md) | scheduled | Quartz — Aftership Create Shipments Job | Registers shipments that have not yet been registered with Aftership for passive tracking |
| [Shipment Notification Dispatch](shipment-notification-dispatch.md) | asynchronous | Shipment status transitions; Quartz — Email and Mobile Notification Jobs | Sends email via Rocketman, mobile push via Event Delivery Service, and Mbus events on qualifying status changes |
| [Carrier OAuth Token Refresh](carrier-oauth-token-refresh.md) | scheduled | Quartz — Auth Token Refresh Job | Refreshes OAuth2 access tokens for UPS, FedEx, and DHL before expiry |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 1 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 3 |
| Event-driven (inbound webhook) | 1 |

## Cross-Service Flows

- The Aftership webhook processing flow spans `aftershipApi` and `continuumGoodsShipmentService`; the dynamic view is documented in the architecture DSL at `goodsShipmentServiceAftershipWebhook`.
- The shipment notification dispatch flow spans `continuumGoodsShipmentService`, `rocketmanService`, `eventDeliveryService`, `tokenService`, and `mbusGoodsShipmentNotificationTopic`.
- The carrier status refresh flow spans `continuumGoodsShipmentService` and all carrier APIs (`upsApi`, `fedexApi`, `dhlApi`, `uspsApi`, `aitApi`, `upsmiApi`, `fedexspApi`).
