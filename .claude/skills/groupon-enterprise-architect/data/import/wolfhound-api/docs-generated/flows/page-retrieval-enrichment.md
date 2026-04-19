---
service: "wolfhound-api"
title: "Page Retrieval and Enrichment Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "page-retrieval-enrichment"
flow_type: synchronous
trigger: "API call to GET /wh/v2/pages/{id}, GET /wh/v3/pages/{id}, or GET /wh/v2/mobile"
participants:
  - "wolfApi_apiResources"
  - "orchestrationServices"
  - "wolfhoundApi_persistenceDaos"
  - "externalGatewayClients"
  - "cacheAndBootstraps"
  - "continuumWolfhoundPostgres"
  - "continuumRelevanceApi"
  - "continuumDealsClusterService"
  - "continuumConsumerAuthorityService"
  - "continuumExpyService"
architecture_ref: "dynamic-wolfhound-page-publish-flow"
---

# Page Retrieval and Enrichment Flow

## Summary

The Page Retrieval and Enrichment Flow handles incoming read requests for SEO page content. It first attempts to serve from the in-memory published page cache. If a cache miss occurs or a full enrichment is requested, the flow fetches the base page record from Wolfhound Postgres, then fans out to multiple external dependencies — Relevance API for cards and facets, Deals Cluster for cluster navigation, Consumer Authority for audience targeting attributes, and Expy for experiment variant resolution — before assembling and returning the enriched page payload to the caller. The `/wh/v2/mobile` endpoint follows this same pattern with a mobile-optimised payload shape.

## Trigger

- **Type**: api-call
- **Source**: `GET /wh/v2/pages/{id}`, `GET /wh/v3/pages/{id}`, or `GET /wh/v2/mobile`
- **Frequency**: Per request — on demand for each page load or content management read

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Resources Layer | Receives and routes the read request | `wolfApi_apiResources` |
| Domain Services Layer | Orchestrates retrieval and enrichment logic | `orchestrationServices` |
| Persistence Layer | Reads page records from database on cache miss | `wolfhoundApi_persistenceDaos` |
| External Gateway Clients | Calls enrichment services in parallel | `externalGatewayClients` |
| Cache and Bootstrapping | Serves published page state from in-memory cache | `cacheAndBootstraps` |
| Wolfhound Postgres | Persistent source of page records | `continuumWolfhoundPostgres` |
| Relevance API | Provides cards and facets for mobile/deal components | `continuumRelevanceApi` |
| Deals Cluster Service | Provides cluster navigation and top-cluster content | `continuumDealsClusterService` |
| Consumer Authority Service | Provides audience membership and targeting attributes | `continuumConsumerAuthorityService` |
| Expy Service | Resolves experiment variants for the request context | `continuumExpyService` |

## Steps

1. **Receive retrieval request**: API Resources Layer receives the `GET` request and extracts page ID and context parameters.
   - From: caller
   - To: `wolfApi_apiResources`
   - Protocol: REST/HTTP

2. **Invoke retrieval use case**: API Resources Layer delegates to Domain Services Layer to orchestrate the retrieval.
   - From: `wolfApi_apiResources`
   - To: `orchestrationServices`
   - Protocol: Direct (in-process)

3. **Check in-memory cache**: Domain Services Layer checks Cache and Bootstrapping for a cached published page entry.
   - From: `orchestrationServices`
   - To: `cacheAndBootstraps`
   - Protocol: Direct (in-process)

4. **Fetch from database (cache miss)**: On cache miss, Domain Services Layer requests the page record from Persistence Layer.
   - From: `orchestrationServices`
   - To: `wolfhoundApi_persistenceDaos`
   - Protocol: Direct (in-process)

5. **Query Wolfhound Postgres**: Persistence Layer executes a JDBI query to retrieve the page record.
   - From: `wolfhoundApi_persistenceDaos`
   - To: `continuumWolfhoundPostgres`
   - Protocol: JDBI/JDBC

