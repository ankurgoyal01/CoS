---
service: "clo-ita"
title: "Bulk Claim"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "bulk-claim"
flow_type: synchronous
trigger: "User triggers a bulk claim action to claim multiple CLO deals at once"
participants:
  - "continuumCloItaService"
  - "apiProxy"
  - "continuumUsersService"
  - "continuumMarketingDealService"
architecture_ref: "dynamic-claim-flow"
---

# Bulk Claim

## Summary

This flow covers a user claiming multiple Card Linked Offer deals in a single operation. The I-Tier frontend validates the user's eligibility and enrollment state, then proxies a bulk-claims request to the CLO Backend API via `apiProxy`. This is commonly triggered from a "claim all available deals" action in the UI.

## Trigger

- **Type**: user-action
- **Source**: User submits a bulk claim action (e.g., "Claim All") which posts to `/clo/proxy/bulk_claims`
- **Frequency**: On demand, per user action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| CLO ITA Service | Validates user eligibility and proxies the bulk claim request | `continuumCloItaService` |
| API Proxy | Forwards bulk claim submission to the CLO Backend API | `apiProxy` |
| Users Service | Provides user enrollment and consent state required for eligibility check | `continuumUsersService` |
| Marketing Deal Service | Provides deal eligibility context for the deals being claimed | `continuumMarketingDealService` |

## Steps

1. **Receive bulk claim request**: `cloHttpRoutes` receives POST to `/clo/proxy/bulk_claims`.
   - From: `cloHttpRoutes`
   - To: `cloDomainControllers`
   - Protocol: Direct (in-process)

2. **Validate user session**: `itier-user-auth` validates the authenticated session.
   - From: `cloDomainControllers`
   - To: itier-user-auth middleware
   - Protocol: Direct (in-process)

3. **Load user enrollment state**: `cloProxyAdapters` requests user enrollment and consent state from the Users Service.
   - From: `cloProxyAdapters`
   - To: `continuumUsersService`
   - Protocol: HTTPS/JSON

4. **Load deal eligibility context**: `cloProxyAdapters` requests deal eligibility details from the Marketing Deal Service for the deals in the bulk request.
   - From: `cloProxyAdapters`
   - To: `continuumMarketingDealService`
   - Protocol: HTTPS/JSON

5. **Proxy bulk claims submission**: `cloProxyAdapters` forwards the validated bulk claim request to the CLO Backend API via `apiProxy`.
   - From: `cloProxyAdapters`
   - To: `apiProxy`
   - Protocol: HTTPS/JSON

6. **Return bulk claim result**: Controller renders the bulk claim confirmation or partial/full error response.
   - From: `cloDomainControllers`
   - To: HTTP response (client)
   - Protocol: HTTP/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| User not enrolled | Users Service returns unenrolled state | Bulk claim blocked; user redirected to enrollment |
| One or more deals ineligible | Deal eligibility check returns partial eligibility | Eligible deals claimed; ineligible deals reported in response |
| apiProxy bulk claim submission fails (5xx) | Error propagated from proxy adapter | User sees error; no claims recorded |
| continuumUsersService unavailable | Upstream timeout or error | Bulk claim cannot proceed |
| continuumMarketingDealService unavailable | Upstream timeout or error | Bulk claim cannot proceed without eligibility context |

## Sequence Diagram

```
User -> continuumCloItaService: POST /clo/proxy/bulk_claims
continuumCloItaService -> continuumUsersService: Load user enrollment state
continuumUsersService --> continuumCloItaService: Enrollment/consent state
continuumCloItaService -> continuumMarketingDealService: Load deal eligibility
continuumMarketingDealService --> continuumCloItaService: Deal eligibility context
continuumCloItaService -> apiProxy: POST /clo/proxy/bulk_claims
apiProxy --> continuumCloItaService: Bulk claim result
continuumCloItaService --> User: Render bulk claim confirmation or error
```

## Related

- Architecture dynamic view: `dynamic-claim-flow`
- Related flows: [Single Deal Claim](single-deal-claim.md), [View Claims](view-claims.md), [Card Enrollment](card-enrollment.md)
