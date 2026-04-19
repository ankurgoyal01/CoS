---
service: "proximity-ui"
title: "Create Campaign (Deal-based)"
generated: "2026-03-03"
type: flow
flow_name: "create-campaign"
flow_type: synchronous
trigger: "Administrator submits the Create Campaign form"
participants:
  - "administrator"
  - "proximityWebUi"
  - "proximityApiRouter"
  - "proximityCampaignApiProxy"
  - "continuumProximityHotzoneApi"
architecture_ref: "components-continuumProximityUi"
---

# Create Campaign (Deal-based)

## Summary

The Create Campaign flow enables an EC-team administrator to configure a deal-based hotzone campaign. Unlike event-based hotzones, campaigns use an MDS query URL to automatically source deals matching configurable criteria (deal type, category, country, price threshold, purchase count, conversion rate). The administrator specifies the campaign's deal selection parameters, geographic radius, time windows, and audience targeting via a structured web form. The payload is POSTed through the Express proxy to the upstream Hotzone API's campaign endpoint.

## Trigger

- **Type**: user-action
- **Source**: Administrator submits the form on the `/campaign/create` Vue route (`src/views/CreateCampaign.vue`)
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Administrator | Fills in and submits the Create Campaign form | `administrator` |
| Web UI Router and Views | Renders the CreateCampaign form; validates and assembles the campaign payload; posts AJAX request | `proximityWebUi` |
| Proximity API Router | Routes `POST /api/proximity/campaigns` to the campaign proxy | `proximityApiRouter` |
| Campaign API Proxy | Forwards the create request to the upstream Hotzone API | `proximityCampaignApiProxy` |
| Continuum Proximity Hotzone API | Persists the campaign and returns the result | `continuumProximityHotzoneApi` |

## Steps

1. **Administrator fills in the Create Campaign form**: Administrator navigates to `/#/campaign/create` and enters campaign parameters: Client Id, Deal Type (HOTZONE or HOTZONE_CLO), Active, Limit (max hotzones), Query URL (MDS query), Category Id (UUID), Category Name, Country Code, Price Threshold (cents), Purchase Number, Conversion Rate, Radius, Deal Time Range, Audience Id, Audience Type (`bcookie` or `consumer_id`), Campaign Start date, Is Reverse flag, Use Open Hours flag, Override Time Window, and Override Radius.
   - From: `administrator`
   - To: `proximityWebUi` (browser form)
   - Protocol: User interaction

2. **Client-side validation**: The `bootstrap-validator` library validates required fields on form submission.
   - From: `proximityWebUi`
   - To: DOM form
   - Protocol: In-browser

3. **Duplicate detection**: The Vue component compares the current payload against `previousHotzoneCategoryCampaignObject` (in-memory). If identical, a `bootbox.confirm()` dialog asks the administrator to confirm.
   - From: `proximityWebUi`
   - To: `administrator`
   - Protocol: Browser dialog

4. **Payload assembly**: The Vue component builds the `hotzoneCategoryCampaign` object. Key mappings: `dealType` is submitted as the string name (HOTZONE/HOTZONE_CLO); `categoryId` maps to `cat`; `categoryName` maps to `customer_taxonomy`; `conversionRate` maps to `conversion`; `dealTimeRange` and `overrideTimeWindow` are serialized as JSON strings of `{ storeHours: { <1-7>: ["HH:MM-HH:MM", ...] } }`; `startDate` is timezone-converted to PT.
   - From: `proximityWebUi` (internal)
   - To: campaign payload object
   - Protocol: In-process

5. **AJAX POST to proxy**: The Vue component calls `Vue.http.post('/api/proximity/campaigns', JSON.stringify(hotzoneCategoryCampaign))`.
   - From: `proximityWebUi`
   - To: `proximityApiRouter`
   - Protocol: HTTP POST (JSON)

6. **Express routes to campaign proxy**: The `proximityApiRouter` routes `POST /api/proximity/campaigns` to `proximityCampaignApiProxy`.
   - From: `proximityApiRouter`
   - To: `proximityCampaignApiProxy`
   - Protocol: Internal Express dispatch

7. **Proxy forwards to Hotzone API**: The `proximityCampaignApiProxy` POSTs the request body to `continuumProximityHotzoneApi` at `POST /v1/proximity/location/hotzone/campaign?client_id=ec-team`.
   - From: `proximityCampaignApiProxy`
   - To: `continuumProximityHotzoneApi`
   - Protocol: HTTP POST (JSON)

8. **Hotzone API persists and responds**: The upstream API creates the campaign and returns a success or error response.
   - From: `continuumProximityHotzoneApi`
   - To: `proximityCampaignApiProxy` -> browser
   - Protocol: HTTP JSON

9. **UI displays result**: The Vue component shows a success (green), warning (if response body contains 'does not exist'), or failure (red) alert banner in the `#alerts` div.
   - From: `proximityWebUi`
   - To: `administrator`
   - Protocol: DOM

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Client-side validation fails | `bootstrap-validator` marks fields with `.has-error`; `submitForm` returns early | Form not submitted |
| Duplicate payload | `bootbox.confirm()` dialog; user can cancel | No request made if user cancels |
| Upstream API HTTP error | Error response status and body relayed verbatim; Vue rejection handler appends a red alert banner | Administrator sees failure message |

## Sequence Diagram

```
Administrator       -> ProximityWebUi: Submits Create Campaign form
ProximityWebUi      -> ProximityWebUi: Client-side validation (bootstrap-validator)
ProximityWebUi      -> Administrator: bootbox.confirm() (if duplicate detected)
Administrator       -> ProximityWebUi: Confirms submission
ProximityWebUi      -> ProximityWebUi: Assembles hotzoneCategoryCampaign payload
ProximityWebUi      -> ProximityApiRouter: POST /api/proximity/campaigns (JSON)
ProximityApiRouter  -> ProximityCampaignApiProxy: route
ProximityCampaignApiProxy -> continuumProximityHotzoneApi: POST /v1/proximity/location/hotzone/campaign?client_id=ec-team
continuumProximityHotzoneApi --> ProximityCampaignApiProxy: 200 OK or error
ProximityCampaignApiProxy --> ProximityWebUi: relayed response
ProximityWebUi      -> Administrator: Success / Warning / Failure alert banner
```

## Related

- Architecture dynamic view: `dynamic-proximity-create-hotzone-flow`
- Related flows: [Create Hotzone](create-hotzone.md), [Browse and Search Hotzones](browse-hotzones.md)
