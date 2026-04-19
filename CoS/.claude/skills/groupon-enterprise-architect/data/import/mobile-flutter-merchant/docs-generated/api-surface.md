---
service: "mobile-flutter-merchant"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [oauth2]
---

# API Surface

## Overview

The Mobile Flutter Merchant app is a consumer of APIs — it does not expose any API surface of its own. All data access flows outward from the app to Continuum backend services via REST/HTTP, orchestrated through the `mmaApiOrchestrator` component. Authentication tokens obtained via Google OAuth / Okta are attached to each outbound request.

## Endpoints

> Not applicable — this service consumes APIs; it does not expose them.

The following navigation screens correspond to the API domains the app interacts with:

| Screen / Feature Area | API Domain | Architecture Ref |
|-----------------------|-----------|-----------------|
| Login | Google OAuth, Okta/webview | `googleOAuth` |
| Dashboard | Universal Merchant API | `continuumUniversalMerchantApi` |
| Deals | Deal Management API | `continuumDealManagementApi` |
| Redemptions | Universal Merchant API | `continuumUniversalMerchantApi` |
| Payments | Payments Service | `continuumPaymentsService` |
| Places | M3 Places Service | `continuumM3PlacesService` |
| Inbox / Support | Salesforce, NOTS Service | `salesForce`, `notsService` |
| Advisor | Merchant Advisor Service | `merchantAdvisorService` |

## Request/Response Patterns

### Common headers

- Authorization bearer token appended by `mmaAuthenticationModule` / `mmaApiOrchestrator` to all outbound requests
- Content-Type: `application/json` for REST calls

### Error format

> No evidence found in the inventory. Error handling patterns are implemented within `mmaApiOrchestrator`; specific error shapes are defined by upstream Continuum services.

### Pagination

> No evidence found in the inventory. Pagination is governed by the upstream API contracts of `continuumUniversalMerchantApi` and `continuumDealManagementApi`.

## Rate Limits

> No rate limiting configured on the client side. Rate limits are enforced by upstream Continuum services.

## Versioning

> Not applicable — the app is a consumer. API versioning is managed by the upstream Continuum API services.

## OpenAPI / Schema References

> No OpenAPI spec maintained in this repository. See upstream service repositories for `continuumUniversalMerchantApi`, `continuumDealManagementApi`, `continuumM3PlacesService`, and `continuumPaymentsService`.
