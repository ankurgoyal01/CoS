---
service: "sponsored-campaign-itier"
title: "Campaign Status Toggle"
generated: "2026-03-02"
type: flow
flow_name: "campaign-status-toggle"
flow_type: synchronous
trigger: "Merchant pauses or resumes a sponsored campaign"
participants:
  - "Merchant (browser)"
  - "continuumSponsoredCampaignItier"
  - "continuumSponsoredCampaignItier_authMiddleware"
  - "continuumSponsoredCampaignItier_campaignWorkflow"
  - "continuumSponsoredCampaignItier_campaignProxyApi"
  - "continuumSponsoredCampaignItier_umapiClient"
  - "continuumUniversalMerchantApi"
architecture_ref: "components-continuum-sponsored-campaign-itier"
---

# Campaign Status Toggle

## Summary

This flow handles a merchant pausing or resuming an active sponsored campaign. The merchant clicks a pause or resume action in the Campaign Workflow SPA; the BFF receives the request, validates the session, and posts the new status to the Campaign Proxy API, which forwards it to UMAPI via the internal API proxy. UMAPI updates the campaign status and returns confirmation.

## Trigger

- **Type**: user-action
- **Source**: Merchant clicks "Pause" or "Resume" on a campaign in Merchant Center
- **Frequency**: on-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant (browser) | Initiates status change action | — |
| Sponsored Campaign iTier | BFF — validates session, routes status change request | `continuumSponsoredCampaignItier` |
| Merchant Auth Middleware | Validates authToken cookie | `continuumSponsoredCampaignItier_authMiddleware` |
| Campaign Workflow SPA | Issues status change POST from browser | `continuumSponsoredCampaignItier_campaignWorkflow` |
| Campaign Proxy API | Receives status change, forwards to UMAPI Client | `continuumSponsoredCampaignItier_campaignProxyApi` |
| UMAPI Client | Issues HTTP status update to Universal Merchant API | `continuumSponsoredCampaignItier_umapiClient` |
| Universal Merchant API | Updates campaign status (paused/active) | `continuumUniversalMerchantApi` |

## Steps

1. **Receive status change request**: Merchant triggers pause or resume on a campaign; Campaign Workflow SPA sends a POST.
   - From: `Merchant (browser)` (via Campaign Workflow SPA)
   - To: `continuumSponsoredCampaignItier_campaignProxyApi`
   - Protocol: REST/JSON (POST `/merchant/center/sponsored/api/proxy/campaign/{campaignId}/update_status/{status}`)

2. **Validate merchant session**: Auth middleware verifies `authToken` and `mc_mid` cookies.
   - From: `continuumSponsoredCampaignItier_authMiddleware`
   - To: `continuumMerchantApi`
   - Protocol: REST/HTTP

3. **Forward status change to UMAPI Client**: Campaign Proxy API passes the status update to UMAPI Client.
   - From: `continuumSponsoredCampaignItier_campaignProxyApi`
   - To: `continuumSponsoredCampaignItier_umapiClient`
   - Protocol: HTTP (in-process)

4. **Update campaign status in UMAPI**: UMAPI Client POSTs the new status to UMAPI via the internal API proxy.
   - From: `continuumSponsoredCampaignItier_umapiClient`
   - To: `continuumUniversalMerchantApi`
   - Protocol: REST/HTTP (via `http://api-proxy--internal-us.production.service`)

5. **Return updated status**: UMAPI confirms status update; BFF relays confirmation to browser.
   - From: `continuumUniversalMerchantApi`
   - To: `Merchant (browser)` (via proxy chain)
   - Protocol: REST/JSON

6. **SPA updates campaign state**: Campaign Workflow SPA updates the Redux store with the new campaign status and reflects it in the UI.
   - From: `continuumSponsoredCampaignItier_campaignWorkflow` (client-side)
   - To: `Merchant (browser)`
   - Protocol: In-browser Redux state update

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid/expired authToken | Auth middleware rejects request | Merchant redirected to login |
| UMAPI returns 404 (campaign not found) | Proxy relays 404 to SPA | Error displayed; campaign status not changed |
| UMAPI returns 4xx (invalid status transition) | Proxy relays error to SPA | Error message displayed; UI state reverted |
| UMAPI returns 5xx | Proxy relays error to SPA | Generic error displayed; merchant may retry |

## Sequence Diagram

```
Merchant         -> BFF:               POST /api/proxy/campaign/{campaignId}/update_status/{status}
BFF              -> MerchantAPI:       Validate authToken cookie
BFF CampaignProxy -> BFF UmapiClient: Forward status update
BFF UmapiClient  -> UMAPI:             POST campaign status change (paused | active)
UMAPI            --> BFF:              Return updated campaign status
BFF              --> Merchant:         Return confirmation JSON
CampaignWorkflow -> Merchant:          Update Redux state, reflect new status in UI
```

## Related

- Architecture dynamic view: `dynamic-update_campaign_flow` (defined but currently disabled)
- Related flows: [Create Sponsored Campaign](create-sponsored-campaign.md), [Delete Campaign](delete-campaign.md), [Merchant Auth Validation](merchant-auth-validation.md)
