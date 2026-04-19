---
service: "clo-ita"
title: "Card Management"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "card-management"
flow_type: synchronous
trigger: "User manages enrolled payment cards for CLO"
participants:
  - "continuumCloItaService"
  - "apiProxy"
  - "continuumUsersService"
architecture_ref: "dynamic-claim-flow"
---

# Card Management

## Summary

This flow covers a user managing their enrolled payment cards within the CLO product — primarily un-enrolling a card. The I-Tier frontend loads the user's current enrolled card state from the Users Service, then proxies the un-enrollment or update request to the CLO Backend API via `apiProxy`. After a successful operation, the user's card enrollment state is updated.

## Trigger

- **Type**: user-action
- **Source**: User accesses card management within the CLO enrollment flow at `/clo/enrollment/*` and submits an un-enrollment or card update action
- **Frequency**: On demand, per user action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| CLO ITA Service | Serves card management UI and orchestrates the un-enrollment or update | `continuumCloItaService` |
| API Proxy | Forwards card enrollment/un-enrollment requests to the CLO Backend API | `apiProxy` |
| Users Service | Provides current card enrollment state for the user | `continuumUsersService` |

## Steps

1. **Receive card management request**: `cloHttpRoutes` receives GET to `/clo/enrollment/*` for the card management view.
   - From: `cloHttpRoutes`
   - To: `cloDomainControllers`
   - Protocol: Direct (in-process)

2. **Validate user session**: `itier-user-auth` validates the authenticated session.
   - From: `cloDomainControllers`
   - To: itier-user-auth middleware
   - Protocol: Direct (in-process)

3. **Load enrolled card state**: `cloProxyAdapters` requests the user's current enrolled card list and enrollment state from the Users Service.
   - From: `cloProxyAdapters`
   - To: `continuumUsersService`
   - Protocol: HTTPS/JSON

4. **Render card management page**: Controller assembles enrolled card data and renders the card management UI via Preact.
   - From: `cloDomainControllers`
   - To: HTTP response (client)
   - Protocol: HTTP/HTML

5. **Submit card un-enrollment (DELETE/POST)**: On user action, `cloProxyAdapters` forwards the un-enrollment or update request to the CLO Backend API via `apiProxy` at `/clo/proxy/card_enrollments`.
   - From: `cloProxyAdapters`
   - To: `apiProxy`
   - Protocol: HTTPS/JSON

6. **Return operation result**: Controller renders the updated card management state or error response.
   - From: `cloDomainControllers`
   - To: HTTP response (client)
   - Protocol: HTTP/HTML or JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| continuumUsersService unavailable | Upstream timeout or error | Card management page cannot render |
| apiProxy un-enrollment request fails (5xx) | Error propagated from proxy adapter | User sees error; card enrollment state unchanged |
| User has no enrolled cards | Empty card list from Users Service | User sees empty state message |

## Sequence Diagram

```
User -> continuumCloItaService: GET /clo/enrollment/*
continuumCloItaService -> continuumUsersService: Load enrolled card state
continuumUsersService --> continuumCloItaService: Enrolled card list
continuumCloItaService --> User: Render card management page

User -> continuumCloItaService: DELETE/POST /clo/enrollment/*
continuumCloItaService -> apiProxy: DELETE/POST /clo/proxy/card_enrollments
apiProxy --> continuumCloItaService: Un-enrollment result
continuumCloItaService --> User: Render updated card management state
```

## Related

- Architecture dynamic view: `dynamic-claim-flow`
- Related flows: [Card Enrollment](card-enrollment.md), [Single Deal Claim](single-deal-claim.md)
