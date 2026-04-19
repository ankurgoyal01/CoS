---
service: "itier-ls-voucher-archive"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumLsVoucherArchive"
  containers: [continuumLsVoucherArchiveItier, continuumLsVoucherArchiveMemcache]
---

# Architecture Context

## System Context

itier-ls-voucher-archive sits within the Continuum platform as the interaction tier for the legacy LivingSocial Voucher Archive system. It is the entry point for browser-based requests from consumers, CSR agents, and merchant users who need to access LivingSocial voucher history. It aggregates data from multiple Continuum backend services — `continuumApiLazloService` (Groupon v2 API), `continuumUniversalMerchantApi`, and `continuumBhuvanService` — and from the Voucher Archive Backend to compose server-rendered pages. A Memcached instance (`continuumLsVoucherArchiveMemcache`) provides a runtime cache layer co-located with the itier. A dynamic view `consumer-voucher-details-flow` documents the runtime interaction for the primary consumer voucher view flow.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| LS Voucher Archive Interaction Tier | `continuumLsVoucherArchiveItier` | Web Application | Node.js, Express 4.14, itier-server 5.36.5, Preact 10.0.4 | Node.js 10.x | Server-rendered web application serving consumer, CSR, and merchant voucher pages |
| LS Voucher Archive Memcache | `continuumLsVoucherArchiveMemcache` | Cache | Memcached | — | Runtime cache for rendered responses and downstream API results |

## Components by Container

### LS Voucher Archive Interaction Tier (`continuumLsVoucherArchiveItier`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Consumer voucher route handlers | Render voucher detail and print views for end users | Express, Preact |
| CSR route handlers | Render CSR voucher detail view; handle refund POST submissions | Express, Preact, csurf |
| Merchant route handlers | Render merchant search page; handle search POST; serve CSV export | Express, Preact, csurf |
| itier-user-auth middleware | Validates user session and populates request identity | itier-user-auth 7.0.0 |
| itier-feature-flags middleware | Evaluates feature flags per request context | itier-feature-flags 1.5.0 |
| CSRF middleware | Generates and validates CSRF tokens for mutating routes | csurf 1.6.4 |
| Keldor HTTP client | Issues outbound requests to downstream Continuum services | keldor 7.3.0 |
| Memcached cache layer | Checks and populates Memcached cache around downstream API calls | Memcached client |
| Webpack asset bundle | Client-side JavaScript and CSS served to browsers | webpack 4, Preact 10.0.4 |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumLsVoucherArchiveItier` | `continuumLsVoucherArchiveMemcache` | Reads and writes cached page fragments and API responses | Memcached protocol |
| `continuumLsVoucherArchiveItier` | `continuumApiLazloService` | Fetches Groupon user and order context for voucher pages | REST (keldor) |
| `continuumLsVoucherArchiveItier` | `continuumUniversalMerchantApi` | Retrieves merchant profile and location data | REST (keldor) |
| `continuumLsVoucherArchiveItier` | `continuumBhuvanService` | Resolves geo and locale details for page localization | REST (keldor) |
| `continuumLsVoucherArchiveItier` | Voucher Archive Backend | Fetches voucher records, redemption history, and deal details | REST (keldor) |
| `continuumLsVoucherArchiveItier` | API Proxy | Routes service-to-service calls through internal gateway | REST (keldor) |
| `continuumLsVoucherArchiveItier` | Subscriptions API | Retrieves subscription plan context for vouchers | REST (keldor) |
| `continuumLsVoucherArchiveItier` | GraphQL Gateway | Fetches structured data for complex page composition | GraphQL (keldor) |

## Architecture Diagram References

- System context: `contexts-continuumLsVoucherArchive`
- Container: `containers-continuumLsVoucherArchive`
- Component: `components-continuumLsVoucherArchiveItier`
- Dynamic view: `consumer-voucher-details-flow`
