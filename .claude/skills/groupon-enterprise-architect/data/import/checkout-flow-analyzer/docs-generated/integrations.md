---
service: "checkout-flow-analyzer"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 0
---

# Integrations

## Overview

The Checkout Flow Analyzer has one external runtime dependency: Okta Identity Cloud for OIDC-based user authentication. All other data — checkout logs from PWA, proxy, Lazlo, and orders systems — is loaded from pre-exported static files rather than live API calls. There are no internal Continuum service-to-service dependencies at runtime.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Okta Identity Cloud | HTTPS / OIDC | User authentication and session token issuance | yes | `oktaIdentityCloud` (stub) |

### Okta Identity Cloud Detail

- **Protocol**: HTTPS / OpenID Connect (OIDC)
- **Base URL / SDK**: Configured via `OKTA_ISSUER` environment variable; NextAuth `OktaProvider` from `next-auth/providers/okta`; `@okta/okta-auth-js ^7.12.1`
- **Auth**: OAuth 2.0 Authorization Code flow with PKCE; client credentials via `OKTA_CLIENT_ID` and `OKTA_CLIENT_SECRET`
- **Purpose**: Validates the identity of internal users before granting access to any UI page or API endpoint. All non-public routes redirect to `/login` when no valid JWT session is present.
- **Failure mode**: If Okta is unreachable, all users are redirected to the login page and cannot authenticate. No degraded / anonymous mode exists in production.
- **Circuit breaker**: No — NextAuth does not implement a circuit breaker over the Okta OIDC endpoint.
- **Development bypass**: When `NEXT_PUBLIC_AUTH_DEV_MODE=true`, a `CredentialsProvider` is used instead of Okta, allowing sign-in with any username/password combination.

## Internal Dependencies

> No evidence found in codebase. At runtime the application does not call any other Continuum or Encore microservice. Log data is supplied as pre-exported files rather than via live API calls.

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Checkout engineers and analysts | HTTPS (browser) | Use the UI to investigate checkout failures and review conversion metrics |

> Upstream consumers are tracked in the central architecture model. The `checkoutFlowAnalyst` actor is defined as an external stub in the Structurizr model.

## Dependency Health

- **Okta health check**: No explicit health probe implemented. NextAuth's `getToken()` validates the JWT on each request; an invalid or missing token triggers a redirect to `/login`.
- **Filesystem health check**: `FileStorage.listFiles()` silently returns an empty array if the `src/assets/data-files/` directory is missing or unreadable, resulting in an empty time-window list in the UI.
- **No retry logic**: Neither the Okta OIDC flow nor the filesystem adapter implements retry. Transient failures result in an error response or login redirect.
