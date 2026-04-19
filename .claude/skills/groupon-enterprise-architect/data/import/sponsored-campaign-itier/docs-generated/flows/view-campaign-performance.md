---
service: "sponsored-campaign-itier"
title: "View Campaign Performance"
generated: "2026-03-02"
type: flow
flow_name: "view-campaign-performance"
flow_type: synchronous
trigger: "Merchant opens the campaign performance dashboard in Merchant Center"
participants:
  - "Merchant (browser)"
  - "continuumSponsoredCampaignItier"
  - "continuumSponsoredCampaignItier_authMiddleware"
  - "continuumSponsoredCampaignItier_performanceDashboard"
  - "continuumSponsoredCampaignItier_ssrRenderer"
  - "continuumSponsoredCampaignItier_performanceProxyApi"
  - "continuumSponsoredCampaignItier_billingProxyApi"
  - "continuumSponsoredCampaignItier_umapiClient"
  - "continuumUniversalMerchantApi"
architecture_ref: "components-continuum-sponsored-campaign-itier"
---

# View Campaign Performance

## Summary

This flow handles the loading of the sponsored campaign performance dashboard. When a merchant navigates to a performance page, the BFF authenticates the session, server-side renders the Performance Dashboard component, and the SPA then fetches performance metrics (impressions, clicks, spend, ROAS), billing records, and wallet balance from UMAPI in parallel. The dashboard renders Chart.js visualizations with the returned data.

## Trigger

- **Type**: user-action
- **Source**: Merchant navigates to a performance route (e.g., `/merchant/center/sponsored/campaign/performance/*`)
- **Frequency**: on-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant (browser) | Requests performance dashboard; consumes rendered charts | — |
| Sponsored Campaign iTier | BFF — authenticates, SSR-renders page, serves proxy endpoints | `continuumSponsoredCampaignItier` |
| Merchant Auth Middleware | Validates authToken cookie | `continuumSponsoredCampaignItier_authMiddleware` |
| SSR Renderer | Server-side renders Performance Dashboard with initial state | `continuumSponsoredCampaignItier_ssrRenderer` |
| Performance Dashboard | React dashboard with Chart.js; requests metrics from Performance Proxy API | `continuumSponsoredCampaignItier_performanceDashboard` |
| Performance Proxy API | Proxies performance metric requests to UMAPI Client | `continuumSponsoredCampaignItier_performanceProxyApi` |
| Billing Proxy API | Proxies billing record and wallet balance requests to UMAPI Client | `continuumSponsoredCampaignItier_billingProxyApi` |
| UMAPI Client | Issues HTTP requests to Universal Merchant API | `continuumSponsoredCampaignItier_umapiClient` |
| Universal Merchant API | Returns performance metrics, billing records, and wallet balance | `continuumUniversalMerchantApi` |

## Steps

1. **Receive performance page request**: Merchant navigates to `/merchant/center/sponsored/campaign/performance/*`.
   - From: `Merchant (browser)`
   - To: `continuumSponsoredCampaignItier`
   - Protocol: REST (HTTP GET)

2. **Validate merchant session**: Auth middleware verifies `authToken` and `mc_mid` cookies.
   - From: `continuumSponsoredCampaignItier_authMiddleware`
   - To: `continuumMerchantApi`
   - Protocol: REST/HTTP

3. **Server-side render dashboard**: SSR Renderer generates the Performance Dashboard shell with initial Redux state.
   - From: `continuumSponsoredCampaignItier_ssrRenderer`
   - To: `continuumSponsoredCampaignItier_performanceDashboard`
   - Protocol: Preact (in-process SSR)

4. **Return rendered HTML**: BFF sends the SSR HTML response to the browser.
   - From: `continuumSponsoredCampaignItier`
   - To: `Merchant (browser)`
   - Protocol: REST (HTTP response)

5. **Fetch performance metrics**: Performance Dashboard SPA calls Performance Proxy API for campaign analytics (impressions, clicks, spend, ROAS).
   - From: `continuumSponsoredCampaignItier_performanceDashboard`
   - To: `continuumSponsoredCampaignItier_performanceProxyApi`
   - Protocol: REST/JSON

6. **Forward metrics request to UMAPI**: Performance Proxy API passes request through UMAPI Client.
   - From: `continuumSponsoredCampaignItier_performanceProxyApi`
   - To: `continuumSponsoredCampaignItier_umapiClient`
   - Protocol: HTTP (in-process)

7. **Retrieve metrics from UMAPI**: UMAPI Client fetches performance data from Universal Merchant API.
   - From: `continuumSponsoredCampaignItier_umapiClient`
   - To: `continuumUniversalMerchantApi`
   - Protocol: REST/HTTP

8. **Fetch billing records**: Billing Module / Dashboard calls Billing Proxy API for billing history and wallet balance.
   - From: `continuumSponsoredCampaignItier_billingModule`
   - To: `continuumSponsoredCampaignItier_billingProxyApi`
   - Protocol: REST/JSON

9. **Retrieve billing records from UMAPI**: Billing Proxy API routes request through UMAPI Client to UMAPI (`grouponV2.users_billing_records`).
   - From: `continuumSponsoredCampaignItier_umapiClient`
   - To: `continuumUniversalMerchantApi`
   - Protocol: REST/HTTP

10. **Render charts**: Performance Dashboard receives metrics and billing data; renders Chart.js visualizations in browser.
    - From: `continuumSponsoredCampaignItier_performanceDashboard` (client-side)
    - To: `Merchant (browser)`
    - Protocol: In-browser rendering

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid/expired authToken | Auth middleware rejects request | Merchant redirected to login |
| UMAPI metrics endpoint unavailable | Proxy returns upstream error | Dashboard shows empty charts or error state |
| UMAPI billing records unavailable | Proxy returns upstream error | Billing section shows error state; metrics may still render |
| No campaign data available | UMAPI returns empty data | Dashboard renders with empty chart states |

## Sequence Diagram

```
Merchant         -> BFF:               GET /merchant/center/sponsored/campaign/performance/{id}
BFF              -> MerchantAPI:       Validate authToken cookie
BFF (SSR)        -> PerfDashboard:     Server-side render dashboard shell
BFF              -> Merchant:          Return rendered HTML
PerfDashboard    -> BFF:               GET /merchant/center/sponsored/api/proxy (performance metrics)
BFF PerfProxy    -> BFF UmapiClient:   Forward metrics request
BFF UmapiClient  -> UMAPI:             Fetch campaign analytics
UMAPI            --> BFF:              Return metrics (impressions, clicks, spend, ROAS)
BFF              --> Merchant:         Return metrics JSON
BillingModule    -> BFF:               GET /merchant/center/sponsored/api/proxy/get_billing_records/{userId}
BFF BillingProxy -> BFF UmapiClient:   Forward billing request
BFF UmapiClient  -> UMAPI:             Fetch billing records and wallet balance
UMAPI            --> BFF:              Return billing records
BFF              --> Merchant:         Return billing records JSON
PerfDashboard    -> Merchant:          Render Chart.js visualizations
```

## Related

- Related flows: [Wallet Top-Up](wallet-topup.md), [Merchant Auth Validation](merchant-auth-validation.md)
- Architecture component view: `components-continuum-sponsored-campaign-itier`
