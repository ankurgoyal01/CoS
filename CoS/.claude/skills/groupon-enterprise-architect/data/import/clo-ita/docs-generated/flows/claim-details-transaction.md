---
service: "clo-ita"
title: "Claim Details and Transaction"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "claim-details-transaction"
flow_type: synchronous
trigger: "User navigates to a specific CLO claim detail page"
participants:
  - "continuumCloItaService"
  - "continuumUsersService"
  - "continuumOrdersService"
  - "continuumMarketingDealService"
architecture_ref: "dynamic-claim-flow"
---

# Claim Details and Transaction

## Summary

This flow covers a user viewing the details of a specific CLO claim, including associated transaction history. The I-Tier frontend loads the claim and deal detail from the Marketing Deal Service, the user's enrollment/consent context from the Users Service, and transaction records from the Orders Service, then assembles a detailed claim view for the user.

## Trigger

- **Type**: user-action
- **Source**: User navigates to a CLO claim detail page (linked from their claims list)
- **Frequency**: On demand, per user action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| CLO ITA Service | Orchestrates data loading and renders the claim detail page | `continuumCloItaService` |
| Marketing Deal Service | Provides deal details associated with the claim | `continuumMarketingDealService` |
| Users Service | Provides user enrollment and consent context for the claim | `continuumUsersService` |
| Orders Service | Provides transaction records associated with the CLO claim | `continuumOrdersService` |

## Steps

1. **Receive claim detail request**: `cloHttpRoutes` receives GET to the claim detail endpoint.
   - From: `cloHttpRoutes`
   - To: `cloDomainControllers`
   - Protocol: Direct (in-process)

2. **Validate user session**: `itier-user-auth` validates the authenticated session.
   - From: `cloDomainControllers`
   - To: itier-user-auth middleware
   - Protocol: Direct (in-process)

3. **Load deal details**: `cloProxyAdapters` requests deal metadata and eligibility context from the Marketing Deal Service.
   - From: `cloProxyAdapters`
   - To: `continuumMarketingDealService`
   - Protocol: HTTPS/JSON

4. **Load user enrollment and consent state**: `cloProxyAdapters` requests user enrollment and consent state from the Users Service.
   - From: `cloProxyAdapters`
   - To: `continuumUsersService`
   - Protocol: HTTPS/JSON

5. **Load transaction history**: `cloProxyAdapters` requests CLO-related transaction and order records from the Orders Service.
   - From: `cloProxyAdapters`
   - To: `continuumOrdersService`
   - Protocol: HTTPS/JSON

6. **Render claim detail page**: Controller assembles deal, user, and transaction data, then renders the claim detail UI via Preact.
   - From: `cloDomainControllers`
   - To: HTTP response (client)
   - Protocol: HTTP/HTML

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| continuumMarketingDealService unavailable | Upstream timeout or error | Claim detail page cannot render; user sees error |
| continuumUsersService unavailable | Upstream timeout or error | Claim detail page cannot render; user sees error |
| continuumOrdersService unavailable | Upstream timeout or error | Transaction section of page is empty or shows error |
| No transactions found | Empty list returned by Orders Service | User sees empty transaction history state |

## Sequence Diagram

```
User -> continuumCloItaService: GET /<claim-detail-path>
continuumCloItaService -> continuumMarketingDealService: Load deal details
continuumMarketingDealService --> continuumCloItaService: Deal metadata + eligibility
continuumCloItaService -> continuumUsersService: Load user enrollment state
continuumUsersService --> continuumCloItaService: Enrollment/consent state
continuumCloItaService -> continuumOrdersService: Load transaction history
continuumOrdersService --> continuumCloItaService: Transaction records
continuumCloItaService --> User: Render claim detail + transaction page
```

## Related

- Architecture dynamic view: `dynamic-claim-flow`
- Related flows: [View Claims](view-claims.md), [Transaction Summary](transaction-summary.md), [Missing Cashback Support](missing-cashback-support.md)
