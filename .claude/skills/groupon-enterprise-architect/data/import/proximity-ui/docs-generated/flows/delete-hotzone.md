---
service: "proximity-ui"
title: "Delete Hotzone"
generated: "2026-03-03"
type: flow
flow_name: "delete-hotzone"
flow_type: synchronous
trigger: "Administrator submits the Delete Hotzone form"
participants:
  - "administrator"
  - "proximityWebUi"
  - "proximityApiRouter"
  - "proximityHotzoneDealsApiProxy"
  - "continuumProximityHotzoneApi"
architecture_ref: "components-continuumProximityUi"
---

# Delete Hotzone

## Summary

The Delete Hotzone flow allows an EC-team administrator to permanently remove a proximity hotzone deal by its ID. The administrator enters a Client Id and the Hotzone ID in a simple form on the `/delete` route. The Vue component sends a DELETE request through the Express proxy to the upstream Hotzone API. The UI displays a dismissible alert banner reporting the outcome.

## Trigger

- **Type**: user-action
- **Source**: Administrator submits the form on the `/delete` Vue route (`src/views/Delete.vue`)
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Administrator | Provides the Client Id and Hotzone ID; clicks the Delete button | `administrator` |
| Web UI Router and Views | Renders the Delete form; extracts Hotzone ID; sends DELETE AJAX request | `proximityWebUi` |
| Proximity API Router | Routes `DELETE /api/proximity/hotzoneDeals/:hotzoneId` to the hotzone deals proxy | `proximityApiRouter` |
| Hotzone Deals API Proxy | Forwards the delete request to the upstream Hotzone API | `proximityHotzoneDealsApiProxy` |
| Continuum Proximity Hotzone API | Deletes the hotzone and returns a success or error response | `continuumProximityHotzoneApi` |

## Steps

1. **Administrator navigates to Delete view**: Administrator clicks the "Delete" navigation item and arrives at `/#/delete` (`src/views/Delete.vue`).
   - From: `administrator`
   - To: `proximityWebUi` (Vue Router)
   - Protocol: Browser navigation

2. **Administrator enters Hotzone ID**: Administrator types the Client Id (e.g., `ec-team`) and the Hotzone ID UUID into the two form fields and clicks the "Delete" button.
   - From: `administrator`
   - To: `proximityWebUi` (DOM form)
   - Protocol: User interaction

3. **Vue extracts Hotzone ID**: The `submitForm` method iterates over child components to find the one with `camelCase === 'hotzoneID'` and reads its `val`.
   - From: `proximityWebUi` (internal)
   - To: child component state
   - Protocol: In-process

4. **AJAX DELETE to proxy**: The Vue component calls `Vue.http.delete('/api/proximity/hotzoneDeals/' + hotZoneId)`.
   - From: `proximityWebUi`
   - To: `proximityApiRouter`
   - Protocol: HTTP DELETE

5. **Express routes to hotzone deals proxy**: The `proximityApiRouter` routes `DELETE /api/proximity/hotzoneDeals/:hotzoneId` to `proximityHotzoneDealsApiProxy`.
   - From: `proximityApiRouter`
   - To: `proximityHotzoneDealsApiProxy`
   - Protocol: Internal Express dispatch

6. **Proxy forwards delete to Hotzone API**: The `proximityHotzoneDealsApiProxy` sends a DELETE request to `continuumProximityHotzoneApi` at `DELETE /v1/proximity/location/hotzone/<hotzoneId>?client_id=ec-team`.
   - From: `proximityHotzoneDealsApiProxy`
   - To: `continuumProximityHotzoneApi`
   - Protocol: HTTP DELETE (JSON)

7. **Hotzone API deletes and responds**: The upstream API removes the hotzone and returns a success or error response body.
   - From: `continuumProximityHotzoneApi`
   - To: `proximityHotzoneDealsApiProxy` -> browser
   - Protocol: HTTP JSON

8. **UI displays result**: The Vue component shows a colored alert banner based on the response body:
   - Info (blue): success without 'does not exist' or 'failed' in body
   - Danger (red): 'failed' detected in success response
   - Warning (yellow): 'does not exist' in success response
   - Warning (yellow): HTTP error from the upstream
   - From: `proximityWebUi`
   - To: `administrator`
   - Protocol: DOM

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Hotzone ID does not exist | Upstream returns a body containing 'does not exist'; relayed to browser | Warning alert shown to administrator |
| Delete operation failed on upstream | Response body contains 'failed' | Danger alert shown |
| HTTP error from upstream | Vue rejection handler appends a warning alert | Warning alert with response body shown |

## Sequence Diagram

```
Administrator         -> ProximityWebUi: Submits Delete form (Client Id + Hotzone ID)
ProximityWebUi        -> ProximityWebUi: Extracts hotzoneID from child components
ProximityWebUi        -> ProximityApiRouter: DELETE /api/proximity/hotzoneDeals/:hotzoneId
ProximityApiRouter    -> ProximityHotzoneDealsApiProxy: route
ProximityHotzoneDealsApiProxy -> continuumProximityHotzoneApi: DELETE /v1/proximity/location/hotzone/<id>?client_id=ec-team
continuumProximityHotzoneApi --> ProximityHotzoneDealsApiProxy: 200 with result body or error
ProximityHotzoneDealsApiProxy --> ProximityWebUi: relayed response
ProximityWebUi        -> Administrator: Info / Warning / Danger alert banner
```

## Related

- Architecture dynamic view: `dynamic-proximity-create-hotzone-flow`
- Related flows: [Create Hotzone](create-hotzone.md), [Browse and Search Hotzones](browse-hotzones.md)
