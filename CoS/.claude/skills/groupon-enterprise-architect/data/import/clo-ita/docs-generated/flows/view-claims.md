---
service: "clo-ita"
title: "View Claims"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "view-claims"
flow_type: synchronous
trigger: "User navigates to their linked deals page"
participants:
  - "continuumCloItaService"
  - "continuumUsersService"
  - "continuumDealCatalogService"
architecture_ref: "dynamic-claim-flow"
---

# View Claims

## Summary

This flow covers a user viewing all CLO deals currently linked to their account. The I-Tier frontend fetches the user's linked deals and enriches them with deal catalog metadata, then renders the full linked-deals list. This gives the user a consolidated view of active CLO claims and their status.

## Trigger

- **Type**: user-action
- **Source**: User navigates to `/users/:userId/linked-deals`
- **Frequency**: On demand, per user action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| CLO ITA Service | Orchestrates data loading and renders linked deals list | `continuumCloItaService` |
| Users Service | Provides the list of CLO deals linked to the user | `continuumUsersService` |
| Deal Catalog Service | Provides deal catalog metadata for rendering each linked deal | `continuumDealCatalogService` |

## Steps

1. **Receive linked-deals request**: `cloHttpRoutes` receives GET to `/users/:userId/linked-deals`.
   - From: `cloHttpRoutes`
   - To: `cloDomainControllers`
   - Protocol: Direct (in-process)

2. **Validate user session**: `itier-user-auth` validates the authenticated session and confirms userId matches the session.
   - From: `cloDomainControllers`
   - To: itier-user-auth middleware
   - Protocol: Direct (in-process)

3. **Load linked deals for user**: `cloProxyAdapters` requests the list of CLO deals linked to the user from the Users Service.
   - From: `cloProxyAdapters`
   - To: `continuumUsersService`
   - Protocol: HTTPS/JSON

4. **Load deal catalog metadata**: `cloProxyAdapters` enriches linked deal records with metadata from the Deal Catalog Service.
   - From: `cloProxyAdapters`
   - To: `continuumDealCatalogService`
   - Protocol: HTTPS/JSON

5. **Render linked deals page**: Controller assembles the enriched deals list and renders the CLO linked-deals UI via Preact.
   - From: `cloDomainControllers`
   - To: HTTP response (client)
   - Protocol: HTTP/HTML

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| continuumUsersService unavailable | Upstream timeout or error | Linked deals page cannot render; user sees error |
| continuumDealCatalogService unavailable | Upstream timeout or error | Deals list renders without full metadata, or error shown |
| User has no linked deals | Empty list returned by Users Service | User sees empty state message |

## Sequence Diagram

```
User -> continuumCloItaService: GET /users/:userId/linked-deals
continuumCloItaService -> continuumUsersService: Load user linked deals
continuumUsersService --> continuumCloItaService: Linked deals list
continuumCloItaService -> continuumDealCatalogService: Load deal catalog metadata
continuumDealCatalogService --> continuumCloItaService: Deal metadata
continuumCloItaService --> User: Render linked deals page
```

## Related

- Architecture dynamic view: `dynamic-claim-flow`
- Related flows: [Claim Details and Transaction](claim-details-transaction.md), [Transaction Summary](transaction-summary.md)
