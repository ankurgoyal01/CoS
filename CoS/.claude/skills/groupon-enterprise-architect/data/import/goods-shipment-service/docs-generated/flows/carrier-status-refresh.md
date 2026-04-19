---
service: "goods-shipment-service"
title: "Carrier Status Refresh"
generated: "2026-03-03"
type: flow
flow_name: "carrier-status-refresh"
flow_type: scheduled
trigger: "Quartz Shipment Refresh Job (schedule configured in Quartz/MySQL)"
participants:
  - "continuumGoodsShipmentService"
  - "continuumGoodsShipmentDatabase"
  - "upsApi"
  - "fedexApi"
  - "dhlApi"
  - "uspsApi"
  - "aitApi"
  - "upsmiApi"
  - "fedexspApi"
architecture_ref: "components-goodsShipmentService"
---

# Carrier Status Refresh

## Summary

The Shipment Refresh Job runs on a Quartz schedule and iterates all active shipments in the MySQL database. For each shipment, the Carrier Router resolves the appropriate carrier implementation and calls the carrier's tracking API to retrieve the latest status. The status is parsed, persisted, and if the new status is a notification state, downstream notifications are triggered. The admin endpoint `PUT /admin/shipments/refreshCarrier` and `PUT /admin/shipments/refreshShipments` can also trigger this flow on demand.

## Trigger

- **Type**: schedule (primary) or api-call (admin endpoint)
- **Source**: Quartz `ShipmentRefreshJob` fired on configured Cron expression stored in the MySQL Quartz tables; or `PUT /admin/shipments/refreshCarrier?carrier=<carrier>` / `PUT /admin/shipments/refreshShipments?shipmentUuids=<uuids>`
- **Frequency**: Per Quartz schedule (exact cron not visible in checked-in config; controlled by Quartz MySQL persistence)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Shipment Refresh Job | Schedules and initiates the refresh cycle | `shipmentRefreshJobComponent` |
| Carrier Refresh Service | Loads active shipments by carrier and dispatches refresh | `carrierRefreshServiceComponent` |
| Carrier Config DAO | Loads active carrier configurations per data centre | `carrierConfigDaoComponent` |
| Carrier Router | Resolves the concrete `Carrier` implementation for each carrier code | `carrierRouterComponent` |
| Carrier API Client (UPS / FedEx / DHL / USPS / AIT / UPSMI / FedEx SmartPost) | Calls the carrier tracking API | `upsApiClientComponent`, `fedexApiClientComponent`, `dhlApiClientComponent`, etc. |
| Shipment DAO | Reads active shipments and writes updated status/tracking data | `shipmentDaoComponent` |
| Shipment Service | Evaluates status transitions and triggers notifications | `shipmentServiceComponent` |
| Goods Shipment MySQL | Source and sink for shipment state | `continuumGoodsShipmentDatabase` |

## Steps

1. **Job fires**: Quartz fires `ShipmentRefreshJob` per schedule. Feature flag `featureFlags.shipmentRefreshJob` must be true.
   - From: Quartz scheduler
   - To: `shipmentRefreshJobComponent`
   - Protocol: internal

2. **Delegate to Carrier Refresh Service**: Job delegates to `carrierRefreshServiceComponent`.
   - From: `shipmentRefreshJobComponent`
   - To: `carrierRefreshServiceComponent`
   - Protocol: direct

3. **Load active carriers**: Carrier Refresh Service reads active carrier configurations for the current data centre from `carrierConfigDaoComponent`.
   - From: `carrierRefreshServiceComponent`
   - To: `carrierConfigDaoComponent` → `continuumGoodsShipmentDatabase`
   - Protocol: JDBC/MySQL

4. **Fetch active shipments (paged)**: For each carrier, reads active shipments in batches using `getActiveShipments` (filtered by carrier, date range, non-final status, batch size and `minId` for pagination).
   - From: `carrierRefreshServiceComponent`
   - To: `shipmentDaoComponent` → `continuumGoodsShipmentDatabase`
   - Protocol: JDBC/MySQL

5. **Resolve carrier implementation**: Carrier Router looks up the carrier-specific `Carrier` instance from the in-process `ConcurrentHashMap`.
   - From: `carrierRouterComponent`
   - To: Carrier-specific implementation (e.g., `UpsCarrier`, `FedexCarrier`, `DhlCarrier`)
   - Protocol: direct

6. **Call carrier tracking API**: Carrier implementation calls the carrier's tracking API using its Retrofit2 client. Request includes the tracking number; responses are carrier-specific models.
   - From: Carrier implementation (e.g., `upsApiClientComponent`)
   - To: External carrier API (`upsApi`, `fedexApi`, `dhlApi`, etc.)
   - Protocol: REST/HTTPS

7. **Parse carrier response**: Carrier-specific `StatusParser` maps the raw carrier events to internal `ShipmentStatus` and timestamps.
   - From: Carrier implementation
   - To: `shipmentDaoComponent`
   - Protocol: direct

8. **Persist updated tracking data**: `saveTrackingUpdates` and `saveStatusUpdates` write the new status, `rawStatus`, event history, and timestamps to MySQL.
   - From: `shipmentDaoComponent`
   - To: `continuumGoodsShipmentDatabase`
   - Protocol: JDBC/MySQL

9. **Trigger notifications**: If the new status is a notification state (SHIPPED, OUT_FOR_DELIVERY, DELIVERED, REJECTED, NOT_DELIVERED), Shipment Service invokes the notification pipeline — see [Shipment Notification Dispatch](shipment-notification-dispatch.md).
   - From: `shipmentServiceComponent`
   - To: `mobileNotificationServiceComponent`, `emailNotificationServiceComponent`, `shipmentNotificationSenderServiceComponent`
   - Protocol: direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Carrier API timeout | Bounded by `carrierApiMaxTimeout`; error logged with `Grapher=apiCountPerCarrier` | Shipment skipped; next shipment processed |
| Carrier not initialised | `LOGGER.error("Carrier not supported")` during CarrierRouter initialisation | Carrier excluded from refresh cycle |
| Database read/write error | Exception logged; job continues to next batch | Individual shipment update skipped |
| Feature flag disabled | Job does not execute | No refresh occurs; silent no-op |

## Sequence Diagram

```
QuartzScheduler -> ShipmentRefreshJob: fire (schedule)
ShipmentRefreshJob -> CarrierRefreshService: refresh()
CarrierRefreshService -> CarrierConfigDAO: getActiveCarriers(datacenter)
CarrierConfigDAO -> MySQL: SELECT carrier_config
MySQL --> CarrierConfigDAO: active carriers
CarrierRefreshService -> ShipmentDAO: getActiveShipments(carrier, dateRange, batchSize)
ShipmentDAO -> MySQL: SELECT shipments
MySQL --> ShipmentDAO: shipment batch
CarrierRefreshService -> CarrierRouter: getCarrier(carrierCode)
CarrierRouter --> CarrierRefreshService: Carrier instance
CarrierRefreshService -> CarrierAPI: getRawResults(shipment)
CarrierAPI --> CarrierRefreshService: tracking response
CarrierRefreshService -> ShipmentDAO: saveTrackingUpdates / saveStatusUpdates
ShipmentDAO -> MySQL: UPDATE shipment
CarrierRefreshService -> ShipmentService: trigger notifications if notification state
```

## Related

- Architecture dynamic view: `components-goodsShipmentService`
- Related flows: [Shipment Notification Dispatch](shipment-notification-dispatch.md), [Carrier OAuth Token Refresh](carrier-oauth-token-refresh.md)
