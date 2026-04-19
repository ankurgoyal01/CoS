---
service: "goods-shipment-service"
title: "Shipment Notification Dispatch"
generated: "2026-03-03"
type: flow
flow_name: "shipment-notification-dispatch"
flow_type: asynchronous
trigger: "Shipment status transition to a notification state; or Quartz Email Notification Job / Mobile Notification Job"
participants:
  - "continuumGoodsShipmentService"
  - "continuumGoodsShipmentDatabase"
  - "rocketmanService"
  - "eventDeliveryService"
  - "tokenService"
  - "mbusGoodsShipmentNotificationTopic"
architecture_ref: "components-goodsShipmentService"
---

# Shipment Notification Dispatch

## Summary

When a shipment transitions to a notification state, the Goods Shipment Service fans out three types of notifications: (1) a transactional email via Rocketman, (2) a mobile push notification via Event Delivery Service (for SHIPPED, OUT_FOR_DELIVERY, DELIVERED), and (3) a message bus event via Mbus for downstream consumers. Scheduled Quartz jobs (`EmailNotificationJob`, `ShipmentUpdateMobileNotificationJob`) also retry pending notifications for shipments that have not yet been notified.

Notification states are: `SHIPPED`, `OUT_FOR_DELIVERY`, `DELIVERED`, `REJECTED`, `NOT_DELIVERED`.
Mobile push states are a subset: `SHIPPED`, `OUT_FOR_DELIVERY`, `DELIVERED`.

## Trigger

- **Type**: event (status transition) or schedule (Quartz jobs)
- **Source**: Carrier refresh, Aftership webhook processing, or admin endpoint triggering a status-eligible shipment; or Quartz `EmailNotificationJob` / `ShipmentUpdateMobileNotificationJob` for pending retries
- **Frequency**: On-demand per status change; or per Quartz schedule for retry jobs

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Shipment Service | Evaluates notification eligibility and orchestrates dispatch | `shipmentServiceComponent` |
| Email Notification Job | Scheduled retry for pending email notifications | `emailNotificationJobComponent` |
| Shipment Update Mobile Notification Job | Scheduled retry for pending mobile notifications | `shipmentUpdateMobileNotificationJobComponent` |
| Email Notification Service | Builds and dispatches email via Rocketman | `emailNotificationServiceComponent` |
| Mobile Notification Service | Fetches push tokens and dispatches mobile events | `mobileNotificationServiceComponent` |
| Shipment Notification Sender Service | Publishes `ShipmentMessage` to Mbus | `shipmentNotificationSenderServiceComponent` |
| Rocketman Client | HTTP client sending email to Rocketman service | `rocketmanClientComponent` |
| Event Delivery Service Client | HTTP client sending push events to EDS | `eventDeliveryServiceClientComponent` |
| Token Service Client | HTTP client fetching push tokens | `tokenServiceClientComponent` |
| Shipment DAO | Reads shipments awaiting email; updates email status | `shipmentDaoComponent` |
| Goods Shipment MySQL | Persistent store; tracks `isEmailed` status | `continuumGoodsShipmentDatabase` |
| Rocketman | External email dispatch service | `rocketmanService` |
| Event Delivery Service | External mobile push notification service | `eventDeliveryService` |
| Token Service | External push token registry | `tokenService` |
| Mbus (`goodsShipmentNotification`) | Async message bus topic for downstream consumers | `mbusGoodsShipmentNotificationTopic` |

## Steps

1. **Evaluate notification state**: Shipment Service (or Aftership Update Receiver Service) checks whether the new status is a notification state (`isNotificationState()`).
   - From: `shipmentServiceComponent` / `aftershipUpdateReceiverServiceComponent`
   - To: `shipmentNotificationSenderServiceComponent`, `mobileNotificationServiceComponent`, `emailNotificationServiceComponent`
   - Protocol: direct

2. **Publish Mbus event**: Shipment Notification Sender Service wraps the shipment in a `ShipmentMessage` (version 1) and writes it to the `goodsShipmentNotification` Mbus destination.
   - From: `shipmentNotificationSenderServiceComponent`
   - To: `mbusGoodsShipmentNotificationTopic`
   - Protocol: Message Bus (Mbus/MbusWriter)

