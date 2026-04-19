---
service: "proximity-ui"
title: "Create Hotzone (Event-based)"
generated: "2026-03-03"
type: flow
flow_name: "create-hotzone"
flow_type: synchronous
trigger: "Administrator submits the Create Hotzone form"
participants:
  - "administrator"
  - "proximityWebUi"
  - "proximityApiRouter"
  - "proximityHotzoneDealsApiProxy"
  - "continuumProximityHotzoneApi"
architecture_ref: "dynamic-proximity-create-hotzone-flow"
---

# Create Hotzone (Event-based)

## Summary

The Create Hotzone flow allows an EC-team administrator to create one or more event-based proximity hotzones. The administrator fills in a web form with deal metadata, geo-coordinates, time ranges, audience targeting, and expiry. The Vue SPA validates the input, assembles a `hotZoneDeals` payload, and POSTs it to the Express proxy which forwards it to the upstream Hotzone API. Bulk creation from multiple lat/lng/radius lines is supported with a confirmation dialog. A duplicate-detection guard warns users if the payload matches the previous submission.

## Trigger

- **Type**: user-action
- **Source**: Administrator submits the form on the `/create` Vue route (`src/views/Create.vue`)
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Administrator | Fills in and submits the Create Hotzone form | `administrator` |
| Web UI Router and Views | Renders the Create form; validates and assembles the hotzone payload; posts AJAX request | `proximityWebUi` |
| Proximity API Router | Routes `POST /api/proximity/hotzoneDeals` to the hotzone deals proxy | `proximityApiRouter` |
| Hotzone Deals API Proxy | Forwards the create request to the upstream Hotzone API | `proximityHotzoneDealsApiProxy` |
| Continuum Proximity Hotzone API | Persists the hotzone deal(s) and returns the result | `continuumProximityHotzoneApi` |

## Steps

1. **Administrator fills in the Create form**: Administrator navigates to `/#/create` and enters deal metadata (Announcement Title, Deeplink, Image URI, Deal Type, Brand, Active, Uncapped), geo-coordinates (Latitude, Longitude, Radius or multi-location text), time ranges (Deal Time Range, Override Time Window), expiry date, Audience Id, and Audience Type.
   - From: `administrator`
   - To: `proximityWebUi` (browser DOM)
   - Protocol: User interaction

2. **Client-side validation**: The `bootstrap-validator` library validates required fields; custom validator checks multi-location textarea format (`lat, lng, radius` per line) and validates URL patterns for deeplink (`groupon:///` or `ls:///`) and image URI (`img.grouponcdn.com`).
   - From: `proximityWebUi`
   - To: DOM form
   - Protocol: In-browser

3. **Duplicate detection (single-location path)**: For single-location submissions, the Vue component compares the current payload against `previousHotzonesObject` (in-memory state). If identical (ignoring random UUIDs), a `bootbox.confirm()` dialog asks the administrator to confirm.
   - From: `proximityWebUi`
   - To: `administrator`
   - Protocol: Browser dialog

4. **Bulk confirmation (multi-location path)**: If the multi-location mode is selected, a `bootbox.confirm()` dialog shows the count of hotzones about to be created and asks for confirmation.
   - From: `proximityWebUi`
   - To: `administrator`
   - Protocol: Browser dialog

5. **Payload assembly**: The Vue component assembles the `hotZoneDeals` array. For each hotzone: a random UUID is generated for `id`, `merchantId`, and `categoryId`; `sendType` is hardcoded to `2` (push); `geoPoint`, `dealTimeRange` (storeHours keyed 1–7), `overrideTimeWindow`, and `expires` (converted to PT timezone via `moment-timezone`) are populated. Multi-location mode generates one hotzone object per location line, sharing `merchantId` and `categoryId`.
   - From: `proximityWebUi` (internal)
   - To: payload object
   - Protocol: In-process

6. **AJAX POST to proxy**: The Vue component calls `Vue.http.post('/api/proximity/hotzoneDeals', JSON.stringify(hotzones))`.
   - From: `proximityWebUi`
   - To: `proximityApiRouter`
   - Protocol: HTTP POST (JSON)

7. **Express routes to hotzone deals proxy**: The `proximityApiRouter` routes `POST /api/proximity/hotzoneDeals` to `proximityHotzoneDealsApiProxy`.
   - From: `proximityApiRouter`
   - To: `proximityHotzoneDealsApiProxy`
   - Protocol: Internal Express dispatch

8. **Proxy forwards to Hotzone API**: The `proximityHotzoneDealsApiProxy` POSTs the request body to `continuumProximityHotzoneApi` at `POST /v1/proximity/location/hotzone?client_id=ec-team` (the base URL with no path suffix appended).
   - From: `proximityHotzoneDealsApiProxy`
   - To: `continuumProximityHotzoneApi`
   - Protocol: HTTP POST (JSON)

9. **Hotzone API persists and responds**: The upstream API creates the hotzone deal(s) and returns a success or error response.
   - From: `continuumProximityHotzoneApi`
   - To: `proximityHotzoneDealsApiProxy` -> browser
   - Protocol: HTTP JSON

10. **UI displays result**: The Vue component shows a success (green), warning (if response body contains 'does not exist'), or failure (red) alert banner in the `#alerts` div.
    - From: `proximityWebUi`
    - To: `administrator`
    - Protocol: DOM

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Client-side validation fails | `bootstrap-validator` marks fields with `.has-error`; `submitForm` returns early | Form not submitted; user must correct fields |
| Duplicate payload (single-location) | `bootbox.confirm()` dialog; user can cancel | No request made if user cancels |
| Upstream API HTTP error | Error response status and body relayed verbatim; Vue promise rejection handler appends a red alert banner | Administrator sees failure message with instructions to check VPN/fields |
| Multi-location parse error | Custom textarea validator rejects malformed lines before submission | Form not submitted |

## Sequence Diagram

```
Administrator     -> ProximityWebUi: Submits Create Hotzone form
ProximityWebUi    -> ProximityWebUi: Client-side validation (bootstrap-validator)
ProximityWebUi    -> Administrator: bootbox.confirm() (duplicate check or bulk count)
Administrator     -> ProximityWebUi: Confirms submission
ProximityWebUi    -> ProximityWebUi: Assembles hotZoneDeals payload (UUIDs, geoPoint, storeHours, expires PT)
ProximityWebUi    -> ProximityApiRouter: POST /api/proximity/hotzoneDeals (JSON)
ProximityApiRouter -> ProximityHotzoneDealsApiProxy: route
ProximityHotzoneDealsApiProxy -> continuumProximityHotzoneApi: POST /v1/proximity/location/hotzone?client_id=ec-team
continuumProximityHotzoneApi --> ProximityHotzoneDealsApiProxy: 200 OK or error
ProximityHotzoneDealsApiProxy --> ProximityWebUi: relayed response
ProximityWebUi    -> Administrator: Success / Warning / Failure alert banner
```

## Related

- Architecture dynamic view: `dynamic-proximity-create-hotzone-flow`
- Related flows: [Browse and Search Hotzones](browse-hotzones.md), [Delete Hotzone](delete-hotzone.md), [Application Startup and Auth Gate](app-startup-auth-gate.md)
