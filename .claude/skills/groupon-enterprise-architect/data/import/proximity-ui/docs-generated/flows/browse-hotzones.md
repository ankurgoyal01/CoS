---
service: "proximity-ui"
title: "Browse and Search Hotzones"
generated: "2026-03-03"
type: flow
flow_name: "browse-hotzones"
flow_type: synchronous
trigger: "Administrator opens the Summary view"
participants:
  - "administrator"
  - "proximityWebUi"
  - "proximityApiRouter"
  - "proximityHotzoneDealsApiProxy"
  - "continuumProximityHotzoneApi"
architecture_ref: "components-continuumProximityUi"
---

# Browse and Search Hotzones

## Summary

The Browse Hotzones flow presents a paginated, filterable, and exportable table of all existing proximity hotzones. When the administrator navigates to the Summary view, a DataTables component automatically fires a server-side POST request to the browse endpoint. Category filtering and column visibility controls are available. Administrators can click on a hotzone ID to navigate to the detail view for that hotzone.

## Trigger

- **Type**: user-action
- **Source**: Administrator navigates to `/#/summary` (renders `src/views/Summary.vue`)
- **Frequency**: On demand; also triggered when the category filter changes

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Administrator | Navigates to the Summary view; applies category filters; clicks hotzone links | `administrator` |
| Web UI Router and Views | Renders the Summary view; initializes DataTables with server-side config; fetches categories | `proximityWebUi` |
| Proximity API Router | Routes POST to `/api/proximity/hotzoneDeals/browse` and GET to `/api/proximity/categories` | `proximityApiRouter` |
| Hotzone Deals API Proxy | Forwards the browse request to the upstream Hotzone API | `proximityHotzoneDealsApiProxy` |
| Category API Proxy | Forwards the category list request to the upstream Hotzone API | `proximityCategoryApiProxy` |
| Continuum Proximity Hotzone API | Returns paginated hotzone results and category list | `continuumProximityHotzoneApi` |

## Steps

1. **Administrator navigates to Summary**: Administrator clicks the "Summary" navigation link or goes directly to `/#/summary`.
   - From: `administrator`
   - To: `proximityWebUi` (Vue Router)
   - Protocol: Browser navigation

2. **Vue fetches category list**: On component `ready()`, the Summary view calls `GET /api/proximity/categories` to populate the category filter dropdown.
   - From: `proximityWebUi`
   - To: `proximityApiRouter` -> `proximityCategoryApiProxy` -> `continuumProximityHotzoneApi` at `/v1/proximity/location/hotzone/categories?client_id=ec-team`
   - Protocol: HTTP GET (JSON)

3. **DataTables initializes**: The `#hotzonesTable` div is converted to a DataTables instance configured for server-side processing, with AJAX pointing to `POST /api/proximity/hotzoneDeals/browse`.
   - From: `proximityWebUi`
   - To: DOM
   - Protocol: In-browser

4. **DataTables fires initial browse request**: DataTables sends a `POST /api/proximity/hotzoneDeals/browse` with `{ client_id: "ec-team", category: "All", <dataTables draw params> }` as the JSON body.
   - From: `proximityWebUi`
   - To: `proximityApiRouter`
   - Protocol: HTTP POST (JSON, `contentType: application/json`)

5. **Express routes to hotzone deals proxy**: The `proximityApiRouter` routes `POST /api/proximity/hotzoneDeals/browse` to `proximityHotzoneDealsApiProxy`.
   - From: `proximityApiRouter`
   - To: `proximityHotzoneDealsApiProxy`
   - Protocol: Internal Express dispatch

6. **Proxy forwards to Hotzone API**: The `proximityHotzoneDealsApiProxy` POSTs the request body to `continuumProximityHotzoneApi` at `POST /v1/proximity/location/hotzone/browse?client_id=ec-team`.
   - From: `proximityHotzoneDealsApiProxy`
   - To: `continuumProximityHotzoneApi`
   - Protocol: HTTP POST (JSON)

7. **Hotzone API returns paginated results**: The API returns a DataTables-compatible JSON response with hotzone records including `hotZoneId`, `active`, `categoryName`, `announcementTitle`, `geoPoint`, `radius`, `price`, `value`, `dealType`, `brand`, `audienceId`, `expires`, `isTravel`, and `isUncapped`.
   - From: `continuumProximityHotzoneApi`
   - To: `proximityHotzoneDealsApiProxy` -> `proximityWebUi`
   - Protocol: HTTP JSON

8. **DataTables renders table**: The browser renders the paginated hotzone list. Each `hotZoneId` cell contains a link to `#!/summary/:hotzoneId` for drill-down. Expiry dates are formatted in PST via `moment-timezone`. Export buttons (CSV, PDF, Excel, Copy, Column Visibility) are available.
   - From: `proximityWebUi`
   - To: `administrator`
   - Protocol: DOM

9. **Administrator applies category filter (optional)**: Administrator selects a category from the dropdown. The Vue `watch` on `category` triggers DataTables `clear()` and `draw()`, which fires a new browse POST with the updated category value.
   - From: `administrator`
   - To: `proximityWebUi` -> repeat from step 4
   - Protocol: User interaction -> HTTP POST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Browse POST fails (upstream error) | DataTables error handling; upstream error status relayed | DataTables shows an error state in the table |
| Category fetch fails | No explicit error handler in `getCategories()`; categories dropdown may remain empty | Filter defaults to hardcoded list: Movie, Massage, Yoga, Spa, Concert, Festival, Restaurant, All |

## Sequence Diagram

```
Administrator     -> ProximityWebUi: Navigate to /#/summary
ProximityWebUi    -> ProximityApiRouter: GET /api/proximity/categories
ProximityApiRouter -> ProximityCategoryApiProxy: route
ProximityCategoryApiProxy -> continuumProximityHotzoneApi: GET /v1/proximity/location/hotzone/categories?client_id=ec-team
continuumProximityHotzoneApi --> ProximityCategoryApiProxy: { categories: [...] }
ProximityCategoryApiProxy --> ProximityWebUi: 200 { categories: [...] }
ProximityWebUi    -> ProximityWebUi: Initialize DataTables (#hotzonesTable)
ProximityWebUi    -> ProximityApiRouter: POST /api/proximity/hotzoneDeals/browse (DataTables params + category)
ProximityApiRouter -> ProximityHotzoneDealsApiProxy: route
ProximityHotzoneDealsApiProxy -> continuumProximityHotzoneApi: POST /v1/proximity/location/hotzone/browse?client_id=ec-team
continuumProximityHotzoneApi --> ProximityHotzoneDealsApiProxy: paginated hotzone data
ProximityHotzoneDealsApiProxy --> ProximityWebUi: 200 paginated data
ProximityWebUi    -> Administrator: Renders hotzone table with export buttons
Administrator     -> ProximityWebUi: (optional) Changes category filter
ProximityWebUi    -> ProximityApiRouter: POST /api/proximity/hotzoneDeals/browse (updated category)
```

## Related

- Architecture dynamic view: `dynamic-proximity-create-hotzone-flow`
- Related flows: [Create Hotzone](create-hotzone.md), [Delete Hotzone](delete-hotzone.md)
