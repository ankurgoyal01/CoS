---
service: "autocomplete"
title: "Autocomplete Search Request"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "autocomplete-search-request"
flow_type: synchronous
trigger: "HTTP GET /suggestions/v1/autocomplete from Consumer App"
participants:
  - "consumerApps"
  - "continuumAutocompleteService"
  - "cardsSearchResource"
  - "cardRequestProcessor"
  - "cardExecutor"
  - "suggestionGenerator"
  - "dealRecommendationGenerator"
  - "suggestAppQueryExecutor"
  - "localQueryExecutor"
  - "recommendedSearchesQueryExecutor"
  - "dataBreakersServiceClient"
  - "suggestAppServiceClient"
  - "cardsFinchClient"
  - "v2FinchClient"
  - "continuumAutocompleteTermFiles"
  - "dataBreakers"
  - "suggestApp"
  - "finchBirdcage"
architecture_ref: "autocompleteRequestRuntimeFlow"
---

# Autocomplete Search Request

## Summary

This flow handles every inbound `GET /suggestions/v1/autocomplete` request from a Consumer App. The request passes through a normalization stage, is orchestrated by a central executor that fans out to multiple suggestion and recommendation generators, and is ultimately returned as a combined cards response. The flow is entirely synchronous — no messages are published and no background work is deferred.

## Trigger

- **Type**: api-call
- **Source**: Consumer Apps (mobile or web) calling `GET /suggestions/v1/autocomplete`
- **Frequency**: per-request (on-demand as user types)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer Apps | Initiates the request | `consumerApps` (stub) |
| Autocomplete Service | Top-level container hosting all components | `continuumAutocompleteService` |
| CardsSearchResource | Receives HTTP request; delegates to processor | `cardsSearchResource` |
| CardRequestProcessor | Normalizes headers/params; builds CardRequest context | `cardRequestProcessor` |
| CardExecutor | Orchestrates all card generators; assembles final response | `cardExecutor` |
| SuggestionGenerator | Routes to configured query executors for suggestion terms | `suggestionGenerator` |
| DealRecommendationGenerator | Generates deal/category recommendation cards | `dealRecommendationGenerator` |
| SuggestAppQueryExecutor | Fetches terms from SuggestApp via HTTP | `suggestAppQueryExecutor` |
| LocalQueryExecutor | Reads terms from in-memory term files | `localQueryExecutor` |
| RecommendedSearchesQueryExecutor | Builds recommended-search suggestions | `recommendedSearchesQueryExecutor` |
| DataBreakersServiceClient | Signs and invokes DataBreakers API | `dataBreakersServiceClient` |
| SuggestAppServiceClient | Invokes SuggestApp API | `suggestAppServiceClient` |
| CardsFinchClient | Fetches experiment treatments (cards) | `cardsFinchClient` |
| V2FinchClient | Fetches V2 experiment treatments | `v2FinchClient` |
| Autocomplete Term Files | Provides in-memory term data | `continuumAutocompleteTermFiles` |
| DataBreakers | External recommendation engine | `dataBreakers` (stub) |
| SuggestApp | External suggestion terms service | `suggestApp` (stub) |
| Finch/Birdcage | External experiment platform | `finchBirdcage` (stub) |

## Steps

1. **Receives autocomplete request**: Consumer App sends `GET /suggestions/v1/autocomplete` with query parameters.
   - From: `consumerApps`
   - To: `cardsSearchResource`
   - Protocol: HTTP

2. **Normalizes request**: `CardRequestProcessor` reads request headers and parameters, normalizes locale and query, and builds the `CardRequest` context object.
   - From: `cardsSearchResource`
   - To: `cardRequestProcessor`
   - Protocol: direct (in-process)

3. **Resolves experiment treatments**: `CardsFinchClient` and `V2FinchClient` fetch active experiment treatments and feature flags to influence ranking and spellcheck behavior.
   - From: `cardExecutor`
   - To: `finchBirdcage` via `cardsFinchClient` / `v2FinchClient`
   - Protocol: HTTP

