---
service: "sponsored-campaign-itier"
title: Architecture Context
generated: "2026-03-02"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumSponsoredCampaignItier, continuumUniversalMerchantApi, continuumMerchantApi, continuumGeoDetailsService, continuumBirdcageService]
---

# Architecture Context

## System Context

`sponsored-campaign-itier` is a container within the `continuumSystem` (Continuum Platform) software system. It sits at the boundary between Groupon merchants (browser clients) and a set of internal Continuum backend services. Merchants access it through the Groupon Merchant Center at `https://www.groupon.com/merchant/center/sponsored`. All persistent state — campaign records, billing data, performance metrics — lives in `continuumUniversalMerchantApi` and related upstream services. The BFF authenticates every inbound request through the Merchant API and evaluates feature flags via Birdcage before serving any content.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Sponsored Campaign iTier | `continuumSponsoredCampaignItier` | Frontend BFF | Node.js 20, itier-server, React 17 | 20.19.5 / 7.9.2 | Node.js BFF that serves the merchant-facing sponsored campaign UI and proxies campaign, billing, and performance operations to UMAPI |
| Universal Merchant API | `continuumUniversalMerchantApi` | Backend service | (stub) | — | Primary backend for campaign CRUD, billing records, wallet operations, and performance data |
| Merchant API | `continuumMerchantApi` | Backend service | (stub) | — | Merchant authentication and profile data |
| GeoDetails Service | `continuumGeoDetailsService` | Backend service | (stub) | — | Division and location lookups for campaign targeting |
| Birdcage Service | `continuumBirdcageService` | Backend service | (stub) | — | Feature flag evaluation for canary rollouts and A/B tests |

## Components by Container

### Sponsored Campaign iTier (`continuumSponsoredCampaignItier`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Campaign Proxy API (`continuumSponsoredCampaignItier_campaignProxyApi`) | Express proxy endpoints for campaign CRUD: create, update, pause, resume, and status changes via UMAPI | Express |
| Billing Proxy API (`continuumSponsoredCampaignItier_billingProxyApi`) | Express proxy endpoints for billing records: create, update, delete payment methods and wallet top-up/refund operations via UMAPI | Express |
| Performance Proxy API (`continuumSponsoredCampaignItier_performanceProxyApi`) | Express proxy endpoints for retrieving campaign performance metrics (impressions, clicks, spend, ROAS) from UMAPI | Express |
| UMAPI Client (`continuumSponsoredCampaignItier_umapiClient`) | HTTP client communicating with UMAPI for deals, campaigns, billing, and performance data | itier-groupon-v2-client |
| Merchant API Client (`continuumSponsoredCampaignItier_merchantApiClient`) | HTTP client for merchant authentication and profile data | itier-merchant-api-client |
| Geodetails Client (`continuumSponsoredCampaignItier_geodetailsClient`) | HTTP client for fetching division and location data for campaign targeting | itier-geodetails-v2-client |
| Feature Flags Client (`continuumSponsoredCampaignItier_featureFlagsClient`) | Evaluates feature flags for canary rollouts and A/B tests | itier-feature-flags |
| Campaign Workflow SPA (`continuumSponsoredCampaignItier_campaignWorkflow`) | React/Redux multi-step wizard for campaign creation: deal selection, location targeting, budget setup, date range, payment, and review/submit | React 17, Redux |
| Performance Dashboard (`continuumSponsoredCampaignItier_performanceDashboard`) | React dashboard with Chart.js visualizations for campaign analytics: impressions, clicks, spend, and ROAS over time | React 17, Chart.js |
| Billing Module (`continuumSponsoredCampaignItier_billingModule`) | React pages for managing payment methods, viewing wallet balances, free credits, and billing history | React 17, Redux |
| SSR Renderer (`continuumSponsoredCampaignItier_ssrRenderer`) | itier-server middleware that handles server-side rendering of React pages with Preact and injects initial Redux state | itier-server, Preact |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumSponsoredCampaignItier` | `continuumUniversalMerchantApi` | Proxies campaign, billing, and performance operations | HTTP |
| `continuumSponsoredCampaignItier` | `continuumMerchantApi` | Authenticates merchants and fetches profile data | HTTP |
| `continuumSponsoredCampaignItier` | `continuumGeoDetailsService` | Fetches divisions and locations for campaign targeting | HTTP |
| `continuumSponsoredCampaignItier` | `continuumBirdcageService` | Evaluates feature flags for canary rollouts | HTTP |
| `continuumSponsoredCampaignItier_campaignProxyApi` | `continuumSponsoredCampaignItier_umapiClient` | Proxy campaign CRUD and status operations | HTTP |
| `continuumSponsoredCampaignItier_billingProxyApi` | `continuumSponsoredCampaignItier_umapiClient` | Proxy billing records and wallet operations | HTTP |
| `continuumSponsoredCampaignItier_performanceProxyApi` | `continuumSponsoredCampaignItier_umapiClient` | Fetch performance metrics | HTTP |
| `continuumSponsoredCampaignItier_campaignWorkflow` | `continuumSponsoredCampaignItier_campaignProxyApi` | Create and manage campaigns | REST/JSON |
| `continuumSponsoredCampaignItier_campaignWorkflow` | `continuumSponsoredCampaignItier_billingProxyApi` | Add payment methods | REST/JSON |
| `continuumSponsoredCampaignItier_performanceDashboard` | `continuumSponsoredCampaignItier_performanceProxyApi` | Load analytics data | REST/JSON |
| `continuumSponsoredCampaignItier_billingModule` | `continuumSponsoredCampaignItier_billingProxyApi` | Manage payments and view history | REST/JSON |
| `continuumSponsoredCampaignItier_ssrRenderer` | `continuumSponsoredCampaignItier_campaignWorkflow` | Server-side render campaign pages | Preact |
| `continuumSponsoredCampaignItier_ssrRenderer` | `continuumSponsoredCampaignItier_performanceDashboard` | Server-side render performance dashboard | Preact |
| `continuumSponsoredCampaignItier_ssrRenderer` | `continuumSponsoredCampaignItier_billingModule` | Server-side render billing pages | Preact |
| `continuumSponsoredCampaignItier_umapiClient` | `continuumUniversalMerchantApi` | Deals, campaigns, billing, performance | HTTP |
| `continuumSponsoredCampaignItier_merchantApiClient` | `continuumMerchantApi` | Merchant authentication and profile | HTTP |
| `continuumSponsoredCampaignItier_geodetailsClient` | `continuumGeoDetailsService` | Division and location lookups | HTTP |
| `continuumSponsoredCampaignItier_featureFlagsClient` | `continuumBirdcageService` | Feature flag evaluation | HTTP |

## Architecture Diagram References

- Component: `components-continuum-sponsored-campaign-itier`
- Component (alternate): `sponsored_campaign_itier_components`
