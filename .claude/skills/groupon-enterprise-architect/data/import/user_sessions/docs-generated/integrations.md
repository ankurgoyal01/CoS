---
service: "user_sessions"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 3
internal_count: 2
---

# Integrations

## Overview

user_sessions has three external dependencies (GAPI, Google OAuth, Facebook OAuth) and two internal Continuum dependencies (Deal Page Service, Memcached cluster). GAPI is the critical path for all authentication and registration operations. The OAuth providers are required only for social login flows. All integrations are synchronous HTTP/HTTPS.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| GAPI | GraphQL / HTTP | User credential validation, account creation, password reset token generation and verification | yes | `gapiSystem_5c8b` |
| Google OAuth | OAuth 2.0 / HTTPS | Authorization code exchange and identity token retrieval for Google social login | yes (for social login flow) | `googleOAuth_1d2e` |
| Facebook OAuth | OAuth 2.0 / HTTPS | Authorization code exchange and identity token retrieval for Facebook social login | yes (for social login flow) | `facebookOAuth_9a7c` |

### GAPI Detail

- **Protocol**: GraphQL over HTTP
- **Base URL / SDK**: Configured via `GRAPHQL_ENDPOINT` environment variable; client implemented via `@grpn/graphql-gapi` 5.2.9
- **Auth**: Internal service-to-service (credentials managed via environment/secrets)
- **Purpose**: Central user data gateway — validates email/password credentials, creates new user accounts on signup, generates password reset tokens and verifies them on reset, returns user identity on successful auth
- **Failure mode**: Login, signup, and password reset flows are unavailable; service returns error pages to the user
- **Circuit breaker**: No evidence found

### Google OAuth Detail

- **Protocol**: OAuth 2.0 / HTTPS (authorization code flow)
- **Base URL / SDK**: Google OAuth 2.0 endpoints; integration via itier-user-auth
- **Auth**: OAuth client credentials configured via environment/secrets
- **Purpose**: Authenticates users who choose "Sign in with Google"; exchanges authorization code for identity token; maps to Groupon user account via GAPI
- **Failure mode**: Google social login flow is unavailable; email/password login remains functional
- **Circuit breaker**: No evidence found

### Facebook OAuth Detail

- **Protocol**: OAuth 2.0 / HTTPS (authorization code flow)
- **Base URL / SDK**: Facebook OAuth endpoints; integration via itier-user-auth
- **Auth**: OAuth client credentials configured via environment/secrets
- **Purpose**: Authenticates users who choose "Sign in with Facebook"; exchanges authorization code for identity token; maps to Groupon user account via GAPI
- **Failure mode**: Facebook social login flow is unavailable; email/password login remains functional
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Memcached cluster | Memcached binary/text protocol | Session storage and retrieval | `memcachedCluster_6e2f` |
| Deal Page Service | HTTP redirect | Sends unauthenticated users to login; receives post-login redirect back | `dealPageService_3b4d` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Web browser (shopper) | HTTPS | Renders login, signup, and password reset pages; submits forms |
| Deal Page Service | HTTP redirect | Redirects unauthenticated users to this service for login |

> Upstream consumers beyond these are tracked in the central architecture model.

## Dependency Health

> No evidence found in codebase for explicit circuit breakers, retry policies, or health-check probes on dependencies. Health of GAPI and OAuth providers is expected to be monitored at the infrastructure level. Memcached availability is checked implicitly — session cache misses result in re-authentication prompts.
