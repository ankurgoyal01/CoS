---
service: "clo-ita"
title: "Missing Cashback Support"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "missing-cashback-support"
flow_type: synchronous
trigger: "User reports a missing cashback transaction and submits a support request"
participants:
  - "continuumCloItaService"
  - "apiProxy"
  - "continuumOrdersService"
  - "continuumUsersService"
architecture_ref: "dynamic-claim-flow"
---

# Missing Cashback Support

## Summary

This flow covers the process by which a user reports a missing CLO cashback transaction. The I-Tier frontend loads the user's transaction history and account context to pre-populate the support form, then proxies the missing cash-back submission to the CLO Backend API via `apiProxy`. This flow enables users to dispute cashback that was expected but not received.

## Trigger

- **Type**: user-action
- **Source**: User navigates to `/clo/missing_cash_back/*` and submits the missing cashback form
- **Frequency**: On demand, per user action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| CLO ITA Service | Serves the missing cashback form and proxies the support submission | `continuumCloItaService` |
| API Proxy | Forwards the missing cashback request to the CLO Backend API | `apiProxy` |
| Orders Service | Provides transaction history to support form pre-population | `continuumOrdersService` |
| Users Service | Provides user account and enrollment context | `continuumUsersService` |

## Steps

1. **Receive missing cashback page request**: `cloHttpRoutes` receives GET to `/clo/missing_cash_back/*`.
   - From: `cloHttpRoutes`
   - To: `cloDomainControllers`
   - Protocol: Direct (in-process)

2. **Validate user session**: `itier-user-auth` validates the authenticated session.
   - From: `cloDomainControllers`
   - To: itier-user-auth middleware
   - Protocol: Direct (in-process)

3. **Load user account context**: `cloProxyAdapters` requests user profile and enrollment state from the Users Service.
   - From: `cloProxyAdapters`
   - To: `continuumUsersService`
   - Protocol: HTTPS/JSON

4. **Load transaction history**: `cloProxyAdapters` requests transaction records from the Orders Service to pre-populate the missing cashback form.
   - From: `cloProxyAdapters`
   - To: `continuumOrdersService`
   - Protocol: HTTPS/JSON

5. **Render missing cashback form**: Controller assembles user and transaction data, then renders the missing cashback support UI via Preact.
   - From: `cloDomainControllers`
   - To: HTTP response (client)
   - Protocol: HTTP/HTML

6. **Submit missing cashback request (POST)**: On form submission, `cloProxyAdapters` forwards the support request to the CLO Backend API via `apiProxy` at `/clo/missing_cash_back/*`.
   - From: `cloProxyAdapters`
   - To: `apiProxy`
   - Protocol: HTTPS/JSON

7. **Return submission result**: Controller renders the submission confirmation or error response.
   - From: `cloDomainControllers`
   - To: HTTP response (client)
   - Protocol: HTTP/HTML or JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| continuumUsersService unavailable | Upstream timeout or error | Missing cashback form cannot render |
| continuumOrdersService unavailable | Upstream timeout or error | Form renders without pre-populated transaction history |
| apiProxy submission fails (5xx) | Error propagated from proxy adapter | User sees error; support request not submitted |
| No eligible transactions found | Empty transaction list from Orders Service | User sees empty history; manual form entry required |

## Sequence Diagram

```
User -> continuumCloItaService: GET /clo/missing_cash_back/*
continuumCloItaService -> continuumUsersService: Load user account context
continuumUsersService --> continuumCloItaService: User profile + enrollment
continuumCloItaService -> continuumOrdersService: Load transaction history
continuumOrdersService --> continuumCloItaService: Transaction records
continuumCloItaService --> User: Render missing cashback form

User -> continuumCloItaService: POST /clo/missing_cash_back/*
continuumCloItaService -> apiProxy: POST /clo/missing_cash_back/*
apiProxy --> continuumCloItaService: Submission result
continuumCloItaService --> User: Render submission confirmation or error
```

## Related

- Architecture dynamic view: `dynamic-claim-flow`
- Related flows: [Transaction Summary](transaction-summary.md), [Claim Details and Transaction](claim-details-transaction.md)
