---
service: "deal"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [dealWebApp]
---

# Architecture Context

## System Context

The deal service sits in the Groupon **Continuum** platform as an I-Tier front-end web application. It occupies the consumer-facing layer of the Commerce / Funnel domain, receiving HTTP requests from browsers, mobile apps, and the Akamai edge layer, and aggregating data from numerous downstream Continuum backend services. The service is stateless — it owns no persistent data store and relies entirely on downstream APIs for all state.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Deal Web App | `dealWebApp` | WebApp | Node.js / Express.js / itier-server | 16 / 4.17.1 / 7.14.2 | Stateless SSR web application serving deal detail pages and AMP variants |

## Components by Container

### Deal Web App (`dealWebApp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Deal Controller | Renders core deal page — prices, availability, merchant info | itier-server / Express route handler |
| Merchant Controller | Renders merchant details section of deal page | itier-server / Express route handler |
| Buy Button Form Controller | Renders purchase/add-to-cart UI | itier-server / Express route handler |
| Deal Highlights Controller | Renders deal highlight content blocks | itier-server / Express route handler |
| Special Content Controller | Renders deal-specific special content (e.g., gig, booking) | itier-server / Express route handler |
| AMP Controller | Renders Accelerated Mobile Pages variant | itier-server / Express route handler |
| Wishlist Page Controller | Renders consumer wishlist page | itier-server / Express route handler |
| Asset Server | Serves Webpack-bundled static assets | Express static middleware |
| Feature Flag Evaluator | Evaluates experiment/feature flags per request | itier-feature-flags 2.2.2 |
| GraphQL Client | Issues GraphQL queries to Groupon APIs | @grpn/graphql 4.1.1 |
| V2 API Client | Issues REST calls to Groupon V2 backend APIs | itier-groupon-v2-client 4.2.5 |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `dealWebApp` | Groupon V2 APIs | Fetches deal data, pricing, merchant, cart, wishlists | REST/HTTP |
| `dealWebApp` | GraphQL APIs | Fetches supplemental deal/merchant data | GraphQL/HTTP |
| `dealWebApp` | Experimentation Service | Evaluates A/B test variant assignments | REST/HTTP |
| `dealWebApp` | Online Booking Service | Fetches appointment availability for bookable deals | REST/HTTP |
| `dealWebApp` | MapProxy / Mapbox | Renders map for merchant location | REST/HTTP |
| `dealWebApp` | Gig Components | Renders gig-type deal content | REST/HTTP |
| Browser / Mobile App | `dealWebApp` | Requests deal page HTML | HTTP |

## Architecture Diagram References

> No architecture/ folder exists for this service in the federated architecture registry. The container `dealWebApp` is defined in the central Continuum model.

- System context: `contexts-continuum`
- Container: `containers-continuum`
- Component: > No evidence found in codebase.
