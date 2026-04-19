---
service: "goods-shipment-service"
title: "Aftership Webhook Processing"
generated: "2026-03-03"
type: flow
flow_name: "aftership-webhook-processing"
flow_type: event-driven
trigger: "POST /aftership — inbound webhook from Aftership platform"
participants:
  - "aftershipApi"
  - "continuumGoodsShipmentService"
  - "continuumGoodsShipmentDatabase"
  - "mbusGoodsShipmentNotificationTopic"
architecture_ref: "dynamic-goodsShipmentServiceAftershipWebhook"
---

# Aftership Webhook Processing

## Summary

Aftership delivers real-time shipment status updates to the Goods Shipment Service via an HTTP POST webhook on the `/aftership` endpoint. The service validates the webhook signature (HMAC-SHA256 or `auth_token`), extracts the `shipment_uuid` from the payload, updates the shipment status in MySQL, and publishes a notification event to the Mbus message bus. This is the primary passive tracking mechanism for shipments registered with Aftership.

## Trigger

- **Type**: event (inbound HTTP webhook)
- **Source**: Aftership platform, which receives tracking events from carriers and delivers them as JSON payloads
- **Frequency**: On-demand, per tracking event received by Aftership from the carrier

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Aftership Platform | Delivers carrier tracking events as webhook | `aftershipApi` |
| Aftership Update Receiver Resource | Receives and authenticates the inbound webhook | `aftershipUpdateReceiverResourceComponent` |
| Aftership Update Receiver Service | Validates payload, extracts data, and orchestrates updates | `aftershipUpdateReceiverServiceComponent` |
| Shipment DAO | Updates shipment status in MySQL | `shipmentDaoComponent` |
| Shipment Notification Sender Service | Publishes shipment notification to Mbus | `shipmentNotificationSenderServiceComponent` |
| Mobile Notification Service | Sends mobile push notification for qualifying statuses | `mobileNotificationServiceComponent` |
| Commerce Interface Client | Sends tracking update to Commerce Interface (EMEA only) | `commerceInterfaceClientComponent` |
| Goods Shipment MySQL | Persistent store for shipment state | `continuumGoodsShipmentDatabase` |
| Mbus (`goodsShipmentNotification`) | Async notification destination | `mbusGoodsShipmentNotificationTopic` |

## Steps

1. **Receive webhook**: Aftership POSTs a JSON payload to `POST /aftership`. The request includes an `Aftership-Hmac-Sha256` header (HMAC-SHA256 signature) and/or an `auth_token` query parameter.
   - From: `aftershipApi`
   - To: `aftershipUpdateReceiverResourceComponent`
   - Protocol: REST/HTTPS (inbound)

2. **Validate authentication**: The Aftership Update Receiver Resource validates the HMAC-SHA256 signature against the configured `aftership.webhookSecret`, or validates the `auth_token` against `aftership.webhookAuthToken`. Returns HTTP 401 on failure.
   - From: `aftershipUpdateReceiverResourceComponent`
   - To: `aftershipUpdateReceiverServiceComponent`
   - Protocol: direct

3. **Parse and validate payload**: Aftership Update Receiver Service deserialises the JSON payload. Returns HTTP 500 if the JSON is invalid, the structure is incomplete, or `shipment_uuid` is missing.
   - From: `aftershipUpdateReceiverServiceComponent`
   - To: internal
   - Protocol: direct

4. **Update shipment status**: Aftership Update Receiver Service writes the new status and event history to MySQL via Shipment DAO (`saveStatusUpdates` / `saveTrackingUpdates`).
   - From: `aftershipUpdateReceiverServiceComponent`
   - To: `shipmentDaoComponent` → `continuumGoodsShipmentDatabase`
   - Protocol: JDBC/MySQL

5. **Publish Mbus notification**: If the new status is a notification state (SHIPPED, OUT_FOR_DELIVERY, DELIVERED, REJECTED, NOT_DELIVERED), the Shipment Notification Sender Service publishes a `ShipmentMessage` to the `goodsShipmentNotification` Mbus destination.
   - From: `aftershipUpdateReceiverServiceComponent` → `shipmentNotificationSenderServiceComponent`
   - To: `mbusGoodsShipmentNotificationTopic`
   - Protocol: Message Bus

6. **Send mobile push notification**: For statuses SHIPPED, OUT_FOR_DELIVERY, or DELIVERED, Mobile Notification Service fetches the consumer push token from Token Service and delivers a push event via Event Delivery Service.
   - From: `aftershipUpdateReceiverServiceComponent` → `mobileNotificationServiceComponent`
   - To: `eventDeliveryService` (via `/pns/v1.0/notification/EVENT/goods_shipment_*`)
   - Protocol: REST/HTTPS

7. **Update Commerce Interface** (EMEA only): If the shipment status is a notification state and the region is EMEA, Commerce Interface Client sends a `PUT api/internal/v1/tracking_update` to update the order status.
   - From: `aftershipUpdateReceiverServiceComponent` → `commerceInterfaceClientComponent`
   - To: `commerceInterfaceService`
   - Protocol: REST/HTTPS

8. **Return HTTP 200**: Aftership Update Receiver Resource returns HTTP 200 to Aftership on successful processing.
   - From: `aftershipUpdateReceiverResourceComponent`
   - To: `aftershipApi`
   - Protocol: REST/HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid HMAC-SHA256 signature | Return HTTP 401 | Aftership retries delivery per its retry policy |
| Invalid JSON or missing `shipment_uuid` | Return HTTP 500 | Aftership retries delivery; error logged |
| Mbus publish failure | `ShipmentNotificationSendingException` thrown; logged as ERROR | Notification not sent; no automatic retry in this flow |
| Mobile push failure | `IOException` thrown; logged as ERROR | Push notification not delivered for this event |
| CI tracking update failure | `IOException` thrown; logged as ERROR | Commerce Interface not updated for this event |

## Sequence Diagram

```
Aftership -> AftershipUpdateReceiverResource: POST /aftership (webhook payload)
AftershipUpdateReceiverResource -> AftershipUpdateReceiverService: validate and parse payload
AftershipUpdateReceiverService -> ShipmentDAO: update shipment status
ShipmentDAO -> MySQL: UPDATE shipment
MySQL --> ShipmentDAO: ok
AftershipUpdateReceiverService -> ShipmentNotificationSenderService: publish notification (if notification state)
ShipmentNotificationSenderService -> Mbus: write ShipmentMessage to goodsShipmentNotification
AftershipUpdateReceiverService -> MobileNotificationService: send push (if SHIPPED/OUT_FOR_DELIVERY/DELIVERED)
MobileNotificationService -> TokenService: fetch device token
MobileNotificationService -> EventDeliveryService: POST /pns/v1.0/notification/EVENT/goods_shipment_*
AftershipUpdateReceiverService -> CommerceInterfaceClient: PUT tracking_update (EMEA only)
AftershipUpdateReceiverResource --> Aftership: HTTP 200
```

## Related

- Architecture dynamic view: `dynamic-goodsShipmentServiceAftershipWebhook`
- Related flows: [Aftership Tracking Registration](aftership-tracking-registration.md), [Shipment Notification Dispatch](shipment-notification-dispatch.md)
