---
service: "itier-3pip-merchant-onboarding"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 3
internal_count: 4
---

# Integrations

## Overview

The service integrates with three external third-party OAuth platforms (Square, Mindbody, Shopify) and four internal Groupon systems. External integrations are browser-redirect-based OAuth flows; internal integrations are synchronous HTTPS/JSON API calls made by the `merchantApiClient` component. Total: 3 external, 4 internal dependencies. Salesforce and Merchant Center are considered internal Groupon systems in this context.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Square OAuth Platform | HTTPS Redirect / OAuth2 | Merchant authorization and token exchange for Square POS integration | yes | stub-only |
| Mindbody API Platform | HTTPS Redirect / API | Merchant authorization and activation flows for Mindbody integration | yes | stub-only |
| Shopify OAuth Platform | HTTPS Redirect / OAuth2 | Merchant authorization for Shopify store integration | yes | stub-only |

> External platform dependencies (Square, Mindbody, Shopify) are modeled as stub-only in the local workspace. They are not present in the central Continuum architecture model.

### Square OAuth Platform Detail

- **Protocol**: HTTPS Redirect + OAuth2 token exchange
- **Base URL / SDK**: Redirect to Square OAuth authorization URL; callback handled by `merchantOauthHandlers`
- **Auth**: OAuth2 authorization code flow
- **Purpose**: Initiates and completes merchant authorization to link their Square account to Groupon
- **Failure mode**: OAuth flow aborted; merchant shown error state; no onboarding state persisted
- **Circuit breaker**: No evidence found

### Mindbody API Platform Detail

- **Protocol**: HTTPS Redirect + Mindbody API calls via `@grpn/mindbody-client`
- **Base URL / SDK**: `@grpn/mindbody-client`
- **Auth**: OAuth2 / Mindbody API credentials
- **Purpose**: Redirects merchant to Mindbody activation flow; exchanges credentials for partner mapping
- **Failure mode**: Onboarding flow aborted; merchant shown error state
- **Circuit breaker**: No evidence found

### Shopify OAuth Platform Detail

- **Protocol**: HTTPS Redirect + OAuth2 token exchange
- **Base URL / SDK**: Redirect to Shopify OAuth authorization URL; callback handled by `merchantOauthHandlers`
- **Auth**: OAuth2 authorization code flow
- **Purpose**: Initiates and completes merchant authorization to link their Shopify store to Groupon
- **Failure mode**: OAuth flow aborted; merchant shown error state
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Universal Merchant API | HTTPS/JSON | Reads and updates 3PIP merchant mapping, auth, and onboarding state | `continuumUniversalMerchantApi` |
| Partner Service | HTTPS/JSON | Executes partner auth and MSS onboarding operations | `continuumPartnerService` |
| Users Service | HTTPS/JSON | Fetches merchant user profile and identity data | `continuumUsersService` |
| Salesforce CRM | HTTPS/JSON | Synchronizes CRM onboarding/auth state when required | `salesForce` |
| Merchant Center | HTTPS Redirect | Navigates merchants to draft/deal and reservation landing pages post-onboarding | `merchantCenter` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. This service is consumed directly by merchant browsers navigating the 3PIP onboarding UX.

## Dependency Health

- All internal API calls are made via `gofer` and partner-specific `@grpn/*` clients which provide standard HTTP retry semantics
- No explicit circuit breaker configuration was identified in the inventory
- Okta JWT validation (`@okta/jwt-verifier`) is a hard dependency for authenticated routes — JWT validation failure blocks the request
