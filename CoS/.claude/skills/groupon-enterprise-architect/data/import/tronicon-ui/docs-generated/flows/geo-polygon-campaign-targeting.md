---
service: "tronicon-ui"
title: "Geo Polygon Campaign Targeting"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "geo-polygon-campaign-targeting"
flow_type: synchronous
trigger: "Operator creates or assigns a geographic boundary definition for campaign targeting in the Tronicon UI browser application"
participants:
  - "troniconUiWeb"
  - "troniconUi_webControllers"
  - "troniconUi_dataAccess"
  - "continuumTroniconUiDatabase"
  - "geoTaxonomyApi"
architecture_ref: "dynamic-troniconUi-geo-polygon-campaign-targeting"
---

# Geo Polygon Campaign Targeting

## Summary

This flow describes how Groupon campaign operators define geographic boundaries (geo-polygons) and associate them with campaigns for geo-targeted delivery. Operators use the `/cardatron/geo-polygons` endpoints to create and manage polygon definitions, which are persisted in `continuumTroniconUiDatabase`. Geo taxonomy reference data is retrieved from the Geo Taxonomy API (`geoTaxonomyApi`) to assist operators in constructing accurate geographic boundaries.

## Trigger

- **Type**: user-action
- **Source**: Operator accesses the geo-polygon management page at `GET /cardatron/geo-polygons` and submits a create or update form
- **Frequency**: On-demand, when a new geographic targeting area is needed or an existing boundary requires modification

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator (browser) | Defines geographic boundaries and assigns them to campaigns | — |
| Tronicon UI Web App | Routes requests and orchestrates geo data retrieval and persistence | `troniconUiWeb` |
| Web Controllers | Handles geo-polygon endpoint routing and input validation | `troniconUi_webControllers` |
| Data Access Layer | Reads and writes geo_polygon records | `troniconUi_dataAccess` |
| Tronicon UI Database | Persists geo polygon definitions | `continuumTroniconUiDatabase` |
| Geo Taxonomy API | Provides geographic taxonomy reference data to assist polygon definition | `geoTaxonomyApi` |

## Steps

1. **Lists existing geo-polygons**: Operator navigates to `GET /cardatron/geo-polygons`; controller retrieves existing polygon definitions from the database.
   - From: `Operator`
   - To: `troniconUi_webControllers`
   - Protocol: REST/HTTP (browser GET)

2. **Reads geo-polygons from database**: Data access layer executes SELECT query on `geo_polygons` table.
   - From: `troniconUi_dataAccess`
   - To: `continuumTroniconUiDatabase`
   - Protocol: SQL over TCP

3. **Fetches geo taxonomy reference data**: Controller calls Geo Taxonomy API to retrieve geographic taxonomy nodes (regions, cities, zones) that the operator can use as boundaries.
   - From: `troniconUiWeb`
   - To: `geoTaxonomyApi`
   - Protocol: REST/HTTP

4. **Returns taxonomy reference data**: Geo Taxonomy API responds with geographic taxonomy hierarchy; controller merges with polygon list and renders the management page.
   - From: `geoTaxonomyApi`
   - To: `troniconUiWeb`
   - Protocol: REST/HTTP

5. **Submits geo-polygon definition**: Operator defines the polygon — specifying name, region, and polygon coordinate data — and submits `POST /cardatron/geo-polygons`.
   - From: `Operator`
   - To: `troniconUi_webControllers`
   - Protocol: REST/HTTP (browser form POST)

6. **Validates polygon input**: Controller validates the submitted polygon data (required fields, coordinate format).
   - From: `troniconUi_webControllers`
   - To: `troniconUi_webControllers`
   - Protocol: direct (in-process)

7. **Persists geo-polygon**: Data access layer executes INSERT or UPDATE on the `geo_polygons` table.
   - From: `troniconUi_dataAccess`
   - To: `continuumTroniconUiDatabase`
   - Protocol: SQL over TCP

8. **Associates polygon with campaign**: Operator updates a campaign or deck to reference the saved geo-polygon, enabling geo-targeted delivery.
   - From: `Operator`
   - To: `troniconUi_webControllers`
   - Protocol: REST/HTTP (browser form POST to campaign/deck update endpoints)

9. **Writes campaign-polygon association**: Data access layer updates the relevant campaign or deck record with the geo-polygon reference.
   - From: `troniconUi_dataAccess`
   - To: `continuumTroniconUiDatabase`
   - Protocol: SQL over TCP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Geo Taxonomy API unavailable | HTTP error surfaced in UI; page loads without taxonomy reference data | Operator can still manually enter polygon coordinates but without taxonomy assistance |
| Invalid polygon coordinates submitted | Controller validation rejects submission | Operator sees validation error; polygon not persisted; operator must correct input |
| Database write fails | SQLAlchemy raises exception; controller returns HTTP 500 | Polygon not saved; operator must retry |

## Sequence Diagram

```
Operator -> troniconUiWeb: GET /cardatron/geo-polygons
troniconUiWeb -> continuumTroniconUiDatabase: SELECT geo_polygons
continuumTroniconUiDatabase --> troniconUiWeb: Polygon list
troniconUiWeb -> geoTaxonomyApi: GET /taxonomy/geo
geoTaxonomyApi --> troniconUiWeb: Geo taxonomy data
troniconUiWeb --> Operator: Geo-polygons management page

Operator -> troniconUiWeb: POST /cardatron/geo-polygons
troniconUiWeb -> troniconUiWeb: Validate polygon data
troniconUiWeb -> continuumTroniconUiDatabase: INSERT/UPDATE geo_polygon
continuumTroniconUiDatabase --> troniconUiWeb: OK
troniconUiWeb --> Operator: Geo-polygon saved

Operator -> troniconUiWeb: POST /cardatron/decks (assign polygon)
troniconUiWeb -> continuumTroniconUiDatabase: UPDATE deck SET geo_polygon_id=...
continuumTroniconUiDatabase --> troniconUiWeb: OK
troniconUiWeb --> Operator: Campaign targeting updated
```

## Related

- Architecture dynamic view: `dynamic-troniconUi-geo-polygon-campaign-targeting`
- Related flows: [Campaign Card Creation](campaign-card-creation.md)
- See [Integrations](../integrations.md) for Geo Taxonomy API (`geoTaxonomyApi`) details
- See [Data Stores](../data-stores.md) for `geo_polygons` entity context
