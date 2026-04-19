---
service: "place-service"
title: "Place Search"
generated: "2026-03-03"
type: flow
flow_name: "place-search"
flow_type: synchronous
trigger: "HTTP GET request to search or filter places"
participants:
  - "placeSvc_apiControllers"
  - "placeSvc_queryEngine"
  - "placeSvc_indexGateway"
  - "continuumPlacesServiceOpenSearch"
architecture_ref: "dynamic-place-read-flow"
---

# Place Search

## Summary

This flow handles multi-criteria place search and count requests. The query engine builds an OpenSearch query from the supplied filter parameters (name, location, geo-radius, status, brand, category, extended attributes, etc.) and executes it against the place index. Pagination, sorting, and field projection (`response_view`) are applied before returning the result array or count. This flow is available for NA via v2.0 endpoints and for both NA and EMEA via v3.0.

## Trigger

- **Type**: api-call
- **Source**: Any internal Groupon service with a registered `client_id`
- **Frequency**: On-demand (deal services, merchant tools, reporting); ~100 RPM for search, ~20k RPM for count per SLA documentation

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Controllers | Receives HTTP GET, validates parameters, delegates to query engine | `placeSvc_apiControllers` |
| Place Query Engine | Builds and executes OpenSearch queries from filter parameters | `placeSvc_queryEngine` |
| OpenSearch Gateway | Executes search/count queries against OpenSearch cluster | `placeSvc_indexGateway` |
| Place OpenSearch | Indexed place documents store | `continuumPlacesServiceOpenSearch` |

## Steps

1. **Receive search request**: HTTP GET arrives at `/v2.0/places/` (NA only) or `/v3.0/places` with `client_id` and filter parameters.
   - From: calling service
   - To: `placeSvc_apiControllers`
   - Protocol: REST/HTTP

2. **Validate and parse parameters**: API controller validates `client_id` and parses all query parameters (name, countries, postcodes, localities, lat/lng/radius, status, visibility, brand_ids, category_ids, service_ids, score_sources, extended_attribute_*, fuzziness, partial_match, sort_by, sort_direction, limit, offset, view_type, response_view).
   - From: `placeSvc_apiControllers`
   - To: `placeSvc_queryEngine`
   - Protocol: direct

3. **Build OpenSearch query**: Query engine constructs a structured OpenSearch query with filters, geo-distance filter if lat/lng/radius are provided, and aggregation for count. Applies fuzziness and partial match settings to the name filter.
   - From: `placeSvc_queryEngine` (PlaceQuery builder)
   - To: `placeSvc_indexGateway`
   - Protocol: direct

4. **Execute search against OpenSearch**: OpenSearch gateway sends the query to the cluster via the Elasticsearch REST High Level Client.
   - From: `placeSvc_indexGateway`
   - To: `continuumPlacesServiceOpenSearch`
   - Protocol: HTTPS

5. **Receive search results**: OpenSearch returns matching place documents (up to `limit`, starting at `offset`).
   - From: `continuumPlacesServiceOpenSearch`
   - To: `placeSvc_indexGateway` → `placeSvc_queryEngine`
   - Protocol: HTTPS/JSON

6. **Apply sort and field projection**: Query engine applies `sort_by` / `sort_direction` ordering and `response_view` field filtering (e.g., `deal`, `gdt`, `essence`).
   - From: `placeSvc_queryEngine`
   - To: `placeSvc_apiControllers`
   - Protocol: direct

7. **Return response**: API controller returns array of `OutputPlace` objects (search) or integer (count).
   - From: `placeSvc_apiControllers`
   - To: calling service
   - Protocol: HTTP/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| OpenSearch unavailable | Exception propagated from gateway | HTTP 500 returned to caller |
| Invalid `client_id` | Authorization check at controller | HTTP 403 Forbidden |
| No results matching filters | Empty array returned | HTTP 200 with empty array |
| Invalid lat/lng combination | Validation at controller | HTTP 400 or 403 depending on validation path |
| `limit` exceeds 1000 | Capped at max (1000) per API documentation | Result limited to 1000 entries |

## Sequence Diagram

```
Caller -> placeSvc_apiControllers: GET /v3.0/places?client_id=xxx&name=foo&countries=US&limit=25
placeSvc_apiControllers -> placeSvc_queryEngine: search(params)
placeSvc_queryEngine -> placeSvc_indexGateway: buildQuery(filters, geo, sort, pagination)
placeSvc_indexGateway -> continuumPlacesServiceOpenSearch: POST /_search (ES query DSL)
continuumPlacesServiceOpenSearch --> placeSvc_indexGateway: search hits (place documents)
placeSvc_indexGateway --> placeSvc_queryEngine: OutputPlace[]
placeSvc_queryEngine --> placeSvc_apiControllers: OutputPlace[] (sorted, projected)
placeSvc_apiControllers --> Caller: HTTP 200 (OutputPlace[] JSON)
```

## Related

- Architecture dynamic view: `dynamic-place-read-flow`
- Related flows: [Place Read by ID](place-read-by-id.md), [Place Write / Create](place-write.md)
