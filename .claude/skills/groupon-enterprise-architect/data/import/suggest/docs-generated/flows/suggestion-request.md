---
service: "suggest"
title: "Suggestion Request"
generated: "2026-03-03"
type: flow
flow_name: "suggestion-request"
flow_type: synchronous
trigger: "GET /suggestions HTTP request from MBNXT search client"
participants:
  - "searchClient_3c1a"
  - "suggest_apiRoutes"
  - "suggestionService"
  - "locationService"
  - "dictionaryManager"
  - "suggestionRankingService"
architecture_ref: "components-suggest-service"
---

# Suggestion Request

## Summary

The suggestion request flow is the primary user-facing flow of the Suggest service. It receives a partial query string and user GPS coordinates from the MBNXT search client, determines the nearest Groupon geographic divisions, and concurrently retrieves ranked query suggestions and category suggestions. The response includes a `did_you_mean` corrected query and a combined list of typed suggestion items (query and category), capped at 10 each by default.

## Trigger

- **Type**: api-call
- **Source**: MBNXT search client (`searchClient_3c1a`) calls `GET /suggestions`
- **Frequency**: Per user keystroke / on-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MBNXT search client | Initiates request with `query`, `lat`, `lon` | `searchClient_3c1a` |
| API Routes | Validates request via Pydantic schema; dispatches to suggestion service | `suggest_apiRoutes` |
| Suggestion Service | Orchestrates the full suggestion pipeline | `suggestionService` |
| Location Service | Resolves nearest Groupon divisions by Haversine distance | `locationService` |
| Dictionary Manager | Provides in-memory `queries_dict`, `categories_dict`, `intent_dict`, `gps_coordinates` | `dictionaryManager` |
| Suggestion Ranking Service | Scores and sorts candidate query suggestions | `suggestionRankingService` |

## Steps

1. **Receive and validate request**: The MBNXT search client sends `GET /suggestions?query=<partial>&lat=<lat>&lon=<lon>`.
   - From: `searchClient_3c1a`
   - To: `suggest_apiRoutes`
   - Protocol: REST

2. **Optional query preprocessing**: If `query_preprocessing_enabled=true`, the Suggestion Service calls `preprocess_raw_query()` to apply text normalization, stopword removal, typo correction (BK-Tree), and locality extraction before proceeding.
   - From: `suggestionService`
   - To: `queryPreprocessingService` (inline call)
   - Protocol: direct

3. **Resolve nearest divisions**: Reads `DictionaryManager.gps_coordinates` and applies the Haversine formula to find all divisions within 100 km of the user's coordinates; returns them ordered by distance.
   - From: `suggestionService`
   - To: `locationService`
   - Protocol: direct

4. **Check intent word match**: Looks up the cleaned query in `DictionaryManager.intent_dict`. If matched, returns the intent term immediately as a single suggestion, bypassing all further matching and ranking.
   - From: `suggestionService`
   - To: `dictionaryManager`
   - Protocol: direct

5. **Fetch and filter division queries in parallel**: For each resolved division, concurrently loads the division's query list from `DictionaryManager.queries_dict` and applies tiered fuzzy matching (tier 0 = exact, tier 1 = prefix, tier 2 = contains, tier 3 = not matched). Queries at tier ≥ 3 or flagged as adult (when `exclude_adult_content=true`) are discarded.
   - From: `suggestionService`
   - To: `dictionaryManager` (read) / asyncio parallel tasks per division
   - Protocol: direct

6. **Rank query suggestions per division**: Passes filtered candidates to `suggestionRankingService.rank_suggestions()`, which enriches each candidate with text-similarity features and engagement metrics (`suggestionClicks`, `dealClicks`, `searchCount`, `query_aggregated_score`) from `DictionaryManager.suggestions_ranking_dict` and scores them using weighted feature scoring.
   - From: `suggestionService`
   - To: `suggestionRankingService`
   - Protocol: direct

7. **Deduplicate and merge cross-division results**: Combines per-division ranked suggestion lists, preserving order while eliminating duplicates, until `query_limit` (default 10) is reached.
   - From: `suggestionService` (internal)
   - To: `suggestionService` (internal)
   - Protocol: direct

8. **Fetch category suggestions**: Concurrently with step 5–7, looks up the cleaned query in `DictionaryManager.categories_dict`, sorts matching categories by GP score (descending), and deduplicates, returning up to `category_limit` (default 10) results.
   - From: `suggestionService`
   - To: `dictionaryManager`
   - Protocol: direct

9. **Build and return response**: Assembles a `SuggestionResponse` with `did_you_mean`, a merged `suggestions` list (query items first, then category items), and optional `debug` information if `debug_mode=true`.
   - From: `suggest_apiRoutes`
   - To: `searchClient_3c1a`
   - Protocol: REST / JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `queries_dict` is `None` (BigQuery and fallback both unavailable) | Log warning; return empty suggestions list | `suggestions: []` returned |
| BigQuery unavailable at refresh time (not at request time) | Fallback to local CSV file | Suggestions served from last loaded local file data |
| Division API failed at startup — empty GPS coordinates | `find_nearest_divisions()` returns empty list | No division queries fetched; only category suggestions returned |
| Intent word matched | Short-circuit — skip division lookup and ranking | Single intent-word suggestion returned immediately |
| Adult content query with `exclude_adult_content=true` | Queries with `is_adult=true` flag skipped | Adult suggestions filtered from result |
| Validation error (missing `query`, `lat`, or `lon`) | FastAPI returns HTTP 422 with field-level error detail | Error response returned to client |

## Sequence Diagram

```
searchClient_3c1a -> suggest_apiRoutes: GET /suggestions?query=spa&lat=40.73&lon=-73.63
suggest_apiRoutes -> suggestionService: get_suggestions(request)
suggestionService -> locationService: find_nearest_divisions(lat, lon)
locationService -> dictionaryManager: read gps_coordinates
locationService --> suggestionService: [division_id, ...]
suggestionService -> dictionaryManager: check intent_dict
suggestionService -> dictionaryManager: read queries_dict (per division, parallel)
suggestionService -> suggestionRankingService: rank_suggestions(division, query, candidates)
suggestionRankingService -> dictionaryManager: read suggestions_ranking_dict
suggestionRankingService --> suggestionService: ranked list
suggestionService -> dictionaryManager: read categories_dict
dictionaryManager --> suggestionService: category items
suggestionService --> suggest_apiRoutes: SuggestionResponse
suggest_apiRoutes --> searchClient_3c1a: 200 OK JSON
```

## Related

- Architecture dynamic view: `components-suggest-service`
- Related flows: [Query Preprocessing](query-preprocessing.md), [Suggestion Ranking](suggestion-ranking.md)