6. **Fetch enrichment data — Relevance API**: Domain Services Layer calls External Gateway Clients to retrieve cards and facets.
   - From: `orchestrationServices`
   - To: `externalGatewayClients`
   - Protocol: Direct (in-process)

7. **Query Relevance API**: External Gateway Clients calls Relevance API for card and facet data.
   - From: `externalGatewayClients`
   - To: `continuumRelevanceApi`
   - Protocol: HTTP

8. **Fetch enrichment data — Deals Cluster**: External Gateway Clients fetches cluster navigation content.
   - From: `externalGatewayClients`
   - To: `continuumDealsClusterService`
   - Protocol: HTTP

9. **Fetch enrichment data — Consumer Authority**: External Gateway Clients fetches audience membership and targeting attributes.
   - From: `externalGatewayClients`
   - To: `continuumConsumerAuthorityService`
   - Protocol: HTTP

10. **Evaluate experiments**: External Gateway Clients calls Expy Service to resolve active experiment variants for the request context.
    - From: `externalGatewayClients`
    - To: `continuumExpyService`
    - Protocol: HTTP

11. **Assemble enriched payload**: Domain Services Layer combines the base page record with enrichment data from all dependencies into the final response payload.
    - From: `orchestrationServices`
    - To: `wolfApi_apiResources`
    - Protocol: Direct (in-process)

12. **Return response**: API Resources Layer returns the enriched page payload to the caller.
    - From: `wolfApi_apiResources`
    - To: caller
    - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Cache miss and database unavailable | Error propagated to caller | HTTP 503 or 500; page cannot be served |
| Relevance API unavailable | Enrichment skipped for cards/facets | Mobile payload returned without enriched card components |
| Deals Cluster Service unavailable | Cluster section omitted from payload | Page returned without cluster navigation content |
| Consumer Authority unavailable | Audience attributes omitted | Page returned without personalization targeting |
| Expy unavailable | Experiment evaluation skipped | Default variant content served |

## Sequence Diagram

```
caller -> wolfApi_apiResources: GET /wh/v2/pages/{id} (or /wh/v3/pages/{id} or /wh/v2/mobile)
wolfApi_apiResources -> orchestrationServices: Invokes page retrieval use case
orchestrationServices -> cacheAndBootstraps: Checks in-memory published page cache
cacheAndBootstraps --> orchestrationServices: Cache hit (published page state) or miss
orchestrationServices -> wolfhoundApi_persistenceDaos: Reads page record (on cache miss)
wolfhoundApi_persistenceDaos -> continuumWolfhoundPostgres: JDBI query for page record
continuumWolfhoundPostgres --> wolfhoundApi_persistenceDaos: Page record
wolfhoundApi_persistenceDaos --> orchestrationServices: Page record
orchestrationServices -> externalGatewayClients: Retrieves enrichment data
externalGatewayClients -> continuumRelevanceApi: Queries cards and facets for mobile and deal components
continuumRelevanceApi --> externalGatewayClients: Cards and facets data
externalGatewayClients -> continuumDealsClusterService: Fetches cluster navigation and top-cluster content
continuumDealsClusterService --> externalGatewayClients: Cluster content
externalGatewayClients -> continuumConsumerAuthorityService: Fetches audience membership and targeting attributes
continuumConsumerAuthorityService --> externalGatewayClients: Audience attributes
externalGatewayClients -> continuumExpyService: Evaluates and manages experiments
continuumExpyService --> externalGatewayClients: Experiment variant resolution
externalGatewayClients --> orchestrationServices: Enrichment data assembled
orchestrationServices --> wolfApi_apiResources: Enriched page payload
wolfApi_apiResources --> caller: HTTP 200 enriched page response
```

## Related

- Architecture dynamic view: `dynamic-wolfhound-page-publish-flow`
- Related flows: [Page Publish Flow](page-publish.md), [Taxonomy Bootstrap Flow](taxonomy-bootstrap.md)
- Flows index: [Flows](index.md)
