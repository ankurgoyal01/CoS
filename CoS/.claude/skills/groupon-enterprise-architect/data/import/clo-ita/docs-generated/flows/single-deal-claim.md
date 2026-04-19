---
service: "clo-ita"
title: "Single Deal Claim"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "single-deal-claim"
flow_type: synchronous
trigger: "User navigates to a CLO deal claim page and submits a claim"
participants:
  - "continuumCloItaService"
  - "apiProxy"
  - "continuumMarketingDealService"
  - "continuumUsersService"
architecture_ref: "dynamic-claim-flow"
---

# Single Deal Claim

## Summary

This flow covers the end-to-end process of a user claiming a single Card Linked Offer deal. The I-Tier frontend receives the claim request, loads deal eligibility and user enrollment context from downstream services, then proxies the claim submission to the CLO Backend API via `apiProxy`. The result is rendered back to the user as a confirmation or error state.

## Trigger

- **Type**: user-action
- **Source**: User navigates to `/deals/:dealId/claim` and submits the claim form
- **Frequency**: On demand, per user action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| CLO ITA Service | Orchestrates the claim flow; renders page and proxies claim submission | `continuumCloItaService` |
| API Proxy | Forwards claim submission to the CLO Backend API | `apiProxy` |
| Marketing Deal Service | Provides deal details and claim eligibility context | `continuumMarketingDealService` |
| Users Service | Provides user enrollment and consent state | `continuumUsersService` |

## Steps

1. **Receive claim page request**: `cloHttpRoutes` receives GET or POST to `/deals/:dealId/claim`.
   - From: `cloHttpRoutes`
   - To: `cloDomainControllers`
   - Protocol: Direct (in-process)

2. **Validate user session**: `itier-user-auth` validates the authenticated session.
   - From: `cloDomainControllers`
   - To: itier-user-auth middleware
   - Protocol: Direct (in-process)

3. **Load deal eligibility context**: `cloProxyAdapters` requests deal details and claim eligibility from the Marketing Deal Service.
   - From: `cloProxyAdapters`
   - To: `continuumMarketingDealService`
   - Protocol: HTTPS/JSON

4. **Load user enrollment state**: `cloProxyAdapters` requests current user enrollment and consent state from the Users Service.
   - From: `cloProxyAdapters`
   - To: `continuumUsersService`
   - Protocol: HTTPS/JSON

5. **Render claim page (GET)**: Controller assembles deal and user data, renders the CLO claim UI via Preact.
   - From: `cloDomainControllers`
   - To: HTTP response (client)
   - Protocol: HTTP/HTML

6. **Submit claim (POST)**: On form submission, `cloProxyAdapters` forwards the claim request to the CLO Backend API via `apiProxy` at `/clo/proxy/claim`.
   - From: `cloProxyAdapters`
   - To: `apiProxy`
   - Protocol: HTTPS/JSON

7. **Return claim result**: Controller renders the claim confirmation or error response back to the user.
   - From: `cloDomainControllers`
   - To: HTTP response (client)
   - Protocol: HTTP/HTML or JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deal not eligible for claim | Deal eligibility check returns ineligible state | User sees ineligibility message; claim not submitted |
| User not enrolled | User enrollment state missing | User is redirected to enrollment flow |
| apiProxy claim submission fails (5xx) | Error propagated from proxy adapter | User sees error state; claim not recorded |
| continuumMarketingDealService unavailable | Upstream timeout or error | Claim page cannot render; user sees error |
| continuumUsersService unavailable | Upstream timeout or error | Claim page cannot render; user sees error |

## Sequence Diagram

```
User -> continuumCloItaService: GET /deals/:dealId/claim
continuumCloItaService -> continuumMarketingDealService: Load deal eligibility
continuumMarketingDealService --> continuumCloItaService: Deal details + eligibility
continuumCloItaService -> continuumUsersService: Load user enrollment state
continuumUsersService --> continuumCloItaService: User enrollment/consent state
continuumCloItaService --> User: Render claim page

User -> continuumCloItaService: POST /deals/:dealId/claim
continuumCloItaService -> apiProxy: POST /clo/proxy/claim
apiProxy --> continuumCloItaService: Claim result
continuumCloItaService --> User: Render claim confirmation or error
```

## Related

- Architecture dynamic view: `dynamic-claim-flow`
- Related flows: [Bulk Claim](bulk-claim.md), [Card Enrollment](card-enrollment.md), [View Claims](view-claims.md)
