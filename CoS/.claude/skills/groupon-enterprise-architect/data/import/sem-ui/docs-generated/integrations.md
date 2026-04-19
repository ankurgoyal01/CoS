---
service: "sem-ui"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 1
internal_count: 2
---

# Integrations

## Overview

SEM Admin UI depends on three downstream services for all data operations. Two are internal Continuum services; one (GPN Data API) is an external data platform. All integrations are synchronous HTTP/JSON, proxied through the I-Tier server-side proxy routes. The `gofer` HTTP client library handles outbound requests.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| GPN Data API | REST/HTTP | Fetches attribution order data for the Attribution Lens page | yes | `gpnDataApi` (stub — not in federated model) |

### GPN Data API Detail

- **Protocol**: REST/HTTP JSON
- **Base URL / SDK**: Proxied via `/proxy/attribution/orders`
- **Auth**: Inherited from I-Tier session context
- **Purpose**: Provides order attribution data displayed in the `/attribution-lens` page
- **Failure mode**: Attribution Lens page data unavailable; other pages unaffected
- **Circuit breaker**: No evidence found in codebase

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| SEM Keywords Service | REST/HTTP | Reads and writes keyword associations for deal permalinks | `semKeywordsService` (stub — not in federated model) |
| SEM Blacklist Service | REST/HTTP | Manages denylist entries for SEM keyword suppression | `continuumSemBlacklistService` |

### SEM Keywords Service Detail

- **Protocol**: REST/HTTP JSON
- **Base URL / SDK**: Proxied via `/proxy/keyword/deals/{permalink}/keywords`
- **Auth**: Inherited from I-Tier session context
- **Purpose**: Supports the `/keyword-manager` page — allows SEM operators to view and modify keyword assignments per deal
- **Failure mode**: Keyword Manager page inoperable
- **Circuit breaker**: No evidence found in codebase

### SEM Blacklist Service Detail

- **Protocol**: REST/HTTP JSON
- **Base URL / SDK**: Proxied via `/proxy/denylist`
- **Auth**: Inherited from I-Tier session context
- **Purpose**: Supports the `/denylisting` page — allows SEM operators to add/remove denylist entries
- **Failure mode**: Denylist management page inoperable
- **Circuit breaker**: No evidence found in codebase

## Consumed By

> Upstream consumers are tracked in the central architecture model. SEM Admin UI is accessed directly by SEM operators and admins via browser.

## Dependency Health

> No evidence found in codebase. Health check and retry patterns for proxy dependencies are not explicitly documented in the repository. I-Tier framework defaults apply.
