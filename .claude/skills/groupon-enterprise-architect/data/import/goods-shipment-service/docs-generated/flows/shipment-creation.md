---
service: "goods-shipment-service"
title: "Shipment Creation"
generated: "2026-03-03"
type: flow
flow_name: "shipment-creation"
flow_type: synchronous
trigger: "POST /shipments from an upstream commerce or fulfilment system"
participants:
  - "continuumGoodsShipmentService"
  - "continuumGoodsShipmentDatabase"
architecture_ref: "components-goodsShipmentService"
---

# Shipment Creation

## Summary

When an upstream fulfilment system creates a new physical shipment, it submits a batch of shipment records to the Goods Shipment Service via `POST /shipments`. The service validates the payload, maps each record to a database entity, and persists all shipments in a single JDBI transaction. Up to 50 shipments may be created per request. On completion the service returns HTTP 200.

## Trigger

- **Type**: api-call
- **Source**: Internal Groupon fulfilment or commerce service calling `POST /shipments` with a `clientId` API key
- **Frequency**: On-demand, triggered when merchant ships physical goods

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Upstream fulfilment system | Initiates the request with shipment data | External to this service |
| Shipment Resource | Receives and validates the HTTP request | `shipmentResourceComponent` |
| Shipment Service | Core business logic — maps request to domain model | `shipmentServiceComponent` |
| Shipment DAO | Persists shipment records to MySQL | `shipmentDaoComponent` |
| Goods Shipment MySQL | Stores created shipment records | `continuumGoodsShipmentDatabase` |

## Steps

1. **Receive create request**: Upstream system sends `POST /shipments` with JSON body containing a `shipments` array (max 50 entries).
   - From: Upstream fulfilment system
   - To: `shipmentResourceComponent` (Shipment Resource)
   - Protocol: REST

2. **Validate payload**: Shipment Resource validates required fields — `channelCountry`, `createdOn`, `fulfillmentLineItemId`, `lineItemId`, `merchantDisplayName`, `orderId`, `orderLineItemUuid`, `quantity`, `shippingAddress`, `tracking` (including nested `carrier`, `shipmentUuid`, `trackingNumber`). Returns HTTP 400 if fields are missing; HTTP 413 if batch size exceeds 50.
   - From: `shipmentResourceComponent`
   - To: `shipmentServiceComponent`
   - Protocol: direct

3. **Map to domain model**: Shipment Service maps each `ShipmentCreateEntity` to a `Shipment` domain object, including shipping address, tracking data, and metadata.
   - From: `shipmentServiceComponent`
   - To: `shipmentDaoComponent`
   - Protocol: direct

4. **Persist shipments**: Shipment DAO executes `createShipments` within a JDBI `@Transaction`, inserting one row per shipment. Returns HTTP 409 on conflict (duplicate `shipmentUuid`).
   - From: `shipmentDaoComponent`
   - To: `continuumGoodsShipmentDatabase`
   - Protocol: JDBC/MySQL

5. **Return response**: HTTP 200 is returned to the caller on success. Initial status is `SHIPMENT_CREATED`.
   - From: `shipmentResourceComponent`
   - To: Upstream fulfilment system
   - Protocol: REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing required fields | Returns HTTP 400 Bad Request | Request rejected; no records written |
| Batch size exceeds 50 | Returns HTTP 413 Payload Too Large | Request rejected; no records written |
| Duplicate shipment UUID | Returns HTTP 409 Conflict | Request rejected; existing record unchanged |
| Database error | Returns HTTP 500 Internal Server Error | Shipments not persisted; caller must retry |

## Sequence Diagram

```
UpstreamSystem -> ShipmentResource: POST /shipments?clientId=<key> {shipments:[...]}
ShipmentResource -> ShipmentService: validate and map request
ShipmentService -> ShipmentDAO: createShipments (transactional)
ShipmentDAO -> MySQL: INSERT shipment rows
MySQL --> ShipmentDAO: generated IDs
ShipmentDAO --> ShipmentService: success
ShipmentService --> ShipmentResource: shipments created
ShipmentResource --> UpstreamSystem: HTTP 200
```

## Related

- Architecture dynamic view: `components-goodsShipmentService`
- Related flows: [Aftership Tracking Registration](aftership-tracking-registration.md), [Carrier Status Refresh](carrier-status-refresh.md)
