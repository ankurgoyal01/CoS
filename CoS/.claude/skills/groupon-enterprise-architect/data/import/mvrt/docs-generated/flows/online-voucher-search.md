---
service: "mvrt"
title: "Online Voucher Search"
generated: "2026-03-03"
type: flow
flow_name: "online-voucher-search"
flow_type: synchronous
trigger: "HTTP POST from browser SPA to /bulkSearch or /unitSearch"
participants:
  - "mvrt_webRouting"
  - "voucherSearch"
  - "apiProxy"
  - "continuumVoucherInventoryService"
  - "continuumDealCatalogService"
  - "continuumM3MerchantService"
architecture_ref: "dynamic-search_and_redeem_flow"
---

# Online Voucher Search

## Summary

A user (EMEA merchant partner or CS agent) submits one or more voucher codes via the MVRT browser UI, selecting a code type (customer code, security code, unit ID, Salesforce ID, product Salesforce ID, or merchant ID). The Web Routing component receives the request, authenticates the user via Okta, and invokes the Voucher Search Engine. The search engine queries Voucher Inventory Service and Deal Catalog Service in parallel chunks and returns enriched voucher data (with merchant name, deal country, and redemption status) to the browser as JSON.

## Trigger

- **Type**: user-action
- **Source**: MVRT browser SPA (Backbone.js) — user submits a search form
- **Frequency**: On demand, per user search request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser SPA | Initiates search; displays results | — |
| Web Routing and Auth (`mvrt_webRouting`) | Receives HTTP POST, enforces auth, passes attributes to controller | `mvrt_webRouting` |
| Voucher Search Engine (`voucherSearch`) | Executes search logic, fans out to downstream services in chunks | `voucherSearch` |
| API Proxy | Routes all outbound service client calls | `apiProxy` |
| Voucher Inventory Service | Returns voucher unit records matching the search criteria | `continuumVoucherInventoryService` |
| Deal Catalog Service | Returns deal/product metadata (country code, Salesforce ID) for matched units | `continuumDealCatalogService` |
| M3 Merchant Service | Returns merchant name for matched units | `continuumM3MerchantService` |

## Steps

1. **Receive search request**: Browser POSTs to `/bulkSearch` or `/unitSearch` with `codeType` and `codes[]` in the request body.
   - From: Browser SPA
   - To: `mvrt_webRouting`
   - Protocol: REST/HTTP POST

2. **Authenticate and extract context**: Web Routing middleware validates the Okta session; extracts `oktaUser`, `MvrtConfig`, `activeCountries`, `chunkSize`, and redemption-enabled flags from config.
   - From: `mvrt_webRouting`
   - To: `voucherSearch`
   - Protocol: Direct (in-process)

3. **Fan out by code type**: Voucher Search Engine determines the appropriate VIS endpoint for the code type (`searchBySecurityCode`, `searchByCustomerCode`, `searchByUnitIdV1`, `searchByInventoryProductId`, `searchByMerchantId`, `searchBySFIDBatch`, `searchProductSFIDBatch`). Codes are processed in chunks (chunk size per code type from config).
   - From: `voucherSearch`
   - To: `apiProxy` → `continuumVoucherInventoryService`
   - Protocol: REST via `@grpn/voucher-inventory-client`

4. **Enrich with deal metadata**: For each returned unit, the search engine calls Deal Catalog to resolve `inventoryProductId` → `countryCode`, `salesforceId`, `dealId`.
   - From: `voucherSearch`
   - To: `apiProxy` → `continuumDealCatalogService`
   - Protocol: REST via `@grpn/deal-catalog-client`

5. **Enrich with merchant name**: For units with a `merchantId`, the search engine calls M3 Merchant Service to resolve merchant name.
   - From: `voucherSearch`
   - To: `apiProxy` → `continuumM3MerchantService`
   - Protocol: REST via `itier-merchant-data-client`

6. **Fetch redemption details**: For units already in `REDEEMED` status, the search engine calls VIS to retrieve `redeemedBy` and `redemptionNotes`.
   - From: `voucherSearch`
   - To: `apiProxy` → `continuumVoucherInventoryService`
   - Protocol: REST via `@grpn/voucher-inventory-client`

7. **Return enriched results**: The assembled voucher array (with redemption status, country, merchant name, deal info) is serialised to JSON and returned to the browser.
   - From: `voucherSearch` → `mvrt_webRouting`
   - To: Browser SPA
   - Protocol: REST/HTTP 200 JSON response

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| VIS returns non-200 response | Error logged via `itier-tracing`; voucher treated as null | Voucher omitted from results; codes reported as not-found |
| Deal Catalog returns non-200 | Error logged; deal data treated as null | Unit returned without country/Salesforce enrichment |
| M3 Merchant returns non-200 | Error logged; merchant data treated as null | Unit returned without merchant name |
| JSON parse error from upstream | Logged as `[JSON-PARSE-ERROR]`; null returned for that unit | Unit omitted from results |
| Search exceeds `searchLimit` (300,000) | Offline path recommended by UI | User directed to use offline search |

## Sequence Diagram

```
Browser -> mvrt_webRouting: POST /bulkSearch {codeType, codes[]}
mvrt_webRouting -> voucherSearch: invoke search with config context
voucherSearch -> apiProxy: search voucher units (chunked by code type)
apiProxy -> continuumVoucherInventoryService: units.search*()
continuumVoucherInventoryService --> apiProxy: unit records
apiProxy --> voucherSearch: unit records
voucherSearch -> apiProxy: getDeal/getProduct by inventoryProductId
apiProxy -> continuumDealCatalogService: deals.get*()
continuumDealCatalogService --> apiProxy: deal metadata
apiProxy --> voucherSearch: deal metadata
voucherSearch -> apiProxy: getMerchant by merchantId
apiProxy -> continuumM3MerchantService: merchants.getMerchant()
continuumM3MerchantService --> apiProxy: merchant name
apiProxy --> voucherSearch: merchant name
voucherSearch --> mvrt_webRouting: assembled voucher array
mvrt_webRouting --> Browser: 200 JSON {vouchers[]}
```

## Related

- Architecture dynamic view: `dynamic-search_and_redeem_flow`
- Related flows: [Online Voucher Redemption](online-voucher-redemption.md), [Offline Search Job Submission](offline-job-submission.md)