4. **Generates suggestion cards**: `CardExecutor` invokes `SuggestionGenerator`, which fans out to three executors in parallel or sequence:
   - `SuggestAppQueryExecutor` calls `suggestAppServiceClient` -> `suggestApp` over HTTP to fetch external suggestion terms
   - `LocalQueryExecutor` reads from `continuumAutocompleteTermFiles` (in-memory, no network I/O)
   - `RecommendedSearchesQueryExecutor` reads from recommendation term sources
   - From: `cardExecutor` -> `suggestionGenerator`
   - To: `suggestApp`, `continuumAutocompleteTermFiles`
   - Protocol: HTTP (SuggestApp), in-process (local files)

5. **Generates recommendation cards**: `CardExecutor` invokes `DealRecommendationGenerator`, which calls `DataBreakersServiceClient` to fetch deal and category recommendation cards from DataBreakers.
   - From: `dealRecommendationGenerator`
   - To: `dataBreakers` via `dataBreakersServiceClient`
   - Protocol: HTTPS

6. **Reads local term resources**: `LocalQueryExecutor` loads term data from `continuumAutocompleteTermFiles` for in-memory suggestion term generation.
   - From: `continuumAutocompleteService`
   - To: `continuumAutocompleteTermFiles`
   - Protocol: in-process / classpath

7. **Assembles and returns response**: `CardExecutor` merges suggestion cards and recommendation cards into a ranked combined response, which `CardsSearchResource` serializes and returns to the Consumer App.
   - From: `cardExecutor`
   - To: `cardsSearchResource` -> `consumerApps`
   - Protocol: HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| DataBreakers unavailable | Hystrix circuit breaker opens on `DataBreakersServiceClient` | Response omits recommendation cards; suggestion cards still returned |
| SuggestApp unavailable | Hystrix circuit breaker opens on `SuggestAppServiceClient` | Response omits SuggestApp terms; local term fallback via `LocalQueryExecutor` still active |
| Finch/Birdcage unavailable | Fallback to default experiment treatment | Default ranking and spellcheck behavior applied |
| gConfigService unavailable | Archaius uses last-known-good configuration | Service continues with cached config values |

## Sequence Diagram

```
ConsumerApps -> CardsSearchResource: GET /suggestions/v1/autocomplete
CardsSearchResource -> CardRequestProcessor: normalize(request)
CardRequestProcessor --> CardsSearchResource: CardRequest context
CardsSearchResource -> CardExecutor: execute(CardRequest)
CardExecutor -> CardsFinchClient: fetchTreatments(CardRequest)
CardsFinchClient -> Finch/Birdcage: GET experiment treatments
Finch/Birdcage --> CardsFinchClient: treatments
CardExecutor -> SuggestionGenerator: generateSuggestions(CardRequest)
SuggestionGenerator -> SuggestAppQueryExecutor: fetchTerms()
SuggestAppQueryExecutor -> SuggestApp: GET suggestion terms
SuggestApp --> SuggestAppQueryExecutor: terms
SuggestionGenerator -> LocalQueryExecutor: fetchTerms()
LocalQueryExecutor -> AutocompleteTermFiles: read in-memory terms
AutocompleteTermFiles --> LocalQueryExecutor: terms
CardExecutor -> DealRecommendationGenerator: generateRecommendations(CardRequest)
DealRecommendationGenerator -> DataBreakersServiceClient: fetchRecommendations()
DataBreakersServiceClient -> DataBreakers: HTTPS recommendation request
DataBreakers --> DataBreakersServiceClient: recommendation cards
CardExecutor --> CardsSearchResource: combined cards response
CardsSearchResource --> ConsumerApps: HTTP 200 JSON cards response
```

## Related

- Architecture dynamic view: `autocompleteRequestRuntimeFlow`
- Related flows: [Health Check Flow](health-check-flow.md)
