---
service: "cs-groupon"
title: "Search and Filter Workflow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "search-and-filter-workflow"
flow_type: synchronous
trigger: "CS agent submits a search query in the cyclops Web App"
participants:
  - "continuumCsWebApp"
  - "continuumCsRedisCache"
  - "continuumCsAppDb"
architecture_ref: "dynamic-cs-groupon"
---

# Search and Filter Workflow

## Summary

cyclops integrates Elasticsearch to provide CS agents with fuzzy full-text search across CS records (users, orders, issues). When an agent submits a search query, the Web App forwards it to Elasticsearch, receives ranked results, and renders the filtered list for the agent to select from. For exact lookups, the Web App may also query `continuumCsAppDb` directly.

## Trigger

- **Type**: user-action
- **Source**: CS agent types a search query into the cyclops search interface
- **Frequency**: On demand (per search action)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| CS Web App | Accepts search query; routes to Elasticsearch or DB; renders results | `continuumCsWebApp` |
| CS Redis Cache | Caches recent search results to reduce repeated Elasticsearch queries | `continuumCsRedisCache` |
| CS App Database | Source of record for exact-match lookups and result hydration | `continuumCsAppDb` |

> Note: Elasticsearch is accessed directly by the Web App. It is not represented as a named container in the DSL model but is referenced in the inventory as a key library/data store.

## Steps

1. **Agent submits search query**: CS agent enters search term (user email, order ID, name, etc.) and submits the form.
   - From: `agent browser`
   - To: `continuumCsWebApp`
   - Protocol: HTTP GET (query parameter)

2. **Session validated**: Web App validates session before processing search.
   - From: `continuumCsWebApp`
   - To: `continuumCsRedisCache`
   - Protocol: Redis

3. **Check result cache**: Web App checks Redis for a cached result set for this query.
   - From: `continuumCsWebApp`
   - To: `continuumCsRedisCache`
   - Protocol: Redis GET

4. **Execute Elasticsearch query** (cache miss): Web App sends fuzzy search query to Elasticsearch.
   - From: `continuumCsWebApp`
   - To: Elasticsearch (HTTP)
   - Protocol: Elasticsearch REST API

5. **Receive ranked results**: Elasticsearch returns a ranked list of matching document IDs and scores.
   - From: Elasticsearch
   - To: `continuumCsWebApp`
   - Protocol: Elasticsearch REST API (JSON response)

6. **Hydrate results from DB**: Web App fetches full record details from `continuumCsAppDb` for the matched IDs.
   - From: `continuumCsWebApp`
   - To: `continuumCsAppDb`
   - Protocol: ActiveRecord / MySQL

7. **Cache results**: Web App writes the result set to Redis for future identical queries.
   - From: `continuumCsWebApp`
   - To: `continuumCsRedisCache`
   - Protocol: Redis SET with TTL

8. **Apply agent filters**: Agent applies additional filters (date range, status, type) to the result set client-side or via a refined query.
   - From: `agent browser`
   - To: `continuumCsWebApp`
   - Protocol: HTTP GET (filter parameters)

9. **Render filtered results**: Web App renders the filtered result list for the agent.
   - From: `continuumCsWebApp`
   - To: `agent browser`
   - Protocol: HTTP / HTML (server-rendered)

10. **Agent selects record**: Agent clicks a result to navigate to the full issue, order, or user record.
    - From: `agent browser`
    - To: `continuumCsWebApp`
    - Protocol: HTTP GET

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Elasticsearch unavailable | Web App falls back to direct DB query with LIKE matching | Degraded search quality; no fuzzy matching |
| Empty result set | Web App renders empty results with guidance | Agent informed no results found; prompted to refine query |
| Redis cache unavailable | Web App proceeds without caching | Elasticsearch queried on every search; higher latency |
| Query timeout | Elasticsearch returns timeout error | Web App shows error; agent prompted to retry |

## Sequence Diagram

```
Agent -> continuumCsWebApp: GET /search?q=<query>
continuumCsWebApp -> continuumCsRedisCache: Validate session
continuumCsWebApp -> continuumCsRedisCache: Check result cache
continuumCsWebApp -> Elasticsearch: POST fuzzy search query (cache miss)
Elasticsearch --> continuumCsWebApp: Ranked result IDs
continuumCsWebApp -> continuumCsAppDb: Fetch full records for matched IDs
continuumCsWebApp -> continuumCsRedisCache: Cache result set
continuumCsWebApp --> Agent: Render search results
Agent -> continuumCsWebApp: Apply filters
continuumCsWebApp --> Agent: Render filtered results
Agent -> continuumCsWebApp: Select record
```

## Related

- Architecture dynamic view: `dynamic-cs-groupon`
- Related flows: [Customer Issue Resolution](customer-issue-resolution.md), [Web UI Session Management](web-ui-session-management.md)
- Data stores detail: [Data Stores](../data-stores.md)
