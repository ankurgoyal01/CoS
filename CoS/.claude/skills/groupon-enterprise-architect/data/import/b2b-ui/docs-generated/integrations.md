---
service: "b2b-ui"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 2
---

# Integrations

## Overview

The RBAC UI has two internal Continuum platform dependencies (`continuumRbacService` and `continuumUsersService`) and one external identity integration (UMAPI). All downstream calls are synchronous REST/HTTP invocations made from the BFF API layer. Akamai bot detection is handled at the edge via the `grpn-request-middleware` library.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| UMAPI (User Management API) | REST | Provides OAuth2-style client identity context for RBAC API calls | yes | — |
| Akamai (bot detection) | Edge middleware | Detects and redirects bot traffic to `/botland` | no | — |
| Marker.io | Browser SDK | In-browser feedback and bug reporting widget (`@marker.io/browser`) | no | — |

### UMAPI (User Management API) Detail

- **Protocol**: REST / OAuth2 client credential context
- **Base URL / SDK**: Configured via `vpcs.config.json` (`umapi-client.client-id: f8ddc46cb0e1d3e1e7eda69d3352831e`)
- **Auth**: OAuth2 client credentials (client ID per environment)
- **Purpose**: Provides authenticated identity context used when constructing API calls to downstream RBAC services
- **Failure mode**: RBAC UI login and user-management operations would fail; users could not authenticate
- **Circuit breaker**: No evidence found in codebase

### Akamai (bot detection) Detail

- **Protocol**: Edge middleware handler (`grpn-request-middleware` library)
- **Base URL / SDK**: `@vpcs/grpn-request-middleware` — `akamai-bot-detection` handler in `vpcs.config.json`
- **Auth**: Not applicable — edge-level header inspection
- **Purpose**: Redirects requests identified as bot traffic to `/botland` with HTTP 200
- **Failure mode**: Passes through transparently (no blocking)
- **Circuit breaker**: Not applicable

### Marker.io Detail

- **Protocol**: Browser JavaScript SDK (`@marker.io/browser 0.19.0`)
- **Base URL / SDK**: Loaded in browser context only
- **Auth**: Marker.io project token (not visible in repo)
- **Purpose**: Allows operators to submit visual feedback and bug reports from within the RBAC admin interface
- **Failure mode**: Feedback widget unavailable; no impact on RBAC functionality
- **Circuit breaker**: Not applicable

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| `continuumRbacService` | REST/HTTP | Calls RBAC v2 endpoints for role, permission, category, and request operations | `continuumRbacService` |
| `continuumUsersService` | REST/HTTP | Validates users, resolves user identities, and creates user accounts | `continuumUsersService` |

### continuumRbacService Detail

- **Protocol**: REST/HTTP via generated TypeScript client (`@vpcs/rbac-client`)
- **Base URL / SDK**: Client generated from `libs/vpcs/core/rbac-client/swagger.yml`
- **Auth**: RBAC client ID (`NEXT_PUBLIC_RBAC_CLIENT_ID`) per environment
- **Purpose**: Provides all RBAC domain operations — querying and mutating roles, permissions, categories, and access requests
- **Failure mode**: RBAC UI BFF API routes return errors; admin screens become non-functional
- **Circuit breaker**: No evidence found in codebase

### continuumUsersService Detail

- **Protocol**: REST/HTTP via `@vpcs/users-client` library
- **Base URL / SDK**: `libs/vpcs/core/users-client`
- **Auth**: Inherits session identity headers injected by Session Middleware
- **Purpose**: Resolves user identities for display, ownership data, and creates user accounts during provisioning
- **Failure mode**: User display names and ownership data unavailable; user provisioning fails
- **Circuit breaker**: No evidence found in codebase

## Consumed By

> Upstream consumers are tracked in the central architecture model. The RBAC UI is consumed directly by internal Groupon operators and merchant administrators via browser.

## Dependency Health

> No explicit health check, retry, or circuit breaker patterns are configured in this repository. Failure handling for downstream dependencies relies on HTTP error responses being propagated back to the browser client.
