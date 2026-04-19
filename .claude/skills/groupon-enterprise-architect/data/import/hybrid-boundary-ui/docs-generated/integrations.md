---
service: "hybrid-boundary-ui"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 3
internal_count: 0
---

# Integrations

## Overview

Hybrid Boundary UI has three external dependencies, all outbound from the browser: Groupon Okta for OIDC authentication, the Hybrid Boundary API for service mesh configuration management, and the PAR Automation API for PAR request submission. All three are stub-only in the current federated architecture model, meaning their container IDs are not yet resolved in the central Structurizr workspace.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Groupon Okta | HTTPS/OIDC | Authenticates users and issues identity tokens consumed by `hbUiAuthModule` | yes | `unknownGrouponOktaOauth_u3ab7` (stub-only) |
| Hybrid Boundary API (`/release/v1`) | HTTPS/JSON | Source of truth for service configuration, endpoints, policies, and permissions | yes | `unknownHybridBoundaryApiReleaseV1_u6f4c` (stub-only) |
| PAR Automation API (`/release/par`) | HTTPS/JSON | Receives PAR request submissions from `hbUiParAutomationClient` | yes | `unknownParAutomationApiReleasePar_u9d21` (stub-only) |

### Groupon Okta Detail

- **Protocol**: HTTPS/OIDC
- **Base URL / SDK**: `angular-oauth2-oidc` library; OIDC discovery endpoint provided by Groupon Okta
- **Auth**: OIDC (this is the auth provider itself)
- **Purpose**: `hbUiAuthModule` performs OIDC discovery, login redirect, and token validation. The resulting access token is attached to all outbound API calls via an Angular HTTP interceptor.
- **Failure mode**: Users cannot log in; application is inaccessible
- **Circuit breaker**: No evidence found — standard OIDC retry behavior in `angular-oauth2-oidc`

### Hybrid Boundary API (`/release/v1`) Detail

- **Protocol**: HTTPS/JSON
- **Base URL / SDK**: `/release/v1` base path (inferred from `hbUiApiClient` description)
- **Auth**: Bearer token from Groupon Okta (attached by `hbUiAuthModule` interceptor)
- **Purpose**: `hbUiApiClient` reads and mutates Hybrid Boundary service definitions, endpoint registrations, traffic shifts, policies, and user permissions on behalf of the logged-in operator
- **Failure mode**: UI displays errors; configuration operations are unavailable
- **Circuit breaker**: No evidence found

### PAR Automation API (`/release/par`) Detail

- **Protocol**: HTTPS/JSON
- **Base URL / SDK**: `/release/par` base path (inferred from `hbUiParAutomationClient` description)
- **Auth**: Bearer token from Groupon Okta (attached by `hbUiAuthModule` interceptor)
- **Purpose**: `hbUiParAutomationClient` submits PAR (Production Access Request) automation requests on behalf of the operator
- **Failure mode**: PAR submission unavailable; UI displays error
- **Circuit breaker**: No evidence found

## Internal Dependencies

> Not applicable — Hybrid Boundary UI has no runtime dependencies on other internal Continuum services.

## Consumed By

> Not applicable — this is a user-facing SPA. No internal services programmatically consume Hybrid Boundary UI.

## Dependency Health

> Operational procedures to be defined by service owner. All dependencies are external and accessed from the browser; no server-side health checks or circuit breakers are evidenced in the architecture DSL.
