---
service: "itier-tpp"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for I-Tier Third Party Partner Portal.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Merchant Onboarding](merchant-onboarding.md) | synchronous | User submits onboarding configuration form | Merchant or ops staff creates and submits an onboarding configuration through the portal, which is persisted in Partner Service |
| [Partner Configuration Review](partner-config-review.md) | synchronous | User submits review decision on a partner configuration | Operations staff reviews a pending partner configuration and posts an approve/reject decision |
| [Booker Deal Mapping](booker-deal-mapping.md) | synchronous | User updates deal-to-Booker mapping | Operations staff maps or updates a Groupon deal to a Booker class, triggering writes to Booker API |
| [Mindbody Deal Mapping](mindbody-deal-mapping.md) | synchronous | User updates deal-to-Mindbody mapping | Operations staff maps or updates a Groupon deal to a Mindbody service, triggering writes to Mindbody API |
| [Portal Page Load](portal-page-load.md) | synchronous | Authenticated user navigates to a portal page | Authenticated request dispatched through route map, controllers, and service adapters to compose and return a server-rendered HTML page |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 5 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The onboarding and deal-mapping flows span multiple services:

- [Merchant Onboarding](merchant-onboarding.md) — references architecture dynamic view `dynamic-itier-tpp-onboarding-flow`
- [Booker Deal Mapping](booker-deal-mapping.md) — spans `continuumTppWebApp`, `continuumPartnerService`, `bookerApi`
- [Mindbody Deal Mapping](mindbody-deal-mapping.md) — spans `continuumTppWebApp`, `continuumPartnerService`, `mindbodyApi`
