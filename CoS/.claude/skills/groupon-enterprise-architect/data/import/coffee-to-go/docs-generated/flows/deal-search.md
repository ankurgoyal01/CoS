---
service: "coffee-to-go"
title: "Deal Search Flow"
generated: "2026-03-03"
type: flow
flow_name: "deal-search"
flow_type: synchronous
trigger: "User pans/zooms map, changes filters, or enters search text"
participants:
  - "salesRep"
  - "coffeeWeb"
  - "coffeeApi"
  - "coffeeDb"
  - "googleMaps"
---

# Deal Search Flow

## Summary

A sales representative explores deals and merchant accounts by navigating the map or adjusting filters in the web application. The frontend sends a parameterized GET request to the API, which queries a PostgreSQL materialized view with spatial indexing. Results are returned with location data and rendered as map markers and list items.

## Trigger

- **Type**: user-action
- **Source**: Map pan/zoom, filter sidebar change, or search text input
- **Frequency**: On demand, per user interaction (debounced by TanStack Query)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Sales Representative | Initiates search by interacting with the map or filters | `salesRep` |
| React Web Application | Manages UI state, sends API requests, renders results on map and list | `coffeeWeb` |
| Express API | Validates parameters, queries database, returns paginated results | `coffeeApi` |
| Coffee DB | Serves deal data from the materialized view with spatial indexing | `coffeeDb` |
| Google Maps | Renders markers and map tiles in the browser | `googleMaps` |

## Steps

1. **User adjusts filters or map viewport**: The sales rep changes filter selections in the sidebar (category, vertical, stage, activity, priority, owner type, PDS, TG, competitors) or pans/zooms the map.
   - From: `salesRep`
   - To: `coffeeWeb` (State Store / Sidebar)
   - Protocol: User interaction

2. **Frontend constructs API request**: Zustand filter store triggers TanStack Query to fetch deals. The API Client sends a GET request to `/api/deals` with query parameters including lat, lon, radius, and all active filters.
   - From: `coffeeWeb` (Query Client / API Client)
   - To: `coffeeApi` (Deals Routes)
   - Protocol: HTTPS, JSON

3. **API validates and parses parameters**: The Deals Controller validates the request using the Zod `DealsQuerySchema`, transforming string parameters to typed values.
   - From: `coffeeApi` (Deals Routes)
   - To: `coffeeApi` (Deals Controller / Deals Service)
   - Protocol: Direct

4. **Service queries materialized view**: The Deals Service builds a Kysely query against the materialized view (`v_deals_cache` or `v_deals_cache_dev` based on feature flag). The query uses `ST_DWithin` for spatial filtering, `tsquery` for full-text search, and applies all filter predicates. Results are sorted (by distance, priority, or rating) and paginated.
   - From: `coffeeApi` (Deals Service / Database Access)
   - To: `coffeeDb` (mv_deals_cache_v6)
   - Protocol: PostgreSQL (read-only pool)

5. **API returns paginated results**: The API responds with an array of deal objects and pagination metadata (`has_more` flag).
   - From: `coffeeApi` (Deals Controller)
   - To: `coffeeWeb` (Query Client)
   - Protocol: HTTPS, JSON

6. **Frontend renders results**: TanStack Query caches the response. The Deals Map component renders markers on Google Maps. The Deals List renders a filterable list. The sidebar reflects active filter state.
   - From: `coffeeWeb` (Query Client / State Store)
   - To: `coffeeWeb` (Deals Map / Deals List)
   - Protocol: React state

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid query parameters | Zod schema validation returns 400 with field-level errors | User sees validation error |
| Authentication failure | Auth middleware returns 401 (`SESSION_NOT_FOUND`) | User is redirected to login |
| Rate limit exceeded | Rate limiter returns 429 (`RATE_LIMIT_EXCEEDED`) | User sees "too many requests" message |
| Database query failure | Service throws `DEALS_FETCH_ERROR`, global error handler returns 500 | User sees error state in UI |
| Invalid owner type | Service throws `INVALID_OWNER_TYPE` | 500 error logged, user sees error |

## Sequence Diagram

```
SalesRep -> CoffeeWeb: Adjusts filters/map
CoffeeWeb -> CoffeeApi: GET /api/deals?lat=...&lon=...&radius=...&filters...
CoffeeApi -> CoffeeApi: Validate params (Zod)
CoffeeApi -> CoffeeDb: SELECT ... FROM v_deals_cache WHERE ST_DWithin(...)
CoffeeDb --> CoffeeApi: Deal rows
CoffeeApi --> CoffeeWeb: { deals: [...], meta: { has_more } }
CoffeeWeb -> GoogleMaps: Render markers
CoffeeWeb --> SalesRep: Map + List view
```

## Related

- Related flows: [User Authentication](user-authentication.md), [Data Ingestion from CRM](data-ingestion-crm.md)
