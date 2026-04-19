---
service: "sponsored-campaign-itier"
title: "Delete Campaign"
generated: "2026-03-02"
type: flow
flow_name: "delete-campaign"
flow_type: synchronous
trigger: "Merchant confirms deletion of an active or draft sponsored campaign"
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

# Delete Campaign

## Summary

This flow covers how a merchant permanently deletes a sponsored campaign — either an active campaign or a draft. The Campaign Workflow SPA sends a DELETE request to the appropriate Campaign Proxy API endpoint. The BFF validates the merchant session and forwards the request to UMAPI via the internal API proxy. UMAPI removes the campaign record and returns confirmation. Two deletion paths exist: active campaign deletion (`/campaign/{campaignId}`) and draft campaign deletion (`/campaign/delete_draft`).

## Trigger

- **Type**: user-action
- **Source**: Merchant confirms deletion in Merchant Center campaign management UI
- **Frequency**: on-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant (browser) | Confirms deletion action | — |
| Sponsored Campaign iTier | BFF — validates session, routes deletion request | `continuumSponsoredCampaignItier` |
| Merchant Auth Middleware | Validates authToken cookie | `continuumSponsoredCampaignItier_authMiddleware` |
| Campaign Workflow SPA | Issues DELETE request from browser | `continuumSponsoredCampaignItier_campaignWorkflow` |
| Campaign Proxy API | Receives delete request, forwards to UMAPI Client | `continuumSponsoredCampaignItier_campaignProxyApi` |
| UMAPI Client | Issues HTTP DELETE to Universal Merchant API | `continuumSponsoredCampaignItier_umapiClient` |
| Universal Merchant API | Removes campaign record | `continuumUniversalMerchantApi` |

## Steps

1. **Merchant confirms deletion**: Merchant clicks "Delete" and confirms in the Campaign Workflow SPA.
   - From: `Merchant (browser)`
   - To: `continuumSponsoredCampaignItier_campaignWorkflow` (client-side action)
   - Protocol: In-browser user interaction

2. **Send DELETE request to Campaign Proxy API**: Campaign Workflow SPA issues the appropriate DELETE request.
   - For active campaigns: DELETE `/merchant/center/sponsored/api/proxy/campaign/{campaignId}`
   - For draft campaigns: DELETE `/merchant/center/sponsored/api/proxy/campaign/delete_draft`
   - From: `Merchant (browser)` (via SPA)
   - To: `continuumSponsoredCampaignItier_campaignProxyApi`
   - Protocol: REST/JSON

3. **Validate merchant session**: Auth middleware verifies `authToken` and `mc_mid` cookies.
   - From: `continuumSponsoredCampaignItier_authMiddleware`
   - To: `continuumMerchantApi`
   - Protocol: REST/HTTP

4. **Forward DELETE to UMAPI Client**: Campaign Proxy API passes the delete request to UMAPI Client.
   - From: `continuumSponsoredCampaignItier_campaignProxyApi`
   - To: `continuumSponsoredCampaignItier_umapiClient`
   - Protocol: HTTP (in-process)

5. **Delete campaign in UMAPI**: UMAPI Client issues DELETE to UMAPI via the internal API proxy.
   - From: `continuumSponsoredCampaignItier_umapiClient`
   - To: `continuumUniversalMerchantApi`
   - Protocol: REST/HTTP (via `http://api-proxy--internal-us.production.service`)

6. **Return confirmation**: UMAPI confirms deletion; BFF relays response to browser.
   - From: `continuumUniversalMerchantApi`
   - To: `Merchant (browser)` (via proxy chain)
   - Protocol: REST/JSON

7. **SPA updates campaign list**: Campaign Workflow SPA removes the deleted campaign from the Redux store and updates the UI.
   - From: `continuumSponsoredCampaignItier_campaignWorkflow` (client-side)
   - To: `Merchant (browser)`
   - Protocol: In-browser Redux state update

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid/expired authToken | Auth middleware rejects request | Merchant redirected to login |
| UMAPI returns 404 (campaign not found) | Proxy relays 404 to SPA | Error displayed; campaign may already be deleted |
| UMAPI returns 403 (not authorized) | Proxy relays 403 to SPA | Error displayed; merchant lacks permission to delete |
| UMAPI returns 5xx | Proxy relays error to SPA | Generic error displayed; campaign not deleted |

## Sequence Diagram

```
Merchant         -> BFF:               DELETE /api/proxy/campaign/{campaignId}
                                        OR DELETE /api/proxy/campaign/delete_draft
BFF              -> MerchantAPI:       Validate authToken cookie
BFF CampaignProxy -> BFF UmapiClient: Forward DELETE request
BFF UmapiClient  -> UMAPI:             DELETE campaign record
UMAPI            --> BFF:              Return deletion confirmation
BFF              --> Merchant:         Return confirmation JSON
CampaignWorkflow -> Merchant:          Remove campaign from UI / Redux state
```

## Related

- Architecture dynamic view: `dynamic-update_campaign_flow` (defined but currently disabled)
- Related flows: [Create Sponsored Campaign](create-sponsored-campaign.md), [Campaign Status Toggle](campaign-status-toggle.md), [Merchant Auth Validation](merchant-auth-validation.md)
