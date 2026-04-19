---
service: "mobile-flutter-merchant"
title: "Location and Place Management"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "location-and-place-management"
flow_type: synchronous
trigger: "Merchant navigates to the places screen"
participants:
  - "continuumMobileFlutterMerchantApp"
  - "mmaPresentationLayer"
  - "mmaApiOrchestrator"
  - "continuumM3PlacesService"
  - "googleMaps"
architecture_ref: "dynamic-location-and-place-management"
---

# Location and Place Management

## Summary

The Location and Place Management flow allows a Groupon merchant to view and update their registered business locations. The `mmaApiOrchestrator` fetches place data from `continuumM3PlacesService` and the `mmaPresentationLayer` renders location details with an embedded Google Maps view using the `google_maps_flutter` plugin. Merchants can also submit updates to location attributes (hours, address, contact details) through the same API.

## Trigger

- **Type**: user-action
- **Source**: Merchant navigates to the places/locations section of the app
- **Frequency**: On-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Presentation Layer | Renders places list, map view, and location detail/edit screens | `mmaPresentationLayer` |
| API Orchestrator | Fetches and submits place data to M3 Places Service | `mmaApiOrchestrator` |
| M3 Places Service | Provides and accepts merchant place/location records | `continuumM3PlacesService` |
| Google Maps | Renders interactive map tiles for location visualisation | `googleMaps` |

## Steps

1. **Navigate to Places Screen**: Merchant taps the places icon; `mmaPresentationLayer` dispatches a load action for the merchant's locations.
   - From: Merchant (user action)
   - To: `mmaPresentationLayer`
   - Protocol: Direct

2. **Fetch Place List**: `mmaApiOrchestrator` calls `continuumM3PlacesService` to retrieve all registered merchant locations.
   - From: `mmaApiOrchestrator`
   - To: `continuumM3PlacesService`
   - Protocol: REST/HTTP

3. **Receive Place Data**: `continuumM3PlacesService` returns location records with names, addresses, coordinates, and operational attributes.
   - From: `continuumM3PlacesService`
   - To: `mmaApiOrchestrator`
   - Protocol: REST/HTTP

4. **Render Places List**: `mmaPresentationLayer` renders the list of merchant locations with names and abbreviated addresses.
   - From: `mmaPresentationLayer`
   - To: Merchant (UI)
   - Protocol: Direct

5. **Open Place Detail with Map**: Merchant taps a location; `mmaPresentationLayer` renders a detail view with an embedded Google Maps widget centred on the location's coordinates.
   - From: `mmaPresentationLayer`
   - To: `googleMaps` (SDK embed)
   - Protocol: SDK

6. **Google Maps Renders Tiles**: The `google_maps_flutter` plugin fetches and displays map tiles for the location's latitude/longitude.
   - From: `googleMaps` SDK
   - To: Google Maps tile servers (external)
   - Protocol: HTTPS (SDK-managed)

7. **Merchant Edits Location**: Merchant taps "Edit" to update location hours, address, or contact information; `mmaPresentationLayer` shows the edit form.
   - From: Merchant (user action)
   - To: `mmaPresentationLayer`
   - Protocol: Direct

8. **Submit Location Update**: Merchant saves changes; `mmaApiOrchestrator` sends the update to `continuumM3PlacesService`.
   - From: `mmaApiOrchestrator`
   - To: `continuumM3PlacesService`
   - Protocol: REST/HTTP

9. **Confirm Update**: `continuumM3PlacesService` confirms the update; `mmaPresentationLayer` refreshes the location detail and shows a success indicator.
   - From: `continuumM3PlacesService`
   - To: `mmaApiOrchestrator` → `mmaPresentationLayer`
   - Protocol: REST/HTTP → Direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| M3 Places Service unavailable | HTTP error in `mmaApiOrchestrator` | Empty places list with error message; edit not possible |
| Google Maps SDK fails to load tiles | SDK error (network or API key issue) | Map renders blank; location details still shown as text |
| Location update rejected by M3 Places Service | API returns validation error | Edit form shows specific error message; no update applied |
| Network failure during update submission | HTTP timeout in `mmaApiOrchestrator` | Submission failure shown; merchant prompted to retry |

## Sequence Diagram

```
Merchant -> mmaPresentationLayer: Opens Places screen
mmaPresentationLayer -> mmaApiOrchestrator: fetchPlaces()
mmaApiOrchestrator -> continuumM3PlacesService: GET /merchant/places
continuumM3PlacesService --> mmaApiOrchestrator: Place list (name, address, coordinates)
mmaApiOrchestrator --> mmaPresentationLayer: Place list
mmaPresentationLayer -> Merchant: Render places list
Merchant -> mmaPresentationLayer: Taps a location
mmaPresentationLayer -> googleMaps: Render map widget (lat/lng)
googleMaps -> GoogleMapsTileServers: Fetch map tiles
GoogleMapsTileServers --> googleMaps: Map tiles
mmaPresentationLayer -> Merchant: Render location detail + map
Merchant -> mmaPresentationLayer: Taps Edit, updates fields, taps Save
mmaPresentationLayer -> mmaApiOrchestrator: updatePlace(placeId, attributes)
mmaApiOrchestrator -> continuumM3PlacesService: PUT /merchant/places/{id}
continuumM3PlacesService --> mmaApiOrchestrator: Update confirmed
mmaApiOrchestrator --> mmaPresentationLayer: Success
mmaPresentationLayer -> Merchant: Show updated location detail
```

## Related

- Architecture dynamic view: `dynamic-location-and-place-management`
- Related flows: [Offline and Sync Workflow](offline-and-sync-workflow.md), [Deal Creation and Publishing](deal-creation-and-publishing.md)
