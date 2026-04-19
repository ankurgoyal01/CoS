---
service: "itier-3pip-merchant-onboarding"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumMerchantOnboardingItier]
---

# Architecture Context

## System Context

The 3PIP Merchant Onboarding service sits within the Continuum platform as a merchant-facing web application. It receives browser requests from merchants initiating or completing third-party platform connections (Square, Mindbody, Shopify) and orchestrates the OAuth and onboarding flows by delegating all state persistence to internal Groupon APIs. The service is stateless — it holds no persistent data and routes all merchant identity, mapping, and onboarding state through `continuumUniversalMerchantApi`, `continuumPartnerService`, and `continuumUsersService`.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| 3PIP Merchant Onboarding iTier | `continuumMerchantOnboardingItier` | Web Application | Node.js 16, Preact, itier-server | 7.9.1 | Stateless Node.js iTier web application providing 3PIP onboarding UX and OAuth callback endpoints for Square, Mindbody, and Shopify integrations |

## Components by Container

### 3PIP Merchant Onboarding iTier (`continuumMerchantOnboardingItier`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `merchantRoutes` | OpenAPI route declarations and controller entrypoints under `modules/*/open-api.js` and App actions | Node.js |
| `merchantUi` | Preact-based onboarding and connection management UI components | Preact |
| `merchantOauthHandlers` | Partner-specific OAuth load and callback handlers for Square, Mindbody, and Shopify | Node.js |
| `merchantApiClient` | Shared client used to call internal Groupon APIs and partner onboarding endpoints | Fetch/HTTP |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumMerchantOnboardingItier` | `continuumUniversalMerchantApi` | Reads and updates 3PIP merchant mapping, auth, and onboarding state | HTTPS/JSON |
| `continuumMerchantOnboardingItier` | `continuumPartnerService` | Executes partner auth and MSS onboarding operations | HTTPS/JSON |
| `continuumMerchantOnboardingItier` | `continuumUsersService` | Fetches merchant user profile and identity data | HTTPS/JSON |
| `continuumMerchantOnboardingItier` | `salesForce` | Synchronizes CRM onboarding/auth state when required | HTTPS/JSON |
| `continuumMerchantOnboardingItier` | `merchantCenter` | Navigates merchants to draft/deal and reservation landing pages | HTTPS Redirect |
| `merchantRoutes` | `merchantUi` | Renders onboarding pages and partner connection flows | direct |
| `merchantRoutes` | `merchantOauthHandlers` | Dispatches OAuth load and callback endpoints | direct |
| `merchantRoutes` | `merchantApiClient` | Requests merchant configuration and state updates | direct |
| `merchantOauthHandlers` | `merchantApiClient` | Exchanges authorization state and persists partner mapping | direct |
| `merchantApiClient` | `continuumUniversalMerchantApi` | Reads and updates merchant 3PIP onboarding records | HTTPS/JSON |
| `merchantApiClient` | `continuumPartnerService` | Triggers partner auth and onboarding operations | HTTPS/JSON |
| `merchantApiClient` | `continuumUsersService` | Retrieves merchant account profile data | HTTPS/JSON |
| `merchantApiClient` | `salesForce` | Updates CRM records during onboarding state transitions | HTTPS/JSON |

> Relationships to external platforms (Square, Mindbody, Shopify) are stub-only in the local model; those systems are not modeled in the central Continuum architecture.

## Architecture Diagram References

- Component view: `components-merchant-onboarding`
- Dynamic view (Square OAuth): `square-oauth-callback` (stub-only — commented out; references external Square platform not in central model)
