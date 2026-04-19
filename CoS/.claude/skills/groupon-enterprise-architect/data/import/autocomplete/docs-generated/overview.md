---
service: "autocomplete"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Search and Relevance"
platform: "continuum"
team: "Search and Relevance"
status: active
tech_stack:
  language: "Java"
  language_version: "21"
  framework: "Dropwizard"
  framework_version: "1.3.5"
  runtime: "Java Dropwizard embedded server"
  runtime_version: "21"
  build_tool: "Maven"
  package_manager: "Maven 3.x"
---

# Autocomplete Overview

## Purpose

The autocomplete service exposes HTTP endpoints that generate real-time search term suggestions and deal recommendation cards for Groupon consumer applications. It orchestrates multiple suggestion sources — local term files, an external Suggest App service, and the DataBreakers recommendations engine — and combines their outputs into a unified response. The service is a core part of the Groupon search and discovery experience, reducing query latency for end users by returning ranked suggestions as they type.

## Scope

### In scope

- Serving GET requests to `GET /suggestions/v1/autocomplete` with ranked suggestion and recommendation cards
- Normalizing incoming request parameters and building a `CardRequest` context via `CardRequestProcessor`
- Generating suggestion cards from three sources: local term files (`LocalQueryExecutor`), Suggest App (`SuggestAppQueryExecutor`), and recommended searches (`RecommendedSearchesQueryExecutor`)
- Generating deal and category recommendation cards via `DealRecommendationGenerator` and `DataBreakersServiceClient`
- Resolving experiment treatments and feature flags through Finch/Birdcage (`CardsFinchClient`, `V2FinchClient`)
- Exposing a DataBreakers dependency health check at `GET /healthcheck/client/databreakers`
- Loading and serving term/division datasets from embedded JSON/text resource files at runtime

### Out of scope

- Full-text search execution (handled by downstream search engine services)
- Deal indexing or ranking (owned by DataBreakers and the broader search platform)
- User session management or personalization storage
- Suggest App term corpus management (owned by the SuggestApp service team)

## Domain Context

- **Business domain**: Search and Relevance
- **Platform**: continuum
- **Upstream consumers**: Consumer Apps (mobile and web clients calling `GET /suggestions/v1/autocomplete`)
- **Downstream dependencies**: DataBreakers (deal/category recommendations), SuggestApp (suggested terms), Finch/Birdcage (experiments and feature flags), gConfigService (dynamic configuration), embedded term files (`continuumAutocompleteTermFiles`)

## Stakeholders

| Role | Description |
|------|-------------|
| Search and Relevance Team | Service owners responsible for development, operations, and term corpus quality |
| Consumer App Teams | Primary API consumers relying on autocomplete for search UX |
| DataBreakers Team | Owners of the recommendation engine that powers deal cards |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 21 | `architecture/models/components/autocomplete-service.dsl` |
| Framework | Dropwizard | 1.3.5 | Inventory — key_libraries |
| Runtime | Java Dropwizard embedded server | 21 | Inventory — runtime |
| Build tool | Maven | 3.x | Inventory — build_tool |
| Package manager | Maven | 3.x | `pom.xml` (jtier-service-pom parent) |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Dropwizard | 1.3.5 | http-framework | Embedded HTTP server and application lifecycle |
| Guice | 5.1.0 | http-framework | Dependency injection container |
| jtier-retrofit | — | http-client | Type-safe HTTP client for outbound service calls |
| Darwin | 170.3.0 | metrics | Runtime metrics and instrumentation |
| Log4j | 2.20.0 | logging | Application logging |
| Hystrix | 1.4.16 | http-framework | Circuit breaker for outbound dependency isolation |
| Archaius | 0.7.6 | config | Netflix dynamic configuration library; feeds gConfigService values |
| Holmes | 125.0.0 | http-framework | Internal Groupon HTTP utilities |
| Mockito | 5.8.0 | testing | Unit test mocking framework |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
