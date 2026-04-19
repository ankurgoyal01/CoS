---
service: "travel-search"
title: "MDS Hotel Update Flow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "mds-hotel-update"
flow_type: event-driven
trigger: "Hotel data change detected by hotelDetailsManager, or explicit MDS control API call"
participants:
  - "externalGetawaysClients_2f4a"
  - "travelSearch_apiResources"
  - "hotelDetailsManager"
  - "travelSearch_mbusPublisher"
  - "externalMessageBus_e5f6"
architecture_ref: "dynamic-hotelSearchFlow"
---

# MDS Hotel Update Flow

## Summary

This event-driven flow publishes MDS (Merchant Data Service) hotel update events to the internal Message Bus whenever hotel data changes within the service. Updates are triggered either automatically by `hotelDetailsManager` when a hotel detail merge produces changed data, or explicitly via the MDS control API endpoints. Downstream MDS consumers in the Continuum platform rely on these events to synchronise their hotel data.

## Trigger

- **Type**: event (internal change detection) or api-call (explicit trigger)
- **Source**: `hotelDetailsManager` (automatic, after hotel detail merge) or MDS control API (`POST /travel-search/v1/mds/hotels/{hotelId}/update`, `POST /travel-search/v1/mds/hotels/bulk-update`)
- **Frequency**: On hotel data change (per hotel detail retrieval that produces new data) or on-demand via API

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Getaways Clients (MDS control) | Optional — calls MDS control endpoints to trigger explicit updates | `externalGetawaysClients_2f4a` |
| REST Resources | Receives MDS control API requests | `travelSearch_apiResources` |
| Hotel Details Manager | Detects hotel data change; triggers MDS update | `hotelDetailsManager` |
| MBus Publisher | Publishes `MdsHotelUpdate` event to internal Message Bus | `travelSearch_mbusPublisher` |
| Message Bus (MBus) | Delivers hotel update event to downstream MDS consumers | `externalMessageBus_e5f6` |

## Steps

### Automatic path (data change detection)

1. **Detects hotel data change**: `hotelDetailsManager` completes a hotel detail merge and determines the merged data differs from the previously persisted record.
   - From: `hotelDetailsManager` (internal comparison)
   - Protocol: direct

2. **Triggers MDS update publication**: `hotelDetailsManager` invokes the MBus Publisher with the changed hotel data.
   - From: `hotelDetailsManager`
   - To: `travelSearch_mbusPublisher`
   - Protocol: direct (JMS)

3. **Publishes MdsHotelUpdate event**: MBus Publisher serialises the event and sends it to the internal Message Bus.
   - From: `travelSearch_mbusPublisher`
   - To: `externalMessageBus_e5f6`
   - Protocol: JMS / MBus

4. **Delivers event to downstream consumers**: Message Bus routes the `MdsHotelUpdate` event to registered downstream MDS consumers in the Continuum platform.
   - From: `externalMessageBus_e5f6`
   - To: Downstream MDS consumers
   - Protocol: JMS / MBus

### Explicit API path

1. **Receives MDS control request**: An operator or upstream service calls `POST /travel-search/v1/mds/hotels/{hotelId}/update` or the bulk-update endpoint.
   - From: `externalGetawaysClients_2f4a` (or internal operator)
   - To: `travelSearch_apiResources`
   - Protocol: REST (HTTP POST)

2. **Routes to Hotel Details Manager**: REST resource delegates the update trigger to `hotelDetailsManager`.
   - From: `travelSearch_apiResources`
   - To: `hotelDetailsManager`
   - Protocol: direct

3. **Triggers MDS update publication**: `hotelDetailsManager` invokes the MBus Publisher for the specified hotel(s).
   - From: `hotelDetailsManager`
   - To: `travelSearch_mbusPublisher`
   - Protocol: direct (JMS)

4. **Publishes MdsHotelUpdate event(s)**: MBus Publisher sends event(s) to the Message Bus.
   - From: `travelSearch_mbusPublisher`
   - To: `externalMessageBus_e5f6`
   - Protocol: JMS / MBus

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MBus broker unavailable | JMS exception logged; publish attempt may retry per JMS retry config | MDS downstream consumers do not receive the update; manual re-trigger via MDS control API required |
| JMS credentials expired | JMS connection failure; service alert raised | Publish blocked until credentials are refreshed |
| Bulk update partial failure | Each hotel update published independently; failures logged per hotel ID | Successful hotels updated; failed hotels require re-trigger |
| Downstream consumer failure | MBus responsibility — events queued for consumer retry | No impact on travel-search service itself |

## Sequence Diagram

```
hotelDetailsManager       -> travelSearch_mbusPublisher : Publish MDS update (change detected)
travelSearch_mbusPublisher -> externalMessageBus_e5f6   : MdsHotelUpdate event (JMS)
externalMessageBus_e5f6   -> DownstreamMdsConsumers     : Deliver hotel update event

--- OR (explicit API path) ---

GetawaysClients           -> travelSearch_apiResources  : POST /mds/hotels/{hotelId}/update
travelSearch_apiResources -> hotelDetailsManager        : Trigger MDS update
hotelDetailsManager       -> travelSearch_mbusPublisher : Publish MDS update
travelSearch_mbusPublisher -> externalMessageBus_e5f6   : MdsHotelUpdate event (JMS)
```

## Related

- Architecture dynamic view: `dynamic-hotelSearchFlow`
- Related flows: [Hotel Detail Retrieval Flow](hotel-detail-retrieval.md), [Background Inventory Sync Flow](background-inventory-sync.md)
