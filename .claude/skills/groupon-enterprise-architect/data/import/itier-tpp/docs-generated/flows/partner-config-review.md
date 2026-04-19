---
service: "itier-tpp"
title: "Partner Configuration Review"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "partner-config-review"
flow_type: synchronous
trigger: "Operations staff submits a review decision on a pending partner configuration"
participants:
  - "merchant"
  - "continuumTppWebApp"
  - "httpRoutes"
  - "featureControllers"
  - "serviceAdapters"
  - "requestModuleRegistry"
  - "continuumPartnerService"
architecture_ref: "dynamic-itier-tpp-onboarding-flow"
---

# Partner Configuration Review

## Summary

The partner configuration review flow enables Groupon operations staff to review, approve, or reject a pending partner configuration submitted through the self-service onboarding path. The reviewer fetches the partner configuration and its review history from Partner Service, then posts a review decision (with optional comment) back to Partner Service. This is a gating workflow that controls whether a partner configuration becomes active.

## Trigger

- **Type**: user-action
- **Source**: Operations staff navigates to `/admin/partner-config-review` and submits a review via `POST /partner_configurations/{configId}/review`
- **Frequency**: On demand (per configuration review session)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operations Staff | Reviews the pending partner configuration and submits approval/rejection | `merchant` (person) |
| I-Tier TPP Web App | Hosts the review UI and orchestrates calls to Partner Service | `continuumTppWebApp` |
| HTTP Route Map | Routes review page and API requests to the appropriate controllers | `httpRoutes` |
| Feature Controllers | Handles review page rendering and review submission logic | `featureControllers` |
| Service Adapters | Wraps Partner Service client for review read/write operations | `serviceAdapters` |
| Request Module Registry | Builds authenticated Partner Service clients | `requestModuleRegistry` |
| Partner Service (PAPI) | Stores and evaluates partner configurations and review decisions | `continuumPartnerService` |

## Steps

1. **Authenticates reviewer**: Operations staff navigates to the review page with a valid `macaroon` cookie; `itier-user-auth` validates the session
   - From: Operations staff (browser)
   - To: `continuumTppWebApp`
   - Protocol: HTTPS

2. **Dispatches review page route**: `httpRoutes` matches `GET /admin/partner-config-review` and forwards to the admin/selfservice feature controller
   - From: `httpRoutes`
   - To: `featureControllers`
   - Protocol: direct (in-process)

3. **Fetches partner configuration**: Controller calls `serviceAdapters` to retrieve the target configuration from Partner Service, including current status
   - From: `featureControllers` via `serviceAdapters`
   - To: `continuumPartnerService`
   - Protocol: REST (HTTPS)

4. **Fetches review history**: Controller calls `GET /partner_configurations/{configId}/reviews` via `serviceAdapters` to load previous review decisions
   - From: `serviceAdapters`
   - To: `continuumPartnerService`
   - Protocol: REST (HTTPS)

5. **Renders review page**: Controller composes the review UI with configuration details and history; returns server-rendered HTML

6. **Reviewer submits decision**: Reviewer selects approve or reject, optionally adds a comment, and submits the form with a CSRF token; browser sends `POST /partner_configurations/{configId}/review`

7. **Posts review decision**: Controller forwards the review payload (`reviewStatus`, `comment`) to Partner Service via `serviceAdapters`
   - From: `serviceAdapters`
   - To: `continuumPartnerService`
   - Protocol: REST (HTTPS)

8. **Returns result**: Controller renders confirmation or redirects to the partner config list

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Config not found | Partner Service returns 404 | Error page rendered |
| Invalid review status value | Partner Service rejects the request | Error surfaced in the portal UI |
| Partner Service unavailable | Service adapter surfaces error | Error page rendered; decision not persisted |
| CSRF token missing or invalid | `csurf` middleware rejects POST | 403 Forbidden |
| Unauthorized reviewer | Doorman macaroon validation fails | 401 redirect to login |

## Sequence Diagram

```
OpsStaff -> continuumTppWebApp: GET /admin/partner-config-review (macaroon cookie)
httpRoutes -> featureControllers: dispatch review controller
featureControllers -> requestModuleRegistry: resolve Partner Service client
featureControllers -> serviceAdapters: fetch partner config
serviceAdapters -> continuumPartnerService: GET /api/partner_configurations?acquisitionMethodId=X
continuumPartnerService --> serviceAdapters: config data
serviceAdapters -> continuumPartnerService: GET /partner_configurations/{configId}/reviews
continuumPartnerService --> serviceAdapters: review history
serviceAdapters --> featureControllers: config + reviews
featureControllers --> OpsStaff: rendered review page HTML

OpsStaff -> continuumTppWebApp: POST /partner_configurations/{configId}/review (CSRF + reviewStatus + comment)
httpRoutes -> featureControllers: dispatch review submit handler
featureControllers -> serviceAdapters: post review decision
serviceAdapters -> continuumPartnerService: POST /partner_configurations/{configId}/review
continuumPartnerService --> serviceAdapters: success
featureControllers --> OpsStaff: confirmation or redirect
```

## Related

- Architecture dynamic view: `dynamic-itier-tpp-onboarding-flow`
- Related flows: [Merchant Onboarding](merchant-onboarding.md), [Portal Page Load](portal-page-load.md)
