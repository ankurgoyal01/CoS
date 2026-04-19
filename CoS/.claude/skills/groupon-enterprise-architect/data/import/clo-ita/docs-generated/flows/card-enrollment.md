---
service: "clo-ita"
title: "Card Enrollment"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "card-enrollment"
flow_type: synchronous
trigger: "User navigates to the CLO card enrollment page and submits enrollment"
participants:
  - "continuumCloItaService"
  - "apiProxy"
  - "continuumUsersService"
architecture_ref: "dynamic-claim-flow"
---

# Card Enrollment

## Summary

This flow covers a user enrolling a payment card for Card Linked Offers. The I-Tier frontend renders the enrollment form by loading current user state, then proxies the enrollment submission to the CLO Backend API via `apiProxy`. On success, the user's card is linked to their CLO account and they become eligible to earn cashback on CLO deals.

## Trigger

- **Type**: user-action
- **Source**: User navigates to `/clo/enrollment/*` and submits the enrollment form
- **Frequency**: On demand, per user action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| CLO ITA Service | Serves and orchestrates the enrollment form and submission | `continuumCloItaService` |
| API Proxy | Forwards card enrollment request to the CLO Backend API | `apiProxy` |
| Users Service | Provides current user enrollment state for page rendering | `continuumUsersService` |

## Steps

1. **Receive enrollment page request**: `cloHttpRoutes` receives GET to `/clo/enrollment/*`.
   - From: `cloHttpRoutes`
   - To: `cloDomainControllers`
   - Protocol: Direct (in-process)

2. **Validate user session**: `itier-user-auth` validates the authenticated session.
   - From: `cloDomainControllers`
   - To: itier-user-auth middleware
   - Protocol: Direct (in-process)

3. **Load user enrollment state**: `cloProxyAdapters` requests user's current enrollment and consent state from the Users Service.
   - From: `cloProxyAdapters`
   - To: `continuumUsersService`
   - Protocol: HTTPS/JSON

4. **Render enrollment form**: Controller assembles user state and renders the CLO enrollment UI via Preact.
   - From: `cloDomainControllers`
   - To: HTTP response (client)
   - Protocol: HTTP/HTML

5. **Submit card enrollment (POST)**: On form submission, `cloProxyAdapters` forwards the enrollment request to the CLO Backend API via `apiProxy` at `/clo/proxy/card_enrollments`.
   - From: `cloProxyAdapters`
   - To: `apiProxy`
   - Protocol: HTTPS/JSON

6. **Return enrollment result**: Controller renders the enrollment confirmation or error response.
   - From: `cloDomainControllers`
   - To: HTTP response (client)
   - Protocol: HTTP/HTML or JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| User already enrolled | Users Service returns enrolled state | Enrollment form skipped or redirect to manage cards |
| apiProxy enrollment submission fails (5xx) | Error propagated from proxy adapter | User sees error; card not enrolled |
| continuumUsersService unavailable | Upstream timeout or error | Enrollment page cannot render; user sees error |
| Invalid card data submitted | CLO Backend API returns validation error via apiProxy | User sees form validation error |

## Sequence Diagram

```
User -> continuumCloItaService: GET /clo/enrollment/*
continuumCloItaService -> continuumUsersService: Load user enrollment state
continuumUsersService --> continuumCloItaService: Current enrollment/consent state
continuumCloItaService --> User: Render enrollment form

User -> continuumCloItaService: POST /clo/enrollment/*
continuumCloItaService -> apiProxy: POST /clo/proxy/card_enrollments
apiProxy --> continuumCloItaService: Enrollment result
continuumCloItaService --> User: Render enrollment confirmation or error
```

## Related

- Architecture dynamic view: `dynamic-claim-flow`
- Related flows: [Card Management](card-management.md), [Single Deal Claim](single-deal-claim.md), [Bulk Claim](bulk-claim.md)
