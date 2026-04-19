---
service: "merchant-center-web"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [merchantCenterWebSPA]
---

# Architecture Context

## System Context

Merchant Center Web is a client-side SPA within the **Continuum** platform. Merchants interact with it directly via web browser; it has no server-side rendering layer. All data operations are performed by delegating to backend services through proxied REST endpoints — primarily UMAPI for core merchant operations and AIDG for analytics data. The application is distributed as static files from GCP Cloud Storage via Akamai CDN, meaning the serving infrastructure is purely static; all dynamic behavior is driven by browser-to-API calls.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Merchant Center Web SPA | `merchantCenterWebSPA` | WebApp | React / TypeScript / Vite | 19.0.0 / 5.9.3 / 7.1.11 | Single-page application served as static files from GCS; runs entirely in the browser |

## Components by Container

### Merchant Center Web SPA (`merchantCenterWebSPA`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Router | Manages client-side route transitions across /, /login, /onboarding/*, /messages, /account/* | react-router-dom 7.1.4 |
| API Client Layer | Wraps proxied REST calls to UMAPI, AIDG, AIaaS, Bynder, Salesforce | @tanstack/react-query 5.90.12 |
| Auth / SSO Handler | Manages Doorman SSO redirect flow, session tokens, and 2FA enrollment | Doorman SSO (external) |
| Form Engine | Drives deal creation, onboarding, and account forms with validation | react-hook-form 7.62.0, zod 4.1.5 |
| Analytics Layer | Emits user events to PostHog, Google Tag Manager, and Microsoft Clarity | @posthog/react, GTM |
| Feature Flag Client | Evaluates GrowthBook feature flags for progressive rollouts | @growthbook/growthbook-react 1.6.5 |
| Telemetry | Emits browser-side distributed traces | @opentelemetry/sdk-trace-web 1.30.1 |
| i18n | Provides translated UI strings | i18next 25.7.2 |
| Charts / Analytics UI | Renders performance dashboards and reports | chart.js 4.4.8 |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `merchantCenterWebSPA` | UMAPI | All merchant backend operations (deals, orders, account) | REST / HTTPS (proxied) |
| `merchantCenterWebSPA` | AIDG | Analytics and data service queries | REST / HTTPS (proxied) |
| `merchantCenterWebSPA` | AIaaS | Image classification for deal assets | REST / HTTPS (proxied) |
| `merchantCenterWebSPA` | Bynder | Digital asset library browsing and selection | REST / HTTPS (proxied) |
| `merchantCenterWebSPA` | Salesforce | CRM data retrieval for merchant context | REST / HTTPS (proxied) |
| `merchantCenterWebSPA` | Doorman SSO | Authentication and session management | OAuth2 redirect |
| `merchantCenterWebSPA` | GrowthBook | Feature flag evaluation | SDK (in-browser) |
| `merchantCenterWebSPA` | PostHog | Product analytics and session recording | SDK (in-browser) |
| `merchantCenterWebSPA` | Google Tag Manager | Marketing and analytics tag management | SDK (in-browser) |
| `merchantCenterWebSPA` | Microsoft Clarity | Session heatmap and replay | SDK (in-browser) |
| `merchantCenterWebSPA` | Marker.io | Bug reporting overlay | SDK (in-browser) |

## Architecture Diagram References

> No architecture/ folder present in the merchant-center-web repository. Container registered as `merchantCenterWebSPA` in the central Continuum architecture model.

- System context: `contexts-continuum`
- Container: `containers-continuum`
- Component: `components-merchantCenterWebSPA`
