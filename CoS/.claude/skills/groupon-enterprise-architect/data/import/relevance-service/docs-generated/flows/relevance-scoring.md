---
service: "relevance-service"
title: "Relevance Scoring"
generated: "2026-03-03"
type: flow
flow_name: "relevance-scoring"
flow_type: synchronous
trigger: "Candidate results returned from Elasticsearch or Booster requiring ranking"
participants:
  - "relevance_rankingEngine"
  - "relevance_featuresClient"
  - "edw"
architecture_ref: "dynamic-relevance-scoring"
---

# Relevance Scoring

## Summary

This flow details how the Ranking Engine component within RAPI scores and ranks candidate search results. After Feynman Search returns raw candidate deals from Elasticsearch, the Ranking Engine fetches feature vectors from the Features Client (sourced from the Enterprise Data Warehouse), applies a machine-learned ranking model to each candidate, and produces a relevance-ordered result set. This sub-flow is invoked as part of every search query processing cycle.

## Trigger

- **Type**: api-call (sub-flow of search query processing)
- **Source**: RAPI search orchestration logic after candidate retrieval
- **Frequency**: Per request (invoked for every search/browse query routed through the Feynman Search path)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Ranking Engine | Orchestrates scoring; applies ML model to candidates with feature vectors | `relevance_rankingEngine` |
| Features Client | Retrieves feature vectors from EDW for ranking input | `relevance_featuresClient` |
| Enterprise Data Warehouse (EDW) | Source of feature vectors (user behavior, deal attributes, contextual signals) | `edw` |

## Steps

1. **Receive Candidates**: The Ranking Engine receives a set of candidate deal results from the search provider (Feynman Search / Elasticsearch) along with query context (search terms, user context, location).
   - From: `continuumRelevanceApi` (orchestration layer)
   - To: `relevance_rankingEngine`
   - Protocol: Internal

2. **Request Feature Vectors**: The Ranking Engine calls the Features Client to fetch feature vectors for the candidate deals. Features include user behavioral signals, deal performance metrics, merchant quality scores, and contextual attributes.
   - From: `relevance_rankingEngine`
   - To: `relevance_featuresClient`
   - Protocol: Internal

3. **Fetch from EDW**: The Features Client reads feature vectors from the Enterprise Data Warehouse. This may involve cached reads for frequently accessed features or batch-preloaded feature stores.
   - From: `relevance_featuresClient`
   - To: `edw`
   - Protocol: Batch

4. **Apply Ranking Model**: The Ranking Engine applies the active ML ranking model to each candidate, combining the Elasticsearch relevance score with feature vector inputs to compute a final relevance score.
   - From: `relevance_rankingEngine`
   - To: (internal computation)
   - Protocol: Internal

5. **Sort and Return**: Candidates are sorted by their computed relevance scores in descending order and returned to the RAPI orchestration layer for response assembly.
   - From: `relevance_rankingEngine`
   - To: `continuumRelevanceApi`
   - Protocol: Internal

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| EDW feature fetch failure | Use cached/stale features or fall back to Elasticsearch-only scoring | Results returned with degraded ranking quality |
| Ranking model execution error | Return candidates in Elasticsearch relevance order (no ML re-ranking) | Functional but with reduced personalization |
| Feature vector missing for candidate | Score candidate with available features; apply default/fallback scores | Candidate still included in results with approximate ranking |
| Ranking model timeout | Return partial scoring or Elasticsearch-ordered results | Latency cap enforced; degraded quality accepted |

## Sequence Diagram

```
RAPI -> Ranking Engine: Score candidates (candidate set + query context)
Ranking Engine -> Features Client: Fetch features (candidate IDs)
Features Client -> EDW: Read feature vectors (Batch)
EDW --> Features Client: Feature vectors
Features Client --> Ranking Engine: Feature vectors
Ranking Engine -> Ranking Engine: Apply ML model (features + candidates)
Ranking Engine --> RAPI: Ranked results (sorted by relevance score)
```

## Related

- Architecture dynamic view: `dynamic-relevance-scoring`
- Related flows: [Search Query Processing](search-query-processing.md), [Elasticsearch Index Rebuild](elasticsearch-index-rebuild.md)
