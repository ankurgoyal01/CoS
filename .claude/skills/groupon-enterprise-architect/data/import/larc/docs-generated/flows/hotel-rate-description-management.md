---
service: "larc"
title: "Hotel and Rate Description Management"
generated: "2026-03-03"
type: flow
flow_name: "hotel-rate-description-management"
flow_type: synchronous
trigger: "HTTP API calls from eTorch or Getaways extranet app"
participants:
  - "continuumTravelLarcService"
  - "continuumTravelLarcDatabase"
architecture_ref: "components-larc-service"
---

# Hotel and Rate Description Management

## Summary

Before LARC can compute LARs for a deal, hotel records must be registered in the LARC database with their corresponding QL2 identifier, and the QL2 rate description names must be mapped to the correct Groupon room types. This flow covers the CRUD operations for hotel records and the management of rate description mappings — both performed synchronously via the LARC REST API by Getaways operations staff using eTorch or the extranet app.

## Trigger

- **Type**: api-call
- **Source**: eTorch or Getaways extranet app
- **Frequency**: On-demand — triggered when a new Getaways deal is set up, or when QL2 introduces new rate description names for an existing hotel

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| eTorch / Extranet App | Initiates hotel and rate description management requests | External operator tool |
| LARC API Resources | Exposes HotelResource and RateDescriptionResource endpoints | `continuumTravelLarcService` / `larcApiResources` |
| LARC Rate Computation | Coordinates hotel creation/update business logic | `continuumTravelLarcService` / `larcRateComputation` |
| LARC Persistence Layer | Reads and writes hotel and rate description records | `continuumTravelLarcService` / `larcDataAccess` |
| LARC Database | Stores hotel UUID-to-QL2-ID mappings and rate description mappings | `continuumTravelLarcDatabase` |

## Steps

### Hotel Registration

1. **Create hotel record**: Operator calls `POST /v2/getaways/larc/hotels` with a JSON body containing `ql2Id` (integer) and optionally `uuid`. `HotelResource` delegates to `HotelCreator`. The hotel UUID-to-QL2-ID mapping is persisted in the `Hotel` table.
   - From: External caller (eTorch/extranet)
   - To: `larcApiResources`
   - Protocol: HTTP/REST (POST JSON)

2. **Write hotel to database**: `HotelConnector` inserts the new hotel record via JDBI.
   - From: `larcDataAccess`
   - To: `continuumTravelLarcDatabase`
   - Protocol: JDBC/MySQL

3. **Return hotel response**: The created or updated hotel record is returned as JSON with `uuid` and `ql2Id`.
   - From: `larcApiResources`
   - To: External caller
   - Protocol: HTTP/REST (200 JSON)

### Rate Description Mapping

4. **Fetch rate descriptions**: `GET /v2/getaways/larc/hotels/{hotel_uuid}/rate_descriptions` — `RateDescriptionResource` calls `RateDescriptionsGetter` to retrieve all `RateDescription` records for the hotel from the database.
   - From: External caller
   - To: `larcApiResources` -> `larcDataAccess` -> `continuumTravelLarcDatabase`
   - Protocol: HTTP/REST then JDBC/MySQL

5. **Operator reviews unmapped descriptions**: The operator views the list of rate descriptions (status: `unassigned`, `ZERO_INDEX`, `hotelOnly`, `optedOut`) returned from QL2 ingestion. Descriptions with `unassigned` status need to be mapped to a `roomTypeUuid`.

6. **Update rate description mappings**: Operator calls `PUT /v2/getaways/larc/hotels/{hotel_uuid}/rate_descriptions` with the updated `RateDescriptions` list — setting `roomTypeUuid` and updating `status` to `assignedToRoom` (or `optedOut`/`hotelOnly` as appropriate).
   - From: External caller
   - To: `larcApiResources`
   - Protocol: HTTP/REST (PUT JSON)

7. **Persist mapping updates**: `RateDescriptionsUpdater` writes the updated `RateDescription` records via `HotelConnector`.
   - From: `larcDataAccess`
   - To: `continuumTravelLarcDatabase`
   - Protocol: JDBC/MySQL

8. **Return updated rate descriptions**: Updated `RateDescriptions` list is returned as JSON.
   - From: `larcApiResources`
   - To: External caller
   - Protocol: HTTP/REST (200 JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Hotel UUID not found | `LarcException` HTTP 404 | 404 returned to caller |
| Duplicate QL2 ID on hotel creation | Database unique constraint; `LarcException` raised | 409 or 500 returned; operator must use PUT to update existing hotel |
| Invalid rate description status value | Enum validation at deserialization | 400 Bad Request; valid statuses: ZERO_INDEX, hotelOnly, optedOut, unassigned, assignedToRoom |
| Unmapped rate descriptions remaining | No error raised | QL2 data for unmapped descriptions will not produce LAR values; Rocketman notification email may be sent to alert operators |

## Sequence Diagram

```
eTorch/Extranet -> LARC API: POST /v2/getaways/larc/hotels {ql2Id}
LARC API -> LARC Database: INSERT Hotel (uuid, ql2Id)
LARC Database --> LARC API: Hotel record
LARC API --> eTorch/Extranet: 200 {uuid, ql2Id}

eTorch/Extranet -> LARC API: GET /v2/getaways/larc/hotels/{hotel_uuid}/rate_descriptions
LARC API -> LARC Database: SELECT RateDescriptions WHERE hotel_uuid
LARC Database --> LARC API: RateDescription list (includes unassigned)
LARC API --> eTorch/Extranet: 200 {rateDescriptions[]}

eTorch/Extranet -> LARC API: PUT /v2/getaways/larc/hotels/{hotel_uuid}/rate_descriptions {rateDescriptions[{roomTypeUuid, status: assignedToRoom}]}
LARC API -> LARC Database: UPDATE RateDescription SET roomTypeUuid, status
LARC Database --> LARC API: Updated records
LARC API --> eTorch/Extranet: 200 {rateDescriptions[]}
```

## Related

- Architecture diagram: `components-larc-service`
- Related flows: [QL2 Feed Ingestion](ql2-feed-ingestion.md), [On-Demand LAR Send](on-demand-lar-send.md)
