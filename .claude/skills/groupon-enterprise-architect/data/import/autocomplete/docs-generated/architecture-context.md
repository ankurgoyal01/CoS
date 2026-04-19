---
service: "autocomplete"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumAutocompleteService, continuumAutocompleteTermFiles]
---

# Architecture Context

## System Context

The autocomplete service sits within the `continuumSystem` and serves as the real-time suggestion layer for Groupon's consumer-facing search experiences. Consumer Apps (mobile/web) call it directly over HTTP to retrieve ranked suggestion and recommendation cards. The service itself calls outward to DataBreakers for deal recommendations, SuggestApp for term suggestions, Finch/Birdcage for experiment treatments, and gConfigService for dynamic configuration. It also reads embedded term resources from the co-located `continuumAutocompleteTermFiles` container at startup and runtime. No event bus or async messaging is involved; all interactions are synchronous HTTP request/response.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Autocomplete Service | `continuumAutocompleteService` | Service | Java 21, Dropwizard, Guice | 1.3.5 | Java Dropwizard service exposing autocomplete and health endpoints, generating suggestions and recommendation cards |
| Autocomplete Term Files | `continuumAutocompleteTermFiles` | Data store | Embedded JSON/Text Resources | — | Packaged JSON/text term and division datasets loaded at runtime for local and locale-aware suggestion generation |

## Components by Container

### Autocomplete Service (`continuumAutocompleteService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `cardsSearchResource` | Handles incoming `GET /suggestions/v1/autocomplete` HTTP requests | JAX-RS Resource |
| `healthCheckResource` | Handles `GET /healthcheck/client/databreakers` health probe requests | JAX-RS Resource |
| `cardRequestProcessor` | Normalizes request headers/params and builds the `CardRequest` context | Request Processor |
| `cardExecutor` | Coordinates card generators and assembles the final cards response payload | Execution Orchestrator |
| `suggestionGenerator` | Generates suggestion cards by routing through configured query executors | Card Generator |
| `recommendedSearchesQueryExecutor` | Builds recommended-search suggestions from recommendation term sources | Suggestion Executor |
| `suggestAppQueryExecutor` | Fetches suggestion terms from the external Suggest App service | Suggestion Executor |
| `localQueryExecutor` | Generates suggestion terms from in-memory local term files | Suggestion Executor |
| `dealRecommendationGenerator` | Generates deal and category recommendation cards | Card Generator |
| `dataBreakersServiceClient` | Encapsulates DataBreakers API request signing, invocation, and response validation | HTTP Client |
| `suggestAppServiceClient` | Encapsulates Suggest App API invocation and response handling | HTTP Client |
| `cardsFinchClient` | Fetches experiment treatments and feature flags for ranking and spellcheck | Experiment Client |
| `v2FinchClient` | Provides V2 autocomplete experiment treatment lookups | Experiment Client |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumAutocompleteService` | `continuumAutocompleteTermFiles` | Loads terms, locale mappings, and division recommendation resources | In-process / classpath |
| `consumerApps` | `continuumAutocompleteService` | Calls autocomplete and health endpoints | HTTP |
| `continuumAutocompleteService` | `dataBreakers` | Requests recommendation cards | HTTPS |
| `continuumAutocompleteService` | `suggestApp` | Requests suggestion terms | HTTP |
| `continuumAutocompleteService` | `finchBirdcage` | Fetches experiment/treatment configuration | HTTP |
| `continuumAutocompleteService` | `gConfigService` | Fetches dynamic configuration values | HTTP |

> Note: All relationships except the `continuumAutocompleteService -> continuumAutocompleteTermFiles` relation are stub-only in the federated model. The active relation is confirmed in `architecture/models/relations.dsl`.

## Architecture Diagram References

- System context: `contexts-autocomplete`
- Container: `containers-autocomplete`
- Component: `components-autocompleteService`
- Dynamic view: `autocompleteRequestRuntimeFlow` (defined in `architecture/views/dynamics/autocomplete-request-flow.dsl`)
