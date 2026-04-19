---
service: "travel-search"
title: "Background Inventory Sync Flow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "background-inventory-sync"
flow_type: scheduled
trigger: "Periodic scheduled job"
participants:
  - "travelSearch_backgroundJobs"
  - "travelSearch_externalClients"
  - "travelSearch_persistenceLayer"
  - "externalInventoryService_5d2a"
  - "externalContentService_3b91"
  - "externalGoogleHotels_b2c3"
  - "continuumTravelSearchDb"
architecture_ref: "dynamic-hotelSearchFlow"
---

# Background Inventory Sync Flow

## Summary

This scheduled flow runs periodically to keep the service's internal hotel inventory and content data fresh. The `travelSearch_backgroundJobs` component calls external inventory and content providers to retrieve the latest hotel data, writes updated entities to MySQL, and uploads OTA inventory and rate feeds to Google Hotels. This flow ensures the synchronous search and detail paths serve current data without every request needing to hit external APIs.

## Trigger

- **Type**: schedule
- **Source**: Internal job scheduler within `travelSearch_backgroundJobs`
- **Frequency**: Periodic (schedule interval configured in `application.properties` — verify exact cron in source code)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Background Jobs | Scheduler that initiates and orchestrates sync tasks | `travelSearch_backgroundJobs` |
| External Service Clients | Issues outbound HTTP calls to inventory, content, and Google Hotels | `travelSearch_externalClients` |
| Inventory Service | Provides updated availability summaries and OTA inventory data | `externalInventoryService_5d2a` |
| Content Service | Provides refreshed hotel content attributes | `externalContentService_3b91` |
| Google Hotels | Receives OTA inventory and rate feed uploads | `externalGoogleHotels_b2c3` |
| Persistence Layer | Writes updated hotel entities to MySQL | `travelSearch_persistenceLayer` |
| Travel Search MySQL | Durable store for synced hotel entities | `continuumTravelSearchDb` |

## Steps

1. **Job scheduler fires**: The internal scheduler triggers the inventory sync task at the configured interval.
   - From: `travelSearch_backgroundJobs` (scheduler)
   - Protocol: direct

2. **Fetches updated inventory data**: Calls the Inventory Service to retrieve current availability summaries and OTA-level inventory updates for the hotel portfolio.
   - From: `travelSearch_externalClients`
   - To: `externalInventoryService_5d2a`
   - Protocol: REST

3. **Fetches updated hotel content**: Calls the Content Service to retrieve refreshed content attributes (descriptions, amenities, images) for hotels that have updates.
   - From: `travelSearch_externalClients`
   - To: `externalContentService_3b91`
   - Protocol: REST

4. **Writes updated inventory entities to MySQL**: Persists the refreshed inventory and availability data to `continuumTravelSearchDb`.
   - From: `travelSearch_backgroundJobs`
   - To: `travelSearch_persistenceLayer`
   - Protocol: direct (Ebean)

5. **Writes updated content entities to MySQL**: Persists the refreshed hotel content data to `continuumTravelSearchDb`.
   - From: `travelSearch_backgroundJobs`
   - To: `travelSearch_persistenceLayer`
   - Protocol: direct (Ebean)

6. **Uploads OTA feed to Google Hotels**: Compiles the current inventory and rate data into an OTA feed and uploads it to Google Hotels.
   - From: `travelSearch_externalClients`
   - To: `externalGoogleHotels_b2c3`
   - Protocol: REST / OTA feed

7. **Records sync completion**: Job scheduler marks the sync cycle as complete and schedules the next run.
   - From: `travelSearch_backgroundJobs` (internal)
   - Protocol: direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Inventory Service unavailable | Log error; skip inventory sync cycle | Inventory data becomes stale until next successful sync |
| Content Service unavailable | Log error; skip content sync cycle | Content data becomes stale until next successful sync |
| MySQL write failure | Log error; retry or skip affected entities | Partial sync; some entities may remain stale |
| Google Hotels upload failure | Log error; retry at next sync cycle | OTA feed not updated; Google Hotels data may be stale |
| Job scheduler failure | Platform-level alert | All sync cycles paused until scheduler recovers |

## Sequence Diagram

```
travelSearch_backgroundJobs -> travelSearch_externalClients    : Sync inventory and content
travelSearch_externalClients -> externalInventoryService_5d2a  : Fetch updated inventory
travelSearch_externalClients -> externalContentService_3b91    : Fetch updated content
travelSearch_backgroundJobs -> travelSearch_persistenceLayer   : Write updated inventory entities
travelSearch_persistenceLayer -> continuumTravelSearchDb       : Upsert inventory records
travelSearch_backgroundJobs -> travelSearch_persistenceLayer   : Write updated content entities
travelSearch_persistenceLayer -> continuumTravelSearchDb       : Upsert content records
travelSearch_externalClients -> externalGoogleHotels_b2c3      : Upload OTA inventory and rate feed
```

## Related

- Architecture dynamic view: `dynamic-hotelSearchFlow`
- Related flows: [EAN Price Update Flow](ean-price-update.md), [Hotel Detail Retrieval Flow](hotel-detail-retrieval.md)