3. **Send email notification**: Email Notification Service builds the appropriate email template (NA template `ShipmentNotificationNaTemplate` or EMEA template `ShipmentNotificationEmeaTemplate`). Rocketman Client posts to the configured Rocketman endpoint with `X-brand` header and `client_id` query param.
   - From: `emailNotificationServiceComponent` → `rocketmanClientComponent`
   - To: `rocketmanService`
   - Protocol: REST/HTTPS

4. **Mark email sent**: Shipment DAO updates `isEmailed` status in MySQL on successful email dispatch.
   - From: `emailNotificationServiceComponent`
   - To: `shipmentDaoComponent` → `continuumGoodsShipmentDatabase`
   - Protocol: JDBC/MySQL

5. **Fetch push token** (mobile push only, for SHIPPED / OUT_FOR_DELIVERY / DELIVERED): Mobile Notification Service calls Token Service to retrieve the consumer's device push token using `consumerUuid`.
   - From: `mobileNotificationServiceComponent` → `tokenServiceClientComponent`
   - To: `tokenService`
   - Protocol: REST/HTTPS

6. **Deliver mobile push notification**: Event Delivery Service Client posts to the appropriate endpoint based on shipment status: `/pns/v1.0/notification/EVENT/goods_shipment_shipped`, `/pns/v1.0/notification/EVENT/goods_shipment_out_for_delivery`, or `/pns/v1.0/notification/EVENT/goods_shipment_delivered`. The `X-HB-Region` header is set if `eventDeliveryService.region` is configured.
   - From: `eventDeliveryServiceClientComponent`
   - To: `eventDeliveryService`
   - Protocol: REST/HTTPS

7. **Scheduled retry (Email Notification Job)**: The Quartz `EmailNotificationJob` queries `getShipmentsAwaitingEmail` (batch up to `batchSize`, filtered by `reportedOnCutoff` using `emailReportedOnCutoffDays`) and retries email dispatch for shipments where `isEmailed` is not sent. Feature flag `featureFlags.emailNotificationJob` must be true.
   - From: `emailNotificationJobComponent`
   - To: `emailNotificationServiceComponent`
   - Protocol: direct

8. **Scheduled retry (Mobile Notification Job)**: The Quartz `ShipmentUpdateMobileNotificationJob` processes pending mobile notifications. Feature flag `featureFlags.shipmentUpdateMobileNotificationJob` must be true.
   - From: `shipmentUpdateMobileNotificationJobComponent`
   - To: `mobileNotificationServiceComponent`
   - Protocol: direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Mbus publish failure | `ShipmentNotificationSendingException` thrown; logged as ERROR | Notification not delivered; no automatic retry from direct invocation path |
| Rocketman HTTP error | `WebApplicationException` thrown; logged | Email not sent for this event; `isEmailed` not updated; retry via Email Notification Job on next schedule |
| Push token not found | No token returned; mobile notification skipped | Push not delivered for this shipment/event |
| Event Delivery Service HTTP error | `IOException` thrown; logged | Push not delivered; no automatic retry from direct invocation path |
| Email already sent (`isEmailed` set) | Shipment skipped in `getShipmentsAwaitingEmail` query | No duplicate email |

## Sequence Diagram

```
ShipmentService -> ShipmentNotificationSenderService: sendNotifiableMessage(shipment)
ShipmentNotificationSenderService -> Mbus: write ShipmentMessage (goodsShipmentNotification)
ShipmentService -> EmailNotificationService: sendEmail(shipment)
EmailNotificationService -> RocketmanClient: POST <rocketman.url>/<sendEmailEndpoint>?client_id=<id>
RocketmanClient -> Rocketman: POST email payload
Rocketman --> RocketmanClient: HTTP 2xx
EmailNotificationService -> ShipmentDAO: updateEmailStatus(SENT)
ShipmentService -> MobileNotificationService: sendMobileNotification(shipment) [if SHIPPED/OFD/DELIVERED]
MobileNotificationService -> TokenServiceClient: GET token for consumerUuid
TokenServiceClient -> TokenService: fetch device token
TokenService --> TokenServiceClient: token
MobileNotificationService -> EventDeliveryServiceClient: POST /pns/v1.0/notification/EVENT/goods_shipment_<status>
EventDeliveryServiceClient -> EventDeliveryService: notification request
EventDeliveryService --> EventDeliveryServiceClient: HTTP 2xx
```

## Related

- Architecture dynamic view: `components-goodsShipmentService`
- Related flows: [Carrier Status Refresh](carrier-status-refresh.md), [Aftership Webhook Processing](aftership-webhook-processing.md)
