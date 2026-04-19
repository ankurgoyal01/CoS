---
service: "goods-shipment-service"
title: "Aftership Tracking Registration"
generated: "2026-03-03"
type: flow
flow_name: "aftership-tracking-registration"
flow_type: scheduled
trigger: "Quartz Aftership Create Shipments Job"
participants:
  - "continuumGoodsShipmentService"
  - "continuumGoodsShipmentDatabase"
  - "aftershipApi"
architecture_ref: "components-goodsShipmentService"
---

# Aftership Tracking Registration

## Summary

The Aftership Create Shipments Job runs on a Quartz schedule and finds shipments in the database that have not yet been registered with the Aftership tracking platform (`SHIPMENT_NOT_CREATED` status or equivalent). For each unregistered shipment, it calls the Aftership API to create a tracking record, linking the shipment UUID as a custom field so that subsequent Aftership webhooks can be correlated back to the internal shipment record.

## Trigger

- **Type**: schedule
- **Source**: Quartz `AftershipCreateShipmentsJob`; feature flag `featureFlags.aftershipCreateShipmentJob` must be true
- **Frequency**: Per Quartz schedule (Cron stored in MySQL Quartz tables); retries shipments up to `aftership.retryForHours` hours (default 480h = 20 days) after initial reporting

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Aftership Create Shipments Job | Schedules and initiates the registration cycle | `aftershipCreateShipmentsJobComponent` |
| Aftership Create Shipment Service | Business logic — identifies and registers unregistered shipments | `aftershipCreateShipmentServiceComponent` |
| Shipment DAO | Reads shipments not yet registered with Aftership | `shipmentDaoComponent` |
| Aftership API Client | Calls Aftership API to create tracking registrations | `aftershipApiClientComponent` |
| Goods Shipment MySQL | Source of unregistered shipments; sink for updated registration status | `continuumGoodsShipmentDatabase` |
| Aftership Platform | Receives the shipment registration and begins passive tracking | `aftershipApi` |

## Steps

1. **Job fires**: Quartz fires `AftershipCreateShipmentsJob` per schedule. Feature flag `featureFlags.aftershipCreateShipmentJob` must be true.
   - From: Quartz scheduler
   - To: `aftershipCreateShipmentsJobComponent`
   - Protocol: internal

2. **Delegate to Aftership Create Shipment Service**: Job delegates to `aftershipCreateShipmentServiceComponent`.
   - From: `aftershipCreateShipmentsJobComponent`
   - To: `aftershipCreateShipmentServiceComponent`
   - Protocol: direct

3. **Fetch unregistered shipments (paged)**: Service queries MySQL for shipments where Aftership has not yet been notified, using `getNotCreatedAftershipShipmentIds` with `reportedOnAfter` cutoff (controlled by `aftership.retryForHours`) and batch pagination by `minId` and `batchSize` (default 500).
   - From: `aftershipCreateShipmentServiceComponent`
   - To: `shipmentDaoComponent` → `continuumGoodsShipmentDatabase`
   - Protocol: JDBC/MySQL

4. **Build create-tracking request**: For each shipment, constructs a `CreateTrackingRequest` with the `trackingNumber`, carrier slug, and a custom field containing the internal `shipment_uuid` (so that Aftership webhooks can be correlated).
   - From: `aftershipCreateShipmentServiceComponent`
   - To: `aftershipApiClientComponent`
   - Protocol: direct

5. **Call Aftership API**: Aftership API Client posts the tracking creation request to the Aftership API using the configured API key (`aftership.apiKey`) sent in the `as-api-key` header. Waits `aftership.waitBetweenRequestsMsec` (default 100ms) between requests.
   - From: `aftershipApiClientComponent`
   - To: `aftershipApi`
   - Protocol: REST/HTTPS

6. **Update registration status**: On success, Shipment DAO updates the shipment record in MySQL to indicate Aftership registration is complete (status updated from `SHIPMENT_NOT_CREATED` to `SHIPMENT_CREATED` or equivalent tracking field).
   - From: `aftershipCreateShipmentServiceComponent`
   - To: `shipmentDaoComponent` → `continuumGoodsShipmentDatabase`
   - Protocol: JDBC/MySQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Aftership API error | Logged; shipment skipped; retried on next job run | Shipment remains unregistered; retried until `retryForHours` window expires |
| Aftership API timeout | Bounded by `aftership.apiTimeoutSecs` (default 10s) | Shipment skipped for this run |
| Feature flag disabled | Job does not execute | No registrations created |
| Shipment already registered | Aftership may return conflict; logged; no update needed | Shipment state unchanged |

## Sequence Diagram

```
QuartzScheduler -> AftershipCreateShipmentsJob: fire (schedule)
AftershipCreateShipmentsJob -> AftershipCreateShipmentService: process()
AftershipCreateShipmentService -> ShipmentDAO: getNotCreatedAftershipShipmentIds(reportedOnAfter, batchSize, minId)
ShipmentDAO -> MySQL: SELECT shipments WHERE aftership_not_created
MySQL --> ShipmentDAO: shipment IDs
AftershipCreateShipmentService -> AftershipApiClient: POST create tracking (trackingNumber, slug, shipment_uuid custom field)
AftershipApiClient -> AftershipAPI: POST /trackings
AftershipAPI --> AftershipApiClient: 201 Created
AftershipCreateShipmentService -> ShipmentDAO: update registration status
ShipmentDAO -> MySQL: UPDATE shipment
```

## Related

- Architecture dynamic view: `components-goodsShipmentService`
- Related flows: [Aftership Webhook Processing](aftership-webhook-processing.md), [Shipment Creation](shipment-creation.md)
