---
service: "merchant-center-web"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 6
internal_count: 2
---

# Integrations

## Overview

Merchant Center Web integrates with 8 systems: 2 internal Continuum services (UMAPI, AIDG) and 6 external platforms (AIaaS, Bynder, Salesforce, GrowthBook, PostHog, Microsoft Clarity, Google Tag Manager, Marker.io, Doorman SSO). All backend integrations are mediated through proxied REST endpoints; browser SDK integrations load third-party scripts directly.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Doorman SSO | OAuth2 redirect | Merchant authentication and session management | yes | `continuumDoormanSSO` |
| AIaaS | REST (proxied) | AI-powered image classification for deal asset uploads | no | N/A |
| Bynder | REST (proxied) | Digital asset management library for deal images | no | N/A |
| Salesforce | REST (proxied) | CRM context and merchant account data | no | N/A |
| GrowthBook | SDK (in-browser) | Feature flags and A/B test assignment | no | N/A |
| PostHog | SDK (in-browser) | Product analytics, session recording, funnel analysis | no | N/A |
| Google Tag Manager | SDK (in-browser) | Marketing tag and analytics event container | no | N/A |
| Microsoft Clarity | SDK (in-browser) | Session heatmaps and user interaction replay | no | N/A |
| Marker.io | SDK (in-browser) | In-app bug reporting and feedback overlay | no | N/A |

### Doorman SSO Detail

- **Protocol**: OAuth2 redirect
- **Base URL / SDK**: Doorman SSO service (Groupon internal)
- **Auth**: OAuth2 authorization code flow
- **Purpose**: Provides single sign-on for merchants; the SPA redirects unauthenticated users to Doorman and receives a session token on return.
- **Failure mode**: Merchants cannot log in; all authenticated routes become inaccessible.
- **Circuit breaker**: No evidence found in codebase.

### AIaaS Detail

- **Protocol**: REST / HTTPS (proxied)
- **Base URL / SDK**: Internal AIaaS proxy endpoint
- **Auth**: Session token (forwarded via proxy)
- **Purpose**: Classifies images uploaded by merchants during deal creation to ensure compliance with content policies.
- **Failure mode**: Image classification step fails or is bypassed; deal creation may continue with manual review fallback.
- **Circuit breaker**: No evidence found in codebase.

### Bynder Detail

- **Protocol**: REST / HTTPS (proxied)
- **Base URL / SDK**: Bynder DAM API (proxied)
- **Auth**: Session token (forwarded via proxy)
- **Purpose**: Allows merchants to browse and select pre-approved digital assets for deal imagery.
- **Failure mode**: Asset picker becomes unavailable; merchants must upload images directly.
- **Circuit breaker**: No evidence found in codebase.

### Salesforce Detail

- **Protocol**: REST / HTTPS (proxied)
- **Base URL / SDK**: Salesforce REST API (proxied)
- **Auth**: Session token (forwarded via proxy)
- **Purpose**: Surfaces CRM data to support merchant context (e.g., assigned rep, account tier).
- **Failure mode**: CRM data not displayed; core merchant operations unaffected.
- **Circuit breaker**: No evidence found in codebase.

### GrowthBook Detail

- **Protocol**: SDK (in-browser)
- **Base URL / SDK**: @growthbook/growthbook-react 1.6.5
- **Auth**: SDK key (client-side)
- **Purpose**: Evaluates feature flags and A/B test assignments to control progressive rollouts.
- **Failure mode**: Feature flags fall back to default values; no merchant-visible impact expected.
- **Circuit breaker**: Not applicable — SDK with local fallbacks.

### PostHog Detail

- **Protocol**: SDK (in-browser)
- **Base URL / SDK**: @posthog/react 1.8.0
- **Auth**: Project API key (public)
- **Purpose**: Captures product analytics events and session recordings for funnel and UX analysis.
- **Failure mode**: Analytics data not collected; no merchant-visible impact.
- **Circuit breaker**: Not applicable — fire-and-forget telemetry.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| UMAPI | REST (proxied) | All core merchant backend operations: deals, orders, vouchers, inventory, account | `continuumUmapi` |
| AIDG | REST (proxied) | Analytics and data service: report generation, performance metrics | `continuumAidg` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Merchant (human user) | HTTPS / browser | Self-service portal access |

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

> No evidence found in codebase for explicit health check, retry, or circuit breaker patterns at the SPA layer. Retry and error recovery is handled by @tanstack/react-query (configurable retry counts on failed queries). Backend health is the responsibility of UMAPI and AIDG service owners.
