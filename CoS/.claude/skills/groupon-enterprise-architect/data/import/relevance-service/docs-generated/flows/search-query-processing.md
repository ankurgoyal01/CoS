---
service: "relevance-service"
title: "Search Query Processing"
generated: "2026-03-03"
type: flow
flow_name: "search-query-processing"
flow_type: synchronous
trigger: "Incoming search or browse API request from API Proxy"
participants:
  - "continuumRelevanceApi"
  - "relevance_feynmanSearch"
  - "continuumFeynmanSearch"
  - "relevance_rankingEngine"
  - "relevance_featuresClient"
  - "booster"
architecture_ref: "dynamic-relevance-search"
---

# Search Query Processing

## Summary

This flow describes the end-to-end processing of a search or browse query received by the Relevance API (RAPI). The request enters via REST from the API Proxy, is parsed and validated, then dispatched to the appropriate search provider (Feynman Search / Elasticsearch or Booster, based on migration configuration). Candidate results are retrieved, scored by the Ranking Engine using ML models and feature vectors, and returned as a ranked result set.

## Trigger

- **Type**: api-call
- **Source**: API Proxy routes consumer search/browse requests to RAPI
- **Frequency**: Per request (high-frequency, every consumer search or browse action)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Relevance API (RAPI) | Entry point; receives query, orchestrates search and ranking, returns results | `continuumRelevanceApi` |
| Feynman Search (component) | Executes Elasticsearch queries for candidate retrieval | `relevance_feynmanSearch` |
| Feynman Search (container) | Elasticsearch cluster backing the search queries | `continuumFeynmanSearch` |
| Ranking Engine | Scores and ranks candidate results using ML models | `relevance_rankingEngine` |
| Features Client | Fetches feature vectors for ranking model input | `relevance_featuresClient` |
| Booster | Next-gen search/ranking engine receiving progressive traffic | `booster` |

## Steps

1. **Receive Search Request**: The API Proxy forwards a search or browse request to the Relevance API (RAPI) via REST.
   - From: `API Proxy`
   - To: `continuumRelevanceApi`
   - Protocol: REST

2. **Route to Search Provider**: RAPI evaluates the Booster migration feature flag to determine routing. If Booster is enabled for this request, traffic goes to Booster (skip to step 6). Otherwise, the request proceeds to Feynman Search.
   - From: `continuumRelevanceApi`
   - To: `relevance_feynmanSearch` or `booster`
   - Protocol: Internal / API

3. **Execute Elasticsearch Query**: The Feynman Search component constructs and executes an Elasticsearch query against the Feynman Search container, retrieving candidate deal results matching the query terms, filters, and geo constraints.
   - From: `relevance_feynmanSearch`
   - To: `continuumFeynmanSearch`
   - Protocol: REST (Elasticsearch API)

4. **Fetch Feature Vectors**: The Ranking Engine requests feature vectors from the Features Client for the candidate results to use as input to the ranking model.
   - From: `relevance_rankingEngine`
   - To: `relevance_featuresClient`
   - Protocol: Internal

5. **Score and Rank Results**: The Ranking Engine applies its ML ranking model to score each candidate result using the fetched features, producing a relevance-ordered result set.
   - From: `relevance_rankingEngine`
   - To: (internal computation)
   - Protocol: Internal

6. **Booster Path (progressive)**: For traffic routed to Booster, the search query is sent to the Booster API, which handles both candidate retrieval and ranking, returning a pre-scored result set.
   - From: `relevance_feynmanSearch`
   - To: `booster`
   - Protocol: API

7. **Return Ranked Results**: RAPI assembles the final response with ranked deal results and returns it to the API Proxy.
   - From: `continuumRelevanceApi`
   - To: `API Proxy`
   - Protocol: REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Elasticsearch cluster unavailable | Return error response; alert on high error rate | 5xx error to caller; fallback to Booster if enabled |
| Booster endpoint unavailable | Fall back to Feynman Search path | Degraded but functional; search served via Elasticsearch |
| Feature vector fetch timeout | Use stale/cached features or skip ranking enhancement | Results returned with reduced ranking quality |
| Query parse error | Return 400 error with descriptive message | Client receives actionable error response |
| Elasticsearch query timeout | Return partial results or error based on configuration | Degraded search experience; logged for investigation |

## Sequence Diagram

```
API Proxy -> RAPI: Search/browse request (REST)
RAPI -> Feynman Search (component): Route query
Feynman Search (component) -> Feynman Search (container): Elasticsearch query (REST)
Feynman Search (container) --> Feynman Search (component): Candidate results
RAPI -> Ranking Engine: Score candidates
Ranking Engine -> Features Client: Fetch features
Features Client -> EDW: Read feature vectors (Batch/cached)
EDW --> Features Client: Feature vectors
Features Client --> Ranking Engine: Feature vectors
Ranking Engine --> RAPI: Ranked results
RAPI --> API Proxy: Ranked deal results (REST)
```

## Related

- Architecture dynamic view: `dynamic-relevance-search`
- Related flows: [Relevance Scoring](relevance-scoring.md), [Elasticsearch Index Rebuild](elasticsearch-index-rebuild.md)
