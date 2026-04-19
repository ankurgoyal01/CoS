---
service: "subscription-programs-itier"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [subscriptionProgramsItier]
---

# Architecture Context

## System Context

subscription-programs-itier is a Continuum platform web application that sits between browser/webview clients and the Groupon subscription membership APIs. Users navigating to Select enrollment or membership pages are served by this service, which coordinates with the Groupon Subscriptions API for all membership operations and with the Groupon V2 API for membership state. The service has no dedicated architecture folder in the central architecture repository; its container is registered as `subscriptionProgramsItier` within the Continuum system.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Select I-Tier Web App | `subscriptionProgramsItier` | Web App | Node.js / I-Tier / Express | 10.16.3 / 7.9.1 / 4.14.0 | Serves Groupon Select enrollment pages; manages subscription lifecycle UI; coordinates upstream membership API calls |

> No dedicated database or cache container is registered for this service in the central architecture model. Memcached is used for membership and feature flag caching but is managed as an infrastructure-level resource.

## Components by Container

### Select I-Tier Web App (`subscriptionProgramsItier`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Select Landing Page Handler | Renders `/programs/select` and purchase variant pages (`/purchg1`, `/purchgg`, `/purchge`) | Express 4.14.0 / itier-server |
| Benefits Page Handler | Renders `/programs/select/benefits` with current member entitlements | Express / itier-server |
| Subscription Enrollment Handler | Processes `POST /programs/select/subscribe`; calls Groupon Subscriptions API to initiate enrollment | itier-subscriptions-client 3.1.0 |
| Add Card Handler | Renders and processes `/programs/select/subscribe/addcard` for payment method collection | Express / itier-server |
| Confirmation Page Handler | Renders `/programs/select/confirmation` after successful enrollment | Express / itier-server |
| Membership Status Poller (endpoint) | Handles `GET /programs/select/poll`; checks enrollment status with Subscriptions API | itier-subscriptions-client |
| Embedded Webview Handler | Serves Select enrollment flow within a mobile app webview context | Express / itier-server |
| Tracking Hub Emitter | Emits enrollment and membership events to Tracking Hub | tracking-hub-node 1.11.0 |
| Division / Locale Manager | Maintains in-process division and locale data | itier-divisions 7.0.2 |
| SSR Renderer | Renders Preact components server-side for initial HTML delivery | preact 10.0.4 / keldor 7.3.0 |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `subscriptionProgramsItier` | Groupon Subscriptions API | Initiates subscription enrollment, queries membership status, manages billing | REST / HTTPS |
| `subscriptionProgramsItier` | Groupon V2 API (Select Membership) | Fetches current membership state and Select-specific data | REST / HTTPS |
| `subscriptionProgramsItier` | Birdcage | Evaluates feature flags for enrollment flow variants | REST / HTTPS |
| `subscriptionProgramsItier` | GeoDetails API | Resolves geo context for the requesting user | REST / HTTPS |
| `subscriptionProgramsItier` | Tracking Hub | Emits enrollment and membership tracking events | REST / HTTPS |
| `subscriptionProgramsItier` | Memcached | Caches membership state and feature flag data | Memcached binary protocol |

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-continuum`
- Component: `components-subscriptionProgramsItier`

> No architecture folder exists for this service in the central architecture repository. Architecture refs are inferred from the inventory. Confirm container IDs with the central model.
