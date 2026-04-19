---
service: "seo-admin-ui"
title: "Crosslinks Analysis"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "crosslinks-analysis"
flow_type: synchronous
trigger: "Operator opens the crosslinks analysis view for a specific page"
participants:
  - "seoAdminUiItier"
  - "neo4jSeo"
  - "memcachedSeoAdminUi"
architecture_ref: "dynamic-seoAdminUiItier"
---

# Crosslinks Analysis

## Summary

The crosslinks analysis flow enables SEO engineers to explore the internal linking graph for Groupon pages. The admin UI queries the SEO Neo4j graph database to retrieve the crosslinks (directed internal links between pages) originating from or pointing to a given page URL. The results are rendered as an interactive graph visualization using D3 6.7.0, allowing operators to identify linking opportunities and gaps in the SEO site structure.

## Trigger

- **Type**: user-action
- **Source**: SEO engineer navigates to the crosslinks analysis screen and enters a page URL
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| SEO Admin UI | Receives operator query; queries Neo4j; renders D3 graph | `seoAdminUiItier` |
| Neo4j SEO Graph | Stores page nodes and directed crosslink relationships; serves graph traversal queries | `neo4jSeo` |
| Memcached | Caches Neo4j query results to reduce repeated graph traversal overhead | `memcachedSeoAdminUi` |

## Steps

1. **Operator enters page URL**: Operator navigates to the crosslinks analysis screen and inputs the target page URL.
   - From: `Operator browser`
   - To: `seoAdminUiItier`
   - Protocol: REST / HTTP (I-Tier session authenticated)

2. **Check cache**: seo-admin-ui checks Memcached for a cached crosslinks result for the given URL.
   - From: `seoAdminUiItier`
   - To: `memcachedSeoAdminUi`
   - Protocol: Memcached protocol

3. **Query Neo4j graph** (on cache miss): seo-admin-ui uses `@grpn/neo4j-seo` to run a Cypher graph traversal query for the target page, retrieving linked pages and their relationship types.
   - From: `seoAdminUiItier`
   - To: `neo4jSeo`
   - Protocol: Bolt (Neo4j binary protocol)

4. **Cache results**: seo-admin-ui stores the Neo4j query results in Memcached for subsequent requests.
   - From: `seoAdminUiItier`
   - To: `memcachedSeoAdminUi`
   - Protocol: Memcached protocol

5. **Render crosslinks graph**: seo-admin-ui serialises the graph data and renders an interactive D3 force-directed graph in the browser.
   - From: `seoAdminUiItier`
   - To: `Operator browser`
   - Protocol: HTTP / HTML + JSON (D3 graph data)

6. **Operator explores graph**: Operator clicks nodes and edges in the D3 visualization to drill into specific linking relationships.
   - From: `Operator browser`
   - To: `seoAdminUiItier` (additional queries as operator drills deeper)
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Neo4j unavailable | Log error; display error message | Crosslinks analysis unavailable; operator retries later |
| Neo4j query timeout | Log error; surface timeout message | Operator reduces scope (e.g., fewer hops) and retries |
| Page URL not in Neo4j | Return empty graph | Operator notified that no crosslinks data exists for the URL |
| Memcached unavailable | Skip cache; query Neo4j directly | Increased latency but correct results |

## Sequence Diagram

```
Operator -> seoAdminUiItier: Enter page URL for crosslinks analysis
seoAdminUiItier -> memcachedSeoAdminUi: Check cache for URL
memcachedSeoAdminUi --> seoAdminUiItier: Cache miss
seoAdminUiItier -> neo4jSeo: Cypher graph traversal query for page URL
neo4jSeo --> seoAdminUiItier: Page nodes + crosslink edges
seoAdminUiItier -> memcachedSeoAdminUi: Cache results
memcachedSeoAdminUi --> seoAdminUiItier: OK
seoAdminUiItier --> Operator: Render D3 crosslinks graph
Operator -> seoAdminUiItier: Click node to drill deeper
seoAdminUiItier -> neo4jSeo: Fetch sub-graph for selected node
neo4jSeo --> seoAdminUiItier: Sub-graph data
seoAdminUiItier --> Operator: Update D3 graph
```

## Related

- Architecture dynamic view: `dynamic-seoAdminUiItier`
- Related flows: [Page Route Auditing](page-route-auditing.md), [Landing Page Route CRUD](landing-page-route-crud.md)
