---
service: "sponsored-campaign-itier"
title: "Create Sponsored Campaign"
generated: "2026-03-02"
type: flow
flow_name: "create-sponsored-campaign"
flow_type: synchronous
trigger: "Merchant navigates to campaign creation in Merchant Center"
participants:
  - "Merchant (browser)"
  - "continuumSponsoredCampaignItier"
  - "continuumSponsoredCampaignItier_authMiddleware"
  - "continuumSponsoredCampaignItier_featureFlagsClient"
  - "continuumSponsoredCampaignItier_campaignWorkflow"
  - "continuumSponsoredCampaignItier_ssrRenderer"
  - "continuumSponsoredCampaignItier_campaignProxyApi"
  - "continuumSponsoredCampaignItier_umapiClient"
  - "continuumUniversalMerchantApi"
  - "continuumGeoDetailsService"
architecture_ref: "dynamic-update_campaign_flow"
---

# Create Sponsored Campaign

## Summary

This flow covers the end-to-end process by which a Groupon merchant creates a new sponsored campaign promotion. The merchant steps through a multi-step wizard in the Campaign Workflow SPA — selecting a deal, defining geographic targeting (via GeoDetails), setting a budget and date range, and adding payment. On submission, the BFF proxies a create request to UMAPI, which persists the campaign and returns a campaign ID.

## Trigger

- **Type**: user-action
- **Source**: Merchant clicks "Create Campaign" in Groupon Merchant Center
- **Frequency**: on-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant (browser) | Initiates campaign creation; completes wizard steps | — |
| Sponsored Campaign iTier | BFF — serves SPA, validates session, proxies submission | `continuumSponsoredCampaignItier` |
| Merchant Auth Middleware | Validates authToken cookie on inbound request | `continuumSponsoredCampaignItier_authMiddleware` |
| Feature Flags Client | Evaluates flags (e.g., preLaunchFeature, smallBudgetFeature) to gate capabilities | `continuumSponsoredCampaignItier_featureFlagsClient` |
| Campaign Workflow SPA | React/Redux multi-step wizard rendered in browser | `continuumSponsoredCampaignItier_campaignWorkflow` |
| SSR Renderer | Server-side renders campaign creation page shell with initial state | `continuumSponsoredCampaignItier_ssrRenderer` |
| Campaign Proxy API | Receives create submission from SPA, forwards to UMAPI Client | `continuumSponsoredCampaignItier_campaignProxyApi` |
| UMAPI Client | Issues HTTP create request to Universal Merchant API | `continuumSponsoredCampaignItier_umapiClient` |
| Universal Merchant API | Persists campaign record, returns campaign ID | `continuumUniversalMerchantApi` |
| GeoDetails Service | Provides division and location data for targeting step | `continuumGeoDetailsService` |

## Steps

1. **Receive page request**: Merchant navigates to `/merchant/center/sponsored/campaign/homepage` or campaign creation route.
   - From: `Merchant (browser)`
   - To: `continuumSponsoredCampaignItier`
   - Protocol: REST (HTTP GET)

2. **Validate merchant session**: Auth middleware verifies `authToken` and `mc_mid` cookies.
   - From: `continuumSponsoredCampaignItier_authMiddleware`
   - To: `continuumMerchantApi`
   - Protocol: REST/HTTP

3. **Evaluate feature flags**: Feature flags client checks `preLaunchFeature.enabled` and `smallBudgetFeature.enabled` to determine available campaign capabilities.
   - From: `continuumSponsoredCampaignItier_featureFlagsClient`
   - To: `continuumBirdcageService`
   - Protocol: REST/HTTP

4. **Server-side render campaign page**: SSR Renderer generates the Campaign Workflow SPA shell with initial Redux state (available deals, merchant context, feature flags).
   - From: `continuumSponsoredCampaignItier_ssrRenderer`
   - To: `continuumSponsoredCampaignItier_campaignWorkflow`
   - Protocol: Preact (in-process SSR)

5. **Return rendered HTML to browser**: BFF sends the SSR HTML response.
   - From: `continuumSponsoredCampaignItier`
   - To: `Merchant (browser)`
   - Protocol: REST (HTTP response)

6. **Merchant completes wizard steps**: Merchant selects deal, sets targeting (fetches locations from GeoDetails), sets budget, date range, and payment method.
   - From: `Merchant (browser)`
   - To: `continuumSponsoredCampaignItier_campaignWorkflow` (client-side)
   - Protocol: In-browser React/Redux state transitions

7. **Fetch location data for targeting**: Campaign Workflow SPA requests available divisions/locations.
   - From: `continuumSponsoredCampaignItier_geodetailsClient`
   - To: `continuumGeoDetailsService`
   - Protocol: REST/HTTP

8. **Submit campaign creation**: SPA POSTs completed campaign data to the Campaign Proxy API endpoint.
   - From: `Merchant (browser)` (via SPA)
   - To: `continuumSponsoredCampaignItier_campaignProxyApi`
   - Protocol: REST/JSON

9. **Forward to UMAPI Client**: Campaign Proxy API passes the request to the UMAPI Client.
   - From: `continuumSponsoredCampaignItier_campaignProxyApi`
   - To: `continuumSponsoredCampaignItier_umapiClient`
   - Protocol: HTTP (in-process)

10. **Create campaign in UMAPI**: UMAPI Client POSTs to `/v2/merchants/{permalink}/sponsored/campaigns/` via the internal API proxy.
    - From: `continuumSponsoredCampaignItier_umapiClient`
    - To: `continuumUniversalMerchantApi`
    - Protocol: REST/HTTP (via `http://api-proxy--internal-us.production.service`)

11. **Return campaign ID**: UMAPI returns the new campaign ID; BFF relays it to the SPA.
    - From: `continuumUniversalMerchantApi`
    - To: `Merchant (browser)` (via proxy chain)
    - Protocol: REST/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid/expired authToken | Auth middleware rejects request | Merchant redirected to login |
| Feature flag evaluation failure | Flags default to disabled | Campaign creation wizard may have reduced capabilities |
| GeoDetails service unavailable | Location targeting step fails | Error displayed in wizard; merchant cannot proceed with targeting |
| UMAPI create returns 4xx | Proxy relays error to SPA | Merchant sees error message in wizard review step |
| UMAPI create returns 5xx | Proxy relays error to SPA | Merchant sees generic error; campaign not created |

## Sequence Diagram

```
Merchant         -> BFF:               GET /merchant/center/sponsored/campaign/homepage
BFF              -> MerchantAPI:       Validate authToken cookie
BFF              -> Birdcage:          Evaluate preLaunchFeature.enabled, smallBudgetFeature.enabled
BFF (SSR)        -> CampaignWorkflow:  Server-side render wizard page
BFF              -> Merchant:          Return rendered HTML
Merchant         -> GeoDetails:        Fetch available locations (via BFF proxy)
Merchant         -> BFF:               POST campaign data to /merchant/center/sponsored/api/proxy/update_campaign/{id}
BFF CampaignProxy -> BFF UmapiClient:  Forward create request
BFF UmapiClient  -> UMAPI:             POST /v2/merchants/{permalink}/sponsored/campaigns/
UMAPI            --> BFF:              Return campaign ID
BFF              --> Merchant:         Return campaign ID (JSON)
```

## Related

- Architecture dynamic view: `dynamic-update_campaign_flow` (defined but currently disabled)
- Related flows: [Campaign Status Toggle](campaign-status-toggle.md), [Delete Campaign](delete-campaign.md), [Merchant Auth Validation](merchant-auth-validation.md)
