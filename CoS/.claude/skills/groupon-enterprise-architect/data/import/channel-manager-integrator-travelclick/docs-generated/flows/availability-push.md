---
service: "channel-manager-integrator-travelclick"
title: "Availability Push from TravelClick"
generated: "2026-03-03"
type: flow
flow_name: "availability-push"
flow_type: synchronous
trigger: "POST request from TravelClick to /getaways/v2/partner/travelclick/CMService/pushAvailability"
participants:
  - "travelclickPlatform"
  - "continuumChannelManagerIntegratorTravelclick"
  - "cmiTc_apiControllers"
  - "cmiTc_inventoryClient"
  - "cmiTc_kafkaProducer"
  - "cmiTc_persistence"
  - "continuumChannelManagerIntegratorTravelclickMySql"
  - "kafkaCluster"
architecture_ref: "components-continuum-channel-manager-integrator-travelclick"
---

# Availability Push from TravelClick

## Summary

TravelClick proactively pushes hotel availability updates to this service when room availability or restrictions change. The service receives the OTA XML availability notification, validates it against the OTA schema and OVal constraints, fetches any required hotel product metadata from the Getaways Inventory service, persists the availability data to MySQL, and publishes an ARI event to Kafka for downstream Getaways services to consume.

## Trigger

- **Type**: api-call
- **Source**: TravelClick channel manager pushes HTTP POST to `/getaways/v2/partner/travelclick/CMService/pushAvailability`
- **Frequency**: On demand, triggered by TravelClick when availability changes at a hotel

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| TravelClick | Initiates availability push with OTA XML payload | `travelclickPlatform` |
| API Controllers | Receives and validates the inbound OTA availability request | `cmiTc_apiControllers` |
| Inventory Client | Fetches hotel hierarchy metadata if required | `cmiTc_inventoryClient` |
| Persistence Layer | Stores availability data to MySQL | `cmiTc_persistence` |
| MySQL | Durable storage for availability records | `continuumChannelManagerIntegratorTravelclickMySql` |
| Kafka Producer | Publishes ARI availability event to Kafka | `cmiTc_kafkaProducer` |
| Kafka | Delivers ARI event to downstream consumers | `kafkaCluster` |

## Steps

1. **Receive OTA availability notification**: TravelClick POSTs an `OTA_HotelAvailNotifRQ` XML body to the endpoint. The request includes hotel code, date range, restriction status (`OPEN`/`CLOSE`), restriction type (`MASTER`/`ARRIVAL`), and minimum length-of-stay constraints.
   - From: `travelclickPlatform`
   - To: `cmiTc_apiControllers`
   - Protocol: HTTPS / OTA XML (`application/xml`)

2. **Validate request**: The API controller validates the XML payload using OVal constraints (required fields: `availStatusMessages`, `statusApplicationControl`). Returns a 200 with OTA error response body if validation fails.
   - From: `cmiTc_apiControllers`
   - To: internal validation
   - Protocol: internal

3. **Fetch hotel product data**: If hotel hierarchy data is needed to enrich the availability record, the inventory client calls the Getaways Inventory service.
   - From: `cmiTc_apiControllers` -> `cmiTc_inventoryClient`
   - To: `getawaysInventoryService`
   - Protocol: HTTP/REST

4. **Persist availability data**: The persistence layer writes the availability update to MySQL.
   - From: `cmiTc_apiControllers` -> `cmiTc_persistence`
   - To: `continuumChannelManagerIntegratorTravelclickMySql`
   - Protocol: JDBI/JDBC

5. **Publish ARI availability event**: The Kafka producer publishes the availability payload to the ARI Kafka topic for downstream consumers.
   - From: `cmiTc_apiControllers` -> `cmiTc_kafkaProducer`
   - To: `kafkaCluster`
   - Protocol: Kafka

6. **Return OTA response**: The API controller returns an `OTA_HotelAvailNotifRS` XML response with `<Success/>` on success, or `<Errors>` on failure.
   - From: `cmiTc_apiControllers`
   - To: `travelclickPlatform`
   - Protocol: HTTPS / OTA XML

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| OTA XML validation failure | Return `OTA_HotelAvailNotifRS` with `<Errors>` element | TravelClick receives structured error; may retry |
| Getaways Inventory service unavailable | Request fails before persistence/Kafka publish | OTA error response returned to TravelClick |
| MySQL write failure | Processing halted | OTA error response returned; no Kafka event published |
| Kafka publish failure | ARI event not delivered to downstream consumers | Availability persisted in MySQL but downstream consumers not notified |

## Sequence Diagram

```
travelclickPlatform -> cmiTc_apiControllers: POST OTA_HotelAvailNotifRQ (XML)
cmiTc_apiControllers -> cmiTc_inventoryClient: Fetch hotel hierarchy data
cmiTc_inventoryClient -> getawaysInventoryService: GET hotel product info
getawaysInventoryService --> cmiTc_inventoryClient: Hotel product response
cmiTc_apiControllers -> cmiTc_persistence: Write availability record
cmiTc_persistence -> MySQL: INSERT/UPDATE availability
cmiTc_apiControllers -> cmiTc_kafkaProducer: Publish ARI availability event
cmiTc_kafkaProducer -> kafkaCluster: Kafka produce (ARI topic)
cmiTc_apiControllers --> travelclickPlatform: OTA_HotelAvailNotifRS (Success/Errors)
```

## Related

- Architecture component view: `components-continuum-channel-manager-integrator-travelclick`
- API surface: [API Surface](../api-surface.md)
- Related flows: [Inventory Push from TravelClick](inventory-push.md), [Rate Push from TravelClick](rate-push.md)
