---
service: "goods-stores-api"
title: "Search Query Execution"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "search-query-execution"
flow_type: synchronous
trigger: "API request — GET /v2/search/products or GET /v2/search/agreements"
participants:
  - "continuumGoodsStoresApi"
  - "continuumGoodsStoresApi_v2Api"
  - "continuumGoodsStoresApi_auth"
  - "continuumGoodsStoresApi_search"
  - "continuumGoodsStoresElasticsearch"
architecture_ref: "dynamic-goods-stores-search-query-execution"
---

# Search Query Execution

## Summary

This flow covers the execution of Elasticsearch-backed search queries for goods products and agreements via the v2 API. The `continuumGoodsStoresApi_search` component builds the appropriate Elasticsearch query from the request parameters, executes it against `continuumGoodsStoresElasticsearch`, serializes the results, and returns a paginated response to the caller.

## Trigger

- **Type**: api-call
- **Source**: GPAPI clients or merchant tooling — `GET /v2/search/products` or `GET /v2/search/agreements`
- **Frequency**: On-demand per search request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| V2 Goods Stores API | Receives search request; coordinates with Search component | `continuumGoodsStoresApi_v2Api` |
| Authorization & Token Helper | Validates token and role before search is executed | `continuumGoodsStoresApi_auth` |
| Search Query Builder | Builds Elasticsearch query from request params; serializes results | `continuumGoodsStoresApi_search` |
| Goods Stores Elasticsearch | Executes search query; returns matching documents | `continuumGoodsStoresElasticsearch` |

## Steps

1. **Receive Search Request**: Client sends `GET /v2/search/products` or `GET /v2/search/agreements` with query parameters (keywords, filters, pagination).
   - From: `GPAPI client / merchant tooling`
   - To: `continuumGoodsStoresApi_v2Api`
   - Protocol: REST/HTTP

2. **Validate Authorization**: Token and role checked.
   - From: `continuumGoodsStoresApi_v2Api`
   - To: `continuumGoodsStoresApi_auth`
   - Protocol: direct (in-process)

3. **Build Elasticsearch Query**: Search Query Builder translates request parameters into an Elasticsearch query DSL object, applying filters (status, merchant_id, category, etc.), full-text search terms, sorting, and pagination (from/size).
   - From: `continuumGoodsStoresApi_v2Api`
   - To: `continuumGoodsStoresApi_search`
   - Protocol: direct (in-process)

4. **Execute Search**: Search Query Builder sends the query to `continuumGoodsStoresElasticsearch` via the Elasticsearch client.
   - From: `continuumGoodsStoresApi_search`
   - To: `continuumGoodsStoresElasticsearch`
   - Protocol: Elasticsearch client (HTTP)

5. **Receive Search Results**: Elasticsearch returns matching documents with scores and pagination metadata.
   - From: `continuumGoodsStoresElasticsearch`
   - To: `continuumGoodsStoresApi_search`
   - Protocol: Elasticsearch client (HTTP)

6. **Serialize Results**: Search Query Builder maps Elasticsearch hit documents to API response serializer format.
   - From: `continuumGoodsStoresApi_search`
   - To: in-process
   - Protocol: direct

7. **Return Paginated Response**: API returns JSON response with result array and pagination metadata to the caller.
   - From: `continuumGoodsStoresApi_v2Api`
   - To: `GPAPI client`
   - Protocol: REST/HTTP (JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Authorization failure | Request rejected | HTTP 401/403; no search executed |
| Invalid query parameters | Grape validation returns 422 | HTTP 422 with parameter errors |
| Elasticsearch unavailable | Elasticsearch client raises connection error | HTTP 500; search endpoint unavailable; CRUD operations unaffected |
| Empty result set | Normal response with empty array | HTTP 200 with empty results and pagination metadata |
| Elasticsearch query timeout | Client raises timeout error | HTTP 500 or 503; caller should retry |

## Sequence Diagram

```
GPAPI Client -> continuumGoodsStoresApi_v2Api: GET /v2/search/products?q=...&page=1
continuumGoodsStoresApi_v2Api -> continuumGoodsStoresApi_auth: Validate token and role
continuumGoodsStoresApi_auth --> continuumGoodsStoresApi_v2Api: Authorized
continuumGoodsStoresApi_v2Api -> continuumGoodsStoresApi_search: Build Elasticsearch query
continuumGoodsStoresApi_search -> continuumGoodsStoresElasticsearch: Execute search query (HTTP)
continuumGoodsStoresElasticsearch --> continuumGoodsStoresApi_search: Matching documents + pagination metadata
continuumGoodsStoresApi_search -> continuumGoodsStoresApi_search: Serialize results
continuumGoodsStoresApi_v2Api --> GPAPI Client: 200 paginated search results (JSON)
```

## Related

- Architecture dynamic view: `dynamic-goods-stores-search-query-execution`
- Related flows: [Elasticsearch Indexing](elasticsearch-indexing.md), [Authorization Token Validation](authorization-token-validation.md)
