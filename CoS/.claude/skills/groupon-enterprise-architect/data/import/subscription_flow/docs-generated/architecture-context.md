---
service: "subscription_flow"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumSubscriptionFlowService]
---

# Architecture Context

## System Context

Subscription Flow sits in the Continuum platform's i-tier layer — a pattern of stateless Node.js services that render server-side HTML fragments for integration into Groupon web pages. It is called by web clients or upstream aggregation services when a subscription modal needs to be rendered. The service fetches dynamic configuration from GConfig and calls legacy Lazlo API endpoints and the Groupon V2 API to construct the full modal response. It has no database and does not participate in async messaging.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Subscription Flow Service | `continuumSubscriptionFlowService` | Service | Node.js / itier-server / Express | — | Stateless i-tier web service that renders subscription modal HTML and related assets for Groupon web clients |

## Components by Container

### Subscription Flow Service (`continuumSubscriptionFlowService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Bootstrap | Initialises the itier-server application; wires middleware, config loader, and route registration on startup | itier-server |
| Config Loader | Fetches dynamic configuration and experiment variants from GConfig on bootstrap and periodically | itier-server / GConfig client |
| Router | Maps incoming HTTP request paths to the appropriate controller handler | Express Router |
| Controller Layer | Handles request dispatching; coordinates config data and renderer pipeline invocation | CoffeeScript controllers |
| Renderer Pipeline | Generates HTML output by combining layout templates, Keldor components, and config-driven experiment variants | itier-render |
| Groupon V2 Client | Makes outbound calls to the Groupon V2 API to fetch user context or subscription-related data needed for rendering | itier-groupon-v2 |
| Fingerprint Middleware | Normalises request fingerprint (device, locale, session context) for downstream rendering decisions | Express middleware |
| Groupon Middleware | Applies standard Groupon i-tier middleware (authentication context, request enrichment) | Express middleware |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumSubscriptionFlowService` | `continuumApiLazloService` | Fetches legacy subscription data and endpoints | REST / HTTP |
| `continuumSubscriptionFlowService` | `gconfigService_4b3a` | Fetches dynamic configuration and A/B experiment assignments | REST / HTTP |
| `continuumSubscriptionFlowService` | `grouponV2Api_2d1e` | Fetches user context and subscription state for modal rendering | REST / HTTP |

## Architecture Diagram References

- System context: `contexts-subscription-flow`
- Container: `containers-subscription-flow`
- Component: `components-continuumSubscriptionFlowService`
