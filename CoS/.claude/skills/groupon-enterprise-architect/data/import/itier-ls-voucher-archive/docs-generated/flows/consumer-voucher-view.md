---
service: "itier-ls-voucher-archive"
title: "Consumer Voucher View Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "consumer-voucher-view"
flow_type: synchronous
trigger: "HTTP GET request from consumer browser"
participants:
  - "continuumLsVoucherArchiveItier"
  - "continuumLsVoucherArchiveMemcache"
  - "continuumApiLazloService"
  - "continuumUniversalMerchantApi"
  - "continuumBhuvanService"
  - "Voucher Archive Backend"
architecture_ref: "dynamic-consumer-voucher-details-flow"
---

# Consumer Voucher View Flow

## Summary

This flow handles a consumer's request to view a legacy LivingSocial voucher detail page. The interaction tier receives the GET request, checks Memcached for a cached response, and — on a cache miss — assembles the page by fetching voucher data from the Voucher Archive Backend, user context from Lazlo, merchant data from the Universal Merchant API, and locale context from Bhuvan. The assembled page is cached in Memcached and returned to the browser. This flow is documented as the Structurizr dynamic view `consumer-voucher-details-flow`.

## Trigger

- **Type**: user-action
- **Source**: Consumer navigates to `/ls_voucher_archive/:voucherId` in their browser
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser | Initiates page request | — |
| LS Voucher Archive Interaction Tier | Request handler, page assembler, cache manager | `continuumLsVoucherArchiveItier` |
| LS Voucher Archive Memcache | Runtime cache — checked before API calls | `continuumLsVoucherArchiveMemcache` |
| Voucher Archive Backend | Primary voucher data source | not modelled separately |
| Groupon v2 API (Lazlo) | User context and order data source | `continuumApiLazloService` |
| Universal Merchant API | Merchant profile and location data source | `continuumUniversalMerchantApi` |
| Bhuvan | Geo and locale resolution | `continuumBhuvanService` |

## Steps

1. **Receive voucher page request**: Browser sends GET `/ls_voucher_archive/:voucherId`; `itier-user-auth` validates the session cookie and populates request identity.
   - From: Browser
   - To: `continuumLsVoucherArchiveItier`
   - Protocol: HTTP

2. **Check Memcached for cached page**: Itier checks `continuumLsVoucherArchiveMemcache` for a cached response keyed by voucher ID, locale, and user role.
   - From: `continuumLsVoucherArchiveItier`
   - To: `continuumLsVoucherArchiveMemcache`
   - Protocol: Memcached protocol

3. **Cache hit path**: If Memcached returns a cached response, itier returns the cached HTML to the browser immediately. Flow ends.
   - From: `continuumLsVoucherArchiveMemcache`
   - To: `continuumLsVoucherArchiveItier` -> Browser
   - Protocol: HTTP

4. **Fetch voucher data** (cache miss): Itier calls Voucher Archive Backend to retrieve the voucher record, deal details, and redemption history.
   - From: `continuumLsVoucherArchiveItier`
   - To: Voucher Archive Backend
   - Protocol: REST (keldor)

5. **Fetch user context**: Itier calls Groupon v2 API (`continuumApiLazloService`) to retrieve the authenticated user's account and order context.
   - From: `continuumLsVoucherArchiveItier`
   - To: `continuumApiLazloService`
   - Protocol: REST (keldor)

6. **Fetch merchant data**: Itier calls Universal Merchant API (`continuumUniversalMerchantApi`) to retrieve the merchant name, address, and location for the voucher's associated deal.
   - From: `continuumLsVoucherArchiveItier`
   - To: `continuumUniversalMerchantApi`
   - Protocol: REST (keldor)

7. **Resolve locale via Bhuvan**: Itier calls Bhuvan (`continuumBhuvanService`) to resolve the geo and locale context for localizing the page.
   - From: `continuumLsVoucherArchiveItier`
   - To: `continuumBhuvanService`
   - Protocol: REST (keldor)

8. **Assemble and render page**: Itier combines voucher data, user context, merchant data, and locale into a Preact component tree and renders the HTML page server-side.
   - From: `continuumLsVoucherArchiveItier`
   - To: (in-process Preact SSR)
   - Protocol: in-process

9. **Write response to Memcached**: Itier stores the rendered HTML in `continuumLsVoucherArchiveMemcache` keyed by voucher ID, locale, and role.
   - From: `continuumLsVoucherArchiveItier`
   - To: `continuumLsVoucherArchiveMemcache`
   - Protocol: Memcached protocol

10. **Return page to browser**: Itier returns the assembled HTML response with HTTP 200.
    - From: `continuumLsVoucherArchiveItier`
    - To: Browser
    - Protocol: HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Voucher not found (404 from backend) | Return 404 error page to browser | Consumer sees voucher-not-found error |
| User session invalid | `itier-user-auth` redirects to login | Consumer redirected to Groupon login |
| Voucher Archive Backend unreachable | Express error handler returns 500 | Consumer sees generic error page |
| Lazlo API error | Express error handler returns 500 or degraded page | User context omitted or error page |
| Universal Merchant API error | Merchant data omitted; page renders with partial data | Consumer sees voucher without merchant details |
| Bhuvan error | Default locale used | Page renders with default locale |
| Memcached write failure | Silently skipped; response still returned | Next request will also be a cache miss |

## Sequence Diagram

```
Browser -> LsVoucherArchiveItier: GET /ls_voucher_archive/:voucherId
LsVoucherArchiveItier -> LsVoucherArchiveMemcache: GET cache key (voucherId, locale, role)
LsVoucherArchiveMemcache --> LsVoucherArchiveItier: Cache miss
LsVoucherArchiveItier -> VoucherArchiveBackend: GET /vouchers/:voucherId
VoucherArchiveBackend --> LsVoucherArchiveItier: Voucher record (JSON)
LsVoucherArchiveItier -> LazloAPI: GET /v2/users/me (user context)
LazloAPI --> LsVoucherArchiveItier: User account data (JSON)
LsVoucherArchiveItier -> UniversalMerchantAPI: GET /merchants/:merchantId
UniversalMerchantAPI --> LsVoucherArchiveItier: Merchant profile (JSON)
LsVoucherArchiveItier -> BhuvanService: GET /geodetails?ip=[ip]
BhuvanService --> LsVoucherArchiveItier: Geo and locale data (JSON)
LsVoucherArchiveItier -> LsVoucherArchiveItier: Render Preact page (SSR)
LsVoucherArchiveItier -> LsVoucherArchiveMemcache: SET cache key = rendered HTML
LsVoucherArchiveItier --> Browser: HTTP 200 (HTML page)
```

## Related

- Architecture dynamic view: `consumer-voucher-details-flow`
- Related flows: [Print Voucher PDF](print-voucher-pdf.md), [Page Load with Localization](page-load-with-localization.md)
