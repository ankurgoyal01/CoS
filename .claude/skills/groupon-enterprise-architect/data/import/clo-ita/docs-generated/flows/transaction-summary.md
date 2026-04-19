---
service: "clo-ita"
title: "Transaction Summary"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "transaction-summary"
flow_type: synchronous
trigger: "User navigates to their CLO transaction summary page"
participants:
  - "continuumCloItaService"
  - "continuumOrdersService"
  - "continuumUsersService"
architecture_ref: "dynamic-claim-flow"
---

# Transaction Summary

## Summary

This flow covers a user viewing an aggregated summary of their CLO cashback transactions. The I-Tier frontend requests transaction and order summary data from the Orders Service, combines it with user account context from the Users Service, and renders a consolidated cashback earnings summary for the user.

## Trigger

- **Type**: user-action
- **Source**: User navigates to `/users/:userId/transaction_summary`
- **Frequency**: On demand, per user action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| CLO ITA Service | Orchestrates data loading and renders the transaction summary page | `continuumCloItaService` |
| Orders Service | Provides aggregated transaction and order summaries for CLO users | `continuumOrdersService` |
| Users Service | Provides user account context and enrollment state | `continuumUsersService` |

## Steps

1. **Receive transaction summary request**: `cloHttpRoutes` receives GET to `/users/:userId/transaction_summary`.
   - From: `cloHttpRoutes`
   - To: `cloDomainControllers`
   - Protocol: Direct (in-process)

2. **Validate user session**: `itier-user-auth` validates the authenticated session and confirms userId matches the session.
   - From: `cloDomainControllers`
   - To: itier-user-auth middleware
   - Protocol: Direct (in-process)

3. **Load user account context**: `cloProxyAdapters` requests user profile and enrollment state from the Users Service.
   - From: `cloProxyAdapters`
   - To: `continuumUsersService`
   - Protocol: HTTPS/JSON

4. **Load transaction summary**: `cloProxyAdapters` requests the CLO transaction and order summary for the user from the Orders Service.
   - From: `cloProxyAdapters`
   - To: `continuumOrdersService`
   - Protocol: HTTPS/JSON

5. **Render transaction summary page**: Controller assembles user and transaction data, then renders the CLO transaction summary UI via Preact.
   - From: `cloDomainControllers`
   - To: HTTP response (client)
   - Protocol: HTTP/HTML

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| continuumOrdersService unavailable | Upstream timeout or error | Transaction summary page cannot render; user sees error |
| continuumUsersService unavailable | Upstream timeout or error | Page cannot render without user context |
| No transactions found | Empty list from Orders Service | User sees empty earnings state message |

## Sequence Diagram

```
User -> continuumCloItaService: GET /users/:userId/transaction_summary
continuumCloItaService -> continuumUsersService: Load user account context
continuumUsersService --> continuumCloItaService: User profile + enrollment state
continuumCloItaService -> continuumOrdersService: Load transaction summary
continuumOrdersService --> continuumCloItaService: CLO transaction summary
continuumCloItaService --> User: Render transaction summary page
```

## Related

- Architecture dynamic view: `dynamic-claim-flow`
- Related flows: [Claim Details and Transaction](claim-details-transaction.md), [View Claims](view-claims.md), [Missing Cashback Support](missing-cashback-support.md)
