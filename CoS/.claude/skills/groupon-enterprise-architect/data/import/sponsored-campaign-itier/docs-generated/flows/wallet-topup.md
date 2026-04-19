---
service: "sponsored-campaign-itier"
title: "Wallet Top-Up"
generated: "2026-03-02"
type: flow
flow_name: "wallet-topup"
flow_type: synchronous
trigger: "Merchant adds funds to their sponsored campaign wallet"
participants:
  - "Merchant (browser)"
  - "continuumSponsoredCampaignItier"
  - "continuumSponsoredCampaignItier_authMiddleware"
  - "continuumSponsoredCampaignItier_billingModule"
  - "continuumSponsoredCampaignItier_billingProxyApi"
  - "continuumSponsoredCampaignItier_umapiClient"
  - "continuumUniversalMerchantApi"
architecture_ref: "components-continuum-sponsored-campaign-itier"
---

# Wallet Top-Up

## Summary

This flow handles the process of a merchant adding funds to their sponsored campaign wallet. The merchant selects an existing payment method or creates a new billing record, then submits a top-up request. The BFF creates the billing record if needed (via Billing Proxy API to UMAPI) and then posts the top-up amount to the wallet endpoint on UMAPI. A custom gauge metric (`sponsored-top-up-amount`) is recorded for each successful top-up.

## Trigger

- **Type**: user-action
- **Source**: Merchant clicks "Add Funds" or initiates wallet top-up from the Merchant Center billing pages
- **Frequency**: on-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant (browser) | Selects payment method, enters top-up amount, confirms | — |
| Sponsored Campaign iTier | BFF — validates session, serves billing pages, proxies top-up | `continuumSponsoredCampaignItier` |
| Merchant Auth Middleware | Validates authToken cookie on inbound request | `continuumSponsoredCampaignItier_authMiddleware` |
| Billing Module | React pages for payment method management and wallet top-up | `continuumSponsoredCampaignItier_billingModule` |
| Billing Proxy API | Proxies billing record create and wallet top-up to UMAPI Client | `continuumSponsoredCampaignItier_billingProxyApi` |
| UMAPI Client | Issues HTTP requests to Universal Merchant API | `continuumSponsoredCampaignItier_umapiClient` |
| Universal Merchant API | Stores billing record and processes wallet top-up | `continuumUniversalMerchantApi` |

## Steps

1. **Receive billing page request**: Merchant navigates to `/merchant/center/sponsored/campaign/billing/*`.
   - From: `Merchant (browser)`
   - To: `continuumSponsoredCampaignItier`
   - Protocol: REST (HTTP GET)

2. **Validate merchant session**: Auth middleware verifies `authToken` and `mc_mid` cookies.
   - From: `continuumSponsoredCampaignItier_authMiddleware`
   - To: `continuumMerchantApi`
   - Protocol: REST/HTTP

3. **Serve billing module**: SSR Renderer generates the Billing Module SPA shell; browser hydrates it.
   - From: `continuumSponsoredCampaignItier_ssrRenderer`
   - To: `continuumSponsoredCampaignItier_billingModule`
   - Protocol: Preact (in-process SSR)

4. **Fetch existing billing records**: Billing Module calls Billing Proxy API to load saved payment methods.
   - From: `continuumSponsoredCampaignItier_billingModule`
   - To: `continuumSponsoredCampaignItier_billingProxyApi`
   - Protocol: REST/JSON (GET `/merchant/center/sponsored/api/proxy/get_billing_records/{userId}`)

5. **Retrieve billing records from UMAPI**: UMAPI Client fetches billing records via Groupon V2.
   - From: `continuumSponsoredCampaignItier_umapiClient`
   - To: `continuumUniversalMerchantApi`
   - Protocol: REST/HTTP

6. **Create billing record (if new payment method)**: If merchant adds a new payment method, Billing Module POSTs to create billing record endpoint.
   - From: `continuumSponsoredCampaignItier_billingModule`
   - To: `continuumSponsoredCampaignItier_billingProxyApi`
   - Protocol: REST/JSON (POST `/merchant/center/sponsored/api/proxy/create_billing_record/{userId}`)

7. **Persist new billing record in UMAPI**: UMAPI Client creates the billing record via Groupon V2 (`grouponV2.users_billing_records`).
   - From: `continuumSponsoredCampaignItier_umapiClient`
   - To: `continuumUniversalMerchantApi`
   - Protocol: REST/HTTP

8. **Submit wallet top-up**: Merchant confirms top-up amount; Billing Module POSTs to top-up endpoint.
   - From: `Merchant (browser)` (via Billing Module SPA)
   - To: `continuumSponsoredCampaignItier_billingProxyApi`
   - Protocol: REST/JSON (POST `/merchant/center/sponsored/api/proxy/top_up_wallet/{merchantId}`)

9. **Proxy top-up to UMAPI**: Billing Proxy API routes request through UMAPI Client to UMAPI wallet endpoint.
   - From: `continuumSponsoredCampaignItier_umapiClient`
   - To: `continuumUniversalMerchantApi`
   - Protocol: REST/HTTP

10. **Record top-up metric**: BFF records `sponsored-top-up-amount` gauge metric for the transaction.
    - From: `continuumSponsoredCampaignItier`
    - To: Grout/Tracky (via itier-instrumentation)
    - Protocol: In-process metrics

11. **Return confirmation**: UMAPI confirms the top-up; BFF relays success response to browser.
    - From: `continuumUniversalMerchantApi`
    - To: `Merchant (browser)` (via proxy chain)
    - Protocol: REST/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid/expired authToken | Auth middleware rejects request | Merchant redirected to login |
| Billing record creation fails | UMAPI returns 4xx/5xx | Error displayed; top-up not attempted |
| UMAPI wallet top-up returns error | Proxy relays upstream error | Merchant sees error message; wallet balance unchanged |
| Payment method invalid | UMAPI returns 4xx | Error displayed on billing form |

## Sequence Diagram

```
Merchant         -> BFF:               GET /merchant/center/sponsored/campaign/billing/*
BFF              -> MerchantAPI:       Validate authToken cookie
BFF (SSR)        -> BillingModule:     Server-side render billing page
BFF              -> Merchant:          Return rendered HTML
BillingModule    -> BFF:               GET /api/proxy/get_billing_records/{userId}
BFF UmapiClient  -> UMAPI:             Fetch billing records (grouponV2.users_billing_records)
UMAPI            --> BFF:              Return billing records
BFF              --> Merchant:         Return billing records JSON
Merchant         -> BFF:               POST /api/proxy/create_billing_record/{userId} [if new card]
BFF UmapiClient  -> UMAPI:             Create billing record
UMAPI            --> BFF:              Return billing record ID
Merchant         -> BFF:               POST /api/proxy/top_up_wallet/{merchantId}
BFF BillingProxy -> BFF UmapiClient:   Forward top-up request
BFF UmapiClient  -> UMAPI:             POST wallet top-up
UMAPI            --> BFF:              Top-up confirmed
BFF              -> Tracky:            Record sponsored-top-up-amount gauge
BFF              --> Merchant:         Return success response
```

## Related

- Related flows: [View Campaign Performance](view-campaign-performance.md), [Merchant Auth Validation](merchant-auth-validation.md)
- Architecture component view: `components-continuum-sponsored-campaign-itier`
