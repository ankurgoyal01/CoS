---
service: "autocomplete"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 4
internal_count: 1
---

# Integrations

## Overview

The autocomplete service integrates with four external dependencies and one internal data resource. All outbound calls are synchronous HTTP/HTTPS. Circuit breaker protection is provided by Hystrix (version 1.4.16). Dynamic configuration for dependency endpoints is managed via gConfigService / Archaius. All external dependencies are represented as stubs in the federated architecture model because the central workspace owns their canonical definitions.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| DataBreakers | HTTPS | Fetches deal and category recommendation cards | yes | `dataBreakers` (stub) |
| SuggestApp | HTTP | Fetches suggested search terms | yes | `suggestApp` (stub) |
| Finch/Birdcage | HTTP | Resolves experiment treatments and feature flags | no | `finchBirdcage` (stub) |
| gConfigService | HTTP | Provides dynamic configuration values at runtime | yes | `gConfigService` (stub) |

### DataBreakers Detail

- **Protocol**: HTTPS
- **Base URL / SDK**: Configured via Archaius/gConfigService at runtime; client implemented in `DataBreakersServiceClient`
- **Auth**: Request signing (encapsulated in `DataBreakersServiceClient`)
- **Purpose**: Supplies deal and category recommendation cards for the `DealRecommendationGenerator`; drives the primary recommendation card slot in the autocomplete response
- **Failure mode**: Hystrix circuit breaker isolates failures; degraded response omits recommendation cards
- **Circuit breaker**: Yes — Hystrix 1.4.16

### SuggestApp Detail

- **Protocol**: HTTP
- **Base URL / SDK**: Configured via Archaius/gConfigService at runtime; client implemented in `SuggestAppServiceClient`
- **Auth**: Internal service-to-service (no evidence of external auth)
- **Purpose**: Provides suggested search terms consumed by `SuggestAppQueryExecutor` within `SuggestionGenerator`
- **Failure mode**: Hystrix circuit breaker isolates failures; suggestion terms from SuggestApp are omitted from response on failure
- **Circuit breaker**: Yes — Hystrix 1.4.16

### Finch/Birdcage Detail

- **Protocol**: HTTP
- **Base URL / SDK**: Clients `CardsFinchClient` and `V2FinchClient`
- **Auth**: Internal service-to-service
- **Purpose**: Resolves A/B experiment treatments and feature flags that influence ranking, spellcheck, and card selection behavior
- **Failure mode**: Non-critical path; response falls back to default treatment on failure
- **Circuit breaker**: Yes — Hystrix 1.4.16

### gConfigService Detail

- **Protocol**: HTTP
- **Base URL / SDK**: Archaius 0.7.6 polling client
- **Auth**: Internal service-to-service
- **Purpose**: Supplies dynamic configuration values (endpoint URLs, feature toggles, thresholds) without requiring a service restart
- **Failure mode**: Falls back to last-known-good configuration cached by Archaius
- **Circuit breaker**: Archaius handles retry/fallback internally

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Autocomplete Term Files | In-process / classpath | Loads term and division recommendation resources at startup | `continuumAutocompleteTermFiles` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Consumer Apps | HTTP | Retrieve ranked suggestion and recommendation cards for search UX |

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

The `HealthCheckResource` exposes `GET /healthcheck/client/databreakers`, which validates the DataBreakers dependency. Hystrix circuit breakers wrap all four external HTTP calls. Archaius polls gConfigService continuously so configuration values remain fresh without restarts. No evidence of retry configuration beyond Hystrix defaults is found in the architecture model.
