---
service: "ugc-moderation"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumUgcModeration"
  containers: ["continuumUgcModerationWeb"]
---

# Architecture Context

## System Context

UGC Moderation is a Continuum-platform internal tooling service. It sits between human moderators (Groupon staff) and the `continuumUgcService` backend. Moderators access the tool via browser; the tool translates their actions into authenticated API calls against the UGC service. It also consults `m3_merchant_service` for merchant profile data and the Groupon V2 API for deal information. Access to the tool is controlled by an allowlist of Okta usernames maintained in the service configuration.

The service does not store UGC data itself — it acts as an administrative gateway. All persistent state lives in downstream systems.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| UGC Moderation Web App | `continuumUgcModerationWeb` | WebApp | Node.js/Express | ^16.13.0 / ^3.16.0 | Moderation web application serving HTML pages and JSON APIs for tips, images, ratings, videos, and merchant transfers |

## Components by Container

### UGC Moderation Web App (`continuumUgcModerationWeb`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Tips Controller | Handles tip search, delete (single and bulk), place lookup, and name resolution | Node.js |
| Reported Tips Controller | Fetches and displays flagged/reported tips; supports date-range search | Node.js |
| Images Controller | Moderates user images: search, accept, reject (with reason code), and URL update | Node.js |
| Videos Controller | Moderates user videos: search, accept, and reject | Node.js |
| Ratings Controller | Searches review ratings; supports rating score updates with case tracking | Node.js |
| UGC Lookup Controller | Aggregates merchant UGC data; creates content opt-outs for merchant entities | Node.js |
| Merchant Transfer Controller | Looks up merchant UGC data and transfers UGC associations between merchants | Node.js |
| Okta User Middleware | Enforces Okta-username-based authorization for restricted routes and HTTP verbs | Node.js |
| UGC Lookup Report | Aggregates recommendation and tip count data for merchant pair comparison | Node.js |
| UGC Service Client | `itier-ugc-client` request module; wraps all calls to `continuumUgcService` | Node.js |
| Merchant Data Client | `itier-merchant-data-client` request module; wraps merchant profile lookups | Node.js |
| Groupon V2 Client | `itier-groupon-v2-client` request module; wraps deal data access | Node.js |
| Page Render | `itier-render` based HTML page rendering using Mustache templates | Node.js |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumUgcModerationWeb` | `continuumUgcService` | Moderates UGC content (search, delete, accept, reject, transfer) | HTTPS |
| `continuumUgcModerationWeb` | `merchantDataApi` | Fetches merchant and place profile data for lookup and transfer flows | HTTPS (stub only — not in federated model) |
| `continuumUgcModerationWeb` | `grouponV2Api` | Fetches deal data | HTTPS (stub only — not in federated model) |
| `continuumUgcModerationWeb` | `memcachedCache` | Caches taxonomy/business data (TTL: 30 days fresh, 10 days stale) | Memcached (stub only — not in federated model) |

## Architecture Diagram References

- System context: `contexts-ugcModeration`
- Container: `containers-ugcModeration`
- Component: `components-ugcModerationWeb`
