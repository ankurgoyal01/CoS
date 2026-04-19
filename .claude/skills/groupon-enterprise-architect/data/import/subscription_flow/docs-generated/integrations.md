---
service: "subscription_flow"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 0
internal_count: 3
---

# Integrations

## Overview

Subscription Flow has 3 internal Continuum dependencies and no external third-party integrations. All integrations are synchronous REST calls made during request handling. The service depends on Lazlo API for legacy subscription data, GConfig for dynamic configuration and experiment assignments, and the Groupon V2 API for user context.

## External Dependencies

> No external (third-party) dependencies. All dependencies are internal Continuum services.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Lazlo API Service | REST | Fetches legacy subscription endpoints and data required for modal rendering | `continuumApiLazloService` |
| GConfig Service | REST | Fetches dynamic runtime configuration and A/B experiment assignments for the subscription modal | `gconfigService_4b3a` |
| Groupon V2 API | REST | Fetches user context (authentication state, subscription status) for personalised modal rendering | `grouponV2Api_2d1e` |

### Lazlo API Service Detail

- **Protocol**: REST / HTTP
- **Base URL / SDK**: Internal Continuum service endpoint (configured via environment variable)
- **Auth**: Internal service credentials / session context
- **Purpose**: Provides legacy subscription-related data and endpoints that the subscription modal rendering depends on
- **Failure mode**: Modal may render in a degraded state (missing data) or return an error page
- **Circuit breaker**: No evidence found in codebase

### GConfig Service Detail

- **Protocol**: REST / HTTP
- **Base URL / SDK**: Internal GConfig endpoint (configured via environment variable)
- **Auth**: Internal service credentials
- **Purpose**: Supplies dynamic configuration values and experiment variant assignments that control modal appearance and behaviour (e.g., which variant to show, feature flags)
- **Failure mode**: Falls back to default configuration values loaded at bootstrap; experiment assignment may be unavailable
- **Circuit breaker**: No evidence found in codebase

### Groupon V2 API Detail

- **Protocol**: REST / HTTP
- **Base URL / SDK**: `itier-groupon-v2` client library
- **Auth**: Forwarded session/cookie from incoming request
- **Purpose**: Fetches user identity and subscription state so the modal can be personalised (e.g., show upgrade vs. new subscription CTA)
- **Failure mode**: Modal renders without personalisation; user shown default unauthenticated view
- **Circuit breaker**: No evidence found in codebase

## Consumed By

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

> No evidence found in codebase for explicit circuit breaker or retry configuration. All downstream calls are made synchronously at render time. Service owners should define timeout and fallback policies for each dependency to prevent cascading latency during high load.
